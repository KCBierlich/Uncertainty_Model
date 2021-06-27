independent_lengths = function(model, nim_pkg) {
  
  # character vector representation of model
  model.deparsed = deparse(model)
  
  # # get node names to be estimated
  # est_nodes = nim_pkg$map$L$NodeName[nim_pkg$map$L$Estimated == TRUE]
  # 
  # # add independent, uniform priors to model
  # model.augmented = c(
  #   model.deparsed[1],
  #   paste(est_nodes, 
  #         ' ~ dunif(min = priors_lengths[1], max = priors_lengths[2])', 
  #         sep = ''),
  #   model.deparsed[-1]
  # )
  
  indep = nimbleCode({
    # priors for lengths to be estimated
    for(i in 1:N_unknown_lengths) {
      L[L_unknown_inds[i]] ~ dunif(min = priors_lengths[1], 
                                   max = priors_lengths[2])
    }
  })
  
  # reassemble model
  list(
    nim_pkg = nim_pkg,
    model = parse(
      text = c(model.deparsed[1], indep, model.deparsed[-1])
    )[[1]]
  )
}