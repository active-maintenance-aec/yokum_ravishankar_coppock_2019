# Reproducing Yokum, Ravishankar and Coppock (2019)


- [What is here](#what-is-here)
- [Summary](#summary)
- [The paper](#the-paper)
- [The deposited archive](#the-deposited-archive)
  - [What the deposited scripts do](#what-the-deposited-scripts-do)
  - [Three ways the deposited code departs from the
    paper](#three-ways-the-deposited-code-departs-from-the-paper)
- [The maintained rewrite](#the-maintained-rewrite)
  - [Coverage](#coverage)
- [Ground truth](#ground-truth)
- [Figures](#figures)
- [Verification](#verification)

This repository reproduces the published results of Yokum, Ravishankar
and Coppock (2019), a randomized trial of police body-worn cameras
conducted with the Metropolitan Police Department of the District of
Columbia. It contains a maintained rewrite of the analysis in current R,
a table that compares every checkable published number against both the
deposited code and the rewrite, and a report on what does and does not
reproduce.

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

## What is here

| Item | Reference |
|:---|:---|
| Article | https://doi.org/10.1073/pnas.1814773116 |
| Supplementary appendix | https://www.pnas.org/lookup/suppl/doi:10.1073/pnas.1814773116/-/DCSupplemental |
| Deposited archive | https://doi.org/10.17605/OSF.IO/P6VUH |
| Preanalysis plan | Included in the deposited archive and reprinted as Appendix G |

Where the paper and its materials live. Both DOIs were resolved and
checked against the registration agency’s record.

    yokum_ravishankar_coppock_2019/
      README.qmd                  this report, rendered to README.md and report/
      yokum_ravishankar_coppock_2019.Rproj
      run_all.R                   entry point: runs everything in order
      download_original.R         fetches and verifies the deposited archive
      original_manifest.csv       the deposit's file names, sizes and checksums
      original/                   the deposited archive (not redistributed here)
      maintained/                 the rewrite, one script per published float
      maintained/output/          everything the rewrite produces
      ground_truth/               published values against archive and rewrite output
      report/                     the PDF build of this report

To reproduce: clone the repository, open
`yokum_ravishankar_coppock_2019.Rproj`, and run

``` r
source("run_all.R")
```

The first run downloads the deposited archive from OSF, which is 176 MB,
and verifies every file against the checksums OSF publishes. Later runs
skip files already present and correct. Each script under `maintained/`
can also be run on its own.

# Summary

**Does the deposited archive run?** Yes. All four deposited scripts
execute at exit status 0 under R 4.6.0 and current package versions. The
only complaints are a deprecation warning and a layout warning, both
from the two coefficient plot scripts.

**Does the deposited archive reproduce the paper?** Almost none of it.
The archive’s one table-producing script fits every model on all 2,224
officers in the trial. The published tables report 1,922, the officers
in the seven patrol districts, which is the sample the article says in
its Methods section it analyses. Of the 205 published table values the
archive’s own output can be compared against, 189 disagree and 16 agree,
and every one of the 16 agreements is a cell whose published value is
zero or a standard error that happens to round the same way.
`regression_tables.R` produces those numbers with no error, no warning
and nothing on screen to suggest a problem.

**Does the maintained rewrite reproduce the paper?** Yes, on everything
the deposit can support. Of 264 checkable published values, 263 agree to
the precision the paper prints and 1 does not. The single disagreement
is an in-text number that disagrees with the paper’s own appendix table.
A further 30 rows record published quantities that no deposit could
reproduce, almost all of them because the officer covariates behind the
covariate-adjusted results cannot be published without identifying
individual officers.

# The paper

Yokum, David, Anita Ravishankar and Alexander Coppock. 2019. “A
randomized control trial evaluating the effects of police body-worn
cameras.” *Proceedings of the National Academy of Sciences* 116 (21):
10329 to 10332.

Roughly half of 2,224 eligible Metropolitan Police Department officers
were randomly assigned a body-worn camera, blocked on district and on
officer characteristics within district. Outcomes came from
administrative records over matched 212-day windows before and after
each district’s camera rollout, and were expressed as yearly rates per
1,000 officers. The paper reports two estimators: a difference in means
weighted by the inverse probability of assignment, and a regression that
adds the pretreatment value of the outcome and officer covariates. The
main analysis is the seven patrol districts, 1,922 officers, excluding
the station detail and the special units.

One small discrepancy inside the paper is worth noting before anything
is compared to it. Eq. 1 in the Methods section writes the
covariate-adjusted specification with a vector of major-block indicators
alongside the pretreatment outcome and the officer covariates. None of
the sixteen published covariate-adjusted tables lists a block indicator:
each prints the pretreatment outcome, gender, a three-category race
variable and length of service, and nothing else. The inverse
probability weights already account for the differing assignment
probabilities across blocks, so the omission is defensible, but the
equation and the tables do not describe the same regression.

The headline result is a null. Across all 45 measured outcomes, covering
use of force, civilian complaints, policing activity and judicial
outcomes, cameras changed nothing detectably.

# The deposited archive

The deposit at [osf.io/p6vuh](https://doi.org/10.17605/OSF.IO/P6VUH)
holds 11 files in two folders, 176 MB in total.

| File | Bytes | OSF id |
|:---|:---|:---|
| Pre-Analysis Plan (PAP)/Pre-analysis Plan - MPD BWC RCT - v1.pdf | 408,266 | hpmrt |
| Replication Data/BWC_dv_df.rdata | 1,855 | kmjxg |
| Replication Data/README.txt | 593 | 4pzyt |
| Replication Data/coefplot_all_dvs.R | 1,914 | vswpu |
| Replication Data/coefplot_main_dvs.R | 1,920 | f2c93 |
| Replication Data/day_level_anon.csv | 177,902,506 | h9wpc |
| Replication Data/dv_df.csv | 8,985 | ctyb9 |
| Replication Data/officer_level_anon.csv | 1,865,518 | gsbwt |
| Replication Data/regression_tables.R | 15,972 | muqpj |
| Replication Data/time_series_plot.R | 3,292 | spr5g |
| TheLabDC_MPD_BWC_Working_Paper_10.20.17.pdf | 4,650,695 | rk2pa |

The deposit, as listed by the OSF API.

`download_original.R` fetches each file by its OSF identifier and checks
it against both published hashes. All 11 files verify on MD5 and on
SHA-256, and the local copy is byte for byte what OSF serves. The script
also refuses to continue if `original/` holds anything the manifest does
not list, so a stray file left behind by a previous run cannot quietly
become part of the archive.

Two notes on the shape of the deposit. It carries a preprint of the
paper from 2017, not the published article, so the published values used
below were read from the article and its appendix rather than from
anything in the deposit. And the deposit’s own `README.txt` lists five R
scripts where four are present: `regression_tables_cov.R`, the script
that would have produced the covariate-adjusted tables, is named but
absent.

## What the deposited scripts do

| Script | Produces | Status |
|:---|:---|:---|
| coefplot_main_dvs.R | Figure 1 | Runs, two warnings |
| coefplot_all_dvs.R | Figure C.1 | Runs, nine warnings |
| regression_tables.R | Tables C.5 to C.37, odd numbered | Runs clean |
| time_series_plot.R | Figures E.3 and E.4 | Runs clean |
| regression_tables_cov.R | Tables C.6 to C.36, even numbered | Absent from the deposit |

The deposited scripts and the published floats they correspond to.

Everything that is present runs, all four at exit status 0.
`coefplot_main_dvs.R` and `coefplot_all_dvs.R` raise a deprecation
warning for `geom_errorbarh()` and then one layout warning from
`position_dodgev()` per panel drawn, which is one warning for the
single-panel figure and eight for the faceted one. Nothing errors. No
script saves an output either: all four draw to the screen or print to
the console, so a reader who runs them has nothing on disk to compare
against anything. Run non-interactively each one leaves an `Rplots.pdf`
in the working directory, which is the only reason to care where they
are run from, and it is why the archive here is copied out before it is
run rather than executed inside `original/`.

## Three ways the deposited code departs from the paper

**The sample.** Every model in `regression_tables.R` is fit on the full
2,224 officers. Every published table reports 1,922. The two coefficient
plot scripts have the same problem. This single difference is why the
deposited output does not match the paper anywhere, and it is invisible
at runtime.

| Outcome | Published | Deposited script | Rewrite | N, deposited | N, rewrite |
|:---|:---|:---|:---|---:|---:|
| Use of Force | 73.6 (87.0) | 69.8 (76.6) | 73.6 (87.0) | 2224 | 1922 |
| Use of Force (Serious) | 13.8 (14.1) | 8.4 (12.7) | 13.8 (14.1) | 2224 | 1922 |
| Use of Force (Other) | 59.8 (83.4) | 61.4 (73.4) | 59.8 (83.4) | 2224 | 1922 |

Table C.5, the first of the appendix tables. Standard errors in
parentheses. The deposited script’s numbers come from all 2,224
officers; the published table and the rewrite use the 1,922 in the seven
patrol districts.

**The second estimator in the figures.** Both coefficient plot scripts
build a vector of covariate-adjusted formulas and then never use it: the
object named for the adjusted fits is computed from the unadjusted
formulas instead. The figures the deposited scripts draw therefore plot
the same estimates twice, one series labelled as though it were
adjusted. The rewrite uses the adjusted formulas, which is plainly what
the deposited code intends.

**The adjustment itself.** Even with that corrected, the adjusted series
cannot be the published one. Every published covariate-adjusted table
conditions on officer gender, race and length of service, and the
deposit contains none of the three, and says so, because releasing them
would identify individual officers. The deposited scripts substitute an
adjustment on the pretreatment outcome alone and note the substitution
in a comment. The rewrite keeps that reduced adjustment and labels it
for what it is. No published number from any covariate-adjusted table or
figure series can be checked against this deposit, by anyone.

# The maintained rewrite

`maintained/` holds one script per published float, a shared `helpers.R`
that defines the two estimators and the analysis sample, and two
cleaning scripts. Output goes to `maintained/output/` and is committed,
so a fresh run can be diffed against it without downloading anything.

| Script | Produces |
|:---|:---|
| helpers.R | packages, paths, the analysis sample, the two estimators |
| clean_officer_level.R | the officer file, whole and cut to the seven districts |
| clean_day_level.R | the officer-day panel collapsed to district by period rates |
| table_a1_random_assignment.R | Table A.1 |
| table_a4_deployment_dates.R | Table A.4 |
| table_c5 … table_c37 (17 scripts) | the odd-numbered appendix tables, C.5 through C.37 |
| figure_1_main_outcomes.R | Figure 1 |
| figure_c1_all_outcomes.R | Figure C.1 |
| figure_e3_use_of_force_time_series.R | Figure E.3 |
| figure_e4_complaints_time_series.R | Figure E.4 |
| text_main_estimates.R | the three effect estimates the Results section states in words |
| text_sample_and_compliance.R | the sample counts and the compliance means in Methods |
| text_null_results_check.R | a count of outcomes reaching significance |
| text_district_by_district.R | the seven district-level estimates the Discussion asserts |

The rewrite.

Substitutions from the deposited code: `%>%` becomes the native pipe;
`geom_errorbarh()` becomes `geom_linerange()`; `position_dodgev()` from
the unmaintained `coefplot` package becomes `position_dodge()` with the
outcome on the discrete axis; `lm()` with `starprep()` becomes
`lm_robust()`, whose default standard error is already HC2;
`stargazer()` printing LaTeX to the console becomes a CSV at full
precision plus a rounded LaTeX table written to a file; and
`rm(list = ls())` at the top of every script is gone, since the scripts
assume nothing about the session they start in.

Two smaller decisions are worth recording. The weights column is pulled
out of the data frame before it reaches `lm_robust()`, because a weights
argument is evaluated inside the data first and the column is called
`weights`. And district labels are read from CSV as text on purpose:
`readr` accepts the Fortran double exponent, so a guessed column of `1D`
through `7D` comes back as the numbers 1 through 7.

## Coverage

Every published float has at least one row in the ground truth. Five are
recorded there as having no source in the deposit at all:

- **Tables A.2 and A.3**, the pretreatment distributions of officer
  race, sex and length of service. Those covariates are not deposited.
- **Tables C.6 through C.36, even numbered**, the sixteen
  covariate-adjusted tables. Same reason, and the script that made them
  is missing besides.
- **Figure D.2**, all outcomes under the alternate measurement strategy,
  which uses each district’s full observation window. The deposited
  officer file carries only the 212-day rates.
- **Figure E.5**, calls for service against videos uploaded. The
  calls-for-service series is not deposited.
- The **adherence figures** in the Discussion, 98 per cent of days and
  96 per cent average adherence, which rest on the same
  calls-for-service data.

# Ground truth

`ground_truth/build_ground_truth.R` assembles 294 rows. Each carries the
published value, typed from the article or the appendix and used only as
a comparison target; the value the deposited specification produces,
read from a file written by `ground_truth/archive_estimates.R`; and the
value the rewrite produces, read from `maintained/output/`. No published
number is an input to any computation anywhere in this repository.

| Comparison                                | Agree | Disagree | Not checkable |
|:------------------------------------------|------:|---------:|--------------:|
| Deposited specification against the paper |    16 |      189 |            89 |
| Maintained rewrite against the paper      |   263 |        1 |            30 |

Ground truth, all rows. A row is not checkable when the paper states no
number, or when nothing in the deposit can produce one.

| Published float             | Rows | Rewrite agrees | Rewrite disagrees |
|:----------------------------|-----:|---------------:|------------------:|
| Appendix Tables C.5 to C.37 |  205 |            205 |                 0 |
| Appendix Tables A.1 and A.4 |   43 |             43 |                 0 |
| In-text quantities          |   16 |             15 |                 1 |

Checkable rows by where the number appears.

The one disagreement is the compliance sentence in Methods. The article
says treatment officers uploaded “about 665” videos a year. The weighted
mean in the analysis sample is 663.1, which is also what the article’s
own Table C.37 implies, since its constant of 13.9 plus its coefficient
of 649.1 is 663.0. No sample or weighting scheme available in the
deposit returns 665. The gap is two videos out of 663 and changes
nothing, but the sentence and the table it summarizes do not agree with
each other.

Two checks in the ground truth are of claims the paper makes in words
and supports with no table.

| Claim | Paper implies | Rewrite finds |
|:---|---:|---:|
| Outcomes significant at conventional levels | 0 | 0 |
| Districts with a significant effect on use of force | 0 | 0 |

Claims stated in prose and checked against the data.

Both hold. Across the 45 outcomes, no unadjusted estimate reaches p \<
0.10, let alone p \< 0.05; two outcomes, serious uses of force against
white and against other-race civilians, are identically zero throughout
the posttreatment window and have no p-value at all. District by
district, no estimate on use of force is significant at the 0.05 level.

# Figures

![Figure 1 of the article. The circles are the published
difference-in-means estimates. The triangles are not the published
second series: the deposit cannot support the covariate adjustment the
paper used, so this adjusts for the pretreatment outcome
alone.](maintained/output/figure_1_main_outcomes.png)

![Appendix Figure C.1, all 45 outcomes. The same caveat applies to the
adjusted series.](maintained/output/figure_c1_all_outcomes.png)

![Appendix Figure E.3, uses of force per 1,000 officers by district and
30-day
period.](maintained/output/figure_e3_use_of_force_time_series.png)

![Appendix Figure E.4, complaints per 1,000 officers by district and
30-day period.](maintained/output/figure_e4_complaints_time_series.png)

None of the published figures prints a number, so each figure script
writes a CSV of the values it plots and the ground truth compares those.
Figure C.1 plots the same unadjusted estimates the appendix tables
print, and across 45 outcomes, matched on the outcome column name rather
than the printed label, the largest absolute difference between the
figure’s values and the tables’ is 0. Figures E.3 and E.4 plot 432
district by period rates each, reproduced from the deposited officer-day
panel.

One caption does not describe its figure. Figures E.3 and E.4 are
captioned “90 days before and after BWC deployment” and say there is no
significant difference “in either the 90-day period before or after”.
The published axis runs from roughly 750 days before deployment to 500
days after, and the underlying panel covers that whole span. The window
in the caption is not the window in the plot.

# Verification

Every script runs in a clean session and the whole pipeline runs end to
end from `run_all.R`. Running it twice returns byte-identical CSV, LaTeX
and PNG output; the four figure PDFs are the only files that change, and
they change because a PDF records the time it was written. No estimator
used anywhere here draws a random number, so there is no seed to set and
no dependence on which sampler the running version of R provides.

`run_all.R` begins by sourcing `download_original.R`, so every run
re-verifies `original/` against the manifest before any analysis reads
from it, and stops if a file has changed or if a file the manifest does
not list has appeared. The deposit’s own scripts are never executed
inside `original/`, which is what a checksum gate placed after the fact
would fail to catch.

| Package    | Version |
|:-----------|:--------|
| tidyverse  | 2.0.0   |
| estimatr   | 1.0.6   |
| broom      | 1.0.13  |
| ggplot2    | 4.0.3   |
| readr      | 2.2.0   |
| dplyr      | 1.2.1   |
| purrr      | 1.2.2   |
| knitr      | 1.51    |
| kableExtra | 1.4.0   |
| here       | 1.0.2   |
| openssl    | 2.4.2   |

R environment. Rendered under R version 4.6.0 (2026-04-24).
