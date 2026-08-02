# yokum_ravishankar_coppock_2019/maintained/table_c9_use_of_force_black.R
# Output: output/table_c9_use_of_force_black.csv, output/table_c9_use_of_force_black.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.9, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "use_of_force_black_1000_rate_post",
  "use_of_force_serious_black_1000_rate_post",
  "use_of_force_less_serious_black_1000_rate_post"
)

labels <- c(
  "Use of Force",
  "Use of Force (Serious)",
  "Use of Force (Other)"
)

table_c9_use_of_force_black <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c9_use_of_force_black, "table_c9_use_of_force_black", "Table C.9: Effects of BWCs on Use of Force Outcomes (Black Civilians)")
