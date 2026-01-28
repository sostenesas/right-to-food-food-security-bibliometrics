library(targets)

tar_option_set(packages = c(
  "dplyr","purrr","jsonlite","httr","arrow","ggplot2","igraph"
))

# ======== CONTROLE DE CENÁRIO ========
scenario <- "S3_BR_abstract" # "S2_multilingual" | "S3_BR_abstract"
max_pages <- 20

# Diretórios por cenário
bronze_dir <- file.path("data/bronze", scenario)
silver_dir <- file.path("data/silver", scenario)
gold_dir   <- file.path("data/gold", scenario)
fig_dir    <- file.path("outputs/figures", scenario)

# ======== SOURCES ========
source("R/R/helpers.R")
source("R/R/openalex_fetch.R")
source("R/R/silver_build.R")
source("R/R/gold_build.R")
source("R/R/gold_figures.R")
source("R/R/concept_network.R")

list(
  tar_target(filter_string, {
    if (scenario == "S2_multilingual") build_query_S2_multilingual()
    else if (scenario == "S3_BR_abstract") build_query_S3_BR_abstract()
    else build_query_S1_core()
  }),
  
  tar_target(raw_path,
             fetch_openalex_bronze(
               filter_string,
               out_dir = bronze_dir,
               max_pages = max_pages
             )
  ),
  
  tar_target(run_log,
             write_run_log(scenario, filter_string, raw_path, out_dir = "outputs/logs")
  ),
  
  tar_target(silver_paths,
             build_silver_tables(raw_path, out_dir = silver_dir)
  ),
  
  tar_target(gold_paths, {
    silver_paths
    build_gold_tables(silver_dir, out_dir = gold_dir)
  }),
  
  tar_target(fig_prod_year, {
    gold_paths
    plot_production_by_year(gold_dir, out_dir = fig_dir)
  }),
  
  tar_target(fig_top_sources, {
    gold_paths
    plot_top_sources(gold_dir, out_dir = fig_dir)
  }),
  
  tar_target(top_concepts_path, {
    silver_paths
    build_top_concepts(silver_dir, out_dir = gold_dir,
                       min_level = 1, max_level = 3,
                       min_score = 0.2, top_n = 200)
  }),
  
  tar_target(concept_edges_path, {
    top_concepts_path
    build_concept_cooccurrence(silver_dir,
                               gold_top_concepts_path = top_concepts_path,
                               out_dir = gold_dir,
                               min_edge_weight = if (scenario == "S3_BR_abstract") 1 else 2)
  }),
  
  tar_target(concept_nodes_path, {
    concept_edges_path
    cluster_concept_network(edges_path = concept_edges_path,
                            out_dir = gold_dir)
  }),
  
  tar_target(fig_concept_network, {
    concept_nodes_path
    plot_concept_network(edges_path = concept_edges_path,
                         nodes_path = concept_nodes_path,
                         out_dir = fig_dir)
  })
)
