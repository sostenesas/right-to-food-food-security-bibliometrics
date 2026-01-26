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
source("R/R/concept_network.R")


list(
  tar_target(query_core, build_query_core_fallback()),
  
  tar_target(raw_path,
             fetch_openalex_bronze(
               query_core,
               out_dir = "data/bronze",
               max_pages = 5
             )),
  
  tar_target(run_log,
             write_run_log(
               query_core,
               raw_path,
               out_dir = "outputs/logs"
             )),
  
  tar_target(silver_paths,
             build_silver_tables(
               raw_path,
               out_dir = "data/silver"
             )),
  
  tar_target(gold_paths,
             build_gold_tables(
               silver_dir = "data/silver",
               out_dir = "data/gold"
             )),
  
  tar_target(top_concepts_path,
             build_top_concepts("data/silver", out_dir = "data/gold",
                                min_level = 1, max_level = 3,
                                min_score = 0.2, top_n = 200)),
  
  tar_target(concept_edges_path,
             build_concept_cooccurrence("data/silver",
                                        gold_top_concepts_path = top_concepts_path,
                                        out_dir = "data/gold",
                                        min_edge_weight = 5)),
  
  tar_target(concept_nodes_path,
             cluster_concept_network(edges_path = concept_edges_path,
                                     out_dir = "data/gold")),
  
  tar_target(fig_concept_network,
             plot_concept_network(edges_path = concept_edges_path,
                                  nodes_path = concept_nodes_path,
                                  out_dir = "outputs/figures")),
  
  tar_target(fig_prod_year, {
    gold_paths  # força dependência (GOLD precisa existir)
    plot_production_by_year("data/gold", out_dir = "outputs/figures")
  }),
  
  tar_target(fig_top_sources, {
    gold_paths
    plot_top_sources("data/gold", out_dir = "outputs/figures")
  })
)