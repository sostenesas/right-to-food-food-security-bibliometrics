# R/R/gold_figures.R

plot_production_by_year <- function(gold_dir = "data/gold",
                                    out_dir = "outputs/figures") {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  prod_year <- arrow::read_parquet(
    file.path(gold_dir, "production_by_year.parquet")
  )
  
  p <- ggplot2::ggplot(prod_year,
                       ggplot2::aes(x = publication_year, y = n)) +
    ggplot2::geom_line() +
    ggplot2::geom_point() +
    ggplot2::labs(
      title = "Scientific production on Right to Food & Food Security",
      x = "Publication year",
      y = "Number of publications"
    ) +
    ggplot2::theme_minimal()
  
  out_path <- file.path(out_dir, "fig_production_year.png")
  ggplot2::ggsave(out_path, p, width = 8, height = 5, dpi = 300)
  out_path
}

plot_top_sources <- function(gold_dir = "data/gold",
                             out_dir = "outputs/figures") {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  top_sources <- arrow::read_parquet(
    file.path(gold_dir, "top_sources.parquet")
  )
  
  p <- ggplot2::ggplot(top_sources,
                       ggplot2::aes(x = reorder(source_name, n), y = n)) +
    ggplot2::geom_col() +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Top publication venues",
      x = NULL,
      y = "Number of publications"
    ) +
    ggplot2::theme_minimal()
  
  out_path <- file.path(out_dir, "fig_top_sources.png")
  ggplot2::ggsave(out_path, p, width = 8, height = 6, dpi = 300)
  out_path
}