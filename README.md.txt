# Right to Food & Food Security — Reproducible Bibliometrics (OpenAlex)

Pipeline reprodutível em R (Bronze → Silver → Gold) para construir e analisar um corpus sobre:
- Direito Humano à Alimentação Adequada (Right to Food)
- Segurança/Insegurança Alimentar (Food Security/Insecurity)

## Como rodar (R)
1) Abra o projeto no RStudio
2) Rode:
```r
source("R/scripts/00_setup.R")
targets::tar_make()
