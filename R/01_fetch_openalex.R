# 01_fetch_openalex.R
# Minimal OpenAlex query to test the pipeline

if (!requireNamespace("openalexR", quietly = TRUE)) {
  install.packages("openalexR")
}
library(openalexR)
library(dplyr)

# Simple query
query_terms <- c(
  '"right to food"',
  '"right to adequate food"',
  '"food security"',
  '"food insecurity"'
)

query <- paste(query_terms, collapse = " OR ")

message("Query: ", query)

# Fetch works
res <- oa_fetch(
  entity = "works",
  query = query,
  per_page = 50
)

df <- oa2df(res)

# Create data folder if needed
dir.create("data/bronze", showWarnings = FALSE, recursive = TRUE)

# Save raw output
out_file <- paste0(
  "data/bronze/openalex_test_",
  Sys.Date(),
  ".csv"
)

write.csv(df, out_file, row.names = FALSE)

message("Saved ", nrow(df), " rows to ", out_file)
