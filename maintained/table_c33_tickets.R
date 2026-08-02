# yokum_ravishankar_coppock_2019/maintained/table_c33_tickets.R
# Output: output/table_c33_tickets.csv, output/table_c33_tickets.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table C.33, the difference-in-means estimates with inverse
#   probability weights on the seven-district sample.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

outcomes <- c(
  "tickets_1000_rate_post"
)

labels <- c(
  "Tickets"
)

table_c33_tickets <- fit_dim_ipw_hc2(outcomes, labels, officer_level_district)

write_dim_table(table_c33_tickets, "table_c33_tickets", "Table C.33: Effects of BWCs on Tickets")
