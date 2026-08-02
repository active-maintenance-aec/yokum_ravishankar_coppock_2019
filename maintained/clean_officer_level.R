# yokum_ravishankar_coppock_2019/maintained/clean_officer_level.R
# Output: output/officer_level_full.rds, output/officer_level_district.rds,
#   output/dv_df.rds
# Depends on: original/Replication Data/officer_level_anon.csv,
#   original/Replication Data/BWC_dv_df.rdata, helpers.R
# Description: Read the deposited officer file, cut it to the seven patrol
#   districts the paper analyses, and save both versions plus the outcome index.

source(here::here("maintained", "helpers.R"))

officer_level <- read_csv(file.path(data_dir, "officer_level_anon.csv"), show_col_types = FALSE)

# dv_df: 45 outcomes with their labels, families, and the names of the
# pretreatment and posttreatment columns that carry them.
load(file.path(data_dir, "BWC_dv_df.rdata"))

officer_level_district <- officer_level |>
  filter(district %in% main_districts)

stopifnot(nrow(officer_level) == 2224, nrow(officer_level_district) == 1922, nrow(dv_df) == 45)

write_rds(officer_level, file.path(out_dir, "officer_level_full.rds"))
write_rds(officer_level_district, file.path(out_dir, "officer_level_district.rds"))
write_rds(as_tibble(dv_df), file.path(out_dir, "dv_df.rds"))

print(count(officer_level, district, Z))
