# yokum_ravishankar_coppock_2019/maintained/figure_c1_all_outcomes.R
# Output: output/figure_c1_all_outcomes.csv, output/figure_c1_all_outcomes.pdf,
#   output/figure_c1_all_outcomes.png
# Depends on: clean_officer_level.R output, helpers.R
# Description: Appendix Figure C.1, all 45 outcomes in eight panels.
#   As in Figure 1, the difference-in-means series is the published one and the
#   second series adjusts for the pretreatment outcome alone, because the officer
#   covariates behind the published adjustment are not in the deposit.
#   Two outcomes, serious uses of force against white and against other-race
#   civilians, are identically zero in both windows, so both series report an
#   estimate and a standard error of zero for them and no p-value at all.
#   Forty-five outcomes across eight panels leave no room to label the two series
#   at the marks, so this is the one figure here that carries a legend.

source(here::here("maintained", "helpers.R"))

officer_level_district <- read_rds(file.path(out_dir, "officer_level_district.rds"))
dv_df <- read_rds(file.path(out_dir, "dv_df.rds"))

estimates_dim <- fit_dim_ipw_hc2(dv_df$dv_1000_rate_post, dv_df$dv_label, officer_level_district)

# Two of these fits warn "NaNs produced": serious uses of force against nonblack
# and against Hispanic civilians, whose pretreatment measure is nonzero for two of
# the 1,922 officers and whose posttreatment measure is nonzero for one. The
# intercept and the pretreatment term come back with a NaN standard error in both.
# The estimate on Z, its standard error and its p-value are finite and equal the
# difference in means to within 5e-15, which is what this figure plots.
estimates_ols <- suppressWarnings(
  fit_ols_pretreatment_hc2(dv_df$dv_1000_rate_post, dv_df$dv_1000_rate_pre,
                           dv_df$dv_label, officer_level_district)
)

figure_c1_all_outcomes <- bind_rows(
  `Difference-in-means` = estimates_dim,
  `OLS, pretreatment outcome only` = estimates_ols,
  .id = "estimator"
) |>
  left_join(select(dv_df, dv_label, dv_category), by = join_by(outcome == dv_label)) |>
  mutate(outcome = factor(outcome, levels = rev(dv_df$dv_label)))

write_csv(figure_c1_all_outcomes, file.path(out_dir, "figure_c1_all_outcomes.csv"))

gg_df <- figure_c1_all_outcomes

g <- ggplot(gg_df, aes(x = estimate, y = outcome, color = estimator, shape = estimator)) +
  geom_vline(xintercept = 0, linewidth = 0.4) +
  geom_linerange(aes(xmin = conf_low, xmax = conf_high),
                 position = position_dodge(width = 0.5)) +
  geom_point(position = position_dodge(width = 0.5), size = 1.4) +
  scale_color_manual(values = c(`Difference-in-means` = "#0072B2",
                                `OLS, pretreatment outcome only` = "#D55E00")) +
  scale_shape_manual(values = c(`Difference-in-means` = 16,
                                `OLS, pretreatment outcome only` = 17)) +
  facet_wrap(~dv_category, scales = "free", ncol = 2) +
  labs(x = "Estimated average treatment effect (yearly rate per 1,000 officers)",
       y = NULL, color = NULL, shape = NULL) +
  theme_bw() +
  theme(strip.background = element_blank(), legend.position = "bottom")

ggsave(file.path(out_dir, "figure_c1_all_outcomes.pdf"), plot = g, width = 12, height = 14)
ggsave(file.path(out_dir, "figure_c1_all_outcomes.png"), plot = g, width = 12, height = 14, dpi = 200)

print(figure_c1_all_outcomes, n = 20)
