# define model configurations to analyze
model_configs = data.frame(
  config = c('barometer+laser', 'barometer', 'laser')
)

nimble_plan = drake_plan(
  
  # directory in which to store mcmc samples and files
  mcmc_sample_dir = target({
    f = file.path('output', 'mcmc') 
    dir.create(f, showWarnings = FALSE, recursive = TRUE)
    f
  }),
  
  # directory in which to store mcmc diagnostics
  mcmc_diagnostics_dir = target({
    f = file.path(mcmc_sample_dir, 'diagnostics')
    dir.create(f, showWarnings = FALSE, recursive = TRUE)
    f
  }),

  # number of mcmc iterations to draw, and samples to thin
  niter = 1e4,
  nthin = 10,

  # number of posterior samples to discard during inference
  nburn = niter / nthin / 2,

  # package training data with whale observations
  nim_pkg_mns = target(
    flatten_data(
      images = rbind(Calibration_images, Mns_images),
      pixels = rbind(Calibration_pixels, Mns_pixels),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths,
      priors_bias = priors_bias, priors_sigma = priors_sigma,
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),

  # fit model to training data with whale observations
  fit_mns = target(
    fit(nim_pkg_file = nim_pkg_mns, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = grepl('barometer', config),
        useLaser = grepl('laser', config)),
    transform = map(.data = !!model_configs),
    format = 'file'
  ),

  # extract and package estimated length samples
  length_samples_mns = target(
    extract_length_samples(nim_pkg = nim_pkg_mns, sample_file = fit_mns,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    transform = map(fit_mns),
    format = 'file'
  ),
  
  # posterior diagnostics for mcmc runs
  posterior_report_mns = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'posterior_diagnostics.Rmd')),
      output_file = paste(fit_mns, '.html', sep = ''),
      output_dir = mcmc_diagnostics_dir,
      quiet = FALSE,
      params = list(samples = fit_mns, nburn = nburn)
    ), 
    transform = map(fit_mns)
  )
)
