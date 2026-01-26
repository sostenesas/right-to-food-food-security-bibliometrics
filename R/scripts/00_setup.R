# R/scripts/00_setup.R
pkgs <- c(
  "targets", "yaml", "dplyr", "readr", "stringr",
  "lubridate", "jsonlite", "httr"
)

to_install <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(to_install)) install.packages(to_install)

message("OK. Next: targets::tar_make()")
