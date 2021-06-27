lapply(list.files("./R/subplans", full.names = TRUE, recursive = TRUE), source)

the_plan = bind_plans(
  data_plan,
  priors_plan,
  nimble_plan,
  morpho_plan,
  validation_plan,
  report_plan,
  sensitivity_plan,
  validation_sensitivity_plan,
  eda_plan
)