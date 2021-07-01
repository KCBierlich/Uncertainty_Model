# plot targets
# This code creates the figures from the manuscript 


# > make it so it has the tables and it has an html output for everything
# could even split it up for 1) uncorrected plots 2) model outputs

root_square_term <- function(l, w, h){
  half_w <- w/2
  l*sqrt(half_w^2 + h^2)
}

root_square_term(1,2,3)
root_square_term(4,5,6)


volume_pyramid <- function(length_base, width_base, height){
  area_base <- length_base * width_base
  term1 <- root_square_term(length_base, width_base, height)
  term2 <- root_square_term(width_base, length_base, height)
  area_base + term1 + term2
}

volume_pyramid(3,5,7)
basename(getwd())

create_plot <-  function(data) {
  ggplot(data) + 
    geom_histogram(aes(x = RB)) + 
    theme_gray(24)
}
  

plan <- drake_plan(
  raw_data = read.csv(file.path("data","marrs_amws.csv")),
  data = raw_data %>% 
    mutate(TL.m = replace_na(TL, mean(TL, na.rm = TRUE))),
  hist = create_plot(data),
  fit = lm(TL.m ~ RB + TL.5.0..Width, data),
  # report = rmarkdown::render(
  #        knitr_in("report.Rmd"),
  #        output_file = file_out("report.html"),
  #        queit = TRUE
       # )
  )

plan

vis_drake_graph(plan)

make(plan)
readd(hist)

create_plot <-  function(data) {
  ggplot(data) + 
    geom_histogram(aes(x = TL), binwidth = 2) + 
    theme_gray(24)
}
vis_drake_graph(plan)
make(plan)
readd(hist)

# when you make a plan, it's better to use functions for each step. Even if filtering raw datas
prefix <- "marrs_"
!!paste0(prefix, "yeah")

read.csv(file.path("data", file_in(!!paste0(prefix, "amws.csv"))))
