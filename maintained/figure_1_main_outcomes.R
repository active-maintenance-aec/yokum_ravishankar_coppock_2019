# yokum_ravishankar_coppock_2019/maintained/figure_1_main_outcomes.R
# Output: output/figure_1_main_outcomes.csv, output/figure_1_main_outcomes.pdf,
#   output/figure_1_main_outcomes.png
# Depends on: clean_officer_level.R output, helpers.R
# Description: Figure 1 of the article, the estimated effect of a camera on use of
#   force, complaints, and arrests for disorderly conduct.
#   The difference-in-means series is the published one. The published second
#   series adjusts for officer race, gender and length of service, none of which
#   the deposit contains; the series drawn here adjusts for the pretreatment value
#   of the outcome alone and is therefore not the published series.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))
dv_df <- read_rds(file.path(out_dir, "dv_df.rds"))

dv_main <- dv_df |>
  filter(dv_name %in% c("use_of_force", "all_complaints", "disorderly_conduct"))

estimates_dim <- fit_dim_ipw_hc2(dv_main$dv_1000_rate_post, dv_main$dv_label, officer_level_district)

estimates_ols <- fit_ols_pretreatment_hc2(dv_main$dv_1000_rate_post, dv_main$dv_1000_rate_pre,
                                          dv_main$dv_label, officer_level_district)

figure_1_main_outcomes <- bind_rows(
  `Difference-in-means` = estimates_dim,
  `OLS, pretreatment outcome only` = estimates_ols,
  .id = "estimator"
) |>
  mutate(outcome = factor(outcome, levels = rev(dv_main$dv_label)))

write_csv(figure_1_main_outcomes, file.path(out_dir, "figure_1_main_outcomes.csv"))

# The two series are labelled on the topmost outcome rather than in a legend. The
# dodge puts the first series below the outcome's tick and the second above it, so
# each label sits on the outer side of its own row.
gg_labels <- figure_1_main_outcomes |>
  filter(outcome == last(levels(outcome))) |>
  mutate(nudge = if_else(estimator == "Difference-in-means", -0.30, 0.30),
         vjust = if_else(estimator == "Difference-in-means", 1, 0))

gg_df <- figure_1_main_outcomes

g <- ggplot(gg_df, aes(x = estimate, y = outcome, color = estimator, shape = estimator)) +
  geom_vline(xintercept = 0, linewidth = 0.4) +
  geom_linerange(aes(xmin = conf_low, xmax = conf_high),
                 position = position_dodge(width = 0.5)) +
  geom_point(position = position_dodge(width = 0.5), size = 2.2) +
  geom_text(data = gg_labels,
            aes(label = estimator, y = as.numeric(outcome) + nudge, vjust = vjust),
            hjust = 0.5, size = 3, show.legend = FALSE) +
  scale_color_manual(values = c(`Difference-in-means` = "#0072B2",
                                `OLS, pretreatment outcome only` = "#D55E00")) +
  scale_shape_manual(values = c(`Difference-in-means` = 16,
                                `OLS, pretreatment outcome only` = 17)) +
  scale_y_discrete(expand = expansion(add = c(0.6, 0.9))) +
  labs(x = "Estimated ATE (yearly rate per 1,000 officers)", y = NULL) +
  theme_bw() +
  theme(legend.position = "none")

ggsave(file.path(out_dir, "figure_1_main_outcomes.pdf"), plot = g, width = 7, height = 3.5)
ggsave(file.path(out_dir, "figure_1_main_outcomes.png"), plot = g, width = 7, height = 3.5, dpi = 300)

print(figure_1_main_outcomes)
