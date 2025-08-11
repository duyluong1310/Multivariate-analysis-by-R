# tools/make_rmds.R
# Convert every .R file in the repo into an .Rmd (English notebook style).
# - Keeps existing roxygen-style comments (#') as narrative (spin-ready).
# - Auto-detects libraries (library(), require(), pkg::fun) -> Libraries chunk.
# - Writes the .Rmd next to the source .R (same folder).
# - Skips docs/, .github/, renv/.

suppressWarnings(suppressMessages({
  if (!requireNamespace("fs", quietly = TRUE)) install.packages("fs", repos = "https://cloud.r-project.org")
  if (!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr", repos = "https://cloud.r-project.org")
  if (!requireNamespace("glue", quietly = TRUE)) install.packages("glue", repos = "https://cloud.r-project.org")
  library(fs); library(stringr); library(glue)
}))

root <- fs::path_abs(".")
r_files <- fs::dir_ls(root, recurse = TRUE, type = "file", glob = "*.R")
# Exclude non-source folders
r_files <- r_files[!stringr::str_detect(r_files, "/docs/|/.github/|/renv/")]

message("Found ", length(r_files), " R files to convert.")

extract_libs <- function(txt) {
  # library(x) / require(x)
  libs1 <- stringr::str_match_all(txt, "(?m)\\b(?:library|require)\\s*\\(\\s*([A-Za-z0-9\\.]+)\\s*\\)")[[1]]
  libs1 <- if (nrow(libs1)) libs1[,2] else character(0)
  # pkg::fun
  libs2 <- stringr::str_match_all(txt, "(?m)\\b([A-Za-z0-9\\.]+)\\s*::\\s*[A-Za-z0-9_]+")[[1]]
  libs2 <- if (nrow(libs2)) libs2[,2] else character(0)
  sort(unique(c(libs1, libs2)))
}

yaml_block <- function(title) glue(
'---
title: "{title}"
output:
  html_document:
    toc: true
    toc_float: true
    code_folding: show
    number_sections: true
    self_contained: true
---

'
)

setup_chunk <- '```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE, message = FALSE, warning = FALSE)
'

libs_chunk <- function(pkgs) {
if (!length(pkgs)) pkgs <- "tidyverse" # fallback nếu không phát hiện được
body <- paste0("library(", pkgs, ")", collapse = "\n")
glue(
'# Libraries (auto-detected)
{body}
'
)
}

wrap_code <- function(code) glue(
'# Code
{code}
'
)

for (rf in r_files) {
  code <- tryCatch(readLines(rf, warn = FALSE, encoding = "UTF-8"),
error = function(e) readLines(rf, warn = FALSE))
code_txt <- paste(code, collapse = "\n")

title <- fs::path_file(rf) |> fs::path_ext_remove()
rmd_path <- fs::path_ext_set(rf, "Rmd")
has_spin <- any(startsWith(trimws(code), "#'"))
libs <- extract_libs(code_txt)

cat("Writing:", rmd_path, "\n")
fs::dir_create(fs::path_dir(rmd_path))

content <- if (has_spin) {
# Giữ narrative #'; chèn YAML + setup + Libraries lên đầu
paste0(yaml_block(title), setup_chunk, libs_chunk(libs), code_txt, "\n")
} else {
# Không có #': gói toàn bộ script vào một code chunk
paste0(yaml_block(title), setup_chunk, libs_chunk(libs), wrap_code(code_txt))
}

writeLines(content, rmd_path, useBytes = TRUE)
}

message("Done generating .Rmd files.")
                 
