validation_sensitivity_plan = drake_plan(
  
  # package training data, with testing and training partitions
  nim_pkg_val_uninformative = target(
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
      priors_bias = priors_bias, priors_sigma = priors_sigma_uninformative, 
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # fit model to training data
  fit_val_uninformative = target(
    fit(nim_pkg_file = nim_pkg_val_uninformative, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = grepl('barometer', config),
        useLaser = grepl('laser', config)),
    transform = map(.data = !!model_configs),
    format = 'file'
  ),
  
  # extract and package estimated length samples
  val_length_samples_uninformative = target(
    extract_length_samples(nim_pkg = nim_pkg_val_uninformative,
                           sample_file = fit_val_uninformative,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file',
    transform = map(fit_val_uninformative)
  ), 
  
  # compare models on validation samples
  model_comparisons_uninformative = target(
    command = {
      
      # load posterior samples
      samples = lapply(dplyr::combine(val_length_samples_uninformative), 
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
    transform = combine(val_length_samples_uninformative)
  )
  
)