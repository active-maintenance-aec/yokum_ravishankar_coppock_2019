# yokum_ravishankar_coppock_2019/ground_truth/archive_estimates.R
# Output: ground_truth/archive_estimates.csv
# Depends on: original/Replication Data/officer_level_anon.csv, the table_c*.csv
#   files in maintained/output/, helpers.R
# Description: Run the deposited regression_tables.R specification and record what
#   it produces, so that "does the archive reproduce the published tables?" is
#   answered by a file rather than by a claim.
#
#   The deposited script reads officer_level_anon.csv and fits every outcome on the
#   whole file, 2,224 officers, with no district filter. The published tables all
#   report 1,922. Everything else about the specification is the same: weighted
#   least squares on the inverse probability weights, HC2 standard errors, which is
#   what estimatr's starprep() gives the deposited lm() fits.
#
#   The outcome list is read out of the maintained table CSVs rather than typed
#   again, so the archive and the rewrite are compared on exactly the same outcomes
#   in exactly the same order.

here::i_am("ground_truth/archive_estimates.R")

source(here::here("maintained", "helpers.R"))

officer_level_archive <- read_csv(file.path(data_dir, "officer_level_anon.csv"), show_col_types = FALSE)

stopifnot(nrow(officer_level_archive) == 2224)

table_files <- list.files(out_dir, pattern = "^table_c[0-9]+_.*\\.csv$", full.names = TRUE)

outcome_index <- map(table_files, function(f) {
  read_csv(f, show_col_types = FALSE) |>
    mutate(stem = str_remove(basename(f), "\\.csv$")) |>
    select(stem, outcome, outcome_variable)
}) |>
  list_rbind()

archive_estimates <- outcome_index |>
  mutate(fit = pmap(list(outcome_variable, outcome), function(variable, label) {
    fit_dim_ipw_hc2(variable, label, officer_level_archive)
  })) |>
  select(stem, fit) |>
  unnest(fit) |>
  select(stem, outcome, outcome_variable, estimate, std_error, constant, constant_se, n, r_squared)

write_csv(archive_estimates, here::here("ground_truth", "archive_estimates.csv"))

print(archive_estimates, n = nrow(archive_estimates))
