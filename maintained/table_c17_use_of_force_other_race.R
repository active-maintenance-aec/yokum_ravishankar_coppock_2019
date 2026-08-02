# yokum_ravishankar_coppock_2019/maintained/table_c17_use_of_force_other_race.R
# Output: output/table_c17_use_of_force_other_race.csv, output/table_c17_use_of_force_other_race.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.17, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "use_of_force_other_1000_rate_post",
  "use_of_force_serious_other_1000_rate_post",
  "use_of_force_less_serious_other_1000_rate_post"
)

labels <- c(
  "Use of Force",
  "Use of Force (Serious)",
  "Use of Force (Other)"
)

table_c17_use_of_force_other_race <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c17_use_of_force_other_race, "table_c17_use_of_force_other_race", "Table C.17: Effects of BWCs on Use of Force Outcomes (Other Race Civilians)")
