# yokum_ravishankar_coppock_2019/ground_truth/run_archive.R
# Output: ground_truth/archive_run_status.csv, ground_truth/archive_overwrites.csv
# Depends on: original/ (run download_original.R first)
# Description: Runs every deposited script, twice, and records how each run ended
#   and what it did to the files the deposit ships.
#
#   Every deposited script reads from its working directory, so each pass runs in
#   its own scratch copy of the Replication Data folder and never inside original/.
#   No deposited script writes a file the deposit ships: all four draw to the screen
#   or print to the console. The stripped pass therefore withholds nothing and runs on
#   the same files as the as-shipped pass; it is recorded so that the table has the
#   same shape in every repository. Run non-interactively, each script that draws
#   leaves an Rplots.pdf behind, which is the one file either pass adds.
#
#   The deposit's README.txt lists a fifth script, regression_tables_cov.R, that is not
#   in the deposit. It gets a row under each pass with outcome not_run.
#
#   This script is not part of run_all.R. It needs coefplot and stargazer, which the
#   deposit loads and the maintained rewrite does not, and its two tables are
#   committed so that nothing downstream needs them.

library(here)
library(tidyverse)

here::i_am("ground_truth/run_archive.R")

deposit <- here::here("original", "Replication Data")
stopifnot(dir.exists(deposit))

# Scripts, in the order the deposit's README lists them ----
scripts <- tribble(
  ~script, ~role,
  "coefplot_all_dvs.R", "analysis",
  "coefplot_main_dvs.R", "analysis",
  "regression_tables_cov.R", "analysis",
  "regression_tables.R", "analysis",
  "time_series_plot.R", "analysis"
) |>
  mutate(present = file.exists(file.path(deposit, script)))

stopifnot(sum(!scripts$present) == 1, !scripts$present[scripts$script == "regression_tables_cov.R"])

# Stage a scratch copy of the deposit ----
stage <- function(label) {
  # normalizePath, because tempdir() resolves through /private on macOS, and the
  # scrubbing below has to see the same spelling the error messages carry.
  root <- file.path(normalizePath(tempdir(), winslash = "/", mustWork = FALSE),
                    str_c("yokum_ravishankar_coppock_2019_", label))
  unlink(root, recursive = TRUE)
  dir.create(root, recursive = TRUE)
  files <- list.files(deposit, all.files = TRUE, no.. = TRUE)
  file.copy(file.path(deposit, files), root)
  root
}

# Run each script in its own process ----
# Every script opens with rm(list = ls()) and the four share object names, so each
# one runs in a fresh Rscript rather than being sourced into this session.
run_one <- function(root, script) {
  log_file <- file.path(dirname(root), str_c(basename(root), "_", make.names(script), ".log"))
  expr <- str_c("setwd(", deparse(root), "); source(", deparse(script), ", echo = FALSE)")
  status <- system2(file.path(R.home("bin"), "Rscript"), args = c("-e", shQuote(expr)),
                    stdout = log_file, stderr = log_file)
  lines <- read_lines(log_file)
  first <- which(str_starts(lines, "Error"))
  stopped_at <- if (length(first) == 0) {
    NA_character_
  } else {
    lines[first[1]:min(first[1] + 2, length(lines))] |>
      discard(\(x) str_detect(x, "Execution halted")) |>
      str_c(collapse = " ") |>
      str_replace_all(fixed(root), "<deposit>") |>
      str_replace_all(fixed(str_remove(root, "^/private")), "<deposit>") |>
      str_squish() |>
      str_trunc(220)
  }
  tibble(script = script, exit_status = status, stopped_at = stopped_at)
}

run_pass <- function(root) {
  present <- scripts |> filter(present)
  ran <- map(present$script, \(s) run_one(root, s)) |> list_rbind()
  absent <- scripts |>
    filter(!present) |>
    transmute(script, exit_status = NA_integer_,
              stopped_at = "Listed in the deposit's README.txt but absent from the deposit")
  bind_rows(ran, absent)
}

checksums <- function(root) {
  files <- list.files(root, all.files = TRUE, no.. = TRUE)
  set_names(unname(tools::md5sum(file.path(root, files))), files)
}

# The two passes ----
stripped_root <- stage("stripped")
stripped_before <- checksums(stripped_root)
stripped <- run_pass(stripped_root)
stripped_after <- checksums(stripped_root)

shipped_root <- stage("as_shipped")
shipped_before <- checksums(shipped_root)
as_shipped <- run_pass(shipped_root)
shipped_after <- checksums(shipped_root)

# Archive run status, one row per script per pass ----
run_status <- bind_rows(as_shipped = as_shipped, stripped = stripped, .id = "pass") |>
  left_join(select(scripts, script, role), by = "script") |>
  transmute(pass, script, role, exit_status = as.integer(exit_status),
            outcome = case_when(is.na(exit_status) ~ "not_run",
                                exit_status == 0 ~ "clean",
                                .default = "error"),
            stopped_at)

stopifnot(nrow(run_status) == 2 * nrow(scripts), !anyNA(run_status$role))

# Archive overwrites ----
# A deposited file has a row only where a run changed its bytes. A file no deposit
# member names is added.
changed_rows <- function(pass, before, after) {
  tibble(pass = pass, file = names(before)) |>
    filter(after[file] != before[file]) |>
    mutate(effect = "overwritten", matches_deposit = FALSE)
}

added_rows <- bind_rows(
  tibble(pass = "as_shipped", file = setdiff(names(shipped_after), names(shipped_before))),
  tibble(pass = "stripped", file = setdiff(names(stripped_after), names(stripped_before)))
) |>
  mutate(effect = "added", matches_deposit = NA)

overwrites <- bind_rows(
  changed_rows("as_shipped", shipped_before, shipped_after),
  changed_rows("stripped", stripped_before, stripped_after),
  added_rows
) |>
  select(pass, file, effect, matches_deposit)

write_csv(run_status, here::here("ground_truth", "archive_run_status.csv"))
write_csv(overwrites, here::here("ground_truth", "archive_overwrites.csv"))

print(run_status, n = nrow(run_status), width = 200)
print(overwrites, n = nrow(overwrites))
