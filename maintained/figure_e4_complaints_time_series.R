# yokum_ravishankar_coppock_2019/maintained/figure_e4_complaints_time_series.R
# Output: output/figure_e4_complaints_time_series.csv,
#   output/figure_e4_complaints_time_series.pdf,
#   output/figure_e4_complaints_time_series.png
# Depends on: clean_day_level.R output, helpers.R
# Description: Appendix Figure E.4, complaints per 1,000 officers by 30-day period,
#   control against camera, one panel per patrol district.

source(here::here("maintained", "helpers.R"))

day_level_district_rates <- read_rds(file.path(out_dir, "day_level_district_rates.rds"))

figure_e4_complaints_time_series <- day_level_district_rates |>
  select(district, relative_month, Z, complaints_1000, n_officers)

write_csv(figure_e4_complaints_time_series,
          file.path(out_dir, "figure_e4_complaints_time_series.csv"))

series_colors <- c(Control = "#D55E00", `Officer Assigned BWC` = "#0072B2")

gg_labels <- tibble(
  district = "1D",
  relative_month = -650,
  complaints_1000 = c(98, 88),
  Z = names(series_colors)
)

gg_df <- figure_e4_complaints_time_series

g <- ggplot(gg_df, aes(x = relative_month, y = complaints_1000, color = Z)) +
  geom_vline(xintercept = 0, color = "grey40") +
  geom_point(size = 0.9, alpha = 0.8) +
  stat_smooth(method = "loess", formula = y ~ x, linewidth = 0.6) +
  geom_text(data = gg_labels, aes(label = Z), hjust = 0, size = 2.8, show.legend = FALSE) +
  coord_cartesian(ylim = c(0, 100)) +
  facet_wrap(~district, ncol = 3) +
  scale_color_manual(values = series_colors) +
  labs(x = "Days since cameras deployed", y = "Complaints per 1,000 officers") +
  theme_bw() +
  theme(strip.background = element_blank(), legend.position = "none")

ggsave(file.path(out_dir, "figure_e4_complaints_time_series.pdf"), plot = g, width = 9, height = 7)
ggsave(file.path(out_dir, "figure_e4_complaints_time_series.png"), plot = g, width = 9, height = 7, dpi = 300)

print(figure_e4_complaints_time_series)
