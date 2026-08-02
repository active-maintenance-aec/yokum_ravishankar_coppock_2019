# yokum_ravishankar_coppock_2019/maintained/table_c25_domestic_violence.R
# Output: output/table_c25_domestic_violence.csv, output/table_c25_domestic_violence.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.25, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "dv_report_taken_1000_rate_post",
  "dv_report_taken_family_1000_rate_post",
  "dv_report_taken_not_family_1000_rate_post",
  "dv_calls_1000_rate_post",
  "dv_arrests_1000_rate_post"
)

labels <- c(
  "DV Report Taken",
  "DV Report Taken (Family)",
  "DV Report Taken (Not Family)",
  "DV Calls",
  "DV Arrests"
)

table_c25_domestic_violence <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c25_domestic_violence, "table_c25_domestic_violence", "Table C.25: Effects of BWCs on Domestic Violence Outcomes")
