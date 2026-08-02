# yokum_ravishankar_coppock_2019/maintained/table_c13_use_of_force_white.R
# Output: output/table_c13_use_of_force_white.csv, output/table_c13_use_of_force_white.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.13, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "use_of_force_white_1000_rate_post",
  "use_of_force_serious_white_1000_rate_post",
  "use_of_force_less_serious_white_1000_rate_post"
)

labels <- c(
  "Use of Force",
  "Use of Force (Serious)",
  "Use of Force (Other)"
)

table_c13_use_of_force_white <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c13_use_of_force_white, "table_c13_use_of_force_white", "Table C.13: Effects of BWCs on Use of Force Outcomes (White Civilians)")
