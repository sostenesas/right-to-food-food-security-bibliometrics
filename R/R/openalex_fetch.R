# R/R/openalex_fetch.R

fetch_openalex_bronze <- function(query, out_dir, max_pages = 5, per_page = 200) {
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  stamp <- format(Sys.Date(), "%Y-%m-%d")
  out_file <- file.path(out_dir, paste0("openalex_bronze_", stamp, ".jsonl"))
  
  base <- "https://api.openalex.org/works"
  cursor <- "*"
  n_pages <- 0
  
  con <- file(out_file, open = "wt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  
  message("Fetching OpenAlex (bronze) ...")
  repeat {
    n_pages <- n_pages + 1
    if (n_pages > max_pages) break
    
    resp <- httr::GET(
      url = base,
      query = list(
        search = query,
        `per-page` = per_page,
        cursor = cursor
        # mailto = "seu_email@dominio.com"  # opcional, recomendado
      ),
      httr::timeout(60)
    )
    httr::stop_for_status(resp)
    
    dat <- httr::content(resp, as = "text", encoding = "UTF-8")
    json <- jsonlite::fromJSON(dat, simplifyVector = FALSE)
    
    results <- json$results
    if (length(results) == 0) break
    
    for (item in results) {
      writeLines(jsonlite::toJSON(item, auto_unbox = TRUE), con)
    }
    
    cursor <- json$meta$next_cursor
    if (is.null(cursor) || cursor == "") break
    Sys.sleep(0.3)
  }
  
  message("Saved bronze: ", out_file)
  out_file
}
