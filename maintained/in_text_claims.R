# yokum_ravishankar_coppock_2019/maintained/in_text_claims.R
# Output: printed to the console; nothing is written
# Depends on: maintained/output/*, ground_truth/published_claims.csv
# Description: The second instrument. Every quantity the article or its supplement
#   states in a sentence, in a caption or in a table note, rather than inside a
#   typeset table body, is recomputed here from the pipeline's own output, by a
#   path of its own, and printed beside the sentence that states it. It reads the
#   extraction, because a block cannot name the article's own figure without it,
#   and it never reads the ground truth, because agreeing with the comparison
#   would prove nothing.
#
#   Where build_ground_truth.R reaches a quantity through one of the text_*.csv
#   summaries, this file goes back to the table or the cleaned data that summary
#   was built from, and where it reaches one through a table it goes through the
#   summary, so the two derivations are separate. Nothing here refits anything.
#
#   It sources helpers.R for the packages and the output path. helpers.R defines
#   functions and loads no data, so no deposited object reaches this file.
#
#   Each printed line is CLAIM <id> = <value> || <label>. The id on that line is
#   the only link the coverage gate uses.

source(here::here("maintained", "helpers.R"))

options(width = 200)

published_claims <- read_csv(
  here::here("ground_truth", "published_claims.csv"),
  col_types = cols(value_paper = col_character(), .default = col_guess())
)

claim_row <- function(id) {
  row <- published_claims |> filter(.data$claim_id == .env$id)
  stopifnot(nrow(row) == 1)
  row
}

# Signed zero is normalised on this side as well as on the transcription side;
# whichever instrument normalises, both must.
render_at <- function(x, digits) {
  rendered <- sprintf(paste0("%.", digits, "f"), x)
  str_replace(rendered, "^-(0(\\.0+)?)$", "\\1")
}

emit <- function(id, value, label) {
  row <- claim_row(id)
  rendered <- if (is.na(value)) "NA" else render_at(value, row$digits)
  cat("CLAIM ", id, " = ", rendered, " || ", label, "\n", sep = "")
}

emit_holds <- function(id, holds, label) {
  claim_row(id)
  cat("CLAIM ", id, " = ", as.character(holds), " || ", label, "\n", sep = "")
}

# Pipeline output ----

out <- function(f) {
  path <- file.path(out_dir, f)
  has_district <- "district" %in% names(read_csv(path, n_max = 0, show_col_types = FALSE))
  if (has_district) {
    read_csv(path, col_types = cols(district = col_character(), .default = col_guess()))
  } else {
    read_csv(path, show_col_types = FALSE)
  }
}

officer_level <- read_rds(file.path(out_dir, "officer_level_full.rds"))
officer_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))
dv_df <- read_rds(file.path(out_dir, "dv_df.rds"))

a1 <- out("table_a1_random_assignment.csv")
a4 <- out("table_a4_deployment_dates.csv")
window <- out("text_measurement_window.csv")
c5 <- out("table_c5_use_of_force.csv")
c7 <- out("table_c7_nighttime.csv")
c19 <- out("table_c19_complaints.csv")
c23 <- out("table_c23_discretionary_arrests.csv")
c37 <- out("table_c37_compliance.csv")
figure_1 <- out("figure_1_main_outcomes.csv")
figure_c1 <- out("figure_c1_all_outcomes.csv")
figure_e3 <- out("figure_e3_use_of_force_time_series.csv")
figure_e4 <- out("figure_e4_complaints_time_series.csv")
null_check <- out("text_null_results_check.csv")
districts <- out("text_district_by_district.csv")

patrol_blocks <- paste0(1:7, "D")

# The rate the article calls "per 1,000 officers", and the window it is annualised
# over, both recovered from the deposit rather than asserted. An officer's
# posttreatment rate divided by the count behind it is scale * 365.25 / window,
# and the window is the span of the posttreatment measurement period.
window_days <- unique(window$post_window_days)
rate_scale <- officer_district |>
  filter(all_complaints_post > 0) |>
  summarize(scale = round(mean(all_complaints_1000_rate_post / all_complaints_post) *
                            window_days / 365.25)) |>
  pull(scale)

# The confidence level the plotted intervals carry, read off the lower limit.
ci_level <- function(dat) {
  usable <- dat |> filter(estimator == "Difference-in-means", std_error > 0)
  levels <- unique(round(100 * (1 - 2 * pt(-(usable$estimate - usable$conf_low) / usable$std_error,
                                           usable$n - 2))))
  stopifnot(length(levels) == 1)
  levels
}

# The compliance means, computed here from the officer file rather than read out
# of text_compliance_means.csv, which is the path the ground truth takes.
compliance <- officer_district |>
  summarize(videos_per_year = weighted.mean(videos_rate_post, weights),
            average_video_minutes = weighted.mean(length_min_post, weights),
            .by = Z)
compliance_of <- function(z, column) compliance[[column]][compliance$Z == z]

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

no_counterpart <- paste("No counterpart in the deposit: the calls-for-service data behind this",
                        "figure are not deposited, and no other file in the archive records",
                        "video uploads against the incidents that should have generated them")

# Abstract ----

# "To estimate the effects of BWCs, we conducted a randomized controlled trial
#  involving 2,224 Metropolitan Police Department officers in Washington, DC."
emit("abstract_officers_in_trial", nrow(officer_level),
     "Rows in the deposited officer file, one per officer in the trial")

# "Here we show that BWCs have very small and statistically insignificant effects
#  on police use of force and civilian complaints, as well as other policing
#  activities and judicial outcomes."
dim_check <- null_check |> filter(estimator == "Difference-in-means")
emit_holds(
  "abstract_effects_small_insignificant",
  dim_check$n_p_below_0.05 == 0,
  str_glue("{dim_check$n_p_below_0.05} of the {dim_check$n_outcomes} measured outcomes ",
           "clear p < 0.05 and {dim_check$n_p_below_0.10} clear p < 0.10; the smallest ",
           "p-value is {sprintf('%.3f', dim_check$smallest_p_value)} on ",
           "{dim_check$outcome_with_smallest_p}, and {dim_check$n_outcomes_not_estimable} ",
           "outcomes are identically zero throughout and have no p-value"))

# Significance statement ----

# "In a large-scale field experiment (2,224 officers of the Metropolitan Police
#  Department in Washington, DC), we randomly assigned officers to receive cameras
#  or not."
emit("significance_officers_in_trial", nrow(officer_level),
     "Rows in the deposited officer file, restated for the significance statement")

# "We tracked subsequent police behavior for a minimum of 7 mo using
#  administrative data."
emit("significance_tracking_months", window_days / (365.25 / 12),
     str_glue("The posttreatment measurement window is {window_days} days, which is ",
              "{sprintf('%.2f', window_days / (365.25 / 12))} months at 30.44 days a month"))

# Methods ----

# "Specifically, as part of MPD's deployment of BWCs to its police force,
#  approximately half of all full duty patrol and station officers were randomly
#  assigned to wear BWCs, while the other half remained without BWCs."
treated_share <- mean(officer_level$Z == 1)
emit_holds(
  "methods_half_assigned",
  abs(treated_share - 0.5) < 0.05,
  str_glue("{sum(officer_level$Z == 1)} of {nrow(officer_level)} officers were assigned a ",
           "camera, {sprintf('%.1f', 100 * treated_share)} per cent"))

# "With 2,224 MPD members participating in the trial, this study is the largest
#  randomized evaluation of BWCs conducted to date."
emit("methods_officers_in_trial", nrow(officer_level),
     "Rows in the deposited officer file, restated in the Methods section")

# "We identified eligible officers within each of the seven police districts (as
#  well as several specialized units) based on the following criteria."
emit("methods_seven_districts", sum(a1$block %in% patrol_blocks),
     str_glue("Major blocks that are patrol districts: ",
              "{str_flatten_comma(sort(a1$block[a1$block %in% patrol_blocks]))}"))

# "We applied a two-level blocking approach: The 'major' blocks were the seven
#  police districts and three special units, and the minor blocks were constructed
#  using a clustering algorithm based on the background characteristics of the
#  officers."
emit("methods_major_blocks_districts", sum(a1$block %in% patrol_blocks),
     "The seven patrol districts among the twelve major blocks")
special_units <- a1 |>
  filter(!block %in% patrol_blocks, block != "1D Station") |>
  mutate(unit = str_remove(district, "_2$"))
emit("methods_major_blocks_units", n_distinct(special_units$unit),
     str_glue("Distinct special units among the major blocks: ",
              "{str_flatten_comma(sort(unique(special_units$unit)))}"))

# "Based on the eligibility requirements noted above, our sample consisted of
#  2,224 MPD members, with 1,035 members assigned to the control group and 1,189
#  members assigned to the treatment group."
emit("methods_sample_total", nrow(officer_level), "Rows in the deposited officer file")
emit("methods_assigned_control", sum(officer_level$Z == 0), "Officers with Z equal to zero")
emit("methods_assigned_treatment", sum(officer_level$Z == 1), "Officers with Z equal to one")

# "On average, treatment officers uploaded about 665 videos annually (compared
#  with 14 videos uploaded among control officers)."
videos_row <- c37 |> filter(outcome == "Videos per year")
emit("methods_videos_treatment", compliance_of(1, "videos_per_year"),
     paste0("Weighted mean of the posttreatment video rate among officers assigned a camera ",
            "in the seven patrol districts, ",
            sprintf("%.1f", compliance_of(1, "videos_per_year")),
            " videos a year. Table C.37's own constant plus coefficient, ",
            sprintf("%.1f", videos_row$constant + videos_row$estimate),
            ", is the same quantity"))
emit("methods_videos_control", compliance_of(0, "videos_per_year"),
     str_glue("Weighted mean of the posttreatment video rate among control officers, ",
              "{sprintf('%.1f', compliance_of(0, 'videos_per_year'))} videos a year"))

# "The average video recorded by a treatment officer was over 11 min long, while
#  the average video recorded by a control officer was just 0.8 min long."
emit("methods_video_minutes_treatment", compliance_of(1, "average_video_minutes"),
     str_glue("Weighted mean video length among officers assigned a camera, ",
              "{sprintf('%.2f', compliance_of(1, 'average_video_minutes'))} minutes, ",
              "which is over the 11 the sentence names"))
emit("methods_video_minutes_control", compliance_of(0, "average_video_minutes"),
     str_glue("Weighted mean video length among control officers, ",
              "{sprintf('%.3f', compliance_of(0, 'average_video_minutes'))} minutes"))

# "For both manipulation check measures, the treatment assignment is both
#  substantively and statistically significant (p < 0.001)."
emit("methods_manipulation_p", max(c37$p_value),
     str_glue("The larger of Table C.37's two p-values, ",
              "{format(max(c37$p_value), digits = 3)}, on ",
              "{c37$outcome[which.max(c37$p_value)]}"))

# "Due to logistical constraints, MPD deployed cameras on a district-by-district
#  basis over the course of 11 mo."
deployment_span <- as.numeric(max(a4$first_deployment) - min(a4$first_deployment))
emit("methods_deployment_months", deployment_span / (365.25 / 12),
     str_glue("{min(a4$first_deployment)} to {max(a4$first_deployment)} is ",
              "{deployment_span} days, {sprintf('%.1f', deployment_span / (365.25 / 12))} ",
              "months, across the seven patrol districts the deposit covers"))

# "Officers in two of the seven police districts received cameras in late June
#  2015, with the deployment to the remaining districts taking place from March to
#  May 2016."
in_2015 <- a4 |> filter(format(first_deployment, "%Y") == "2015")
emit("methods_pilot_districts_deployed", nrow(in_2015),
     str_glue("Districts whose first deployment falls in 2015: ",
              "{str_flatten_comma(in_2015$district)}, both on {unique(in_2015$first_deployment)}"))
emit("methods_first_deployment_year", as.numeric(format(min(a4$first_deployment), "%Y")),
     str_glue("Calendar year of the earliest deployment, {min(a4$first_deployment)}"))
emit("methods_remaining_deployment_year", as.numeric(format(max(a4$first_deployment), "%Y")),
     str_glue("Calendar year of the latest district deployment, {max(a4$first_deployment)}"))

# "We calculate these rates before and after the intervention based on a window of
#  212 d, because 212 is the number of days between deployment and the end of the
#  study period for the district that was the last to receive cameras."
emit("methods_window_days", window_days,
     str_glue("Days between the first and last day of each district's posttreatment ",
              "period; all seven agree at {window_days}"))
last_district <- window |> slice_max(start_post, n = 1)
emit("methods_window_days_reason", last_district$post_window_days,
     str_glue("{last_district$district} was the last of the seven to receive cameras, on ",
              "{last_district$start_post}, and its posttreatment period ends ",
              "{last_district$end_post}"))

# "the pretreatment measurements come from the same 212-d window (in the previous
#  year) as the posttreatment measurements, to account for seasonality in policing
#  and desensitization to the treatment over time."
emit("methods_window_days_pretreatment", unique(window$pre_window_days),
     str_glue("Days between the first and last day of each district's pretreatment ",
              "period; all seven agree at {unique(window$pre_window_days)}, and each ",
              "pretreatment window opens exactly one year before its posttreatment window"))

# "Because all of our outcomes are unconditional event counts translated into
#  yearly event rates per 1,000 offices, our measurement procedure avoids the
#  posttreatment bias that would be associated with measuring various conditional
#  quantities."
emit("methods_rate_denominator", rate_scale,
     str_glue("An officer's posttreatment complaint rate divided by the count behind it ",
              "is the scale times 365.25 over the {window_days}-day window, which gives ",
              "a scale of {rate_scale}"))

# "We conduct our primary analysis among officers in the seven districts of DC
#  (n = 1,922)."
emit("methods_analysis_sample", nrow(officer_district),
     "Rows in the officer file after cutting to the seven patrol districts")

# "We conduct this analysis at the officer level, and report results as a yearly
#  rate per 1,000 officers."
emit("methods_rate_denominator_restated", rate_scale,
     "The same rate scale, recovered the same way")

# Figure 1 ----

# "Fig. 1. Average difference (with 95% confidence interval) between BWC and
#  non-BWC groups, per 1,000 officers over a year for police use of force,
#  complaints filed against officers, and arrests for disorderly conduct."
emit("figure_1_ci_level", ci_level(figure_1),
     "Confidence level implied by the plotted lower limits and standard errors")
emit("figure_1_rate_denominator", rate_scale, "The same rate scale, recovered the same way")
emit("float_figure_1", nrow(figure_1),
     str_glue("Estimates the rewrite plots on Figure 1: ",
              "{n_distinct(figure_1$outcome)} outcomes by ",
              "{n_distinct(figure_1$estimator)} estimators"))

# Results ----

# "Across each of the four outcome categories, our analyses consistently point to
#  a null result: The average treatment effect estimate on all measured outcomes
#  was very small, and no estimate rose to statistical significance at
#  conventional levels."
emit_holds(
  "results_no_significant_estimate",
  dim_check$n_p_below_0.05 == 0,
  str_glue("Of the {dim_check$n_outcomes} outcomes Figure C.1 plots, ",
           "{dim_check$n_p_below_0.05} clear p < 0.05 and {dim_check$n_p_below_0.10} clear ",
           "p < 0.10 under the difference-in-means estimator"))

# "Fig. 1 plots the estimated average treatment effect (as a yearly rate per 1,000
#  officers) of BWCs on police use of force, civilian complaints, and officer
#  discretion (as measured by arrests for disorderly conduct)."
emit_holds(
  "results_figure_1_reference",
  setequal(figure_1$outcome, c("Use of Force", "Complaints", "Disorderly Conduct")),
  str_glue("The rewrite's Figure 1 carries ",
           "{str_flatten_comma(sort(unique(figure_1$outcome)))}"))
emit("results_rate_denominator", rate_scale, "The same rate scale, recovered the same way")

# "Our best guess is that cameras caused an increase of 74 (SE = 87) uses of force
#  per 1,000 officers, per year. This estimate is not statistically significantly
#  different from zero."
uof <- c5 |> filter(outcome == "Use of Force")
emit("results_uof_estimate", uof$estimate,
     str_glue("Table C.5's use of force coefficient, {sprintf('%.2f', uof$estimate)}"))
emit("results_uof_se", uof$std_error,
     str_glue("Its standard error, {sprintf('%.2f', uof$std_error)}"))
emit("results_uof_rate_denominator", rate_scale, "The same rate scale, recovered the same way")
emit_holds(
  "results_uof_not_significant",
  uof$conf_low < 0 & uof$conf_high > 0,
  str_glue("The 95 per cent interval runs {sprintf('%.1f', uof$conf_low)} to ",
           "{sprintf('%.1f', uof$conf_high)}, at p = {sprintf('%.3f', uof$p_value)}"))

# "The effects on complaints (57 per 1,000 officers per year, SE = 41) and arrests
#  for disorderly conduct (-128 per 1,000 officers per year, SE = 277) were also
#  nonsignificant."
complaints <- c19 |> filter(outcome == "Complaints")
disorderly <- c23 |> filter(outcome == "Disorderly Conduct")
emit("results_complaints_estimate", complaints$estimate,
     str_glue("Table C.19's complaints coefficient, {sprintf('%.2f', complaints$estimate)}"))
emit("results_complaints_se", complaints$std_error,
     str_glue("Its standard error, {sprintf('%.2f', complaints$std_error)}"))
emit("results_complaints_rate_denominator", rate_scale,
     "The same rate scale, recovered the same way")
emit("results_disorderly_estimate", disorderly$estimate,
     str_glue("Table C.23's disorderly conduct coefficient, ",
              "{sprintf('%.2f', disorderly$estimate)}"))
emit("results_disorderly_se", disorderly$std_error,
     str_glue("Its standard error, {sprintf('%.2f', disorderly$std_error)}"))
emit("results_disorderly_rate_denominator", rate_scale,
     "The same rate scale, recovered the same way")
emit_holds(
  "results_others_nonsignificant",
  all(c(complaints$p_value, disorderly$p_value) >= 0.05),
  str_glue("Complaints p = {sprintf('%.3f', complaints$p_value)}, disorderly conduct ",
           "p = {sprintf('%.3f', disorderly$p_value)}"))

# Discussion ----

# "we also note that, as BWCs were randomly assigned within each of the seven
#  police districts, we conducted the equivalent of seven mini-experiments.
#  Despite substantial district-to-district heterogeneity in baseline outcomes, we
#  observe small, insignificant effects in all seven districts."
emit("discussion_seven_districts", n_distinct(districts$district),
     str_glue("Districts the rewrite estimates separately: ",
              "{str_flatten_comma(sort(districts$district))}"))
emit("discussion_seven_mini_experiments", n_distinct(districts$district),
     "The same seven districts, restated as mini-experiments")
emit_holds(
  "discussion_all_seven_insignificant",
  all(districts$p.value >= 0.05),
  str_glue("District use of force effects run ",
           "{sprintf('%.0f', min(districts$estimate))} to ",
           "{sprintf('%.0f', max(districts$estimate))} per 1,000 officers, with p-values ",
           "{str_flatten_comma(sprintf('%.3f', sort(districts$p.value)))}"))

# "Approximately one-third of calls were responded to by control officers only,
#  one-third by treatment officers only, and the last third by a mix of treatment
#  and control officers."
emit_holds("discussion_calls_thirds", NA,
           paste("No counterpart in the deposit: the calls-for-service data are not",
                 "deposited, and the officer file records no call-level responder. What",
                 "the deposit does support is the assignment split itself,",
                 sprintf("%.1f per cent treated", 100 * treated_share)))

# "As a check of whether the introduction of cameras affected both treatment and
#  control officers, we examined time trends for documented uses of force and
#  civilian complaints before and after cameras were deployed (analysis presented
#  in SI Appendix). We observed no differences in precamera versus postcamera
#  outcomes for either group."
pre_post <- figure_e3 |>
  mutate(period = if_else(relative_month < 0, "before", "after")) |>
  summarize(rate = mean(use_of_force_1000), .by = c(Z, period)) |>
  mutate(shown = paste0(Z, " ", period, " ", sprintf("%.1f", rate)))
emit_holds(
  "discussion_no_precamera_difference", NA,
  paste("The deposit ships no test behind Figures E.3 and E.4, and running one here",
        "would be estimation rather than derivation. The unweighted mean of the plotted",
        "uses of force per 1,000 officers is",
        str_flatten_comma(pre_post$shown)))

# "To explore this possibility (we note that this analysis was not preregistered),
#  we examined the effect of treatment on use of force at night, when exposure to
#  nonpolice cameras is lower. We also found no effect of cameras on this
#  alternative dependent variable."
night <- c7 |> filter(outcome == "Use of Force (Night)")
emit_holds(
  "discussion_night_no_effect",
  night$p_value >= 0.05,
  str_glue("Table C.7's night-time use of force effect is ",
           "{sprintf('%.1f', night$estimate)} with a standard error of ",
           "{sprintf('%.1f', night$std_error)}, at p = {sprintf('%.3f', night$p_value)}"))

# "We have no indication that nonadherence was a widespread problem in our
#  experiment. For 98% of the days in 2016, MPD averaged at least one video (and
#  often many more) per call for service associated with a treatment officer.
#  Further, even for the 2% of days in 2016 in which the number of videos uploaded
#  was less than the number of incidents for which we would expect them, the
#  difference is minimal, with 96% average adherence based on our measure."
emit("discussion_adherence_days", NA, no_counterpart)
emit("discussion_shortfall_days", NA, no_counterpart)
emit("discussion_average_adherence", NA, no_counterpart)

# Appendix A ----

# "Finally, to determine the appropriate design of the study (e.g., level of
#  randomization, length of study period), we conducted a pilot study in two of
#  the seven MPD police districts. In June 2015, eligible officers in these two
#  districts were randomly assigned to receive a BWC or not: 325 officers were
#  outfitted with BWCs, while 180 were not given cameras (the 'control' group)."
pilot <- a1 |> filter(block %in% c("5D", "7D"))
emit("appendix_pilot_districts", nrow(pilot),
     str_glue("Blocks that were the pilot: {str_flatten_comma(pilot$block)}"))
emit("appendix_pilot_bwc", sum(pilot$bwc),
     str_glue("Table A.1's camera counts in the two pilot districts, ",
              "{str_flatten_comma(pilot$bwc)}"))
emit("appendix_pilot_control", sum(pilot$control),
     str_glue("Table A.1's control counts in the two pilot districts, ",
              "{str_flatten_comma(pilot$control)}, which is {sum(pilot$control)} and not ",
              "the 180 the sentence gives"))

# "The major blocks are the seven districts, and three special units (NSID, SOD,
#  and School Security Division [SSD])."
emit("appendix_major_blocks_districts", sum(a1$block %in% patrol_blocks),
     "The seven patrol districts among the twelve major blocks, restated")
emit("appendix_major_blocks_units", n_distinct(special_units$unit),
     "Distinct special units among the major blocks, restated")

# "We grouped officers into matched pairs so that within each pair, officers were
#  maximally similar to each other according to these characteristics."
block_sizes <- officer_level |>
  filter(!district %in% c("5D", "7D")) |>
  count(district_block_id) |>
  count(n, name = "blocks") |>
  mutate(shown = paste0(n, " officers (", blocks, " blocks)"))
modal_size <- block_sizes$n[which.max(block_sizes$blocks)]
emit_holds(
  "appendix_matched_pairs",
  modal_size == 2,
  paste("Outside the two pilot districts, which were assigned by complete random",
        "assignment, the deposited minor blocks come in sizes",
        str_flatten_comma(block_sizes$shown)))

# "In the first Narcotics and Special Investigations Division (NSID) subgroup of
#  officers to be randomly assigned BWCs, we were requested to assign cameras to
#  more than 50% of the officers."
nsid_a <- a1 |> filter(block == "NSIDa")
emit_holds(
  "appendix_nsid_probability",
  100 * nsid_a$probability_of_assignment > 50,
  str_glue("NSIDa assigned {nsid_a$bwc} of {nsid_a$bwc + nsid_a$control} officers a camera, ",
           "{sprintf('%.1f', 100 * nsid_a$probability_of_assignment)} per cent"))

# "Officers assigned to the station in district 1D (1D-station) were assigned
#  separately from other officers in 1D. Random assignment of BWCs to NSID were
#  completed in two separate rounds. This makes a total of 12 major blocks in our
#  randomization strategy."
emit("appendix_total_major_blocks", nrow(a1),
     str_glue("Distinct major blocks in the deposited officer file: ",
              "{str_flatten_comma(a1$block)}"))
emit("appendix_nsid_rounds", sum(str_starts(special_units$district, "NSID")),
     str_glue("Major blocks whose unit is NSID: ",
              "{str_flatten_comma(special_units$block[str_starts(special_units$district, 'NSID')])}"))

# "The general order enumerates the range of events for which officers were
#  required to activate their BWCs; this list is included in Appendix F."
emit_holds(
  "appendix_appendix_f_reference",
  "F" == section_of("MPD General Order SPT-302.13"),
  str_glue("The general order is supplement section ",
           "{section_of('MPD General Order SPT-302.13')}"))

# "In addition to the primary specification described in the main text, we use all
#  available data for all districts to calculate the yearly rate per 1000 officers
#  for each of the measured outcomes."
emit("appendix_a1_rate_denominator", rate_scale, "The same rate scale, recovered the same way")

# "The coefficient plots for each of the outcomes using this alternate measurement
#  strategy are provided in Section 4."
emit_holds(
  "appendix_alternate_section_reference",
  "4" == section_of("Application of Alternate Measurement Strategy"),
  str_glue("The supplement's sections are lettered ",
           "{str_flatten_comma(appendix_contents$letter)} and it has no Section 4. The ",
           "alternate measurement plots are in section ",
           "{section_of('Application of Alternate Measurement Strategy')}"))

# "Regardless of which measurement strategy we apply, our findings remain the
#  same: we are unable to detect any statistically significant effects of BWCs on
#  the measured outcomes."
alternate_note <- paste("No counterpart in the deposit: the alternate strategy uses each",
                        "district's full observation window and the deposited officer file",
                        sprintf("carries only the %d-day rates.", window_days),
                        "What the deposit does support is the primary specification, where",
                        sprintf("%d of %d outcomes clear p < 0.05.", dim_check$n_p_below_0.05,
                                dim_check$n_outcomes))
emit_holds("appendix_alternate_no_significant", NA, alternate_note)

# "In addition to comparing all uses of force across the control and treatment
#  groups, we also differentiate between serious uses of force and other uses of
#  force, as defined by MPD policy. We look at these two measures separately."
emit("appendix_two_uof_measures",
     sum(dv_df$dv_name %in% c("use_of_force_serious", "use_of_force_less_serious")),
     "Severity variants of the overall use of force outcome in the deposited index")

# "Based on this demographic distribution, we examined use of force across the
#  following race categories: White, Black/African American, Hispanic, and
#  Other/Unknown."
named_races <- c("white", "black", "hispanic", "other")
present <- map_lgl(named_races, \(r) any(str_detect(dv_df$dv_name, paste0("use_of_force_", r))))
missing_races <- if (all(present)) "none" else str_flatten_comma(named_races[!present])
emit_holds(
  "appendix_race_categories",
  all(present),
  paste0("Use of force outcomes exist for ", str_flatten_comma(named_races[present]),
         "; missing: ", missing_races,
         ". The deposited index also carries a nonblack aggregate the sentence does not name"))

# "Per our interviews with MPD officials, officers exercise greater discretion to
#  make arrests on charges in the following subset of offense categories:
#  Disorderly Conduct, Simple Assault, Traffic Violations."
discretionary <- dv_df |>
  filter(dv_name %in% c("disorderly_conduct", "simple_assault", "traffic_arrest"))
emit("appendix_discretionary_categories", nrow(discretionary),
     str_glue("Discretionary arrest outcomes in the deposited index: ",
              "{str_flatten_comma(discretionary$dv_label)}"))

# "We divided prosecutions into four categories, each of which serves as a
#  separate dependent variable."
dispositions <- dv_df |>
  filter(dv_category == unique(dv_df$dv_category[dv_df$dv_name == "charge_prosecuted"]),
         dv_name != "charge_prosecuted")
emit("appendix_prosecution_categories", nrow(dispositions),
     str_glue("Judicial outcomes other than the parent Prosecuted measure: ",
              "{str_flatten_comma(dispositions$dv_label)}"))

# Appendix C ----

# "We display estimates with 95% confidence intervals from both the
#  difference-in-means and OLS estimators. As the plots indicate, we find no
#  discernible effect of BWCs on any of the measured outcomes."
emit("figure_c1_ci_level", ci_level(figure_c1),
     "Confidence level implied by the plotted lower limits and standard errors")
emit_holds(
  "figure_c1_no_discernible_effect",
  all(null_check$n_p_below_0.05 == 0),
  str_glue("Across both estimators the rewrite draws, ",
           "{sum(null_check$n_p_below_0.05)} of {sum(null_check$n_outcomes)} plotted ",
           "estimates clear p < 0.05. The published covariate-adjusted series is not the ",
           "one drawn here, because officer gender, race and length of service are not in ",
           "the deposit"))
emit("float_figure_c1", nrow(figure_c1),
     str_glue("Estimates the rewrite plots on Figure C.1: ",
              "{n_distinct(figure_c1$outcome)} outcomes by ",
              "{n_distinct(figure_c1$estimator)} estimators"))

# "Outcomes are yearly event rates per 1000 officers." (the note printed beneath
#  Tables C.5 to C.30)
emit("table_c_note_rate_denominator", rate_scale, "The same rate scale, recovered the same way")

# "Table C.37 presents the results of our manipulation check. If officers complied
#  with the randomization protocol, we would expect that officers assigned BWCs
#  would make vastly more videos per year, as well as have a longer average length
#  of videos. We find this to be true, and conclude that MPD officers adhered to
#  the randomization protocol."
emit_holds(
  "appendix_c37_manipulation_holds",
  all(c37$estimate > 0) && all(c37$p_value < 0.001),
  str_glue("Table C.37's two effects are ",
           "{str_flatten_comma(sprintf('%.1f', c37$estimate))}, both positive, at p-values ",
           "of {str_flatten_comma(format(c37$p_value, digits = 2))}"))

# Appendix D ----

# "Regardless of which measurement strategy we apply, our findings remain the
#  same: we are unable to detect any statistically significant effect of BWCs on
#  the measured outcomes." (Figure D.2's caption)
emit_holds("figure_d2_no_significant", NA, alternate_note)

# Appendix E ----

# "Figure E.3: Uses of Force per 1000 Officers, 90 days before and after BWC
#  deployment, broken out by police district. ... As the chart indicates, there is
#  no statistically significant difference between the two groups in either the
#  90-day period before or after the deployment of BWCs (which occurs on day 0)."
e3_span <- range(figure_e3$relative_month)
emit_holds(
  "figure_e3_window",
  e3_span[1] == -90 && e3_span[2] == 90,
  str_glue("The deposited panel behind Figure E.3 runs from {e3_span[1]} to {e3_span[2]} ",
           "days since deployment, in {n_distinct(figure_e3$relative_month)} periods of ",
           "30 days, and the published axis is broken at -750 through 500"))
e3_by_arm <- figure_e3 |>
  summarize(rate = mean(use_of_force_1000), .by = Z) |>
  mutate(shown = paste0(Z, " ", sprintf("%.1f", rate)))
emit_holds(
  "figure_e3_no_difference", NA,
  paste("The deposit ships no test behind this caption. Over the whole plotted window",
        "the unweighted mean is", str_flatten_comma(e3_by_arm$shown),
        "uses of force per 1,000 officers"))
emit("figure_e3_day_zero", min(figure_e3$relative_month[figure_e3$relative_month >= 0]),
     "The first non-negative period label in the deposited panel, which is deployment day")
emit("figure_e3_rate_denominator", rate_scale, "The same rate scale, recovered the same way")
emit("float_figure_e3", nrow(figure_e3),
     str_glue("Points the rewrite plots on Figure E.3: ",
              "{n_distinct(figure_e3$district)} districts by ",
              "{n_distinct(figure_e3$relative_month)} periods by ",
              "{n_distinct(figure_e3$Z)} assignment arms"))

# "Figure E.4: Complaints per 1000 Officers, 90 days before and after BWC
#  deployment, broken out by police district. ... there is no statistically
#  significant difference between the two groups in either the 90-day period
#  before or after the deployment of BWCs (which occurs on day 0)."
e4_span <- range(figure_e4$relative_month)
emit_holds(
  "figure_e4_window",
  e4_span[1] == -90 && e4_span[2] == 90,
  str_glue("The deposited panel behind Figure E.4 runs from {e4_span[1]} to {e4_span[2]} ",
           "days since deployment, in {n_distinct(figure_e4$relative_month)} periods of ",
           "30 days, and the published axis is broken at -750 through 500"))
e4_by_arm <- figure_e4 |>
  summarize(rate = mean(complaints_1000), .by = Z) |>
  mutate(shown = paste0(Z, " ", sprintf("%.1f", rate)))
emit_holds(
  "figure_e4_no_difference", NA,
  paste("The deposit ships no test behind this caption. Over the whole plotted window",
        "the unweighted mean is", str_flatten_comma(e4_by_arm$shown),
        "complaints per 1,000 officers"))
emit("figure_e4_day_zero", min(figure_e4$relative_month[figure_e4$relative_month >= 0]),
     "The first non-negative period label in the deposited panel, which is deployment day")
emit("figure_e4_rate_denominator", rate_scale, "The same rate scale, recovered the same way")
emit("float_figure_e4", nrow(figure_e4),
     str_glue("Points the rewrite plots on Figure E.4: ",
              "{n_distinct(figure_e4$district)} districts by ",
              "{n_distinct(figure_e4$relative_month)} periods by ",
              "{n_distinct(figure_e4$Z)} assignment arms"))

# "For 98% of the days in 2016, MPD is averaging at least one video (often many
#  more) per call for service with CCN that had a treated officer on scene.
#  Further, even for the 2% of days in 2016 in which the number of videos is less
#  than the number of incidents for which we would expect them, the difference is
#  minimal, with 96% average compliance based on our measure."
emit("appendix_adherence_days", NA, no_counterpart)
emit("appendix_shortfall_days", NA, no_counterpart)
emit("appendix_average_compliance", NA, no_counterpart)
