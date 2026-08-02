# yokum_ravishankar_coppock_2019/maintained/helpers.R
# Output: (none; sourced by every other script)
# Depends on: original/ (fetched by download_original.R)
# Description: Packages, paths, the analysis sample definition, and the two
#   estimators the paper uses, so that every script states the same thing.

library(here)
library(tidyverse)
library(estimatr)
library(broom)
library(knitr)

here::i_am("maintained/helpers.R")

data_dir <- here::here("original", "Replication Data")
out_dir <- here::here("maintained", "output")

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Analysis sample ----
# The paper analyses the seven patrol districts (n = 1,922) and excludes the 1D
# station detail ("1Ds") and the four special units (NSID, NSID_2, SOD, SSD).
main_districts <- c("1D", "2D", "3D", "4D", "5D", "6D", "7D")

# Estimators ----
# Both estimators are weighted least squares with the inverse probability weights
# carried in the data, and HC2 standard errors, which is what the paper
# preregisters and what estimatr uses by default. The weights column is pulled out
# of the data first: lm_robust evaluates a weights argument inside the data frame,
# so passing the bare name of a column called "weights" is ambiguous.

fit_dim_ipw_hc2 <- function(outcomes, labels, data, se_type = "HC2") {
  wts <- data$weights
  map2(outcomes, labels, function(y_name, label) {
    fit <- lm_robust(reformulate("Z", y_name), data = data, weights = wts, se_type = se_type)
    tibble(
      outcome = label,
      outcome_variable = y_name,
      estimate = coef(fit)[["Z"]],
      std_error = fit$std.error[["Z"]],
      p_value = fit$p.value[["Z"]],
      conf_low = fit$conf.low[["Z"]],
      conf_high = fit$conf.high[["Z"]],
      constant = coef(fit)[["(Intercept)"]],
      constant_se = fit$std.error[["(Intercept)"]],
      n = fit$nobs,
      r_squared = fit$r.squared
    )
  }) |>
    list_rbind()
}

# The paper's Eq. 1 writes the covariate-adjusted estimator as the pretreatment
# value of the outcome, indicators for the officer's major block, and officer race,
# gender and length of service. The sixteen published covariate-adjusted tables
# print a shorter list: the pretreatment outcome, gender, a three-category race
# variable and length of service, with no block indicators in any of them. Race,
# gender and length of service are not in the deposit and cannot be, because they
# would identify individual officers, so this adjustment uses the pretreatment
# outcome alone. That is the reduced specification the deposited figure scripts
# define in their formulae_OLS object, which they then never pass to a fit, and it
# is not the specification the published figures plot.
fit_ols_pretreatment_hc2 <- function(outcomes, pre_outcomes, labels, data, se_type = "HC2") {
  wts <- data$weights
  pmap(list(outcomes, pre_outcomes, labels), function(y_name, pre_name, label) {
    fit <- lm_robust(reformulate(c("Z", pre_name), y_name),
                     data = data, weights = wts, se_type = se_type)
    tibble(
      outcome = label,
      outcome_variable = y_name,
      estimate = coef(fit)[["Z"]],
      std_error = fit$std.error[["Z"]],
      p_value = fit$p.value[["Z"]],
      conf_low = fit$conf.low[["Z"]],
      conf_high = fit$conf.high[["Z"]],
      n = fit$nobs,
      r_squared = fit$r.squared
    )
  }) |>
    list_rbind()
}

# Table output ----
# Every table script writes the same pair: a CSV at full precision, which is what
# the ground truth reads and what a fresh run is diffed against, and a LaTeX
# version rounded the way the appendix rounds it, which is what the report shows.
write_dim_table <- function(tab, stem, caption) {
  write_csv(tab, file.path(out_dir, paste0(stem, ".csv")))

  display <- tab |>
    transmute(
      Outcome = outcome,
      Estimate = formatC(estimate, format = "f", digits = 1, big.mark = ","),
      SE = paste0("(", formatC(std_error, format = "f", digits = 1, big.mark = ","), ")"),
      Constant = formatC(constant, format = "f", digits = 1, big.mark = ","),
      `Constant SE` = paste0("(", formatC(constant_se, format = "f", digits = 1, big.mark = ","), ")"),
      N = formatC(n, format = "d", big.mark = ","),
      `R2` = formatC(r_squared, format = "f", digits = 3)
    )

  kable(display, format = "latex", booktabs = TRUE, caption = caption, escape = TRUE) |>
    write_lines(file.path(out_dir, paste0(stem, ".tex")))

  print(tab)
}
