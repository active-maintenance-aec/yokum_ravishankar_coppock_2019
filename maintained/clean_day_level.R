# yokum_ravishankar_coppock_2019/maintained/clean_day_level.R
# Output: output/day_level_district_rates.rds, output/text_measurement_window.csv
# Depends on: original/Replication Data/day_level_anon.csv, helpers.R
# Description: Collapse the 1.7 million row officer-day panel to the district by
#   30-day-period by assignment rates that the two time series figures plot, and
#   record each district's pretreatment and posttreatment measurement window,
#   which is where the Methods section's 212 days comes from.

source(here::here("maintained", "helpers.R"))

# The deposited panel covers the seven patrol districts only, and codes them 1 to
# 7 where the officer file and the published figures write 1D to 7D.
day_level <- read_csv(
  file.path(data_dir, "day_level_anon.csv"),
  col_select = c(ID_anon, district, relative_month, Z, weights, use_of_force_mpd,
                 all_complaints, start_pre, end_pre, start_post, end_post),
  show_col_types = FALSE
)

stopifnot(identical(sort(unique(day_level$district)), as.numeric(1:7)))

# The measurement window ----
# Each district carries the four dates that bound its pretreatment and
# posttreatment measurement periods. The window the Methods section names is the
# number of days between the first and last day of the posttreatment period.
text_measurement_window <- day_level |>
  distinct(district, start_pre, end_pre, start_post, end_post) |>
  mutate(district = paste0(district, "D"),
         pre_window_days = as.numeric(end_pre - start_pre),
         post_window_days = as.numeric(end_post - start_post)) |>
  arrange(start_post)

stopifnot(nrow(text_measurement_window) == 7)

write_csv(text_measurement_window, file.path(out_dir, "text_measurement_window.csv"))

officer_period <- day_level |>
  mutate(district = paste0(district, "D")) |>
  summarize(
    use_of_force = sum(use_of_force_mpd),
    complaints = sum(all_complaints),
    .by = c(district, relative_month, ID_anon, Z, weights)
  )

day_level_district_rates <- officer_period |>
  summarize(
    use_of_force_1000 = weighted.mean(use_of_force, weights) * 1000,
    complaints_1000 = weighted.mean(complaints, weights) * 1000,
    n_officers = n(),
    .by = c(district, relative_month, Z)
  ) |>
  arrange(district, relative_month, Z)

write_rds(day_level_district_rates, file.path(out_dir, "day_level_district_rates.rds"))

print(text_measurement_window)
print(day_level_district_rates)
