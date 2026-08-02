# yokum_ravishankar_coppock_2019/maintained/text_district_by_district.R
# Output: output/text_district_by_district.csv
# Depends on: clean_officer_level.R output, helpers.R
# Description: The Discussion says that, because cameras were assigned within each
#   of the seven districts, the study is the equivalent of seven mini-experiments,
#   and that small and insignificant effects appear in all seven. The article
#   prints no table for that claim, so this estimates the use of force effect
#   district by district. Assignment probabilities are constant within a district,
#   so the within-district estimate needs no weights.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

text_district_by_district <- officer_level_district |>
  nest(.by = district) |>
  mutate(fit = map(data, function(d) {
    tidy(lm_robust(use_of_force_1000_rate_post ~ Z, data = d)) |> filter(term == "Z")
  })) |>
  select(district, fit) |>
  unnest(fit) |>
  select(district, estimate, std.error, p.value, conf.low, conf.high) |>
  arrange(district)

write_csv(text_district_by_district, file.path(out_dir, "text_district_by_district.csv"))

print(text_district_by_district)
