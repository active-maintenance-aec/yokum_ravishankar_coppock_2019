# yokum_ravishankar_coppock_2019/maintained/table_c31_clinic_visits.R
# Output: output/table_c31_clinic_visits.csv, output/table_c31_clinic_visits.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.31, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "clinic_1000_rate_post"
)

labels <- c(
  "Clinic Visits"
)

table_c31_clinic_visits <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c31_clinic_visits, "table_c31_clinic_visits", "Table C.31: Effects of BWCs on Clinic Visits")
