# yokum_ravishankar_coppock_2019/maintained/table_c7_nighttime.R
# Output: output/table_c7_nighttime.csv, output/table_c7_nighttime.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.7, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "use_of_force_night_1000_rate_post",
  "all_complaints_night_1000_rate_post"
)

labels <- c(
  "Use of Force (Night)",
  "Complaints (Night)"
)

table_c7_nighttime <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c7_nighttime, "table_c7_nighttime", "Table C.7: Effects of BWCs on Use of Force Outcomes (Night)")
