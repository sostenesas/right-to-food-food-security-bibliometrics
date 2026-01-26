# R/R/gold_build.R

build_gold_tables <- function(silver_dir = "data/silver",
                              out_dir = "data/gold") {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  works <- arrow::read_parquet(file.path(silver_dir, "works.parquet"))
  
  prod_year <- works |>
    dplyr::filter(!is.na(publication_year)) |>
    dplyr::count(publication_year, name = "n")
  
  prod_type <- works |>
    dplyr::count(type, name = "n") |>
    dplyr::arrange(dplyr::desc(n))
  
  top_sources <- works |>
    dplyr::filter(!is.na(source_name)) |>
    dplyr::count(source_name, sort = TRUE, name = "n") |>
    dplyr::slice_head(n = 20)
  
  arrow::write_parquet(prod_year, file.path(out_dir, "production_by_year.parquet"))
  arrow::write_parquet(prod_type, file.path(out_dir, "production_by_type.parquet"))
  arrow::write_parquet(top_sources, file.path(out_dir, "top_sources.parquet"))
  
  list(
    production_by_year = file.path(out_dir, "production_by_year.parquet"),
    production_by_type = file.path(out_dir, "production_by_type.parquet"),
    top_sources = file.path(out_dir, "top_sources.parquet")
  )
}