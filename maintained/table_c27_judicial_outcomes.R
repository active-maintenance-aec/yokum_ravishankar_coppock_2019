# yokum_ravishankar_coppock_2019/maintained/table_c27_judicial_outcomes.R
# Output: output/table_c27_judicial_outcomes.csv, output/table_c27_judicial_outcomes.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.27, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "charge_prosecuted_1000_rate_post",
  "trial_guilty_1000_rate_post",
  "trial_not_guilty_1000_rate_post",
  "not_trial_guilty_1000_rate_post",
  "not_trial_not_guilty_1000_rate_post"
)

labels <- c(
  "Prosecuted",
  "Found Guilty",
  "Not Found Guilty",
  "Entered Plea",
  "Not Pursued"
)

table_c27_judicial_outcomes <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c27_judicial_outcomes, "table_c27_judicial_outcomes", "Table C.27: Effects of BWCs on Judicial Outcomes")
