# Right to Food & Food Security — Reproducible Bibliometrics (OpenAlex)

This repository contains a fully reproducible pipeline (Bronze → Silver → Gold) to build and analyze a scholarly corpus on:
- the Human Right to Adequate Food (Right to Food) and
- Food Security / Food Insecurity

Primary data source: OpenAlex API (with planned cross-database robustness checks).

## Research outputs
- Academic paper (anchor): mapping the field and conceptual clusters
- Thematic academic paper (e.g., justiciability / governance / post-2020)
- Data paper: dataset descriptor + reproducible code
- Citable repository releases + Zenodo DOI

## Repository structure
- `protocol/` — PRISMA-S logs, search strings, inclusion/exclusion criteria, decision log
- `data/` — pipeline artifacts (bronze/silver/gold), dictionaries, and external curated inputs
- `R/` — R pipeline using `{targets}` for reproducibility
- `python/` — Python pipeline (optional alternative implementation)
- `outputs/` — figures, tables, and run logs
- `paper/` — Quarto manuscript + bibliography

## Quickstart (R)
1) Install R (>= 4.3) and RStudio
2) Clone the repo
3) Run:
```r
source("R/scripts/00_setup.R")
targets::tar_make()
