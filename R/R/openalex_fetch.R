# R/R/openalex_fetch.R

fetch_openalex_bronze <- function(filter_string,
                                  out_dir = "data/bronze",
                                  per_page = 200,
                                  max_pages = 20,
                                  select_fields = c(
                                    "id","doi","title","display_name",
                                    "publication_year","publication_date","type",
                                    "cited_by_count","language",
                                    "primary_location","open_access",
                                    "authorships","concepts","referenced_works",
                                    "abstract_inverted_index"
                                  ),
                                  polite_email = Sys.getenv("OPENALEX_EMAIL", "")) {
  
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  
  base_url <- "https://api.openalex.org/works"
  cursor <- "*"
  page <- 0
  
  stamp <- format(Sys.time(), "%Y-%m-%d_%H%M%S")
  out_path <- file.path(out_dir, paste0("openalex_bronze_", stamp, ".jsonl"))
  
  con <- file(out_path, open = "wt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  
  select_param <- paste(select_fields, collapse = ",")
  
  repeat {
    page <- page + 1
    if (!is.null(max_pages) && page > max_pages) break
    
    url <- paste0(
      base_url,
      "?filter=", URLencode(filter_string, reserved = TRUE),
      "&select=", URLencode(select_param, reserved = TRUE),
      "&per-page=", per_page,
      "&cursor=", URLencode(cursor, reserved = TRUE)
    )
    
    ua <- httr::user_agent("right-to-food-food-security-bibliometrics/0.1")
    headers <- if (nzchar(polite_email)) httr::add_headers("mailto" = polite_email) else NULL
    
    resp <- httr::GET(url, ua, headers)
    if (httr::status_code(resp) != 200) {
      stop(
        "OpenAlex HTTP ", httr::status_code(resp),
        "\nURL:\n", url,
        "\nBody:\n", httr::content(resp, "text", encoding = "UTF-8")
      )
    }
    
    payload <- httr::content(resp, as = "parsed", simplifyVector = FALSE)
    results <- payload$results
    if (is.null(results) || length(results) == 0) break
    
    for (r in results) {
      writeLines(jsonlite::toJSON(r, auto_unbox = TRUE, null = "null"), con = con, sep = "\n", useBytes = TRUE)
    }
    
    next_cursor <- payload$meta$next_cursor
    if (is.null(next_cursor) || !nzchar(next_cursor)) break
    cursor <- next_cursor
    
    Sys.sleep(0.2)
  }
  
  out_path
}