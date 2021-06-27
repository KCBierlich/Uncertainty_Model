priors_plan = drake_plan(
  
  # minimum and maximum altitudes (m) at which drones are flown
  priors_altitude = c(min = 5, max = 130),
  
  # minimum and maximum lengths (m) for which the model is used
  priors_lengths = c(min = 0, max = 30),
  
  # prior distributions for measurement error bias parameters
  priors_bias = rbind(
    Barometer = c(mean = 0, sd = 1e2),
    Laser = c(mean = 0, sd = 1e2),
    Pixels = c(mean = 0, sd = 1e2)
  ), 
  
  # prior distributions for measurement error scale parameters
  priors_sigma = rbind(
    Barometer = invgamma.param(mu = 2, sd = 1),
    Laser = invgamma.param(mu = 2, sd = 1),
    Pixels = invgamma.param(mu = 5, sd = 4)
  ),
  
  # prior distributions for measurement error scale parameters
  priors_sigma_uninformative = rbind(
    Barometer = c(shape = .01, rate = .01),
    Laser = c(shape = .01, rate = .01),
    Pixels = c(shape = .01, rate = .01)
  )
  
)
