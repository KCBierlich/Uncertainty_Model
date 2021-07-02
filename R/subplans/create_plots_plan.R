create_plots_plan <- drake_plan(
  Sc1_figures = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'Sc1_figures.Rmd')),
      #output_file = file_out("Sc1_output_figures.html"),
    output_dir = file.path('output', 'reports'),
    quiet = FALSE)),


# for uncorrected figures 
Uncorrected_error_figures = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'uncorrected_error_plots.Rmd')), 
      output_file = file_out("Uncorrected_error_figures.html"),
      output_dir = file.path('output', 'reports'),
      quiet = FALSE))
)
