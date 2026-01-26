# R/R/silver_build.R

read_jsonl_lines <- function(path) {
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

jsonl_to_list <- function(lines) {
  lapply(lines, function(x) jsonlite::fromJSON(x, simplifyVector = FALSE))
}

safe_null <- function(x, default = NA_character_) {
  if (is.null(x) || length(x) == 0) default else x
}

build_silver_tables <- function(bronze_path, out_dir = "data/silver") {
  if (!file.exists(bronze_path)) stop("Bronze file not found: ", bronze_path)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  lines <- read_jsonl_lines(bronze_path)
  recs <- jsonl_to_list(lines)
  
  # ---- works (1 row per work) ----
  works <- dplyr::tibble(
    work_id = vapply(recs, function(r) safe_null(r$id), character(1)),
    doi = vapply(recs, function(r) safe_null(r$doi), character(1)),
    title = vapply(recs, function(r) safe_null(r$title), character(1)),
    display_name = vapply(recs, function(r) safe_null(r$display_name), character(1)),
    publication_year = vapply(recs, function(r) safe_null(r$publication_year, NA_integer_), integer(1)),
    type = vapply(recs, function(r) safe_null(r$type), character(1)),
    cited_by_count = vapply(recs, function(r) safe_null(r$cited_by_count, NA_integer_), integer(1)),
    language = vapply(recs, function(r) safe_null(r$language), character(1)),
    source_id = vapply(recs, function(r) safe_null(r$primary_location$source$id), character(1)),
    source_name = vapply(recs, function(r) safe_null(r$primary_location$source$display_name), character(1)),
    host_venue = vapply(recs, function(r) safe_null(r$host_venue$display_name), character(1)),
    open_access_status = vapply(recs, function(r) safe_null(r$open_access$oa_status), character(1)),
    open_access_is_oa = vapply(recs, function(r) safe_null(r$open_access$is_oa, NA), logical(1))
  )
  
  # ---- authorships (work x author) ----
  authorships <- purrr::map_dfr(recs, function(r) {
    auths <- r$authorships
    if (is.null(auths) || length(auths) == 0) return(NULL)
    purrr::map_dfr(auths, function(a) {
      dplyr::tibble(
        work_id = safe_null(r$id),
        author_id = safe_null(a$author$id),
        author_name = safe_null(a$author$display_name),
        author_position = safe_null(a$author_position),
        is_corresponding = safe_null(a$is_corresponding, NA)
      )
    })
  })
  
  # ---- concepts (work x concept) ----
  concepts <- purrr::map_dfr(recs, function(r) {
    cs <- r$concepts
    if (is.null(cs) || length(cs) == 0) return(NULL)
    purrr::map_dfr(cs, function(cn) {
      dplyr::tibble(
        work_id = safe_null(r$id),
        concept_id = safe_null(cn$id),
        concept_name = safe_null(cn$display_name),
        concept_level = safe_null(cn$level, NA_integer_),
        concept_score = safe_null(cn$score, NA_real_)
      )
    })
  })
  
  # ---- references (work x referenced_work_id) ----
  references <- purrr::map_dfr(recs, function(r) {
    refs <- r$referenced_works
    if (is.null(refs) || length(refs) == 0) return(NULL)
    dplyr::tibble(
      work_id = safe_null(r$id),
      referenced_work_id = unlist(refs, use.names = FALSE)
    )
  })
  
  # write parquet
  arrow::write_parquet(works, file.path(out_dir, "works.parquet"))
  arrow::write_parquet(authorships, file.path(out_dir, "authorships.parquet"))
  arrow::write_parquet(concepts, file.path(out_dir, "concepts.parquet"))
  arrow::write_parquet(references, file.path(out_dir, "references.parquet"))
  
  list(
    works_path = file.path(out_dir, "works.parquet"),
    authorships_path = file.path(out_dir, "authorships.parquet"),
    concepts_path = file.path(out_dir, "concepts.parquet"),
    references_path = file.path(out_dir, "references.parquet")
  )
}
