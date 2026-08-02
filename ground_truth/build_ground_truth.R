# yokum_ravishankar_coppock_2019/ground_truth/build_ground_truth.R
# Output: ground_truth/yokum_ravishankar_coppock_2019_ground_truth.csv
# Depends on: maintained/output/, ground_truth/archive_estimates.csv (run run_all.R)
# Description: Assemble the ground truth table. Every value_paper in this file was
#   typed from the article PDF or the supplementary appendix and is used only as a
#   comparison target; no published number is an input to any computation here or
#   anywhere in maintained/. value_script is read back from the file that runs the
#   deposited specification, and value_rewrite from maintained/output/, so neither
#   column can drift from the code that produced it.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

options(width = 200)

# District labels are read as text on purpose. readr accepts the Fortran double
# exponent, so a guessed column of "1D" through "7D" comes back as the numbers 1
# through 7 and then fails to join against the labels the appendix prints.
out <- function(file) {
  path <- here::here("maintained", "output", file)
  has_district <- "district" %in% names(read_csv(path, n_max = 0, show_col_types = FALSE))
  if (has_district) {
    read_csv(path, col_types = cols(district = col_character(), .default = col_guess()))
  } else {
    read_csv(path, show_col_types = FALSE)
  }
}

archive <- read_csv(here::here("ground_truth", "archive_estimates.csv"), show_col_types = FALSE)

# Appendix difference-in-means tables ----
# Typed from Tables C.5 through C.37 of the supplementary appendix. The odd-numbered
# tables are the unadjusted estimates; the even-numbered ones are covariate-adjusted
# and are handled further down, because the deposit cannot support them.
paper_dim <- tribble(
  ~table_figure, ~stem, ~outcome, ~estimate, ~std_error, ~constant, ~constant_se,
  "Table C.5", "table_c5_use_of_force", "Use of Force", 73.6, 87.0, 807.2, 59.2,
  "Table C.5", "table_c5_use_of_force", "Use of Force (Serious)", 13.8, 14.1, 36.2, 9.0,
  "Table C.5", "table_c5_use_of_force", "Use of Force (Other)", 59.8, 83.4, 771.0, 57.5,
  "Table C.7", "table_c7_nighttime", "Use of Force (Night)", -33.2, 65.2, 475.2, 47.0,
  "Table C.7", "table_c7_nighttime", "Complaints (Night)", 12.6, 20.6, 87.0, 13.6,
  "Table C.9", "table_c9_use_of_force_black", "Use of Force", -18.2, 67.9, 530.9, 46.6,
  "Table C.9", "table_c9_use_of_force_black", "Use of Force (Serious)", 5.8, 10.0, 21.3, 6.9,
  "Table C.9", "table_c9_use_of_force_black", "Use of Force (Other)", -7.5, 67.0, 515.5, 45.9,
  "Table C.11", "table_c11_use_of_force_nonblack", "Use of Force", -1.0, 14.4, 45.8, 9.8,
  "Table C.11", "table_c11_use_of_force_nonblack", "Use of Force (Serious)", 1.8, 1.8, 0.0, 0.0,
  "Table C.11", "table_c11_use_of_force_nonblack", "Use of Force (Other)", 3.9, 14.4, 45.8, 9.8,
  "Table C.13", "table_c13_use_of_force_white", "Use of Force", 7.2, 10.1, 21.5, 6.2,
  "Table C.13", "table_c13_use_of_force_white", "Use of Force (Serious)", 0.0, 0.0, 0.0, 0.0,
  "Table C.13", "table_c13_use_of_force_white", "Use of Force (Other)", 8.5, 10.2, 21.5, 6.2,
  "Table C.15", "table_c15_use_of_force_hispanic", "Use of Force", -8.2, 8.3, 22.5, 6.5,
  "Table C.15", "table_c15_use_of_force_hispanic", "Use of Force (Serious)", 1.8, 1.8, 0.0, 0.0,
  "Table C.15", "table_c15_use_of_force_hispanic", "Use of Force (Other)", -4.6, 9.0, 22.5, 6.5,
  "Table C.17", "table_c17_use_of_force_other_race", "Use of Force", 0.0, 2.5, 1.8, 1.8,
  "Table C.17", "table_c17_use_of_force_other_race", "Use of Force (Serious)", 0.0, 0.0, 0.0, 0.0,
  "Table C.17", "table_c17_use_of_force_other_race", "Use of Force (Other)", 0.0, 2.5, 1.8, 1.8,
  "Table C.19", "table_c19_complaints", "Complaints", 57.3, 41.4, 280.1, 29.6,
  "Table C.19", "table_c19_complaints", "Complaints (Sustained)", 16.9, 14.2, 38.7, 10.3,
  "Table C.19", "table_c19_complaints", "Complaints (Not Sustained)", 40.4, 37.0, 241.4, 26.1,
  "Table C.19", "table_c19_complaints", "Compliants (Insufficient Facts)", -7.9, 13.8, 47.8, 10.8,
  "Table C.21", "table_c21_assaults_on_police", "Assault on PO", 71.6, 145.7, 1381.8, 107.8,
  "Table C.21", "table_c21_assaults_on_police", "Felony APO", -16.6, 39.1, 155.2, 29.6,
  "Table C.21", "table_c21_assaults_on_police", "Misdemeanor APO", 88.3, 131.9, 1226.6, 97.3,
  "Table C.23", "table_c23_discretionary_arrests", "Disorderly Conduct", -127.7, 277.2, 1416.5, 186.3,
  "Table C.23", "table_c23_discretionary_arrests", "Simple Assault", 430.8, 593.1, 9065.7, 442.5,
  "Table C.23", "table_c23_discretionary_arrests", "Traffic Violation", 91.1, 617.2, 5230.6, 458.2,
  "Table C.25", "table_c25_domestic_violence", "DV Report Taken", -9448.5, 10905.5, 230390.1, 8087.3,
  "Table C.25", "table_c25_domestic_violence", "DV Report Taken (Family)", -858.5, 886.4, 12962.6, 677.6,
  "Table C.25", "table_c25_domestic_violence", "DV Report Taken (Not Family)", -8590.1, 10260.7, 217427.5, 7582.4,
  "Table C.25", "table_c25_domestic_violence", "DV Calls", -22217.9, 21363.5, 446876.3, 15822.8,
  "Table C.25", "table_c25_domestic_violence", "DV Arrests", -464.7, 454.8, 4272.0, 348.6,
  "Table C.27", "table_c27_judicial_outcomes", "Prosecuted", 2421.6, 2632.7, 33139.1, 1814.6,
  "Table C.27", "table_c27_judicial_outcomes", "Found Guilty", 13.5, 20.0, 39.6, 14.1,
  "Table C.27", "table_c27_judicial_outcomes", "Not Found Guilty", -15.6, 22.2, 49.3, 17.7,
  "Table C.27", "table_c27_judicial_outcomes", "Entered Plea", 62.8, 353.1, 1348.5, 182.0,
  "Table C.27", "table_c27_judicial_outcomes", "Not Pursued", -114.3, 102.2, 390.1, 95.9,
  "Table C.29", "table_c29_court_appearances", "Court Appearances", -936.0, 868.5, 11798.2, 683.8,
  "Table C.29", "table_c29_court_appearances", "Hours in Court", -2639.0, 2220.5, 28026.2, 1724.3,
  "Table C.31", "table_c31_clinic_visits", "Clinic Visits", -23.0, 32.8, 237.3, 25.0,
  "Table C.33", "table_c33_tickets", "Tickets", -3059.6, 7460.1, 24815.5, 5472.1,
  "Table C.35", "table_c35_warnings", "Warnings", -4.9, 868.9, 4250.7, 595.4,
  "Table C.37", "table_c37_compliance", "Videos per year", 649.1, 17.2, 13.9, 3.8,
  "Table C.37", "table_c37_compliance", "Average length of videos in minutes", 10.3, 0.2, 0.8, 0.1
)

quantity_labels <- c(estimate = "estimate on Officer Assigned BWC",
                     std_error = "standard error on Officer Assigned BWC",
                     constant = "constant",
                     constant_se = "standard error on the constant")

rewrite_dim <- paper_dim |>
  distinct(stem) |>
  mutate(values = map(stem, function(s) out(paste0(s, ".csv")))) |>
  unnest(values) |>
  select(stem, outcome, outcome_variable, estimate, std_error, constant, constant_se, n)

dim_rows <- paper_dim |>
  pivot_longer(c(estimate, std_error, constant, constant_se),
               names_to = "quantity", values_to = "value_paper") |>
  left_join(
    rewrite_dim |>
      pivot_longer(c(estimate, std_error, constant, constant_se),
                   names_to = "quantity", values_to = "value_rewrite") |>
      select(stem, outcome, quantity, value_rewrite),
    by = join_by(stem, outcome, quantity)
  ) |>
  left_join(
    archive |>
      pivot_longer(c(estimate, std_error, constant, constant_se),
                   names_to = "quantity", values_to = "value_script") |>
      select(stem, outcome, quantity, value_script),
    by = join_by(stem, outcome, quantity)
  ) |>
  transmute(
    table_figure,
    claim = paste0(outcome, ": ", quantity_labels[quantity]),
    value_script, value_paper, value_rewrite,
    digits = 1,
    notes = ""
  )

n_rows <- paper_dim |>
  distinct(table_figure, stem) |>
  left_join(distinct(rewrite_dim, stem, n), by = join_by(stem)) |>
  left_join(distinct(select(archive, stem, n_archive = n)), by = join_by(stem)) |>
  transmute(
    table_figure,
    claim = "N",
    value_script = n_archive,
    value_paper = 1922,
    value_rewrite = n,
    digits = 0,
    notes = "The deposited script fits every one of these models on all 2,224 officers in the trial, not on the 1,922 in the seven patrol districts that the published tables report"
  )

# Appendix Table A.1 ----
paper_a1 <- tribble(
  ~block, ~control, ~bwc, ~probability, ~probability_digits,
  "1D", 142, 142, 0.5, 1,
  "1D Station", 7, 7, 0.5, 1,
  "2D", 137, 137, 0.5, 1,
  "3D", 137, 137, 0.5, 1,
  "4D", 141, 141, 0.5, 1,
  "5D", 79, 166, 0.68, 2,
  "6D", 153, 152, 0.5, 1,
  "7D", 99, 159, 0.62, 2,
  "NSIDa", 12, 19, 0.61, 2,
  "NSIDb", 36, 36, 0.5, 1,
  "SOD", 48, 49, 0.5, 1,
  "School Security", 44, 44, 0.5, 1
)

rewrite_a1 <- out("table_a1_random_assignment.csv")

a1_joined <- paper_a1 |>
  left_join(rewrite_a1, by = join_by(block), suffix = c("_paper", "_rewrite"))

a1_rows <- bind_rows(
  a1_joined |> transmute(block, claim = "officers assigned to control",
                         value_paper = control_paper, value_rewrite = control_rewrite, digits = 0),
  a1_joined |> transmute(block, claim = "officers assigned a camera",
                         value_paper = bwc_paper, value_rewrite = bwc_rewrite, digits = 0),
  a1_joined |> transmute(block, claim = "probability of assignment",
                         value_paper = probability, value_rewrite = probability_of_assignment,
                         digits = probability_digits)
) |>
  arrange(match(block, paper_a1$block)) |>
  transmute(
    table_figure = "Table A.1",
    claim = paste0(block, ": ", claim),
    value_script = NA_real_,
    value_paper, value_rewrite, digits,
    notes = "No deposited script builds this table"
  )

# Appendix Table A.4 ----
paper_a4 <- tribble(
  ~district, ~date_yyyymmdd,
  "5D", 20150628,
  "7D", 20150628,
  "3D", 20160315,
  "1D", 20160322,
  "6D", 20160419,
  "4D", 20160503,
  "2D", 20160517
)

rewrite_a4 <- out("table_a4_deployment_dates.csv")

a4_rows <- paper_a4 |>
  left_join(select(rewrite_a4, district, rewrite_date = date_yyyymmdd), by = join_by(district)) |>
  transmute(
    table_figure = "Table A.4",
    claim = paste0(district, ": date of first BWC deployment, as YYYYMMDD"),
    value_script = NA_real_,
    value_paper = date_yyyymmdd,
    value_rewrite = rewrite_date,
    digits = 0,
    notes = "No deposited script builds this table; the date is the first day of each district's posttreatment window in the deposited officer-day panel"
  )

# In-text quantities ----
sample_sizes <- out("text_sample_sizes.csv")
compliance <- out("text_compliance_means.csv")
main_estimates <- out("text_main_estimates.csv")
null_check <- out("text_null_results_check.csv")
districts <- out("text_district_by_district.csv")
compliance_fits <- out("table_c37_compliance.csv")

value_of <- function(data, quantity) data$value[data$quantity == quantity]
compliance_value <- function(sample_label, assignment_label, column) {
  compliance[[column]][compliance$sample == sample_label & compliance$assignment == assignment_label]
}
estimate_of <- function(outcome_label, column) main_estimates[[column]][main_estimates$outcome == outcome_label]

text_rows <- tribble(
  ~table_figure, ~claim, ~value_script, ~value_paper, ~value_rewrite, ~digits, ~notes,
  "Text, Methods", "Officers in the trial", NA, 2224, value_of(sample_sizes, "Officers in the trial"), 0, "",
  "Text, Methods", "Officers assigned to control", NA, 1035, value_of(sample_sizes, "Assigned to control"), 0, "",
  "Text, Methods", "Officers assigned a camera", NA, 1189, value_of(sample_sizes, "Assigned to a camera"), 0, "",
  "Text, Methods", "Officers in the seven patrol districts", NA, 1922,
    value_of(sample_sizes, "Officers in the seven patrol districts"), 0, "",
  "Text, Methods", "Videos per year, officers assigned a camera", NA, 665,
    compliance_value("Seven patrol districts", "Officer assigned BWC", "videos_per_year"), 0,
    "The article says 'about 665'. The weighted mean in the analysis sample is 663.1, which is also what the article's own Table C.37 implies, since 13.9 plus 649.1 is 663.0. No sample or weighting scheme in the deposit returns 665: dropping the weights gives 659.3 on the analysis sample, and taking all 2,224 officers gives 592.5 weighted and 591.9 unweighted",
  "Text, Methods", "Videos per year, control officers", NA, 14,
    compliance_value("Seven patrol districts", "Control", "videos_per_year"), 0, "",
  "Text, Methods", "Average video length in minutes, officers assigned a camera", NA, 11,
    compliance_value("Seven patrol districts", "Officer assigned BWC", "average_video_minutes"), 0,
    "The article says 'over 11 min'",
  "Text, Methods", "Average video length in minutes, control officers", NA, 0.8,
    compliance_value("Seven patrol districts", "Control", "average_video_minutes"), 1, "",
  "Text, Methods", "Manipulation check significance", NA, NA,
    max(compliance_fits$p_value), NA,
    "The article reports p < 0.001 on both compliance measures. The larger of the two p-values is far below that, so the claim holds, but a bound is not a value and cannot be matched to printed precision",
  "Text, Results", "Use of force, estimate", NA, 74, estimate_of("Use of Force", "estimate"), 0, "",
  "Text, Results", "Use of force, standard error", NA, 87, estimate_of("Use of Force", "std_error"), 0, "",
  "Text, Results", "Complaints, estimate", NA, 57, estimate_of("Complaints", "estimate"), 0, "",
  "Text, Results", "Complaints, standard error", NA, 41, estimate_of("Complaints", "std_error"), 0, "",
  "Text, Results", "Arrests for disorderly conduct, estimate", NA, -128,
    estimate_of("Disorderly Conduct", "estimate"), 0, "",
  "Text, Results", "Arrests for disorderly conduct, standard error", NA, 277,
    estimate_of("Disorderly Conduct", "std_error"), 0, "",
  "Text, Results", "Outcomes significant at conventional levels", NA, 0,
    null_check$n_p_below_0.05[null_check$estimator == "Difference-in-means"], 0,
    "Counted over the 45 outcomes of Figure C.1. Two of them, serious uses of force against white and against other-race civilians, are identically zero throughout the posttreatment window and have no p-value at all",
  "Text, Discussion", "Districts with a significant effect on use of force", NA, 0,
    sum(districts$p.value < 0.05), 0,
    "The Discussion calls the study seven mini-experiments and says the effects are small and insignificant in all seven. No published table reports this, so it is estimated here district by district",
  "Text, Discussion", "Days in 2016 with at least one video per treated call for service (per cent)", NA, 98, NA, 0,
    "The calls-for-service data behind this figure are not in the deposit",
  "Text, Discussion", "Average adherence on the remaining days (per cent)", NA, 96, NA, 0,
    "The calls-for-service data behind this figure are not in the deposit",
  "Text, Discussion", "Share of calls answered by control officers only", NA, NA, NA, NA,
    "Stated as approximately one-third. The calls-for-service data behind it are not in the deposit"
)

# Floats with no source in the deposit, and floats that print no numbers ----
figure_1 <- out("figure_1_main_outcomes.csv")
figure_c1 <- out("figure_c1_all_outcomes.csv")
figure_e3 <- out("figure_e3_use_of_force_time_series.csv")
figure_e4 <- out("figure_e4_complaints_time_series.csv")

# The join key is the outcome column name, not the printed label. Six of the
# appendix tables print a row labelled "Use of Force", so a join on the label
# crosses every one of them against every other and the agreement it reports is
# between outcomes that have nothing to do with each other.
dim_series_agreement <- figure_c1 |>
  filter(estimator == "Difference-in-means") |>
  select(outcome_variable, figure_estimate = estimate, figure_std_error = std_error) |>
  inner_join(select(rewrite_dim, outcome_variable, estimate, std_error),
             by = join_by(outcome_variable)) |>
  summarize(n_outcomes = n(),
            max_difference = max(abs(figure_estimate - estimate), abs(figure_std_error - std_error)))

stopifnot(dim_series_agreement$n_outcomes == 45)

float_rows <- tribble(
  ~table_figure, ~claim, ~value_script, ~value_paper, ~value_rewrite, ~digits, ~notes,
  "Figure 1", "Difference-in-means series, three outcomes", NA, NA,
    nrow(filter(figure_1, estimator == "Difference-in-means")), NA,
    "The figure prints no numbers. Its three unadjusted estimates are the ones the Results section states in words and Tables C.5, C.19 and C.23 print, and those rows are checked above",
  "Figure 1", "Covariate-adjusted series, three outcomes", NA, NA, NA, NA,
    "Not reproducible. The published series adjusts for officer gender, race and length of service, which the deposit cannot contain without identifying officers. The series drawn in the rewrite adjusts for the pretreatment outcome alone and is labelled as such",
  "Figure C.1", "Difference-in-means series, 45 outcomes", NA, NA, nrow(filter(figure_c1, estimator == "Difference-in-means")), NA,
    paste0("The figure prints no numbers. Matched on the outcome column name, all 45 plotted unadjusted estimates and standard errors agree with the appendix table entries for the same outcome to within ",
           format(dim_series_agreement$max_difference, digits = 2), ", and those table rows are checked above"),
  "Figure C.1", "Covariate-adjusted series, 45 outcomes", NA, NA, NA, NA,
    "Not reproducible, for the same reason as Figure 1",
  "Figure D.2", "All outcomes under the alternate measurement strategy", NA, NA, NA, NA,
    "Not reproducible. The alternate measurement strategy uses the full observation window for every district, and the deposited officer file carries only the 212-day rates",
  "Figure E.3", "Uses of force per 1,000 officers by district and period", NA, NA, nrow(figure_e3), NA,
    "The figure prints no numbers. The deposited officer-day panel reproduces the 432 plotted points. The caption says 90 days before and after deployment; the published axis runs from about 750 days before to 500 days after, so the caption describes a window the figure does not show",
  "Figure E.4", "Complaints per 1,000 officers by district and period", NA, NA, nrow(figure_e4), NA,
    "As Figure E.3, including the caption's 90-day claim",
  "Figure E.5", "Case-generating calls for service and videos uploaded per day", NA, NA, NA, NA,
    "Not reproducible. The calls-for-service series is not in the deposit",
  "Table A.2", "Pretreatment race and sex distribution", NA, NA, NA, NA,
    "Not reproducible. Officer race and sex are not in the deposit",
  "Table A.3", "Pretreatment length of service", NA, NA, NA, NA,
    "Not reproducible. Officer length of service is not in the deposit"
)

ols_tables <- tribble(
  ~table_figure, ~outcomes_described,
  "Table C.6", "use of force",
  "Table C.8", "use of force and complaints at night",
  "Table C.10", "use of force, black civilians",
  "Table C.12", "use of force, nonblack civilians",
  "Table C.14", "use of force, white civilians",
  "Table C.16", "use of force, Hispanic civilians",
  "Table C.18", "use of force, other-race civilians",
  "Table C.20", "complaints",
  "Table C.22", "assaults on police officers",
  "Table C.24", "discretionary arrests",
  "Table C.26", "domestic violence outcomes",
  "Table C.28", "judicial outcomes",
  "Table C.30", "court appearances",
  "Table C.32", "clinic visits",
  "Table C.34", "tickets",
  "Table C.36", "warnings"
) |>
  transmute(
    table_figure,
    claim = paste0("Covariate-adjusted estimates, ", outcomes_described),
    value_script = NA_real_, value_paper = NA_real_, value_rewrite = NA_real_,
    digits = NA_real_,
    notes = "Not reproducible. Every column of this table conditions on officer gender, race and length of service, which the deposit cannot contain without identifying officers. The covariate rows the table prints are the pretreatment outcome, gender, a three-category race variable and length of service, with no block indicators, although the article's Eq. 1 writes the specification with a vector of major-block indicators. The deposit's own README lists a regression_tables_cov.R that would have produced these tables, and that file is not in the deposit"
  )

# Assemble ----
agrees <- function(value, target, digits) {
  case_when(
    is.na(value) | is.na(target) | is.na(digits) ~ NA_real_,
    abs(value - target) <= 0.5 * 10^(-digits) ~ 1,
    .default = 0
  )
}

ground_truth <- bind_rows(dim_rows, n_rows, a1_rows, a4_rows, text_rows, float_rows, ols_tables) |>
  mutate(
    paper_id = "yokum_ravishankar_coppock_2019",
    match = agrees(value_script, value_paper, digits),
    match_rewrite = agrees(value_rewrite, value_paper, digits),
    defect_locus = case_when(
      is.na(match_rewrite) | match_rewrite == 1 ~ NA_character_,
      claim == "Videos per year, officers assigned a camera" ~ "paper_internal",
      .default = "unresolved"
    )
  ) |>
  select(paper_id, table_figure, claim, value_script, value_paper, match,
         value_rewrite, match_rewrite, defect_locus, notes)

write_csv(ground_truth, here::here("ground_truth", "yokum_ravishankar_coppock_2019_ground_truth.csv"))

print(ground_truth |> select(table_figure, claim, value_script, value_paper, match, value_rewrite, match_rewrite),
      n = nrow(ground_truth))

print(ground_truth |>
        summarize(rows = n(),
                  archive_match_1 = sum(match == 1, na.rm = TRUE),
                  archive_match_0 = sum(match == 0, na.rm = TRUE),
                  archive_match_na = sum(is.na(match)),
                  rewrite_match_1 = sum(match_rewrite == 1, na.rm = TRUE),
                  rewrite_match_0 = sum(match_rewrite == 0, na.rm = TRUE),
                  rewrite_match_na = sum(is.na(match_rewrite))))
