# yokum_ravishankar_coppock_2019/maintained/table_c21_assaults_on_police.R
# Output: output/table_c21_assaults_on_police.csv, output/table_c21_assaults_on_police.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.21, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "assault_on_po_1000_rate_post",
  "felony_assault_on_po_1000_rate_post",
  "msd_assault_on_po_1000_rate_post"
)

labels <- c(
  "Assault on PO",
  "Felony APO",
  "Misdemeanor APO"
)

table_c21_assaults_on_police <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c21_assaults_on_police, "table_c21_assaults_on_police", "Table C.21: Effects of BWCs on Assaults on Police Officers")
