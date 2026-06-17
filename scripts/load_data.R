# ── load_data.R ───────────────────────────────────────────────────────────────
# Loads a CSV, TSV, or Excel file into a dataframe and saves it as .rds.
#
# Pipeline usage:  Rscript scripts/load_data.R input/file.csv output/file.rds
# Interactive:     source("scripts/load_data.R")  (loads all files in input/)
# ──────────────────────────────────────────────────────────────────────────────

library(readr)
library(readxl)

load_file <- function(filepath) {
  ext <- tolower(tools::file_ext(filepath))
  switch(ext,
    "csv"  = read_csv(filepath, show_col_types = FALSE),
    "tsv"  = read_tsv(filepath, show_col_types = FALSE),
    "xls"  = read_excel(filepath),
    "xlsx" = read_excel(filepath),
    stop("Unsupported file type: ", ext)
  )
}

# ── Pipeline mode (called via Rscript with arguments) ─────────────────────────
args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 2) {
  input_file  <- args[1]
  output_file <- args[2]

  message("Loading: ", input_file)
  df <- load_file(input_file)
  message("  → ", nrow(df), " rows × ", ncol(df), " cols")

  dir.create(dirname(output_file), showWarnings = FALSE, recursive = TRUE)
  saveRDS(df, output_file)
  message("  → Saved to: ", output_file)

# ── Interactive mode (source from RStudio) ────────────────────────────────────
} else if (interactive()) {
  input_dir <- file.path(getwd(), "input")
  file_list <- list.files(
    input_dir,
    pattern = "\\.(csv|xlsx?|tsv)$",
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(file_list) == 0) {
    message("⚠ No data files found in: ", input_dir)
  } else {
    for (f in file_list) {
      df_name <- make.names(tools::file_path_sans_ext(basename(f)))
      df <- tryCatch(
        load_file(f),
        error = function(e) {
          warning("✖ Failed to load ", basename(f), ": ", e$message)
          NULL
        }
      )
      if (!is.null(df)) {
        assign(df_name, df, envir = .GlobalEnv)
        message("✔ Loaded '", basename(f), "' → ", df_name,
                "  (", nrow(df), " rows × ", ncol(df), " cols)")
      }
    }
  }
}
