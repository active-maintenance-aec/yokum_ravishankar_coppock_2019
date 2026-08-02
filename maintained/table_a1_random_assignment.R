# yokum_ravishankar_coppock_2019/maintained/table_a1_random_assignment.R
# Output: output/table_a1_random_assignment.csv, output/table_a1_random_assignment.tex
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Table A.1, the number of officers assigned to control and to
#   a camera in each of the twelve major blocks, with the probability of assignment.
#   The table's fourth column lists the covariates used to build the minor blocks;
#   those covariates are not in the deposit, so the column is not reproduced here.

source(here::here("maintained", "helpers.R"))

officer_level <- read_rds(file.path(out_dir, "officer_level_full.rds"))

block_labels <- c(
  "1D" = "1D",
  "1Ds" = "1D Station",
  "2D" = "2D",
  "3D" = "3D",
  "4D" = "4D",
  "5D" = "5D",
  "6D" = "6D",
  "7D" = "7D",
  "NSID" = "NSIDa",
  "NSID_2" = "NSIDb",
  "SOD" = "SOD",
  "SSD" = "School Security"
)

table_a1_random_assignment <- officer_level |>
  summarize(
    control = sum(Z == 0),
    bwc = sum(Z == 1),
    probability_of_assignment = mean(prob_1),
    .by = district
  ) |>
  mutate(block = unname(block_labels[district])) |>
  arrange(match(district, names(block_labels))) |>
  select(block, district, control, bwc, probability_of_assignment)

write_csv(table_a1_random_assignment, file.path(out_dir, "table_a1_random_assignment.csv"))

display <- table_a1_random_assignment |>
  transmute(
    `District/Unit` = block,
    Control = control,
    BWC = bwc,
    `Probability of Assignment` = formatC(probability_of_assignment, format = "f", digits = 3)
  )

kable(display, format = "latex", booktabs = TRUE,
      caption = "Table A.1: Summary of Random Assignment Results") |>
  write_lines(file.path(out_dir, "table_a1_random_assignment.tex"))

print(table_a1_random_assignment)
