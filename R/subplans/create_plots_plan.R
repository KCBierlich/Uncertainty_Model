create_plots_plan <- drake_plan(
  
  Sc1_figures = {
    rmarkdown::render(
      knitr_in("reports/Sc1_figures.Rmd"),
      output_dir = 'output/reports',
      output_file = "Sc1_output_figures.html",
      quiet = FALSE
      )
    file_out("output/reports/Sc1_output_figures.html")
  },
    
    
  # for uncorrected figures 
  Uncorrected_error_figures = {
    rmarkdown::render(
      knitr_in("reports/'uncorrected_error_plots.Rmd"),
      output_dir = 'output/reports',
      output_file = "Uncorrected_error_figures.html",
      quiet = FALSE
      )
    file_out("output/reports/Uncorrected_error_figures.html")
  }
)

