# R/R/silver_build.R

safe_null <- function(x, default = NA) {
  if (is.null(x) || length(x) == 0) default else x
}

build_silver_tables <- function(bronze_path, out_dir = "data/silver") {
  if (!file.exists(bronze_path)) stop("Bronze file not found: ", bronze_path)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  lines <- readLines(bronze_path, warn = FALSE, encoding = "UTF-8")
  recs <- lapply(lines, function(x) jsonlite::fromJSON(x, simplifyVector = FALSE))
  
  works <- dplyr::tibble(
    work_id = vapply(recs, function(r) safe_null(r$id, NA_character_), character(1)),
    doi = vapply(recs, function(r) safe_null(r$doi, NA_character_), character(1)),
    title = vapply(recs, function(r) safe_null(r$title, NA_character_), character(1)),
    display_name = vapply(recs, function(r) safe_null(r$display_name, NA_character_), character(1)),
    publication_year = vapply(recs, function(r) safe_null(r$publication_year, NA_integer_), integer(1)),
    publication_date = vapply(recs, function(r) safe_null(r$publication_date, NA_character_), character(1)),
    type = vapply(recs, function(r) safe_null(r$type, NA_character_), character(1)),
    cited_by_count = vapply(recs, function(r) safe_null(r$cited_by_count, NA_integer_), integer(1)),
    language = vapply(recs, function(r) safe_null(r$language, NA_character_), character(1)),
    source_id = vapply(recs, function(r) safe_null(r$primary_location$source$id, NA_character_), character(1)),
    source_name = vapply(recs, function(r) safe_null(r$primary_location$source$display_name, NA_character_), character(1)),
    host_venue = vapply(recs, function(r) safe_null(r$host_venue$display_name, NA_character_), character(1)),
    open_access_status = vapply(recs, function(r) safe_null(r$open_access$oa_status, NA_character_), character(1)),
    open_access_is_oa = vapply(recs, function(r) safe_null(r$open_access$is_oa, NA), logical(1))
  )
  
  authorships <- purrr::map_dfr(recs, function(r) {
    auths <- r$authorships
    if (is.null(auths) || length(auths) == 0) return(NULL)
    purrr::map_dfr(auths, function(a) {
      dplyr::tibble(
        work_id = safe_null(r$id, NA_character_),
        author_id = safe_null(a$author$id, NA_character_),
        author_name = safe_null(a$author$display_name, NA_character_),
        author_position = safe_null(a$author_position, NA_character_),
        is_corresponding = safe_null(a$is_corresponding, NA)
      )
    })
  })
  
  concepts <- purrr::map_dfr(recs, function(r) {
    cs <- r$concepts
    if (is.null(cs) || length(cs) == 0) return(NULL)
    purrr::map_dfr(cs, function(cn) {
      dplyr::tibble(
        work_id = safe_null(r$id, NA_character_),
        concept_id = safe_null(cn$id, NA_character_),
        concept_name = safe_null(cn$display_name, NA_character_),
        concept_level = safe_null(cn$level, NA_integer_),
        concept_score = safe_null(cn$score, NA_real_)
      )
    })
  })
  
  # garante schema mesmo se vazio
  if (is.null(concepts) || nrow(concepts) == 0) {
    concepts <- dplyr::tibble(
      work_id = character(),
      concept_id = character(),
      concept_name = character(),
      concept_level = integer(),
      concept_score = numeric()
    )
  }
  
  references <- purrr::map_dfr(recs, function(r) {
    refs <- r$referenced_works
    if (is.null(refs) || length(refs) == 0) return(NULL)
    dplyr::tibble(
      work_id = safe_null(r$id, NA_character_),
      referenced_work_id = unlist(refs, use.names = FALSE)
    )
  })
  
  arrow::write_parquet(works, file.path(out_dir, "works.parquet"))
  arrow::write_parquet(authorships, file.path(out_dir, "authorships.parquet"))
  arrow::write_parquet(concepts, file.path(out_dir, "concepts.parquet"))
  arrow::write_parquet(references, file.path(out_dir, "references.parquet"))
  
  list(
    works = file.path(out_dir, "works.parquet"),
    authorships = file.path(out_dir, "authorships.parquet"),
    concepts = file.path(out_dir, "concepts.parquet"),
    references = file.path(out_dir, "references.parquet")
  )
}