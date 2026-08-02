# yokum_ravishankar_coppock_2019/maintained/text_null_results_check.R
# Output: output/text_null_results_check.csv
# Depends on: figure_c1_all_outcomes.R output, helpers.R
# Description: The Results section claims that no estimate on any measured outcome
#   reaches statistical significance at conventional levels. This counts how many
#   of the 45 outcomes clear each conventional threshold, so the claim is checked
#   rather than repeated.
#   Two outcomes, serious uses of force against white and against other-race
#   civilians, are identically zero across the whole posttreatment window, so their
#   estimate, standard error and p-value are all degenerate and they are counted
#   separately rather than dropped silently.

source(here::here("maintained", "helpers.R"))

estimates <- read_csv(file.path(out_dir, "figure_c1_all_outcomes.csv"), show_col_types = FALSE)

text_null_results_check <- estimates |>
  summarize(
    n_outcomes = n(),
    n_outcomes_not_estimable = sum(is.na(p_value)),
    n_p_below_0.05 = sum(p_value < 0.05, na.rm = TRUE),
    n_p_below_0.10 = sum(p_value < 0.10, na.rm = TRUE),
    smallest_p_value = min(p_value, na.rm = TRUE),
    outcome_with_smallest_p = outcome[which.min(p_value)],
    .by = estimator
  )

write_csv(text_null_results_check, file.path(out_dir, "text_null_results_check.csv"))

print(text_null_results_check)
