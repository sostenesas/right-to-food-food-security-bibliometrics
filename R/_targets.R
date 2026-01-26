library(targets)

tar_option_set(packages = c("dplyr","readr","stringr","lubridate","jsonlite","httr"))

source("R/R/helpers.R")
source("R/R/openalex_fetch.R")

list(
  tar_target(query_core, build_query_core_fallback()),
  tar_target(raw_path, fetch_openalex_bronze(query_core, out_dir = "data/bronze", max_pages = 5)),
  tar_target(run_log, write_run_log(query_core, raw_path, out_dir = "outputs/logs"))
)