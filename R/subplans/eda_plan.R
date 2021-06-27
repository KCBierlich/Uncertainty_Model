eda_plan = drake_plan(
  
  altimeter_eda_report = target(
    rmarkdown::render(
      knitr_in(!!file.path('reports', 'altimeter_errors_eda.Rmd')),
      output_file = 'altimeter_errors_eda.html',
      output_dir = rendered_report_dir
    )
  )

)
