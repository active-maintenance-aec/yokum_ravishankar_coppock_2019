# yokum_ravishankar_coppock_2019/maintained/table_a4_deployment_dates.R
# Output: output/table_a4_deployment_dates.csv, output/table_a4_deployment_dates.tex
# Depends on: original/Replication Data/day_level_anon.csv, helpers.R
# Description: Appendix Table A.4, the date cameras were first deployed in each
#   district. The deposited officer-day panel carries the deployment date as the
#   first day of each district's posttreatment window. It covers the seven patrol
#   districts only, so the table's three special-unit rows have no source here.

source(here::here("maintained", "helpers.R"))

deployment <- read_csv(
  file.path(data_dir, "day_level_anon.csv"),
  col_select = c(district, start_post),
  show_col_types = FALSE
)

table_a4_deployment_dates <- deployment |>
  distinct(district, start_post) |>
  mutate(district = paste0(district, "D"),
         date_yyyymmdd = as.integer(format(start_post, "%Y%m%d"))) |>
  arrange(start_post) |>
  select(district, first_deployment = start_post, date_yyyymmdd)

stopifnot(nrow(table_a4_deployment_dates) == 7)

write_csv(table_a4_deployment_dates, file.path(out_dir, "table_a4_deployment_dates.csv"))

kable(table_a4_deployment_dates |> select(District = district, `First BWC Deployment` = first_deployment),
      format = "latex", booktabs = TRUE,
      caption = "Table A.4: District and Date of First BWC Deployment") |>
  write_lines(file.path(out_dir, "table_a4_deployment_dates.tex"))

print(table_a4_deployment_dates)
