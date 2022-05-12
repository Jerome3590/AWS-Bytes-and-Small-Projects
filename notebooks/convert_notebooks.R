library(rmarkdown)
library(here)

notebook <- list.files(here("Jupyter"))

notebook

input_file <- here("Jupyter", notebook[9])
file_output <- here("RMarkdown", notebook[9])


rmarkdown:::convert_ipynb(input_file, output = xfun::with_ext(file_output, "Rmd"))

