# yokum_ravishankar_coppock_2019/maintained/text_sample_and_compliance.R
# Output: output/text_sample_sizes.csv, output/text_compliance_means.csv
# Depends on: clean_officer_level.R output, helpers.R
# Description: The sample counts the Methods section gives, and the average number
#   and length of videos by assignment that the compliance paragraph gives. Both
#   are reported for the full trial and for the seven-district analysis sample,
#   because the article does not say which of the two the compliance means use.

source(here::here("maintained", "helpers.R"))

officer_level <- read_rds(file.path(out_dir, "officer_level_full.rds"))
officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))

text_sample_sizes <- tibble(
  quantity = c("Officers in the trial", "Assigned to control", "Assigned to a camera",
               "Officers in the seven patrol districts"),
  value = c(nrow(officer_level), sum(officer_level$Z == 0), sum(officer_level$Z == 1),
            nrow(officer_level_district))
)

write_csv(text_sample_sizes, file.path(out_dir, "text_sample_sizes.csv"))

compliance_means <- function(data, sample_label) {
  data |>
    summarize(
      videos_per_year = weighted.mean(videos_rate_post, weights),
      average_video_minutes = weighted.mean(length_min_post, weights),
      n = n(),
      .by = Z
    ) |>
    mutate(sample = sample_label,
           assignment = if_else(Z == 1, "Officer assigned BWC", "Control")) |>
    select(sample, assignment, n, videos_per_year, average_video_minutes)
}

text_compliance_means <- bind_rows(
  compliance_means(officer_level_district, "Seven patrol districts"),
  compliance_means(officer_level, "All officers in the trial")
) |>
  arrange(sample, assignment)

write_csv(text_compliance_means, file.path(out_dir, "text_compliance_means.csv"))

print(text_sample_sizes)
print(text_compliance_means)
