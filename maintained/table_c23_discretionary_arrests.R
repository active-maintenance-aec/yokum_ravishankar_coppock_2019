# yokum_ravishankar_coppock_2019/maintained/table_c23_discretionary_arrests.R
# Output: output/table_c23_discretionary_arrests.csv, output/table_c23_discretionary_arrests.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.23, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "disorderly_conduct_1000_rate_post",
  "simple_assault_1000_rate_post",
  "traffic_arrest_1000_rate_post"
)

labels <- c(
  "Disorderly Conduct",
  "Simple Assault",
  "Traffic Violation"
)

table_c23_discretionary_arrests <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c23_discretionary_arrests, "table_c23_discretionary_arrests", "Table C.23: Effects of BWCs on Discretionary Arrests")
