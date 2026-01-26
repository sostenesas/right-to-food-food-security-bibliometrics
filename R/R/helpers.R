# R/R/helpers.R

read_yaml_safe <- function(path) {
  if (!file.exists(path)) {
    stop("Missing file: ", path, "\nDid you complete ETAPA 2 (protocol/search_strings.yml)?")
  }
  yaml::read_yaml(path)
}

build_query_core <- function(cfg) {
  core <- c(cfg$core_concepts$right_to_food, cfg$core_concepts$food_security)
  paste(core, collapse = " OR ")
}

write_run_log <- function(query, raw_path, out_dir) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  stamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
  log_path <- file.path(out_dir, paste0("run_", stamp, ".txt"))
  
  txt <- c(
    paste0("timestamp: ", Sys.time()),
    paste0("query: ", query),
    paste0("raw_path: ", raw_path)
  )
  writeLines(txt, log_path)
  log_path
}

build_query_core_fallback <- function() {
  paste(
    c(
      '"right to food"',
      '"right to adequate food"',
      '"human right to food"',
      '"right to adequate nutrition"',
      '"food security"',
      '"food insecurity"',
      '"nutrition security"'
    ),
    collapse = " OR "
  )
}