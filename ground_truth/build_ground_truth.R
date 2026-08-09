# yokum_ravishankar_coppock_2019/ground_truth/build_ground_truth.R
# Output: ground_truth/yokum_ravishankar_coppock_2019_ground_truth.csv,
#   ground_truth/float_coverage.csv
# Depends on: ground_truth/published_claims.csv, ground_truth/archive_estimates.csv,
#   maintained/output/ (run run_all.R first), maintained/in_text_claims.R
# Description: Assemble the comparison table, then run the coverage gate over the
#   second instrument. One row per published quantity, carrying the value the
#   article prints, the value the deposited specification produces, and the value
#   the maintained rewrite computes.
#
#   Every value_paper in this file was read from the article PDF or the
#   supplementary appendix and is used only as a comparison target. No published
#   number is an input to any computation here or anywhere in maintained/.
#   value_script is read back from archive_estimates.csv, which runs the deposited
#   specification, and value_rewrite from maintained/output/, so neither column can
#   drift from the code that produced it.
#
#   value_paper is carried as the STRING the page prints, and a value agrees when
#   the pipeline's number, printed to that page's own precision, gives the same
#   digits. A double cannot do this job: it does not record that Table C.5 prints a
#   standard error as 87.0 rather than 87, nor that Table C.11 prints a constant as
#   -0.0.

library(here)
library(tidyverse)

here::i_am("ground_truth/build_ground_truth.R")

options(width = 200)

paper_id <- "yokum_ravishankar_coppock_2019"

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

# The extraction ----
# published_claims.csv is the numeric-token extraction from the article and the
# appendix. It governs coverage for both instruments and is the single home of the
# per-claim precision, so neither file can name a different one.

published_claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(value_paper = col_character(), .default = col_guess())
)

# Rendering and comparison ----

# "The string the article prints" means its digits, not its typography: the
# Unicode minus, thousands separators, a missing leading zero and a signed zero
# are normalised away, and the number of decimals, which is the one typographic
# fact the comparison needs, survives.
normalise_printed <- function(x) {
  x |>
    str_replace_all("[−–—]", "-") |>
    str_remove_all(",") |>
    str_replace("^(-?)\\.", "\\10") |>
    str_replace("^-(0(\\.0+)?)$", "\\1")
}

# Signed zero is normalised on this side as well as on the transcription side;
# whichever instrument normalises, both must.
render_at <- function(x, digits) {
  rendered <- sprintf(paste0("%.", digits, "f"), x)
  str_replace(rendered, "^-(0(\\.0+)?)$", "\\1")
}

# A value agrees when the pipeline's number, printed to the page's own precision,
# gives the same digits. The epsilon keeps a value sitting a hair from the
# rounding boundary from being rejected by floating point. A claim that names a
# threshold rather than a value carries its own operator.
agrees <- function(value, value_paper, digits, comparison = NULL) {
  target <- suppressWarnings(as.numeric(normalise_printed(value_paper)))
  d <- if_else(is.na(digits), 0L, as.integer(digits))
  cmp <- if (is.null(comparison)) rep("==", length(value)) else if_else(is.na(comparison), "==", comparison)
  equal <- suppressWarnings(
    render_at(value, d) == normalise_printed(value_paper) |
      abs(round(value, d) - target) < 1e-9 * pmax(1, abs(target))
  )
  case_when(
    is.na(value) | is.na(target) | is.na(digits) ~ NA_real_,
    cmp == "approx" ~ NA_real_,
    cmp == "==" ~ as.numeric(equal),
    cmp == ">" ~ as.numeric(value > target),
    cmp == ">=" ~ as.numeric(value >= target),
    cmp == "<" ~ as.numeric(value < target),
    cmp == "<=" ~ as.numeric(value <= target),
    .default = NA_real_
  )
}

# Checks that depend only on the extraction ----
# These run before anything consumes it, so a wrong precision trips its own check
# rather than the value comparison downstream.

stopifnot(
  !any(duplicated(published_claims$claim_id)),
  all(nzchar(published_claims$claim_id)),
  all(published_claims$claim_type %in%
        c("pipeline", "descriptive", "definitional", "structural", "transcribed")),
  all(published_claims$needs_block %in% c(TRUE, FALSE)),
  all(is.na(published_claims$comparison) |
        published_claims$comparison %in% c("==", "<", ">", "<=", ">=", "approx")),
  all(published_claims$needs_block[
    published_claims$claim_type %in% c("pipeline", "descriptive")])
)

# A stored value_paper that does not survive a round trip through its own recorded
# precision means digits is wrong about the precision even where it is right about
# the value, which numeric equality would pass.
round_trips <- function(value_paper, digits, where) {
  normalised <- normalise_printed(value_paper)
  numeric_rows <- !is.na(value_paper) & !is.na(digits) &
    str_detect(normalised, "^-?\\d+(\\.\\d+)?$")
  bad <- numeric_rows & render_at(as.numeric(normalised), digits) != normalised
  if (any(bad)) {
    print(tibble(value_paper = value_paper[bad], digits = digits[bad]), n = Inf)
    stop("A stored published value does not round trip through its own precision in ",
         where, ".")
  }
  invisible(NULL)
}

round_trips(published_claims$value_paper, published_claims$digits, "published_claims.csv")

# The precision and the operator of a prose claim come from the extraction and
# from nowhere else.
claim_field <- function(id, field) {
  row <- match(id, published_claims$claim_id)
  stopifnot(!any(is.na(row)))
  published_claims[[field]][row]
}

# Appendix C difference-in-means tables ----
# Transcribed from Tables C.5 through C.37 of the supplementary appendix, as the
# strings those pages print. The odd-numbered tables are the unadjusted estimates;
# the even-numbered ones are covariate-adjusted and are handled further down,
# because the deposit cannot support them.
#
# Each outcome column prints six numbers: an estimate and standard error on
# Officer Assigned BWC, a constant and its standard error, a sample size and an
# R-squared. Two columns print no R-squared, and they are NA here.
paper_dim <- tribble(
  ~table_figure, ~stem, ~outcome, ~estimate, ~std_error, ~constant, ~constant_se, ~r_squared, ~r2_digits,
  "Table C.5", "table_c5_use_of_force", "Use of Force", "73.6", "87.0", "807.2", "59.2", "0.000", 3,
  "Table C.5", "table_c5_use_of_force", "Use of Force (Serious)", "13.8", "14.1", "36.2", "9.0", "0.001", 3,
  "Table C.5", "table_c5_use_of_force", "Use of Force (Other)", "59.8", "83.4", "771.0", "57.5", "0.000", 3,
  "Table C.7", "table_c7_nighttime", "Use of Force (Night)", "-33.2", "65.2", "475.2", "47.0", "0.000", 3,
  "Table C.7", "table_c7_nighttime", "Complaints (Night)", "12.6", "20.6", "87.0", "13.6", "0.000", 3,
  "Table C.9", "table_c9_use_of_force_black", "Use of Force", "-18.2", "67.9", "530.9", "46.6", "0.000", 3,
  "Table C.9", "table_c9_use_of_force_black", "Use of Force (Serious)", "5.8", "10.0", "21.3", "6.9", "0.000", 3,
  "Table C.9", "table_c9_use_of_force_black", "Use of Force (Other)", "-7.5", "67.0", "515.5", "45.9", "0.000", 3,
  "Table C.11", "table_c11_use_of_force_nonblack", "Use of Force", "-1.0", "14.4", "45.8", "9.8", "0.000", 3,
  "Table C.11", "table_c11_use_of_force_nonblack", "Use of Force (Serious)", "1.8", "1.8", "-0.0", "0.0", "0.001", 3,
  "Table C.11", "table_c11_use_of_force_nonblack", "Use of Force (Other)", "3.9", "14.4", "45.8", "9.8", "0.000", 3,
  "Table C.13", "table_c13_use_of_force_white", "Use of Force", "7.2", "10.1", "21.5", "6.2", "0.000", 3,
  "Table C.13", "table_c13_use_of_force_white", "Use of Force (Serious)", "0.0", "0.0", "0.0", "0.0", NA, 3,
  "Table C.13", "table_c13_use_of_force_white", "Use of Force (Other)", "8.5", "10.2", "21.5", "6.2", "0.000", 3,
  "Table C.15", "table_c15_use_of_force_hispanic", "Use of Force", "-8.2", "8.3", "22.5", "6.5", "0.001", 3,
  "Table C.15", "table_c15_use_of_force_hispanic", "Use of Force (Serious)", "1.8", "1.8", "-0.0", "0.0", "0.001", 3,
  "Table C.15", "table_c15_use_of_force_hispanic", "Use of Force (Other)", "-4.6", "9.0", "22.5", "6.5", "0.000", 3,
  "Table C.17", "table_c17_use_of_force_other_race", "Use of Force", "-0.0", "2.5", "1.8", "1.8", "0.0", 1,
  "Table C.17", "table_c17_use_of_force_other_race", "Use of Force (Serious)", "0.0", "0.0", "0.0", "0.0", NA, 1,
  "Table C.17", "table_c17_use_of_force_other_race", "Use of Force (Other)", "-0.0", "2.5", "1.8", "1.8", "0.0", 1,
  "Table C.19", "table_c19_complaints", "Complaints", "57.3", "41.4", "280.1", "29.6", "0.001", 3,
  "Table C.19", "table_c19_complaints", "Complaints (Sustained)", "16.9", "14.2", "38.7", "10.3", "0.001", 3,
  "Table C.19", "table_c19_complaints", "Complaints (Not Sustained)", "40.4", "37.0", "241.4", "26.1", "0.001", 3,
  "Table C.19", "table_c19_complaints", "Compliants (Insufficient Facts)", "-7.9", "13.8", "47.8", "10.8", "0.000", 3,
  "Table C.21", "table_c21_assaults_on_police", "Assault on PO", "71.6", "145.7", "1381.8", "107.8", "0.000", 3,
  "Table C.21", "table_c21_assaults_on_police", "Felony APO", "-16.6", "39.1", "155.2", "29.6", "0.000", 3,
  "Table C.21", "table_c21_assaults_on_police", "Misdemeanor APO", "88.3", "131.9", "1226.6", "97.3", "0.000", 3,
  "Table C.23", "table_c23_discretionary_arrests", "Disorderly Conduct", "-127.7", "277.2", "1416.5", "186.3", "0.000", 3,
  "Table C.23", "table_c23_discretionary_arrests", "Simple Assault", "430.8", "593.1", "9065.7", "442.5", "0.000", 3,
  "Table C.23", "table_c23_discretionary_arrests", "Traffic Violation", "91.1", "617.2", "5230.6", "458.2", "0.000", 3,
  "Table C.25", "table_c25_domestic_violence", "DV Report Taken", "-9448.5", "10905.5", "230390.1", "8087.3", "0.000", 3,
  "Table C.25", "table_c25_domestic_violence", "DV Report Taken (Family)", "-858.5", "886.4", "12962.6", "677.6", "0.000", 3,
  "Table C.25", "table_c25_domestic_violence", "DV Report Taken (Not Family)", "-8590.1", "10260.7", "217427.5", "7582.4", "0.000", 3,
  "Table C.25", "table_c25_domestic_violence", "DV Calls", "-22217.9", "21363.5", "446876.3", "15822.8", "0.001", 3,
  "Table C.25", "table_c25_domestic_violence", "DV Arrests", "-464.7", "454.8", "4272.0", "348.6", "0.001", 3,
  "Table C.27", "table_c27_judicial_outcomes", "Prosecuted", "2421.6", "2632.7", "33139.1", "1814.6", "0.000", 3,
  "Table C.27", "table_c27_judicial_outcomes", "Found Guilty", "13.5", "20.0", "39.6", "14.1", "0.000", 3,
  "Table C.27", "table_c27_judicial_outcomes", "Not Found Guilty", "-15.6", "22.2", "49.3", "17.7", "0.000", 3,
  "Table C.27", "table_c27_judicial_outcomes", "Entered Plea", "62.8", "353.1", "1348.5", "182.0", "0.000", 3,
  "Table C.27", "table_c27_judicial_outcomes", "Not Pursued", "-114.3", "102.2", "390.1", "95.9", "0.001", 3,
  "Table C.29", "table_c29_court_appearances", "Court Appearances", "-936.0", "868.5", "11798.2", "683.8", "0.001", 3,
  "Table C.29", "table_c29_court_appearances", "Hours in Court", "-2639.0", "2220.5", "28026.2", "1724.3", "0.001", 3,
  "Table C.31", "table_c31_clinic_visits", "Clinic Visits", "-23.0", "32.8", "237.3", "25.0", "0.000", 3,
  "Table C.33", "table_c33_tickets", "Tickets", "-3059.6", "7460.1", "24815.5", "5472.1", "0.000", 3,
  "Table C.35", "table_c35_warnings", "Warnings", "-4.9", "868.9", "4250.7", "595.4", "0.000", 3,
  "Table C.37", "table_c37_compliance", "Videos per year", "649.1", "17.2", "13.9", "3.8", "0.4", 1,
  "Table C.37", "table_c37_compliance", "Average length of videos in minutes", "10.3", "0.2", "0.8", "0.1", "0.6", 1
) |>
  mutate(n = "1922")

round_trips(c(paper_dim$estimate, paper_dim$std_error, paper_dim$constant,
              paper_dim$constant_se, paper_dim$n),
            rep(c(1L, 1L, 1L, 1L, 0L), each = nrow(paper_dim)),
            "the Appendix C transcription")
round_trips(paper_dim$r_squared, paper_dim$r2_digits, "the Appendix C R-squared transcription")

# Every appendix C regression the deposit refits differs from the published one in
# the same single respect, so the sentence saying so is written once and attached
# to each row it explains rather than retyped beside the sample sizes alone.
district_note <- paste0(
  "The deposited script fits every one of these models on all 2,224 officers in the ",
  "trial, not on the 1,922 in the seven patrol districts that the published tables report")

quantity_labels <- c(estimate = "estimate on Officer Assigned BWC",
                     std_error = "standard error on Officer Assigned BWC",
                     constant = "constant",
                     constant_se = "standard error on the constant",
                     n = "N",
                     r_squared = "R squared")

quantity_digits <- c(estimate = 1L, std_error = 1L, constant = 1L,
                     constant_se = 1L, n = 0L, r_squared = NA_integer_)

slug <- function(x) {
  x |>
    str_to_lower() |>
    str_replace_all("[^a-z0-9]+", "_") |>
    str_remove_all("^_|_$")
}

rewrite_dim <- paper_dim |>
  distinct(stem) |>
  mutate(values = map(stem, function(s) out(paste0(s, ".csv")))) |>
  unnest(values) |>
  select(stem, outcome, outcome_variable, estimate, std_error, constant, constant_se,
         n, r_squared)

archive <- read_csv(here::here("ground_truth", "archive_estimates.csv"), show_col_types = FALSE)

long_quantities <- function(dat, value_name) {
  dat |>
    pivot_longer(any_of(names(quantity_labels)), names_to = "quantity",
                 values_to = value_name) |>
    select(stem, outcome, quantity, all_of(value_name))
}

# Every join between a transcription and a pipeline output goes through one place,
# and it asserts that neither side is duplicated and that nothing falls through in
# either direction. A published value with no rewrite counterpart is a mistyped
# label, not an unverifiable quantity, and a rewrite value with nothing to compare
# is a published cell the transcription missed.
join_sides <- function(published, archive_long, rewrite_long) {
  key <- c("stem", "outcome", "quantity")
  stopifnot(
    !any(duplicated(published[key])),
    !any(duplicated(archive_long[key])),
    !any(duplicated(rewrite_long[key]))
  )
  joined <- published |>
    left_join(archive_long, by = key) |>
    left_join(rewrite_long, by = key)
  stopifnot(nrow(joined) == nrow(published), !any(is.na(joined$value_rewrite)))
  unmatched_published <- anti_join(published, rewrite_long, by = key)
  if (nrow(unmatched_published) > 0) {
    print(unmatched_published)
    stop("A published cell has no counterpart in the rewrite.")
  }
  # The rewrite computes an R-squared for every column; Tables C.13 and C.17 print
  # none for their serious use of force column, whose outcome is identically zero.
  # Those two cells, and only those two, have nothing on the page to compare.
  unmatched_rewrite <- anti_join(rewrite_long, published, by = key)
  if (nrow(unmatched_rewrite) != 2 || !all(unmatched_rewrite$quantity == "r_squared")) {
    print(unmatched_rewrite)
    stop("The rewrite produces cells the published transcription does not account for.")
  }
  joined
}

published_dim <- paper_dim |>
  pivot_longer(c(estimate, std_error, constant, constant_se, n, r_squared),
               names_to = "quantity", values_to = "value_paper") |>
  filter(!is.na(value_paper)) |>
  mutate(digits = if_else(quantity == "r_squared", r2_digits,
                          unname(quantity_digits[quantity]))) |>
  select(table_figure, stem, outcome, quantity, value_paper, digits)

dim_rows <- join_sides(
  published_dim,
  long_quantities(archive, "value_script"),
  long_quantities(rewrite_dim, "value_rewrite")
) |>
  transmute(
    claim_id = paste(stem, slug(outcome), quantity, sep = "_"),
    table_figure,
    claim = paste0(outcome, ": ", quantity_labels[quantity]),
    value_script, value_paper, digits, value_rewrite,
    comparison = "==",
    holds = NA,
    defect_locus = NA_character_,
    notes = if_else(quantity == "n", district_note, "")
  )

# Appendix Table A.1 ----
paper_a1 <- tribble(
  ~block, ~control, ~bwc, ~probability, ~probability_digits,
  "1D", "142", "142", "0.5", 1,
  "1D Station", "7", "7", "0.5", 1,
  "2D", "137", "137", "0.5", 1,
  "3D", "137", "137", "0.5", 1,
  "4D", "141", "141", "0.5", 1,
  "5D", "79", "166", "0.68", 2,
  "6D", "153", "152", "0.5", 1,
  "7D", "99", "159", "0.62", 2,
  "NSIDa", "12", "19", "0.61", 2,
  "NSIDb", "36", "36", "0.5", 1,
  "SOD", "48", "49", "0.5", 1,
  "School Security", "44", "44", "0.5", 1
)

round_trips(c(paper_a1$control, paper_a1$bwc), 0L, "the Table A.1 count transcription")
round_trips(paper_a1$probability, paper_a1$probability_digits, "the Table A.1 probability transcription")

rewrite_a1 <- out("table_a1_random_assignment.csv")

stopifnot(setequal(paper_a1$block, rewrite_a1$block))

a1_joined <- paper_a1 |>
  left_join(rewrite_a1 |> select(block, rewrite_control = control, rewrite_bwc = bwc,
                                 probability_of_assignment),
            by = join_by(block))

a1_rows <- bind_rows(
  a1_joined |> transmute(block, quantity = "control", claim = "officers assigned to control",
                         value_paper = control, value_rewrite = as.numeric(rewrite_control), digits = 0),
  a1_joined |> transmute(block, quantity = "bwc", claim = "officers assigned a camera",
                         value_paper = bwc, value_rewrite = as.numeric(rewrite_bwc), digits = 0),
  a1_joined |> transmute(block, quantity = "probability", claim = "probability of assignment",
                         value_paper = probability, value_rewrite = probability_of_assignment,
                         digits = probability_digits)
) |>
  arrange(match(block, paper_a1$block)) |>
  transmute(
    claim_id = paste("table_a1", slug(block), quantity, sep = "_"),
    table_figure = "Table A.1",
    claim = paste0(block, ": ", claim),
    value_script = NA_real_,
    value_paper, digits, value_rewrite,
    comparison = "==",
    holds = NA,
    defect_locus = NA_character_,
    notes = "No deposited script builds this table"
  )

# Appendix Table A.4 ----
# The published table has ten rows. The deposited officer-day panel covers the
# seven patrol districts only, so the three special-unit rows have no source.
paper_a4 <- tribble(
  ~district, ~date_yyyymmdd, ~in_deposit,
  "5D", "20150628", TRUE,
  "7D", "20150628", TRUE,
  "NSID", "20160211", FALSE,
  "3D", "20160315", TRUE,
  "1D", "20160322", TRUE,
  "6D", "20160419", TRUE,
  "4D", "20160503", TRUE,
  "2D", "20160517", TRUE,
  "SOD", "20160722", FALSE,
  "School Security", "20160914", FALSE
)

round_trips(paper_a4$date_yyyymmdd, 0L, "the Table A.4 transcription")

rewrite_a4 <- out("table_a4_deployment_dates.csv")

a4_rows <- paper_a4 |>
  left_join(select(rewrite_a4, district, rewrite_date = date_yyyymmdd), by = join_by(district)) |>
  transmute(
    claim_id = paste("table_a4", slug(district), "date", sep = "_"),
    table_figure = "Table A.4",
    claim = paste0(district, ": date of first BWC deployment, as YYYYMMDD"),
    value_script = NA_real_,
    value_paper = date_yyyymmdd,
    digits = 0,
    value_rewrite = as.numeric(rewrite_date),
    comparison = "==",
    holds = NA,
    defect_locus = if_else(in_deposit, NA_character_, "archive"),
    notes = if_else(
      in_deposit,
      "No deposited script builds this table; the date is the first day of each district's posttreatment window in the deposited officer-day panel",
      "The deposited officer-day panel covers the seven patrol districts only, so the special units have no deployment date in the deposit")
  )

stopifnot(sum(is.na(a4_rows$value_rewrite)) == 3)

# In-text quantities ----
sample_sizes <- out("text_sample_sizes.csv")
compliance <- out("text_compliance_means.csv")
main_estimates <- out("text_main_estimates.csv")
null_check <- out("text_null_results_check.csv")
districts <- out("text_district_by_district.csv")
compliance_fits <- out("table_c37_compliance.csv")
measurement_window <- out("text_measurement_window.csv")
figure_1 <- out("figure_1_main_outcomes.csv")
figure_c1 <- out("figure_c1_all_outcomes.csv")
figure_e3 <- out("figure_e3_use_of_force_time_series.csv")
figure_e4 <- out("figure_e4_complaints_time_series.csv")
officer_level <- read_rds(here::here("maintained", "output", "officer_level_full.rds"))
dv_df <- read_rds(here::here("maintained", "output", "dv_df.rds"))
uof_night <- out("table_c7_nighttime.csv")

value_of <- function(data, quantity) data$value[data$quantity == quantity]
compliance_value <- function(sample_label, assignment_label, column) {
  compliance[[column]][compliance$sample == sample_label & compliance$assignment == assignment_label]
}
estimate_of <- function(outcome_label, column) main_estimates[[column]][main_estimates$outcome == outcome_label]

# The supplement's own contents page, transcribed here. The section a sentence
# names is part of the sentence, so a cross-reference is checked against this list
# rather than assumed.
appendix_contents <- tribble(
  ~letter, ~title,
  "A", "Methodology",
  "B", "A Novel Approach to Program Evaluation",
  "C", "Full Results",
  "D", "Application of Alternate Measurement Strategy",
  "E", "Supplementary Analyses",
  "F", "MPD General Order SPT-302.13",
  "G", "Preanalysis Plan"
)
section_of <- function(title) appendix_contents$letter[appendix_contents$title == title]

# Derivations the prose rows below use. Each is a derivation over pipeline output,
# never a refit.
window_days <- unique(measurement_window$post_window_days)
stopifnot(length(window_days) == 1)

# The rate scale the article calls "per 1,000 officers", recovered from the
# deposit rather than asserted: an officer's posttreatment rate divided by the
# count behind it is scale * 365.25 / window.
rate_ratio <- officer_level |>
  filter(use_of_force_post > 0) |>
  mutate(ratio = use_of_force_1000_rate_post / use_of_force_post) |>
  pull(ratio)
rate_scale <- round(median(rate_ratio) * window_days / 365.25)

deployment_days <- as.numeric(diff(range(rewrite_a4$first_deployment)))
pilot_blocks <- rewrite_a1 |> filter(block %in% c("5D", "7D"))
special_units <- rewrite_a1 |>
  filter(!block %in% paste0(c(1:7), "D"), block != "1D Station") |>
  mutate(unit = str_remove(district, "_2$"))

minor_blocks <- officer_level |>
  filter(!district %in% c("5D", "7D")) |>
  count(district_block_id)
modal_block_size <- as.integer(names(sort(table(minor_blocks$n), decreasing = TRUE))[1])

dim_estimates <- figure_c1 |> filter(estimator == "Difference-in-means")
uof_row <- figure_1 |> filter(estimator == "Difference-in-means", outcome == "Use of Force")
other_rows <- figure_1 |>
  filter(estimator == "Difference-in-means", outcome != "Use of Force")
night_row <- uof_night |> filter(outcome == "Use of Force (Night)")

race_outcomes <- c("white", "black", "hispanic", "other")
judicial_dispositions <- dv_df |>
  filter(dv_category == "Judicial Outcomes", dv_name != "charge_prosecuted")

# The confidence level the plotted intervals carry, read back off the interval
# rather than asserted. Two of the 45 outcomes are identically zero throughout the
# posttreatment window and have a zero standard error, so they carry no interval.
ci_level <- function(dat) {
  usable <- dat |> filter(estimator == "Difference-in-means", std_error > 0)
  levels <- round(100 * (1 - 2 * pt(-(usable$conf_high - usable$estimate) / usable$std_error,
                                    usable$n - 2)))
  levels <- unique(levels)
  stopifnot(length(levels) == 1)
  levels
}

text_rows <- tribble(
  ~claim_id, ~table_figure, ~claim, ~value_script, ~value_paper, ~digits, ~value_rewrite, ~holds, ~defect_locus, ~notes,

  # Abstract and significance statement ----
  "abstract_officers_in_trial", "Text, Abstract", "Officers in the trial",
    NA, "2224", 0, value_of(sample_sizes, "Officers in the trial"), NA, NA_character_, "",
  "abstract_effects_small_insignificant", "Text, Abstract", "Effects on all measured outcomes are small and insignificant",
    NA, NA_character_, NA, NA,
    all(dim_estimates$p_value >= 0.05, na.rm = TRUE), NA_character_,
    "Two of the 45 outcomes, serious uses of force against white and against other-race civilians, are identically zero throughout the posttreatment window and have no p-value at all",
  "significance_officers_in_trial", "Text, Significance", "Officers in the trial, restated",
    NA, "2224", 0, value_of(sample_sizes, "Officers in the trial"), NA, NA_character_, "",
  "significance_tracking_months", "Text, Significance", "Minimum tracking period in months",
    NA, "7", 0, round(window_days / (365.25 / 12)), NA, NA_character_,
    "The posttreatment measurement window is 212 days, which is 7.0 months at 30.4 days a month",

  # Methods ----
  "methods_half_assigned", "Text, Methods", "About half the officers were assigned a camera",
    NA, NA_character_, NA, NA,
    abs(value_of(sample_sizes, "Assigned to a camera") /
          value_of(sample_sizes, "Officers in the trial") - 0.5) < 0.05, NA_character_, "",
  "methods_officers_in_trial", "Text, Methods", "Officers in the trial, restated",
    NA, "2224", 0, value_of(sample_sizes, "Officers in the trial"), NA, NA_character_, "",
  "methods_seven_districts", "Text, Methods", "Police districts in the study",
    NA, "7", 0, n_distinct(measurement_window$district), NA, NA_character_, "",
  "methods_major_blocks_districts", "Text, Methods", "Major blocks that are police districts",
    NA, "7", 0, sum(rewrite_a1$block %in% paste0(1:7, "D")), NA, NA_character_, "",
  "methods_major_blocks_units", "Text, Methods", "Special units among the major blocks",
    NA, "3", 0, n_distinct(special_units$unit), NA, NA_character_, "",
  "methods_sample_total", "Text, Methods", "Officers in the sample",
    NA, "2224", 0, value_of(sample_sizes, "Officers in the trial"), NA, NA_character_, "",
  "methods_assigned_control", "Text, Methods", "Officers assigned to control",
    NA, "1035", 0, value_of(sample_sizes, "Assigned to control"), NA, NA_character_, "",
  "methods_assigned_treatment", "Text, Methods", "Officers assigned a camera",
    NA, "1189", 0, value_of(sample_sizes, "Assigned to a camera"), NA, NA_character_, "",
  "methods_videos_treatment", "Text, Methods", "Videos per year, officers assigned a camera",
    NA, "665", 0, compliance_value("Seven patrol districts", "Officer assigned BWC", "videos_per_year"),
    NA, "paper_internal",
    "The article says 'about 665'. The weighted mean in the analysis sample is 663.1, which is also what the article's own Table C.37 implies, since 13.9 plus 649.1 is 663.0. No sample or weighting scheme in the deposit returns 665: dropping the weights gives 659.3 on the analysis sample, and taking all 2,224 officers gives 592.5 weighted and 591.9 unweighted",
  "methods_videos_control", "Text, Methods", "Videos per year, control officers",
    NA, "14", 0, compliance_value("Seven patrol districts", "Control", "videos_per_year"), NA, NA_character_, "",
  "methods_video_minutes_treatment", "Text, Methods", "Average video length in minutes, officers assigned a camera",
    NA, "11", 0, compliance_value("Seven patrol districts", "Officer assigned BWC", "average_video_minutes"),
    NA, NA_character_, "The article says 'over 11 min', so the comparison is a threshold rather than a value",
  "methods_video_minutes_control", "Text, Methods", "Average video length in minutes, control officers",
    NA, "0.8", 1, compliance_value("Seven patrol districts", "Control", "average_video_minutes"), NA, NA_character_, "",
  "methods_manipulation_p", "Text, Methods", "Manipulation check significance",
    NA, "0.001", 3, max(compliance_fits$p_value), NA, NA_character_,
    "The article reports p < 0.001 on both compliance measures, so the comparison is a threshold rather than a value. The larger of the two p-values is far below it",
  "methods_outcome_families", "Text, Methods", "Families of outcome measures",
    NA, "4", 0, NA, NA, NA_character_,
    "The deposited outcome index groups the 45 outcomes into eight plotting categories and records no mapping onto the four families the article names, so nothing in the deposit was ever going to record this count",
  "methods_deployment_months", "Text, Methods", "Months over which cameras were deployed",
    NA, "11", 0, round(deployment_days / (365.25 / 12)), NA, NA_character_,
    "Taken over the seven patrol districts, the only ones whose deployment date is in the deposit",
  "methods_pilot_districts_deployed", "Text, Methods", "Districts that received cameras in 2015",
    NA, "2", 0, sum(format(rewrite_a4$first_deployment, "%Y") == "2015"), NA, NA_character_, "",
  "methods_first_deployment_year", "Text, Methods", "Year of the first deployment",
    NA, "2015", 0, as.numeric(format(min(rewrite_a4$first_deployment), "%Y")), NA, NA_character_, "",
  "methods_remaining_deployment_year", "Text, Methods", "Year of the last district deployment",
    NA, "2016", 0, as.numeric(format(max(rewrite_a4$first_deployment), "%Y")), NA, NA_character_, "",
  "methods_window_days", "Text, Methods", "Length of the measurement window in days",
    NA, "212", 0, window_days, NA, NA_character_, "",
  "methods_window_days_reason", "Text, Methods", "Days between the last district's deployment and the end of the study",
    NA, "212", 0,
    measurement_window$post_window_days[which.max(measurement_window$start_post)], NA, NA_character_, "",
  "methods_window_days_pretreatment", "Text, Methods", "Length of the pretreatment window in days",
    NA, "212", 0, unique(measurement_window$pre_window_days), NA, NA_character_, "",
  "methods_rate_denominator", "Text, Methods", "Denominator of the yearly event rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "methods_analysis_sample", "Text, Methods", "Officers in the seven patrol districts",
    NA, "1922", 0, value_of(sample_sizes, "Officers in the seven patrol districts"), NA, NA_character_, "",
  "methods_rate_denominator_restated", "Text, Methods", "Denominator of the yearly rate, restated",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",

  # Figure 1 ----
  "figure_1_ci_level", "Figure 1", "Confidence level of the plotted intervals",
    NA, "95", 0, ci_level(figure_1), NA, NA_character_, "",
  "figure_1_rate_denominator", "Figure 1", "Denominator of the plotted rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "float_figure_1", "Figure 1", "Estimates Figure 1 plots",
    NA, "6", 0, nrow(figure_1), NA, NA_character_,
    "The figure prints no estimate on its face. Its three unadjusted estimates are the ones the Results section states in words and Tables C.5, C.19 and C.23 print, and those rows are checked above. Its three covariate-adjusted estimates are not reproducible",

  # Results ----
  "results_four_categories", "Text, Results", "Outcome categories",
    NA, "4", 0, NA, NA, NA_character_,
    "As the Methods section's count of outcome families",
  "results_no_significant_estimate", "Text, Results", "No estimate reaches significance at conventional levels",
    NA, NA_character_, NA, NA,
    null_check$n_p_below_0.05[null_check$estimator == "Difference-in-means"] == 0, NA_character_,
    "Counted over the 45 outcomes of Figure C.1. Two of them, serious uses of force against white and against other-race civilians, are identically zero throughout the posttreatment window and have no p-value at all",
  "results_figure_1_reference", "Text, Results", "Figure 1 plots use of force, complaints and disorderly conduct arrests",
    NA, NA_character_, NA, NA,
    setequal(figure_1$outcome, c("Use of Force", "Complaints", "Disorderly Conduct")), NA_character_, "",
  "results_rate_denominator", "Text, Results", "Denominator of the plotted rate, restated",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "results_uof_estimate", "Text, Results", "Use of force, estimate",
    NA, "74", 0, estimate_of("Use of Force", "estimate"), NA, NA_character_, "",
  "results_uof_se", "Text, Results", "Use of force, standard error",
    NA, "87", 0, estimate_of("Use of Force", "std_error"), NA, NA_character_, "",
  "results_uof_rate_denominator", "Text, Results", "Denominator of the use of force rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "results_uof_not_significant", "Text, Results", "The use of force estimate is not distinguishable from zero",
    NA, NA_character_, NA, NA, uof_row$conf_low < 0 && uof_row$conf_high > 0, NA_character_, "",
  "results_complaints_estimate", "Text, Results", "Complaints, estimate",
    NA, "57", 0, estimate_of("Complaints", "estimate"), NA, NA_character_, "",
  "results_complaints_se", "Text, Results", "Complaints, standard error",
    NA, "41", 0, estimate_of("Complaints", "std_error"), NA, NA_character_, "",
  "results_complaints_rate_denominator", "Text, Results", "Denominator of the complaints rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "results_disorderly_estimate", "Text, Results", "Arrests for disorderly conduct, estimate",
    NA, "-128", 0, estimate_of("Disorderly Conduct", "estimate"), NA, NA_character_, "",
  "results_disorderly_se", "Text, Results", "Arrests for disorderly conduct, standard error",
    NA, "277", 0, estimate_of("Disorderly Conduct", "std_error"), NA, NA_character_, "",
  "results_disorderly_rate_denominator", "Text, Results", "Denominator of the disorderly conduct rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "results_others_nonsignificant", "Text, Results", "The complaints and disorderly conduct effects are also nonsignificant",
    NA, NA_character_, NA, NA,
    all(other_rows$conf_low < 0 & other_rows$conf_high > 0), NA_character_, "",

  # Discussion ----
  "discussion_seven_districts", "Text, Discussion", "Police districts within which cameras were assigned",
    NA, "7", 0, n_distinct(districts$district), NA, NA_character_, "",
  "discussion_seven_mini_experiments", "Text, Discussion", "Mini-experiments the districts constitute",
    NA, "7", 0, n_distinct(districts$district), NA, NA_character_, "",
  "discussion_all_seven_insignificant", "Text, Discussion", "Small and insignificant effects in all seven districts",
    NA, NA_character_, NA, NA, all(districts$p.value >= 0.05), NA_character_,
    "No published table reports this, so it is estimated district by district in the rewrite",
  "discussion_calls_thirds", "Text, Discussion", "About a third of calls answered by control officers only",
    NA, NA_character_, NA, NA, NA, "archive",
    "The calls-for-service data behind this claim are not in the deposit",
  "discussion_no_precamera_difference", "Text, Discussion", "No difference in precamera versus postcamera outcomes for either group",
    NA, NA_character_, NA, NA, NA, "archive",
    "The claim summarises Figures E.3 and E.4, which are smoothed scatterplots. The deposit ships no test behind them, and running one here would be estimation rather than derivation",
  "discussion_night_no_effect", "Text, Discussion", "No effect of cameras on use of force at night",
    NA, NA_character_, NA, NA, night_row$p_value >= 0.05, NA_character_, "",
  "discussion_adherence_days", "Text, Discussion", "Days in 2016 with at least one video per treated call for service (per cent)",
    NA, "98", 0, NA, NA, "archive",
    "The calls-for-service data behind this figure are not in the deposit",
  "discussion_shortfall_days", "Text, Discussion", "Days in 2016 with fewer videos than expected (per cent)",
    NA, "2", 0, NA, NA, "archive",
    "The calls-for-service data behind this figure are not in the deposit",
  "discussion_average_adherence", "Text, Discussion", "Average adherence on the remaining days (per cent)",
    NA, "96", 0, NA, NA, "archive",
    "The calls-for-service data behind this figure are not in the deposit",

  # Appendix A ----
  "appendix_pilot_districts", "Text, Appendix A", "Districts in the pilot",
    NA, "2", 0, nrow(pilot_blocks), NA, NA_character_, "",
  "appendix_pilot_bwc", "Text, Appendix A", "Pilot officers outfitted with cameras",
    NA, "325", 0, sum(pilot_blocks$bwc), NA, NA_character_, "",
  "appendix_pilot_control", "Text, Appendix A", "Pilot officers not given cameras",
    NA, "180", 0, sum(pilot_blocks$control), NA, "paper_internal",
    "The appendix's own Table A.1 gives 79 control officers in 5D and 99 in 7D, which is 178. The treated count in the same sentence, 325, is 166 plus 159 and agrees exactly",
  "appendix_major_blocks_districts", "Text, Appendix A", "Major blocks that are districts, restated",
    NA, "7", 0, sum(rewrite_a1$block %in% paste0(1:7, "D")), NA, NA_character_, "",
  "appendix_major_blocks_units", "Text, Appendix A", "Special units among the major blocks, restated",
    NA, "3", 0, n_distinct(special_units$unit), NA, NA_character_, "",
  "appendix_matched_pairs", "Text, Appendix A", "Officers were grouped into matched pairs",
    NA, NA_character_, NA, NA, modal_block_size == 2, NA_character_,
    "Outside the two pilot districts, which were assigned by complete random assignment, the deposited minor blocks hold two officers apiece with a handful of exceptions",
  "appendix_nsid_probability", "Text, Appendix A", "Share of the first NSID subgroup assigned a camera (per cent)",
    NA, "50", 0, NA,
    100 * rewrite_a1$probability_of_assignment[rewrite_a1$block == "NSIDa"] > 50, NA_character_, "",
  "appendix_total_major_blocks", "Text, Appendix A", "Major blocks in the randomization",
    NA, "12", 0, nrow(rewrite_a1), NA, NA_character_, "",
  "appendix_nsid_rounds", "Text, Appendix A", "Rounds of NSID assignment",
    NA, "2", 0, sum(str_starts(special_units$district, "NSID")), NA, NA_character_, "",
  "appendix_appendix_f_reference", "Text, Appendix A", "The general order list is said to be in Appendix F",
    NA, NA_character_, NA, NA, "F" == section_of("MPD General Order SPT-302.13"), NA_character_, "",
  "appendix_a1_rate_denominator", "Text, Appendix A.1", "Denominator of the alternate-strategy rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "appendix_alternate_section_reference", "Text, Appendix A.1", "The alternate measurement plots are said to be in Section 4",
    NA, NA_character_, NA, NA, "4" == section_of("Application of Alternate Measurement Strategy"),
    "paper_internal",
    "The supplement's sections are lettered A to G and it has no Section 4. The alternate measurement plots are Figure D.2, in Appendix D",
  "appendix_alternate_no_significant", "Text, Appendix A.1", "No significant effects under the alternate measurement strategy",
    NA, NA_character_, NA, NA, NA, "archive",
    "The alternate strategy uses the full observation window for every district, and the deposited officer file carries only the 212-day rates",
  "appendix_four_families", "Text, Appendix A.2", "Families of outcome measures, restated",
    NA, "4", 0, NA, NA, NA_character_,
    "As the Methods section's count of outcome families",
  "appendix_two_uof_measures", "Text, Appendix A.2.1", "Use of force measures held apart",
    NA, "2", 0,
    sum(dv_df$dv_name %in% c("use_of_force_serious", "use_of_force_less_serious")),
    NA, NA_character_,
    "The deposited outcome index carries a serious and an other measure beside the overall one",
  "appendix_race_categories", "Text, Appendix A.2.1", "Use of force examined across four race categories",
    NA, NA_character_, NA, NA,
    all(map_lgl(race_outcomes, \(r) any(str_detect(dv_df$dv_name, paste0("use_of_force_", r))))),
    NA_character_,
    "White, Black, Hispanic and Other are all present. The deposited index also carries a Nonblack aggregate, which the sentence does not name",
  "appendix_discretionary_categories", "Text, Appendix A.2.3", "Offense categories treated as discretionary",
    NA, "3", 0, sum(dv_df$dv_name %in% c("disorderly_conduct", "simple_assault", "traffic_arrest")),
    NA, NA_character_, "",
  "appendix_prosecution_categories", "Text, Appendix A.2.4", "Prosecution disposition categories",
    NA, "4", 0, nrow(judicial_dispositions), NA, NA_character_,
    "The judicial family carries five outcomes; the fifth, Prosecuted, is the parent of the four dispositions",

  # Appendix C ----
  "figure_c1_ci_level", "Figure C.1", "Confidence level of the plotted intervals",
    NA, "95", 0, ci_level(figure_c1), NA, NA_character_, "",
  "figure_c1_no_discernible_effect", "Figure C.1", "No discernible effect on any measured outcome",
    NA, NA_character_, NA, NA, all(null_check$n_p_below_0.05 == 0), NA_character_,
    "Taken over both estimators the rewrite draws. The published OLS series adjusts for officer gender, race and length of service, which the deposit cannot contain",
  "float_figure_c1", "Figure C.1", "Estimates Figure C.1 plots",
    NA, "90", 0, nrow(figure_c1), NA, NA_character_,
    "The figure prints no estimate on its face. Its 45 unadjusted estimates are the ones Tables C.5 to C.37 print and are checked above; its 45 covariate-adjusted estimates are not reproducible",
  "table_c_note_rate_denominator", "Appendix C table notes", "Denominator named in the table notes",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "appendix_c37_manipulation_holds", "Table C.37", "Officers assigned cameras made vastly more and longer videos",
    NA, NA_character_, NA, NA,
    all(compliance_fits$estimate > 0) && all(compliance_fits$p_value < 0.001), NA_character_, "",

  # Appendix D ----
  "figure_d2_no_significant", "Figure D.2", "No significant effect under the alternate measurement strategy",
    NA, NA_character_, NA, NA, NA, "archive",
    "The alternate strategy uses the full observation window for every district, and the deposited officer file carries only the 212-day rates",

  # Appendix E ----
  "figure_e3_window", "Figure E.3", "Days before and after deployment the figure covers",
    NA, "90", 0, NA,
    min(figure_e3$relative_month) == -90 && max(figure_e3$relative_month) == 90,
    "paper_internal",
    "The published figure runs from 750 days before deployment to 500 days after, and the deposited panel behind it from 690 before to 510 after. The deposit's own time_series_plot.R filters to a window of plus or minus 90 days for the pooled plot only, which the appendix does not print; the faceted plot the appendix does print carries no such filter",
  "figure_e3_no_difference", "Figure E.3", "No significant difference between the groups before or after deployment",
    NA, NA_character_, NA, NA, NA, "archive",
    "The deposit ships no test behind this caption, and running one here would be estimation rather than derivation",
  "figure_e3_day_zero", "Figure E.3", "Deployment occurs on day zero",
    NA, "0", 0, min(figure_e3$relative_month[figure_e3$relative_month >= 0]), NA, NA_character_, "",
  "figure_e3_rate_denominator", "Figure E.3", "Denominator of the plotted rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "float_figure_e3", "Figure E.3", "Points Figure E.3 plots",
    NA, NA_character_, NA, nrow(figure_e3), NA, NA_character_,
    "The published points are too densely overlaid to be counted from the page, so no published count can be laid against this one",
  "figure_e4_window", "Figure E.4", "Days before and after deployment the figure covers",
    NA, "90", 0, NA,
    min(figure_e4$relative_month) == -90 && max(figure_e4$relative_month) == 90,
    "paper_internal",
    "As Figure E.3",
  "figure_e4_no_difference", "Figure E.4", "No significant difference between the groups before or after deployment",
    NA, NA_character_, NA, NA, NA, "archive",
    "As Figure E.3",
  "figure_e4_day_zero", "Figure E.4", "Deployment occurs on day zero",
    NA, "0", 0, min(figure_e4$relative_month[figure_e4$relative_month >= 0]), NA, NA_character_, "",
  "figure_e4_rate_denominator", "Figure E.4", "Denominator of the plotted rate",
    NA, "1000", 0, rate_scale, NA, NA_character_, "",
  "float_figure_e4", "Figure E.4", "Points Figure E.4 plots",
    NA, NA_character_, NA, nrow(figure_e4), NA, NA_character_,
    "As Figure E.3",
  "appendix_adherence_days", "Text, Appendix E.2", "Days in 2016 with at least one video per treated call, restated",
    NA, "98", 0, NA, NA, "archive",
    "The calls-for-service data behind this figure are not in the deposit",
  "appendix_shortfall_days", "Text, Appendix E.2", "Days in 2016 with fewer videos than expected, restated",
    NA, "2", 0, NA, NA, "archive",
    "The calls-for-service data behind this figure are not in the deposit",
  "appendix_average_compliance", "Text, Appendix E.2", "Average compliance on the remaining days (per cent)",
    NA, "96", 0, NA, NA, "archive",
    "The calls-for-service data behind this figure are not in the deposit"
) |>
  mutate(comparison = claim_field(claim_id, "comparison"))

# Floats with no source in the deposit ----
# Every numbered float in the article and the appendix appears in the ground
# truth, including the ones with nothing in them to compare, so that a float's
# absence can never be mistaken for a float that was checked and passed.

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
            max_difference = max(abs(figure_estimate - estimate),
                                 abs(figure_std_error - std_error)))

stopifnot(dim_series_agreement$n_outcomes == 45)

float_rows <- tribble(
  ~claim_id, ~table_figure, ~claim, ~notes,
  "figure_1_adjusted_series", "Figure 1", "Covariate-adjusted series, three outcomes",
    "Not reproducible. The published series adjusts for officer gender, race and length of service, which the deposit cannot contain without identifying officers. The series drawn in the rewrite adjusts for the pretreatment outcome alone and is labelled as such",
  "figure_c1_dim_series", "Figure C.1", "Difference-in-means series, 45 outcomes",
    paste0("Matched on the outcome column name, all 45 plotted unadjusted estimates and standard errors agree with the appendix table entries for the same outcome to within ",
           format(dim_series_agreement$max_difference, digits = 2), ", and those table rows are checked above"),
  "figure_c1_adjusted_series", "Figure C.1", "Covariate-adjusted series, 45 outcomes",
    "Not reproducible, for the same reason as Figure 1",
  "figure_d2_all_outcomes", "Figure D.2", "All outcomes under the alternate measurement strategy",
    "Not reproducible. The alternate measurement strategy uses the full observation window for every district, and the deposited officer file carries only the 212-day rates",
  "figure_e5_calls_and_videos", "Figure E.5", "Case-generating calls for service and videos uploaded per day",
    "Not reproducible. The calls-for-service series is not in the deposit",
  "table_a2_race_and_sex", "Table A.2", "Pretreatment race and sex distribution",
    "Not reproducible. Officer race and sex are not in the deposit",
  "table_a3_length_of_service", "Table A.3", "Pretreatment length of service",
    "Not reproducible. Officer length of service is not in the deposit"
) |>
  mutate(value_script = NA_real_, value_paper = NA_character_, digits = NA_real_,
         value_rewrite = NA_real_, comparison = "==", holds = NA,
         defect_locus = if_else(claim_id == "figure_c1_dim_series", NA_character_, "archive"))

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
    claim_id = paste0("table_c", str_remove(table_figure, "Table C\\."), "_covariate_adjusted"),
    table_figure,
    claim = paste0("Covariate-adjusted estimates, ", outcomes_described),
    value_script = NA_real_, value_paper = NA_character_, digits = NA_real_,
    value_rewrite = NA_real_, comparison = "==", holds = NA,
    defect_locus = "archive",
    notes = "Not reproducible. Every column of this table conditions on officer gender, race and length of service, which the deposit cannot contain without identifying officers. The covariate rows the table prints are the pretreatment outcome, gender, a three-category race variable and length of service, with no block indicators, although the article's Eq. 1 writes the specification with a vector of major-block indicators. The deposit's own README lists a regression_tables_cov.R that would have produced these tables, and that file is not in the deposit"
  )

# Assemble ----

ground_truth <- bind_rows(dim_rows, a1_rows, a4_rows, text_rows, float_rows, ols_tables) |>
  mutate(
    paper_id = paper_id,
    match = agrees(value_script, value_paper, digits, comparison),
    match_rewrite = agrees(value_rewrite, value_paper, digits, comparison),
    notes = replace_na(notes, "")
  ) |>
  # Every adverse Appendix C cell has the same cause, and the sentence naming it
  # is attached to each row it explains rather than retyped 189 times.
  mutate(
    row_adverse = (!is.na(match) & match == 0) | (!is.na(match_rewrite) & match_rewrite == 0) |
      (!is.na(holds) & !holds),
    defect_locus = if_else(row_adverse & str_starts(table_figure, "Table C") &
                             is.na(defect_locus), "archive", defect_locus),
    notes = if_else(row_adverse & str_starts(table_figure, "Table C") & notes == "",
                    district_note, notes)
  ) |>
  select(-row_adverse)

table_order <- c("Table A.1", "Table A.2", "Table A.3", "Table A.4", "Figure 1",
                 paste("Table C.", c(5:37), sep = ""),
                 "Appendix C table notes", "Figure C.1", "Figure D.2", "Figure E.3",
                 "Figure E.4", "Figure E.5",
                 "Text, Abstract", "Text, Significance", "Text, Methods", "Text, Results",
                 "Text, Discussion", "Text, Appendix A", "Text, Appendix A.1",
                 "Text, Appendix A.2", "Text, Appendix A.2.1", "Text, Appendix A.2.3",
                 "Text, Appendix A.2.4", "Text, Appendix E.2")

ground_truth <- ground_truth |>
  arrange(match(table_figure, table_order)) |>
  select(paper_id, claim_id, table_figure, claim, value_script, value_paper, digits,
         match, value_rewrite, match_rewrite, holds, defect_locus, notes)

stopifnot(!any(duplicated(ground_truth$claim_id)),
          all(ground_truth$table_figure %in% table_order))

# The locus rule, in three states ----
# An adverse row must carry a defect_locus, a clean match must not, and a row with
# no verdict may. A gate stated on match_rewrite alone can see neither an archive
# failure the rewrite survives, which is every appendix C regression cell the
# district filter moves, nor a descriptive claim that does not hold.

adverse <- with(ground_truth,
                (!is.na(match) & match == 0) |
                  (!is.na(match_rewrite) & match_rewrite == 0) |
                  (!is.na(holds) & !holds))
clean <- with(ground_truth,
              !adverse & ((!is.na(match_rewrite) & match_rewrite == 1) |
                            (!is.na(holds) & holds)))

if (any(adverse & is.na(ground_truth$defect_locus))) {
  print(ground_truth |> filter(adverse & is.na(defect_locus)) |>
          select(claim_id, value_paper, value_rewrite, match, match_rewrite, holds), n = Inf)
  stop("An adverse row carries no defect_locus.")
}
if (any(clean & !is.na(ground_truth$defect_locus))) {
  print(ground_truth |> filter(clean & !is.na(defect_locus)) |>
          select(claim_id, value_paper, value_rewrite, match, match_rewrite, holds, defect_locus),
        n = Inf)
  stop("A clean match carries a defect_locus.")
}
stopifnot(all(is.na(ground_truth$defect_locus) |
                ground_truth$defect_locus %in%
                c("paper_internal", "archive", "environment", "rewrite", "unresolved")))

# Every pipeline and descriptive claim in the extraction needs a ground-truth row
# as well as a block, and a claim with neither is the coverage failure this stage
# exists to stop.
needs_row <- published_claims |>
  filter(claim_type %in% c("pipeline", "descriptive")) |>
  pull(claim_id)
missing_rows <- setdiff(needs_row, ground_truth$claim_id)
if (length(missing_rows) > 0) {
  print(missing_rows)
  stop("A pipeline or descriptive claim has no row in the ground truth.")
}

# The extraction against the ground truth ----
# Two hand transcriptions of the same pages, and nothing else compares them.

reconcile <- published_claims |>
  filter(!is.na(value_paper)) |>
  select(claim_id, extraction = value_paper) |>
  inner_join(ground_truth |> select(claim_id, transcription = value_paper), by = "claim_id")

stopifnot(nrow(reconcile) == sum(!is.na(published_claims$value_paper) &
                                   published_claims$claim_id %in% ground_truth$claim_id))
if (!all(normalise_printed(reconcile$extraction) ==
           normalise_printed(reconcile$transcription))) {
  print(reconcile |> filter(normalise_printed(extraction) !=
                              normalise_printed(transcription)), n = Inf)
  stop("The extraction and the ground truth disagree about a published value.")
}

# Float coverage ----
# The extraction records how many numbers each published float carries; the ground
# truth records how many of them are covered and how many reproduce. For the
# coefficient plots the count is what the float plots rather than what it prints,
# since they print nothing.

float_of <- c(
  "Table A.1" = "table_a1", "Table A.2" = "table_a2", "Table A.3" = "table_a3",
  "Table A.4" = "table_a4", "Figure 1" = "figure_1", "Figure C.1" = "figure_c1",
  "Figure D.2" = "figure_d2", "Figure E.3" = "figure_e3", "Figure E.4" = "figure_e4",
  "Figure E.5" = "figure_e5",
  setNames(paste0("table_c", 5:37), paste0("Table C.", 5:37))
)

cell_ids <- c(dim_rows$claim_id, a1_rows$claim_id, a4_rows$claim_id)

per_float <- ground_truth |>
  filter(claim_id %in% cell_ids) |>
  summarize(basis = "published cells",
            covered = n(),
            reproduced_by_rewrite = sum(match_rewrite == 1, na.rm = TRUE),
            reproduced_by_archive = sum(match == 1, na.rm = TRUE),
            .by = table_figure) |>
  transmute(float = unname(float_of[table_figure]), basis, covered,
            reproduced_by_rewrite, reproduced_by_archive)

# Figures 1 and C.1 print nothing, so their coverage is the plotted estimates. The
# covariate-adjusted half of each is not reproducible, so only the unadjusted half
# is covered.
figure_floats <- tibble(
  float = c("figure_1", "figure_c1"),
  basis = "plotted estimates, unadjusted series only",
  covered = c(nrow(filter(figure_1, estimator == "Difference-in-means")),
              dim_series_agreement$n_outcomes),
  reproduced_by_rewrite = covered,
  reproduced_by_archive = 0L
)

declared_floats <- published_claims |>
  filter(str_starts(claim_id, "float_")) |>
  transmute(float = str_remove(claim_id, "^float_"),
            published_numbers = if_else(is.na(value_paper), 0L, as.integer(value_paper)))

float_coverage <- declared_floats |>
  left_join(bind_rows(per_float, figure_floats), by = "float") |>
  mutate(basis = replace_na(basis, "no comparable number"),
         across(c(covered, reproduced_by_rewrite, reproduced_by_archive),
                \(x) replace_na(x, 0L))) |>
  arrange(match(float, float_of))

stopifnot(nrow(float_coverage) == nrow(declared_floats),
          all(float_coverage$covered <= float_coverage$published_numbers),
          setequal(float_coverage$float, unname(float_of)))

# The coverage gate ----
# The second instrument is read as a program, not as text: it is run, its output
# is captured, and the printed claim lines are counted. A block that errors, or
# that prints nothing, satisfies a textual gate completely and fails this one. It
# runs in its own environment, because both files necessarily read the same
# outputs and name objects for what they hold.

claims_output <- capture.output(
  source(here::here("maintained", "in_text_claims.R"), local = new.env(), echo = FALSE)
)

printed <- claims_output |>
  str_subset("^CLAIM ") |>
  str_match("^CLAIM ([^ ]+) = (.*?) \\|\\| (.*)$")
printed_claims <- tibble(claim_id = printed[, 2], printed_value = printed[, 3],
                         label = printed[, 4])

required <- published_claims |> filter(needs_block)

missing_blocks <- setdiff(required$claim_id, printed_claims$claim_id)
unknown_blocks <- setdiff(printed_claims$claim_id, published_claims$claim_id)
if (length(missing_blocks) > 0 || length(unknown_blocks) > 0) {
  print(list(missing = missing_blocks, unknown = unknown_blocks))
  stop("in_text_claims.R does not print exactly the claims the extraction requires.")
}
if (nrow(printed_claims) != nrow(required)) {
  print(printed_claims |> count(claim_id) |> filter(n > 1))
  stop("in_text_claims.R printed ", nrow(printed_claims), " claims against ",
       nrow(required), " extraction rows requiring a block.")
}

# Cross-instrument comparison. The two files reach the same claimed number by
# separate paths from the same pipeline outputs; where they disagree, one of them
# is wrong.
cross <- printed_claims |>
  left_join(ground_truth |> select(claim_id, value_rewrite, holds), by = "claim_id") |>
  left_join(published_claims |> select(claim_id, digits, comparison, claim_type),
            by = "claim_id") |>
  mutate(
    expected = pmap_chr(
      list(claim_type, holds, value_rewrite, digits, comparison),
      function(type, holds_value, value, digits, comparison) {
        if (!is.na(comparison) && comparison == "approx") return(NA_character_)
        if (type == "descriptive") return(as.character(holds_value))
        if (is.na(value) || is.na(digits)) return(NA_character_)
        render_at(value, digits)
      }
    ),
    agrees = is.na(expected) | printed_value == expected
  )

if (!all(cross$agrees)) {
  print(cross |> filter(!agrees) |> select(claim_id, printed_value, expected), n = Inf)
  stop("The two instruments disagree about a claimed value.")
}

# Write ----

write_csv(float_coverage, here::here("ground_truth", "float_coverage.csv"))
write_csv(ground_truth, here::here("ground_truth", paste0(paper_id, "_ground_truth.csv")))

print(ground_truth |>
        select(table_figure, claim, value_script, value_paper, match, value_rewrite,
               match_rewrite, holds),
      n = nrow(ground_truth))

print(str_glue(
  "{nrow(ground_truth)} rows. ",
  "Archive: {sum(ground_truth$match == 1, na.rm = TRUE)} match, ",
  "{sum(ground_truth$match == 0, na.rm = TRUE)} fail, ",
  "{sum(is.na(ground_truth$match))} not comparable. ",
  "Rewrite: {sum(ground_truth$match_rewrite == 1, na.rm = TRUE)} match, ",
  "{sum(ground_truth$match_rewrite == 0, na.rm = TRUE)} fail, ",
  "{sum(is.na(ground_truth$match_rewrite))} not comparable."
))
print(ground_truth |> count(holds))
print(ground_truth |> filter(!is.na(defect_locus)) |> count(defect_locus))
print(ground_truth |> filter(adverse) |>
        select(table_figure, claim, value_paper, value_rewrite, holds, defect_locus),
      n = 100, width = 200)
print(str_glue(
  "{nrow(printed_claims)} claims printed by the second instrument against ",
  "{nrow(required)} extraction rows requiring a block; ",
  "{sum(float_coverage$covered)} of {sum(float_coverage$published_numbers)} ",
  "published float numbers covered."
))
