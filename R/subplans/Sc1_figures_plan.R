Sc1_figures_plan <- drake_plan(
  y = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'Sc1_figures.Rmd')), 
      output_file = file_out("Sc1_output_figures.html"),
    output_dir = file.path('output', 'reports'),
    quiet = FALSE)),


# for uncorrected figures 
Uncorrected_error_figures_plan = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'uncorrected_error_plots.Rmd')), 
      output_file = file_out("Uncorrected_error_figures.html"),
      output_dir = file.path('output', 'reports'),
      quiet = FALSE))
)
