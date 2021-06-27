validation_plan = drake_plan(
  
  # indices for validation training
  validation_subset = target(
    sample.int(n = nrow(Calibration_filtered), 
               size = 0.5 * nrow(Calibration_filtered), 
               replace = FALSE),
    seed = 2020
  ),
  
  # indices for validation testing
  validation_subset_test = (1:nrow(Calibration_filtered))[-validation_subset],
  
  # breakpoints used to stratify altitudes for validation
  validation_altitude_breaks = c(0, 30, 60, Inf),
  
  # indices for validation training, stratified by altitude
  validation_subset_stratified = target(
    command = {
      # split images into altitude categories
      altitude_range = cut(
        x = Calibration_filtered$Altitude, 
        breaks = validation_altitude_breaks, 
        include.lowest = TRUE
      )
      # select test/training indices per subset
     validation_inds = data.frame(ind = 1:length(altitude_range), 
                                  range = altitude_range) %>% 
       dplyr::group_by(range) %>% 
       dplyr::slice_sample(prop = .5) %>% 
       ungroup() %>% 
       dplyr::select(ind) %>% 
       unlist() %>% 
       as.numeric()
     # return training/validation inds
     list(
       train = setdiff(1:length(altitude_range), validation_inds),
       test = validation_inds
     )
    }
  ),
  
  # package training data, with testing and training partitions
  nim_pkg_val = target(
    flatten_data(
      images = rbind(Calibration_images[validation_subset, ], 
                     Calibration_images[validation_subset_test, ]),
      pixels = rbind(
        Calibration_pixels[validation_subset, ],
        Calibration_pixels[validation_subset_test, ] %>% 
          dplyr::mutate(
            replicate = 1:n(),
            Measurement = paste(Measurement, ' (', replicate, ')', sep ='')
          ) %>% 
          dplyr::select(-replicate)
      ),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths, 
      priors_bias = priors_bias, priors_sigma = priors_sigma, 
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # package training data, with testing and training partitions
  nim_pkg_val_stratified = target(
    flatten_data(
      images = rbind(Calibration_images[validation_subset_stratified$train, ], 
                     Calibration_images[validation_subset_stratified$test, ]),
      pixels = rbind(
        Calibration_pixels[validation_subset_stratified$train, ],
        Calibration_pixels[validation_subset_stratified$test, ] %>% 
          dplyr::mutate(
            replicate = 1:n(),
            Measurement = paste(Measurement, ' (', replicate, ')', sep ='')
          ) %>% 
          dplyr::select(-replicate)
      ),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths, 
      priors_bias = priors_bias, priors_sigma = priors_sigma, 
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # fit model to training data
  fit_val = target(
    fit(nim_pkg_file = nim_pkg_val, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = grepl('barometer', config),
        useLaser = grepl('laser', config)),
    transform = map(.data = !!model_configs),
    format = 'file'
  ),
  
  # fit model to training data
  fit_val_stratified = target(
    fit(nim_pkg_file = nim_pkg_val_stratified, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = grepl('barometer', config),
        useLaser = grepl('laser', config)),
    transform = map(.data = !!model_configs),
    format = 'file'
  ),
  
  # extract and package estimated length samples
  val_length_samples = target(
    extract_length_samples(nim_pkg = nim_pkg_val,
                           sample_file = fit_val,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file',
    transform = map(fit_val)
  ),
  
  # extract and package estimated length samples
  val_length_samples_stratified = target(
    extract_length_samples(nim_pkg = nim_pkg_val_stratified,
                           sample_file = fit_val_stratified,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file',
    transform = map(fit_val_stratified)
  ), 
  
  # compare models on validation samples
  model_comparisons = target(
    command = {
      
      # load posterior samples
      samples = lapply(dplyr::combine(val_length_samples), 
                       function(x) readRDS(x))
      
      # return error summaries by training object
      df = do.call(rbind, lapply(samples, function(s) { 
        do.call(rbind, mapply(function(obj_name, obj_samples) {
          # posterior samples
          dat = obj_samples[-(1:nburn),]
          # posterior means as point estimates
          pt_est = colMeans(dat)
          # true length of training object
          true_len = training_obj %>% 
            dplyr::filter(Subject == obj_name) %>% 
            dplyr::select(Length) %>% 
            unlist()
          # coverage of posterior hpd intervals
          hpds = HPDinterval(mcmc(dat))
          covered = (hpds[,'lower'] <= true_len) & (true_len <= hpds[,'upper'])
          # summary of model's errors on hold out data
          data.frame(
            # name of training object
            obj = obj_name,
            # error summaries
            rmse = sqrt(mean((pt_est - true_len)^2)),
            mae = mean(abs(pt_est - true_len)),
            crps = mean(crps_sample(
              y = rep(true_len, ncol(dat)), 
              dat = as.matrix(t(dat))
            )),
            coverage = mean(covered),
            # model configuration
            usedBarometer = s$config$consts$useBarometer,
            usedLaser = s$config$consts$useLaser
          )
        }, names(s$samples), s$samples, SIMPLIFY = FALSE))
      }))
      
      # aggregate error summaries by training object
      df %>% 
        dplyr::group_by(usedBarometer, usedLaser) %>% 
        dplyr::summarise(
          rmse = mean(rmse),
          mae = mean(mae),
          crps = mean(crps),
          coverage = mean(coverage)
        )
    },
    transform = combine(val_length_samples)
  ),
  
  # compare models on validation samples
  model_comparisons_stratified = target(
    command = {
      
      # load posterior samples
      samples = lapply(dplyr::combine(val_length_samples_stratified), 
                       function(x) readRDS(x))
      
      # load model configuration
      nim_pkg = readRDS(nim_pkg_val_stratified)
      
      # return error summaries by training object
      df = do.call(rbind, lapply(samples, function(s) { 
        do.call(rbind, mapply(function(obj_name, obj_samples) {
          # posterior samples
          dat = obj_samples[-(1:nburn), , drop = FALSE]
          # posterior means as point estimates
          pt_est = colMeans(dat)
          # true length of training object
          true_len = training_obj %>% 
            dplyr::filter(Subject == obj_name) %>% 
            dplyr::select(Length) %>% 
            unlist()
          # coverage of posterior hpd intervals
          hpds = HPDinterval(mcmc(dat))
          covered = (hpds[,'lower'] <= true_len) & (true_len <= hpds[,'upper'])
          # estimated object names
          est_names = names(pt_est)
          # altitude range associated with each object
          altitude_classes = nim_pkg$maps$L %>% 
            # flatten object names 
            dplyr::mutate(
              NodeName = as.numeric(
                str_extract(string = NodeName, pattern = '[0-9]+')
              )
            ) %>% 
            # associate images ids with objects
            dplyr::left_join(
              data.frame(nim_pkg$consts$pixel_id_map), 
              by = c(NodeName = 'ObjectId')
            ) %>% 
            # associate images with observed altitudes
            dplyr::left_join(
              data.frame(ImageId = 1:nim_pkg$consts$N_images,
                         Altitude = nim_pkg$inits$a),
              by = 'ImageId'
            ) %>% 
            # convert to altitude classes
            dplyr::mutate(
              AltitudeRange = cut(
                x = Altitude, 
                breaks = validation_altitude_breaks, 
                include.lowest = TRUE
              )
            ) %>% 
            # extract ranges
            dplyr::select(Measurement, AltitudeRange)
          # summary of model's errors on hold out data
          data.frame(
            # name of estimated object
            est_name = est_names,
            # errors for individual estimates
            pt_error = pt_est - true_len,
            crps = crps_sample(
              y = rep(true_len, ncol(dat)), 
              dat = as.matrix(t(dat))
            ),
            covered = covered
          ) %>% 
          # associate with altitude classes
          dplyr::left_join(
            altitude_classes, by = c(est_name = 'Measurement')
          ) %>% 
          # summarize errors by altitude class
          dplyr::group_by(AltitudeRange) %>% 
          dplyr::summarise(
            # name of training object
            obj = obj_name,
            # error summaries
            rmse = sqrt(mean(pt_error^2)),
            mae = mean(abs(pt_error)),
            crps = mean(crps),
            coverage = mean(covered),
            # model configuration
            usedBarometer = s$config$consts$useBarometer,
            usedLaser = s$config$consts$useLaser
          )
        }, names(s$samples), s$samples, SIMPLIFY = FALSE))
      }))
      
      # aggregate error summaries by training object
      df %>% 
        dplyr::group_by(usedBarometer, usedLaser, AltitudeRange) %>% 
        dplyr::summarise(
          rmse = mean(rmse),
          mae = mean(mae),
          crps = mean(crps),
          coverage = mean(coverage)
        )
    },
    transform = combine(val_length_samples_stratified)
  )
  
)