# yokum_ravishankar_coppock_2019/maintained/table_c29_court_appearances.R
# Output: output/table_c29_court_appearances.csv, output/table_c29_court_appearances.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.29, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "court_appearances_1000_rate_post",
  "court_hours_1000_rate_post"
)

labels <- c(
  "Court Appearances",
  "Hours in Court"
)

table_c29_court_appearances <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c29_court_appearances, "table_c29_court_appearances", "Table C.29: Effects of BWCs on Court Appearances")
