library(targets)

tar_option_set(packages = c(
  "dplyr","readr","stringr","lubridate",
  "jsonlite","httr","purrr","arrow","ggplot2"
))

source("R/R/helpers.R")
source("R/R/openalex_fetch.R")
source("R/R/silver_build.R")
source("R/R/gold_build.R")
source("R/R/gold_figures.R")

list(
  tar_target(query_core, build_query_core_fallback()),
  
  tar_target(raw_path,
             fetch_openalex_bronze(query_core,
                                   out_dir = "data/bronze",
                                   max_pages = 5)),
  
  tar_target(run_log,
             write_run_log(query_core, raw_path,
                           out_dir = "outputs/logs")),
  
  tar_target(silver_paths,
             build_silver_tables(raw_path,
                                 out_dir = "data/silver")),
  
  tar_target(gold_paths,
             build_gold_tables("data/silver",
                               out_dir = "data/gold")),
  
  tar_target(fig_prod_year,
             plot_production_by_year("data/gold",
                                     out_dir = "outputs/figures")),
  
  tar_target(fig_top_sources,
             plot_top_sources("data/gold",
                              out_dir = "outputs/figures"))
)