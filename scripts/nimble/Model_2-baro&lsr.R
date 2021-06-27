library(nimble)

model = nimbleCode({
  
  #
  # likelihood and hidden values
  #
  
  for(i in 1:N_train) {
    
    # (unobserved) true altitude observation was made at 
    altitude[i] ~ dunif(min = priors_altitude[1], 
                        max = priors_altitude[2])
    
    # barometer altimeter reading
    altitude_baro[i] ~ dnorm(mean = altitude[i] + bias_baro, sd = sigma_baro)
    
    # laser altimeter reading
    altitude_laser[i] ~ dnorm(mean = altitude[i] + bias_laser, sd = sigma_laser)
    
    # (unobserved) true pixel count w/respect to altitude to object
    pixels[i] <- (L_train * fc.train[i] * Iw) / (altitude[i] * Sw)
    
    # Observed pixel count with measurement error; dependent on dist. to object
    pixels_obs[i] ~ dnorm(mean = pixels[i] + bias_pixels, 
                          sd = sigma_pixels)
    
  }

  
  #
  # measurement error priors
  #
    
  bias_baro ~ dnorm(mean = priors_bias_altitude[1,1], 
                    sd = priors_bias_altitude[1,2])
  
  bias_laser ~ dnorm(mean = priors_bias_altitude[2,1], 
                     sd = priors_bias_altitude[2,2])
  
  bias_pixels ~ dnorm(mean = priors_bias_pixels[1], 
                      sd = priors_bias_pixels[2])
  
  log_sigma_baro ~ dlogGamma(shape = priors_sigma_altitude[1,1], 
                             rate = priors_sigma_altitude[1,2])
  
  log_sigma_laser ~ dlogGamma(shape = priors_sigma_altitude[2,1], 
                              rate = priors_sigma_altitude[2,2])
  
  log_sigma_pixels ~ dlogGamma(shape = priors_sigma_pixels[1], 
                               rate = priors_sigma_pixels[2])
  
  sigma_baro <- exp(log_sigma_baro)
  sigma_laser <- exp(log_sigma_laser)
  sigma_pixels <- exp(log_sigma_pixels)
  
  
  #
  # predictive distribution
  #
  
  for(i in 1:N_new) {
    
    # (unobserved) true altitude observation was made at 
    altitude_new[i] ~ dunif(min = priors_altitude_new[1], 
                            max = priors_altitude_new[2])
    
    # observed barometer altimeter reading
    altitude_new_baro[i] ~ dnorm(mean = altitude_new[i] + bias_baro, 
                                 sd = sigma_baro)
    
    # observed laser altimeter reading
    altitude_new_laser[i] ~ dnorm(mean = altitude_new[i] + bias_laser, 
                                  sd = sigma_laser)
    
    # prior for true Lp
    pixels_new[i] ~ dgamma(shape = priors_pixels_new[1], 
                           rate = priors_pixels_new[2])
    
    # (unobserved) true Lp for w/ respects to altitude to object
    pixels_obs_new[i] ~  dnorm(mean = pixels_new[i] + bias_pixels, 
                               sd = sigma_pixels)
    
    # Object size is deterministic give true (unobserved) geometry
    L_new[i] <- altitude_new[i] / fc.test.obs[i] * Sw / Iw * pixels_new[i]
    
  }
  
})
