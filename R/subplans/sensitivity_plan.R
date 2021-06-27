sensitivity_plan = drake_plan(
  
  # package training data with whale observations
  nim_pkg_mns_uninformative = target(
    flatten_data(
      images = rbind(Calibration_images, Mns_images),
      pixels = rbind(Calibration_pixels, Mns_pixels),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths,
      priors_bias = priors_bias, priors_sigma = priors_sigma_uninformative,
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # fit model to training data with whale observations
  fit_mns_uninformative = target(
    fit(nim_pkg_file = nim_pkg_mns_uninformative, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = TRUE, useLaser = TRUE),
    format = 'file'
  ),
  
  # extract and package estimated length samples
  length_samples_mns_uninformative = target(
    extract_length_samples(nim_pkg = nim_pkg_mns_uninformative, 
                           sample_file = fit_mns_uninformative,
                           estimated_only = TRUE,
                           mcmc_sample_dir = mcmc_sample_dir),
    format = 'file'
  ),
  
  # posterior diagnostics for mcmc runs
  posterior_report_mns_uninformative = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'posterior_diagnostics.Rmd')),
      output_file = paste(fit_mns_uninformative, '.html', sep = ''),
      output_dir = mcmc_diagnostics_dir,
      quiet = FALSE,
      params = list(samples = fit_mns_uninformative, nburn = nburn)
    )
  ),

  # visualize impact of priors on parameter estimates
  parameter_sensitivity_mns = target(
    command = {
      
      # load posterior samples
      samples_uninformative = readRDS(fit_mns_uninformative)$samples
      samples = readRDS(fit_mns_barometer.laser)$samples
      
      # define burnin
      burn = 1:nburn
      
      # study impact on measurement error parameters
      tgt = c(
        '$\\sigma^2_{baro}$'  = 'sigma[1]',
        '$\\sigma^2_{laser}$' = 'sigma[2]',
        '$\\sigma^2_{pixels}$' = 'sigma[3]'
      )
      
      # fn. to compute posterior summaries from samples
      summarize_samples = function(samples, type) {
        m = mcmc(samples)
        data.frame(parameter = colnames(samples), est = colMeans(m), 
                   sd = apply(m, 2, sd), type = type)
      }
      
      # combine different posterior distributions
      df = rbind(
        summarize_samples(
          samples = samples_uninformative[-burn, tgt], 
          type = 'Uninformative'
        ),
        summarize_samples(
          samples = samples[-burn, tgt], 
          type = 'Standard'
        )
      )
      
      # compute percent changes in posterior quantities
      df.printable = df %>% 
        # assign common value names to all posterior quantities
        pivot_longer(
          cols = c('est', 'sd'), names_to = 'qty', values_to = 'value'
        ) %>% 
        # assemble the different posterior estimates for model parameters
        pivot_wider(id_cols = c('parameter', 'qty'), names_from = 'type', 
                    values_from = 'value') %>% 
        # compute percent change between posterior quantities wrt. model priors
        group_by(parameter, qty) %>% 
        summarise(
          pct.change = (Standard - Uninformative) / Uninformative * 100,
          pct.change.formatted = paste(round(pct.change), '%', sep ='')
        ) %>% 
        # reformat for printing
        ungroup() %>% 
        pivot_wider(id_cols = c('parameter', 'qty'), 
                    names_from = qty, 
                    values_from = pct.change.formatted)
        
      # format table
      df.printable$parameter = names(tgt)
      colnames(df.printable) = c('Parameter', 'Posterior mean', 'Posterior sd.')
      
      # temorary file, for rendering final file
      f = file.path(rendered_report_dir, paste(id_chr(), '.md', sep = ''))
      
      # write table in markdown format
      sink(f)
      kable(
        x = df.printable, 
        caption = paste(
          "Percent changes in the model's posterior quantities when ",
          "replacing uninformative priors with \"standard\" priors.",
          sep =''
        ), 
        escape = FALSE, format = 'pandoc'
      )
      sink()
      
      # render table to word file, delete temporary md file
      fout = pandoc(input = f, format = 'docx')
      unlink(f)
      
      fout
    },
    format = 'file'
  ),
  
  # visualize impact of priors on fitted lengths
  length_sensitivity_mns = target(
    command = {
      
      # load samples for labeled lengths
      lengths_uninformative = readRDS(length_samples_mns_uninformative)
      lengths_standard = readRDS(length_samples_mns_fit_mns_barometer.laser)
      
      # define burnin
      burn = 1:nburn
      
      # function to summarize posterior samples
      summarise_samples = function(samples, type) {
        do.call(rbind, 
          mapply(function(nom, samples) {
            m = mcmc(unlist(samples)[-burn])
            hpds = HPDinterval(m)
            data.frame(name = nom, est = mean(m), sd = sd(m), 
                       lwr = hpds[,'lower'], upr = hpds[,'upper'], type = type)
          }, names(samples), samples, SIMPLIFY = FALSE)
        )
      }
      
      # combine different posterior distributions
      df = rbind(
        summarise_samples(
          samples = lengths_uninformative$samples, 
          type = 'Uninformative'
        ),
        summarise_samples(
          samples = lengths_standard$samples, 
          type = 'Standard'
        )
      )
      
      # build plot      
      linealpha = .3
      pl = ggplot(
        data = df %>% pivot_wider(
          id_cols = c('name', 'type'), 
          names_from = type, values_from = c(est, sd, lwr, upr)
        )
      ) +
        # 1:1 reference line
        geom_abline(slope = 1, intercept = 0, lty = 3) + 
        # HPDs for standard priors
        geom_pointrange(aes(x = est_Uninformative, 
                            y = est_Standard, 
                            ymin = lwr_Standard, ymax = upr_Standard),
                        pch = '.', alpha = linealpha) + 
        # HPDs for uninformative priors
        geom_errorbarh(aes(y = est_Standard,
                           xmin = lwr_Uninformative, 
                           xmax = upr_Uninformative),
                       alpha = linealpha) + 
        # means for both priors
        geom_point(aes(x = est_Uninformative, y = est_Standard)) + 
        # formatting
        xlab('Posterior mean and HPD (Uninformative prior)') + 
        ylab('Posterior mean and HPD (Standard prior)') + 
        theme_few() + 
        theme(panel.border = element_blank()) + 
        coord_equal()
      
      # save plot
      f = file.path(rendered_report_dir, paste(id_chr(), '.pdf', sep = ''))
      ggsave(pl, filename = f)
      f
    }, 
    format = 'file'
  ),
  
  # package training data with whale observations
  nim_pkg_marrs_uninformative = target(
    flatten_data(
      images = rbind(Calibration_images, Marrs_images),
      pixels = rbind(Calibration_pixels, Marrs_pixels),
      train_objs = training_obj,
      priors_altitude = priors_altitude, priors_lengths = priors_lengths,
      priors_bias = priors_bias, priors_sigma = priors_sigma_uninformative,
      mcmc_sample_dir = mcmc_sample_dir
    ),
    format = 'file'
  ),
  
  # fit model to training data with whale observations
  fit_marrs_uninformative = target(
    fit(nim_pkg_file = nim_pkg_marrs_uninformative, niter = niter, 
        mcmc_sample_dir = mcmc_sample_dir, nthin = nthin, 
        useBarometer = TRUE, useLaser = TRUE, length_prior = rbtl),
    format = 'file'
  ),
  
  # posterior diagnostics for mcmc runs
  posterior_report_marrs_uninformative = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'posterior_diagnostics.Rmd')),
      output_file = paste(fit_marrs_uninformative, '.html', sep = ''),
      output_dir = mcmc_diagnostics_dir,
      quiet = FALSE,
      params = list(samples = fit_marrs_uninformative, nburn = nburn)
    )
  ),
  
  # posterior summary of modeled relationship
  posterior_report_relationship_uninformative = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'rbtl_posteriors.Rmd')),
      output_file = paste(fit_marrs_uninformative, '_relationship.html', 
                          sep = ''),
      output_dir = rendered_report_dir,
      quiet = FALSE,
      params = list(samples = fit_marrs_uninformative, nburn = nburn)
    )
  )
)
