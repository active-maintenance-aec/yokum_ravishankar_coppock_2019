# yokum_ravishankar_coppock_2019/run_all.R
# Runs the whole reproduction in order: fetch and verify the deposited archive,
# clean the two data files, then every published table, every published figure, the
# in-text quantities, and finally the ground truth table. Every script is
# self-contained and can also be run on its own.

library(here)
here::i_am("run_all.R")

# Deposited archive ----
# Downloads from OSF on a fresh clone; verifies checksums either way.
source(here::here("download_original.R"))

# Cleaning ----
source(here::here("maintained", "clean_officer_level.R"))
source(here::here("maintained", "clean_day_level.R"))

# Appendix tables ----
source(here::here("maintained", "table_a1_random_assignment.R"))
source(here::here("maintained", "table_a4_deployment_dates.R"))
source(here::here("maintained", "table_c5_use_of_force.R"))
source(here::here("maintained", "table_c7_nighttime.R"))
source(here::here("maintained", "table_c9_use_of_force_black.R"))
source(here::here("maintained", "table_c11_use_of_force_nonblack.R"))
source(here::here("maintained", "table_c13_use_of_force_white.R"))
source(here::here("maintained", "table_c15_use_of_force_hispanic.R"))
source(here::here("maintained", "table_c17_use_of_force_other_race.R"))
source(here::here("maintained", "table_c19_complaints.R"))
source(here::here("maintained", "table_c21_assaults_on_police.R"))
source(here::here("maintained", "table_c23_discretionary_arrests.R"))
source(here::here("maintained", "table_c25_domestic_violence.R"))
source(here::here("maintained", "table_c27_judicial_outcomes.R"))
source(here::here("maintained", "table_c29_court_appearances.R"))
source(here::here("maintained", "table_c31_clinic_visits.R"))
source(here::here("maintained", "table_c33_tickets.R"))
source(here::here("maintained", "table_c35_warnings.R"))
source(here::here("maintained", "table_c37_compliance.R"))

# Figures ----
source(here::here("maintained", "figure_1_main_outcomes.R"))
source(here::here("maintained", "figure_c1_all_outcomes.R"))
source(here::here("maintained", "figure_e3_use_of_force_time_series.R"))
source(here::here("maintained", "figure_e4_complaints_time_series.R"))

# In-text quantities ----
source(here::here("maintained", "text_main_estimates.R"))
source(here::here("maintained", "text_sample_and_compliance.R"))
source(here::here("maintained", "text_null_results_check.R"))
source(here::here("maintained", "text_district_by_district.R"))

# Archive reproducibility check ----
# Runs the deposited specification on the whole trial, as the deposited script does,
# so the ground truth's value_script column has a file behind it.
source(here::here("ground_truth", "archive_estimates.R"))

# Figure timestamps ----
# R's pdf() device stamps a wall-clock /CreationDate and /ModDate into every figure it
# writes, and those two fields are the only reason two runs of this pipeline produce
# differing files. Blanking them lets the determinism check cover every file the
# pipeline writes rather than all but the figures.
source(here::here("maintained", "helpers.R"))
walk(
  list.files(here::here("maintained", "output"), pattern = "\\.pdf$", full.names = TRUE),
  blank_pdf_timestamps
)

# Ground truth ----
# Rebuilt from the outputs above, so it cannot go stale.
source(here::here("ground_truth", "build_ground_truth.R"))

# Deposited archive, again ----
# The check at the top of this file is a precondition: it says original/ was intact
# before anything ran. Nothing above writes to original/, and this second pass is what
# demonstrates it rather than assuming it. Nothing is downloaded; the files are already
# present and are re-checked against the manifest on checksum, byte size and membership.
source(here::here("download_original.R"))
