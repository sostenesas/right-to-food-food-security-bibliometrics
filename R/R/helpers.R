# R/R/helpers.R

build_query_S1_core <- function() {
  # termo amplo: direito à alimentação + segurança alimentar
  # (OpenAlex filter usa OR e aspas; aqui mantemos simples em abstract.search)
  paste0(
    'abstract.search:"right to food" OR ',
    'abstract.search:"human right to food" OR ',
    'abstract.search:"right to adequate food" OR ',
    'abstract.search:"food security" OR ',
    'abstract.search:"food insecurity"'
  )
}

build_query_S2_multilingual <- function() {
  paste(
    c(
      'abstract.search:"right to food"',
      'abstract.search:"human right to food"',
      'abstract.search:"right to adequate food"',
      'abstract.search:"food security"',
      'abstract.search:"food insecurity"',
      'abstract.search:"direito à alimentação"',
      'abstract.search:"direito humano à alimentação adequada"',
      'abstract.search:"segurança alimentar"',
      'abstract.search:"insegurança alimentar"',
      'abstract.search:"derecho a la alimentación"',
      'abstract.search:"seguridad alimentaria"',
      'abstract.search:"inseguridad alimentaria"',
      'abstract.search:"droit à l’alimentation"',
      'abstract.search:"sécurité alimentaire"'
    ),
    collapse = " OR "
  )
}

build_query_S3_BR_abstract <- function() {
  
  # Usar abstract.search / abstract.search.no_stem (forma suportada)
  # Evitar parênteses para não quebrar o parser do filter
  
  core_terms <- paste(
    c(
      'abstract.search.no_stem:"direito à alimentação"',
      'abstract.search.no_stem:"direito humano à alimentação"',
      'abstract.search.no_stem:"direito à alimentação adequada"',
      'abstract.search:"right to food"',
      'abstract.search:"human right to food"',
      'abstract.search.no_stem:"segurança alimentar"',
      'abstract.search.no_stem:"segurança alimentar e nutricional"',
      'abstract.search.no_stem:"insegurança alimentar"',
      'abstract.search:"food security"',
      'abstract.search:"food insecurity"'
    ),
    collapse = " OR "
  )
  
  paste0(
    core_terms,
    ",authorships.institutions.country_code:BR",
    ",from_publication_date:2001-01-01",
    ",to_publication_date:2024-12-31"
  )
}

write_run_log <- function(scenario, filter_string, raw_path, out_dir = "outputs/logs") {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  stamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
  path <- file.path(out_dir, paste0("run_", scenario, "_", stamp, ".txt"))
  txt <- c(
    paste0("scenario: ", scenario),
    paste0("datetime: ", Sys.time()),
    paste0("filter_string: ", filter_string),
    paste0("raw_path: ", raw_path)
  )
  writeLines(txt, con = path, useBytes = TRUE)
  path
}