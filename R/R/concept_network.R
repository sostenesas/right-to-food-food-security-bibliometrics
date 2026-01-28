# R/R/concept_network.R

build_top_concepts <- function(silver_dir = "data/silver",
                               out_dir = "data/gold",
                               min_level = 1,
                               max_level = 3,
                               min_score = 0.2,
                               top_n = 200) {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  concepts_path <- file.path(silver_dir, "concepts.parquet")
  if (!file.exists(concepts_path)) {
    stop("concepts.parquet not found: ", concepts_path)
  }
  
  concepts <- arrow::read_parquet(concepts_path)
  
  # Se vier vazio ou sem colunas esperadas, salva vazio e retorna.
  needed <- c("concept_id","concept_name","concept_level","concept_score")
  if (nrow(concepts) == 0 || !all(needed %in% names(concepts))) {
    top <- dplyr::tibble(
      concept_id = character(),
      concept_name = character(),
      concept_level = integer(),
      n_works = integer()
    )
    out_path <- file.path(out_dir, "top_concepts.parquet")
    arrow::write_parquet(top, out_path)
    return(out_path)
  }
  
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
    dplyr::distinct(work_id, concept_id, concept_name) |>
    dplyr::semi_join(dplyr::distinct(top, concept_id), by = "concept_id")
  
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
  
  nodes_path <- file.path(out_dir, "concept_network_nodes.parquet")
  
  # ✅ Se não há arestas, retorna nodes vazio e NÃO quebra o pipeline
  if (nrow(edges) == 0) {
    empty_nodes <- dplyr::tibble(
      concept_name = character(),
      cluster = integer(),
      degree = integer()
    )
    arrow::write_parquet(empty_nodes, nodes_path)
    return(nodes_path)
  }
  
  g <- igraph::graph_from_data_frame(
    d = data.frame(
      from = edges$concept_name_a,
      to = edges$concept_name_b,
      weight = edges$weight
    ),
    directed = FALSE
  )
  
  cl <- igraph::cluster_louvain(g, weights = igraph::E(g)$weight)
  memb <- igraph::membership(cl)
  
  nodes <- dplyr::tibble(
    concept_name = names(memb),
    cluster = as.integer(memb),
    degree = igraph::degree(g)
  )
  
  arrow::write_parquet(nodes, nodes_path)
  nodes_path
}

plot_concept_network <- function(edges_path = "data/gold/concept_cooccurrence_edges.parquet",
                                 nodes_path = "data/gold/concept_network_nodes.parquet",
                                 out_dir = "outputs/figures") {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  edges <- arrow::read_parquet(edges_path)
  out_path <- file.path(out_dir, "fig_concept_network.png")
  
  # ✅ Se não há arestas, cria placeholder
  if (nrow(edges) == 0) {
    png(out_path, width = 1400, height = 900, res = 170)
    par(mar = c(0, 0, 0, 0))
    plot.new()
    text(0.5, 0.55, "Concept co-occurrence network", cex = 1.6)
    text(0.5, 0.45, "No edges available for this scenario.\nTry increasing max_pages or using topics/keywords network.", cex = 1.1)
    dev.off()
    return(out_path)
  }
  
  nodes <- arrow::read_parquet(nodes_path)
  
  g <- igraph::graph_from_data_frame(
    d = data.frame(
      from = edges$concept_name_a,
      to = edges$concept_name_b,
      weight = edges$weight
    ),
    directed = FALSE
  )
  
  set.seed(42)
  lay <- igraph::layout_with_fr(g)
  
  cl_map <- if (nrow(nodes) > 0) setNames(nodes$cluster, nodes$concept_name) else NULL
  vcl <- if (!is.null(cl_map)) cl_map[igraph::V(g)$name] else rep(0, igraph::vcount(g))
  vcl[is.na(vcl)] <- 0
  
  deg <- igraph::degree(g)
  vsize <- pmax(4, pmin(16, sqrt(deg) * 3))
  
  png(out_path, width = 1400, height = 1000, res = 170)
  plot(
    g,
    layout = lay,
    vertex.label = igraph::V(g)$name,
    vertex.label.cex = 0.6,
    vertex.size = vsize,
    vertex.color = as.factor(vcl),
    edge.width = pmax(1, edges$weight / max(edges$weight) * 5),
    main = "Concept co-occurrence network (OpenAlex concepts)"
  )
  dev.off()
  
  out_path
}