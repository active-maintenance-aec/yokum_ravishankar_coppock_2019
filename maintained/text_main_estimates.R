# yokum_ravishankar_coppock_2019/maintained/text_main_estimates.R
# Output: output/text_main_estimates.csv
# Depends on: table_c5_use_of_force.R, table_c19_complaints.R,
#   table_c23_discretionary_arrests.R output, helpers.R
# Description: The three effect estimates the Results section states in words,
#   read back out of the appendix tables that print them, so the sentence and the
#   table cannot disagree.

source(here::here("maintained", "helpers.R"))

read_output <- function(file) read_csv(file.path(out_dir, file), show_col_types = FALSE)

text_main_estimates <- bind_rows(
  read_output("table_c5_use_of_force.csv") |> filter(outcome == "Use of Force"),
  read_output("table_c19_complaints.csv") |> filter(outcome == "Complaints"),
  read_output("table_c23_discretionary_arrests.csv") |> filter(outcome == "Disorderly Conduct")
) |>
  transmute(
    outcome,
    estimate,
    std_error,
    estimate_as_printed = round(estimate),
    std_error_as_printed = round(std_error),
    n
  )

write_csv(text_main_estimates, file.path(out_dir, "text_main_estimates.csv"))

print(text_main_estimates)
