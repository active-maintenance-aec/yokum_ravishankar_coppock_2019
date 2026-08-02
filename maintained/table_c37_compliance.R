# yokum_ravishankar_coppock_2019/maintained/table_c37_compliance.R
# Output: output/table_c37_compliance.csv, output/table_c37_compliance.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.37, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.
#   The two compliance outcomes are counts and minutes per officer per year,
#   not rates per 1,000 officers, which is why the appendix note on this table
#   drops the rate line.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "videos_rate_post",
  "length_min_post"
)

labels <- c(
  "Videos per year",
  "Average length of videos in minutes"
)

table_c37_compliance <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c37_compliance, "table_c37_compliance", "Table C.37: Effects of BWCs on Compliance Outcomes")
