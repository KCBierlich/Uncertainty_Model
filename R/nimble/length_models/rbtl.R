rbtl = function(model, nim_pkg) {
  
  # template for subject-level joint RB/TL model
  joint_template = gsub(
    pattern = '[\\{\\}]', 
    replacement = '', 
    x = deparse(nimbleCode({
    # RB regressed onto TL; truncation restricts lengths to physical scales
    rbhNode ~ T(dnorm(mean = beta[1] + beta[2] * tlNode, var = sigma_rbh),
                priors_lengths[1], priors_lengths[2])
    # TL varies around population-level mean; truncation used here too
    tlNode ~ T(dnorm(mean = beta[3], var = sigma_tl),
               priors_lengths[1], priors_lengths[2])
  })))
  
  # additional hyperpriors
  hyper = nimbleCode({
    # population mean RB offset, restricted to physical scales
    beta[1] ~ dunif(-3, priors_lengths[2])
    # population-level RB:TL ratio, restricted s.t. RB < TL 
    beta[2] ~ dbeta(1,1)  
    # population mean TL, restricted to physical scales
    beta[3] ~ dunif(priors_lengths[1], priors_lengths[2]) 
    # population-level variability
    sigma_rbh ~ dinvgamma(shape = .01, rate = 100)
    sigma_tl ~ dinvgamma(shape = .01, rate = 100)
  })
  
  # additional model initializations
  nim_pkg$inits$beta = rep(0, 3)
  nim_pkg$inits$sigma_rbh = 1e2
  nim_pkg$inits$sigma_tl = 1e2
  
  # length measurements to be estimated
  L_est = nim_pkg$map$L[nim_pkg$map$L$Estimated == TRUE, , drop = FALSE]
  
  # specialize joint model for RB and TL; loop over all subjects
  joint = sapply(unique(L_est$Subject), function(subj) {
    # identify L[] nodes associated with subject 
    subjNodes = L_est[L_est$Subject == subj, , drop = FALSE]
    # substitutde node names into template for subject
    gsub(
      pattern = 'rbhNode', 
      replacement = subjNodes$NodeName[subjNodes$Measurement == 'RB'], 
      x = gsub(
        pattern = 'tlNode', 
        replacement = subjNodes$NodeName[subjNodes$Measurement == 'TL'], 
        x = joint_template
      )
    )
  })
  
  # character vector representation of base model
  model.deparsed = deparse(model)
  
  # return reassembled model
  list(
    nim_pkg = nim_pkg,
    model = parse(
      text = c(model.deparsed[1], joint, hyper, model.deparsed[-1])
    )[[1]],
    configure_sampler = function(conf) {
      conf$removeSamplers(c('beta[1]','beta[2]'))
      conf$addSampler(target = c('beta[1]', 'beta[2]'), type = 'AF_slice')
      conf
    }
  )
}