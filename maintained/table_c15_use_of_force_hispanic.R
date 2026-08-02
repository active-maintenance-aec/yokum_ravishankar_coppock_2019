# yokum_ravishankar_coppock_2019/maintained/table_c15_use_of_force_hispanic.R
# Output: output/table_c15_use_of_force_hispanic.csv, output/table_c15_use_of_force_hispanic.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.15, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "use_of_force_hispanic_1000_rate_post",
  "use_of_force_serious_hispanic_1000_rate_post",
  "use_of_force_less_serious_hispanic_1000_rate_post"
)

labels <- c(
  "Use of Force",
  "Use of Force (Serious)",
  "Use of Force (Other)"
)

table_c15_use_of_force_hispanic <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c15_use_of_force_hispanic, "table_c15_use_of_force_hispanic", "Table C.15: Effects of BWCs on Use of Force Outcomes (Hispanic Civilians)")
