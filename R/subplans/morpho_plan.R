morpho_plan = drake_plan(
  
  # package training data with whale observations
  nim_pkg_marrs = target(
    flatten_data(
      images = rbind(Calibration_images, Marrs_images),
      pixels = rbind(Calibration_pixels, Marrs_pixels),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths,
      priors_bias = priors_bias, priors_sigma = priors_sigma,
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),

  # fit model to training data with whale observations
  fit_marrs = target(
    fit(nim_pkg_file = nim_pkg_marrs, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = TRUE, useLaser = TRUE, length_prior = rbtl),
    format = 'file'
  ),

  # extract and package estimated length samples
  length_samples_marrs = target(
    extract_length_samples(nim_pkg = nim_pkg_marrs, sample_file = fit_marrs,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file'
  ),
  
  # posterior diagnostics for mcmc runs
  posterior_report_marrs = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'posterior_diagnostics.Rmd')),
      output_file = paste(fit_marrs, '.html', sep = ''),
      output_dir = mcmc_diagnostics_dir,
      quiet = FALSE,
      params = list(samples = fit_marrs, nburn = nburn)
    )
  ),
  
  # posterior summary of modeled relationship
  posterior_report_relationship = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'rbtl_posteriors.Rmd')),
      output_file = paste(fit_marrs, '_relationship.html', sep = ''),
      output_dir = rendered_report_dir,
      quiet = FALSE,
      params = list(samples = fit_marrs, nburn = nburn)
    )
  )

)
