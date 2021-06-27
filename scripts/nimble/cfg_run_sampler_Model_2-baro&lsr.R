#
# set initial parameters for Model 2 (barometer and laser)
#

attach(nim_pkg$consts)
attach(nim_pkg$data)

nim_pkg$inits = list(
  sigma_baro = rgamma(n = 1, 
                      shape = priors_sigma_altitude['Barometer', 'shape'], 
                      rate = priors_sigma_altitude['Barometer', 'rate']),
  sigma_laser = rgamma(n = 1, 
                       shape = priors_sigma_altitude['Laser', 'shape'], 
                       rate = priors_sigma_altitude['Laser', 'rate']),
  sigma_pixels = rgamma(n = 1,
                        shape = priors_sigma_pixels['shape'],
                        rate = priors_sigma_pixels['rate']),
  bias_baro = priors_bias_altitude['Barometer', 'mean'],
  bias_laser = priors_bias_altitude['Laser', 'mean'],
  bias_pixels = priors_bias_pixels['mean'],
  altitude = altitude_baro,
  pixels = pixels_obs,
  altitude_new = altitude_new_laser,
  pixels_new = pixels_obs_new,
  L_new = altitude_new_baro / fc.test.obs * Sw / Iw * pixels_obs_new
)

nim_pkg$inits$log_sigma_baro = log(nim_pkg$inits$sigma_baro)
nim_pkg$inits$log_sigma_laser = log(nim_pkg$inits$sigma_laser)
nim_pkg$inits$log_sigma_pixels = log(nim_pkg$inits$sigma_pixels)

detach(nim_pkg$consts)
detach(nim_pkg$data)

# construct nimble model
droneLengths = nimbleModel(code = model, 
                           name = 'droneLengths', 
                           constants = nim_pkg$consts, 
                           data = nim_pkg$data, 
                           inits = nim_pkg$inits)

droneLengths_cmp = compileNimble(droneLengths, resetFunctions = TRUE)


#
# build sampler
#

# default MCMC configuration
conf = configureMCMC(droneLengths_cmp, print = TRUE)

# store samples for predicted lengths
conf$addMonitors('L_new')

# store samples for parameters on observation-scale
conf$addMonitors(c('sigma_baro', 'sigma_laser', 'sigma_pixels'))

# construct MCMC sampler
droneLengthsMCMC = buildMCMC(conf)


droneLengthsMCMC_cmp = compileNimble(droneLengthsMCMC, 
                                     project = droneLengths_cmp, 
                                     resetFunctions = TRUE)


#
# run sampler
#

mcmc.out = runMCMC(droneLengthsMCMC_cmp, niter = 1e6)
