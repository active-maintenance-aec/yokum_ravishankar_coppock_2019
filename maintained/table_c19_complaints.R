# yokum_ravishankar_coppock_2019/maintained/table_c19_complaints.R
# Output: output/table_c19_complaints.csv, output/table_c19_complaints.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.19, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.
#   The fourth column's label reproduces the appendix spelling.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "all_complaints_1000_rate_post",
  "all_complaints_sustained_1000_rate_post",
  "all_complaints_not_sustained_1000_rate_post",
  "all_complaints_insufficient_facts_1000_rate_post"
)

labels <- c(
  "Complaints",
  "Complaints (Sustained)",
  "Complaints (Not Sustained)",
  "Compliants (Insufficient Facts)"
)

table_c19_complaints <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c19_complaints, "table_c19_complaints", "Table C.19: Effects of BWCs on Complaints")
