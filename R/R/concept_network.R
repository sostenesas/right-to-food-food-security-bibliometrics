# R/R/concept_network.R

build_top_concepts <- function(silver_dir = "data/silver",
                               out_dir = "data/gold",
                               min_level = 1,
                               max_level = 3,
                               min_score = 0.2,
                               top_n = 200) {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  concepts <- arrow::read_parquet(file.path(silver_dir, "concepts.parquet"))
  
  top <- concepts |>
    dplyr::filter(!is.na(concept_name)) |>
    dplyr::filter(!is.na(concept_level)) |>
    dplyr::filter(concept_level >= min_level, concept_level <= max_level) |>
    dplyr::filter(!is.na(concept_score), concept_score >= min_score) |>
    dplyr::count(concept_id, concept_name, concept_level, sort = TRUE, name = "n_works") |>
    dplyr::slice_head(n = top_n)
  
  out_path <- file.path(out_dir, "top_concepts.parquet")
  arrow::write_parquet(top, out_path)
  out_path
}

build_concept_cooccurrence <- function(silver_dir = "data/silver",
                                       gold_top_concepts_path = "data/gold/top_concepts.parquet",
                                       out_dir = "data/gold",
                                       min_edge_weight = 5) {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  concepts <- arrow::read_parquet(file.path(silver_dir, "concepts.parquet"))
  top <- arrow::read_parquet(gold_top_concepts_path)
  
  # filtra só top conceitos
  concepts_f <- concepts |>
    dplyr::semi_join(top, by = c("concept_id", "concept_name", "concept_level")) |>
    dplyr::select(work_id, concept_id, concept_name) |>
    dplyr::distinct()
  
  # pares de conceitos por work (coocorrência)
  pairs <- concepts_f |>
    dplyr::inner_join(concepts_f, by = "work_id", suffix = c("_a", "_b")) |>
    dplyr::filter(concept_id_a < concept_id_b) |>
    dplyr::count(concept_id_a, concept_name_a, concept_id_b, concept_name_b, name = "weight") |>
    dplyr::filter(weight >= min_edge_weight) |>
    dplyr::arrange(dplyr::desc(weight))
  
  out_path <- file.path(out_dir, "concept_cooccurrence_edges.parquet")
  arrow::write_parquet(pairs, out_path)
  out_path
}

cluster_concept_network <- function(edges_path = "data/gold/concept_cooccurrence_edges.parquet",
                                    out_dir = "data/gold") {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  edges <- arrow::read_parquet(edges_path)
  
  if (nrow(edges) == 0) {
    stop("No edges in cooccurrence network. Try lowering min_edge_weight or increasing max_pages in OpenAlex fetch.")
  }
  
  g <- igraph::graph_from_data_frame(
    d = data.frame(
      from = edges$concept_name_a,
      to = edges$concept_name_b,
      weight = edges$weight
    ),
    directed = FALSE
  )
  
  # comunidade Louvain (ponderada)
  cl <- igraph::cluster_louvain(g, weights = igraph::E(g)$weight)
  memb <- igraph::membership(cl)
  
  nodes <- dplyr::tibble(
    concept_name = names(memb),
    cluster = as.integer(memb),
    degree = igraph::degree(g)
  )
  
  nodes_path <- file.path(out_dir, "concept_network_nodes.parquet")
  arrow::write_parquet(nodes, nodes_path)
  
  nodes_path
}

plot_concept_network <- function(edges_path = "data/gold/concept_cooccurrence_edges.parquet",
                                 nodes_path = "data/gold/concept_network_nodes.parquet",
                                 out_dir = "outputs/figures") {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  edges <- arrow::read_parquet(edges_path)
  nodes <- arrow::read_parquet(nodes_path)
  
  g <- igraph::graph_from_data_frame(
    d = data.frame(
      from = edges$concept_name_a,
      to = edges$concept_name_b,
      weight = edges$weight
    ),
    directed = FALSE
  )
  
  # layout
  set.seed(42)
  lay <- igraph::layout_with_fr(g)
  
  # map clusters
  cl_map <- setNames(nodes$cluster, nodes$concept_name)
  vcl <- cl_map[igraph::V(g)$name]
  vcl[is.na(vcl)] <- 0
  
  # tamanhos por grau (suave)
  deg <- igraph::degree(g)
  vsize <- pmax(4, pmin(16, sqrt(deg) * 3))
  
  out_path <- file.path(out_dir, "fig_concept_network.png")
  png(out_path, width = 1400, height = 1000, res = 170)
  
  plot(
    g,
    layout = lay,
    vertex.label = igraph::V(g)$name,
    vertex.label.cex = 0.6,
    vertex.size = vsize,
    vertex.color = as.factor(vcl),   # sem escolher cores manualmente (base R decide)
    edge.width = pmax(1, edges$weight / max(edges$weight) * 5),
    main = "Concept co-occurrence network (OpenAlex concepts)"
  )
  dev.off()
  
  out_path
}