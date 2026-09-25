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
- [The extraction and the two
  instruments](#the-extraction-and-the-two-instruments)
- [Errata](#errata)
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
| Errata | yokum_ravishankar_coppock_2019_errata.pdf, in this repository |

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
      maintained/in_text_claims.R every quantity the article states in a sentence
      maintained/output/          everything the rewrite produces
      ground_truth/               published values against archive and rewrite output
      ground_truth/published_claims.csv   the numeric-token extraction from the paper
      errata.qmd                  the corrections to the published text
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
its Methods section it analyses. Of the 280 published table values the
archive’s own output can be compared against, 227 disagree and 53 agree,
and every one of the 53 agreements is a cell whose published value is
zero or a standard error that happens to round the same way.
`regression_tables.R` produces those numbers with no error, no warning
and nothing on screen to suggest a problem.

**Does the maintained rewrite reproduce the paper?** Yes, on everything
the deposit can support. Of 381 checkable published values, 379 agree to
the precision the paper prints and 2 do not. A further 60 rows record
published quantities that no deposit could reproduce, almost all of them
because the officer covariates behind the covariate-adjusted results
cannot be published without identifying individual officers. Beside the
numeric comparisons, 17 claims the paper states in words are given a
computed truth value; 14 hold and 3 do not.

**Does the paper agree with itself?** In 5 places it does not, and those
are collected in `yokum_ravishankar_coppock_2019_errata.pdf` at the root
of this repository as five entries. Two figure captions name a window an
order of magnitude shorter than the one their figures cover, and because
they carry the same error they are one entry; the rest are a compliance
figure that disagrees with the article’s own Table C.37, a pilot count
that disagrees with its own Table A.1, and a cross-reference that points
at a section the supplement does not have. None of them changes a
conclusion, and none touches an estimate.

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

Every published float has a row in the ground truth and a count of what
it prints in the extraction. Five are recorded as having no source in
the deposit at all:

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

`ground_truth/build_ground_truth.R` assembles 441 rows. Each carries the
published value, typed from the article or the appendix and used only as
a comparison target; the value the deposited specification produces,
read from a file written by `ground_truth/archive_estimates.R`; and the
value the rewrite produces, read from `maintained/output/`. No published
number is an input to any computation anywhere in this repository.

| Comparison                                | Agree | Disagree | Not checkable |
|:------------------------------------------|------:|---------:|--------------:|
| Deposited specification against the paper |    53 |      227 |           161 |
| Maintained rewrite against the paper      |   379 |        2 |            60 |

Ground truth, all rows. A row is not checkable when the paper states no
number, or when nothing in the deposit can produce one.

| Where the number appears | Rows | Rewrite agrees | Rewrite disagrees |
|:---|---:|---:|---:|
| Appendix Tables A.1 and A.4 | 43 | 43 | 0 |
| Figure captions and plotted counts | 9 | 9 | 0 |
| Appendix Tables C.5 to C.37 | 280 | 280 | 0 |
| Quantities stated in sentences and table notes | 49 | 47 | 2 |

Checkable rows by where the number appears.

Every one of the 280 cells the odd-numbered appendix tables print
reproduces exactly, as do all 36 cells of Table A.1 and the seven of
Table A.4’s ten deployment dates that the deposited officer-day panel
covers.

| Where | Claim | Paper says | Data give |
|:---|:---|:---|:---|
| Figure E.3 | Days before and after deployment the figure covers | 90 | FALSE |
| Figure E.4 | Days before and after deployment the figure covers | 90 | FALSE |
| Text, Methods | Videos per year, officers assigned a camera | 665 | 663.1 |
| Text, Appendix A | Pilot officers not given cameras | 180 | 178.0 |
| Text, Appendix A.1 | The alternate measurement plots are said to be in Section 4 | \- | FALSE |

The rows where the paper disagrees with itself. Each is corrected in the
errata.

The compliance sentence in Methods is the sharpest of them. The article
says treatment officers uploaded “about 665” videos a year. The weighted
mean in the analysis sample is 663.1, which is also what the article’s
own Table C.37 implies, since its constant of 13.9 plus its coefficient
of 649.1 is 663.0. No sample or weighting scheme available in the
deposit returns 665. The gap is two videos out of 663 and changes
nothing, but the sentence and the table it summarizes do not agree with
each other.

# The extraction and the two instruments

The ground truth answers “does this published number reproduce?” It
cannot answer “is this published number in the ground truth at all?”,
and that second question is where the errors in this article turned out
to live. Two further files answer it.

`ground_truth/published_claims.csv` is the extraction: every numeric
token in the article and in its supplement, read line by line rather
than searched for, classified by hand into the five kinds a claim can
be. It carries 191 rows. `pipeline` claims are quantities the analysis
produces, `descriptive` claims are assertions about shape, sign or count
that need a truth value rather than a number, `definitional` claims are
scale endpoints and design constants, `structural` claims are page
furniture and float inventories, and `transcribed` claims are numbers
copied from another document and unable to move with the pipeline.

| Kind of claim | Rows | Need a block |
|:--------------|-----:|-------------:|
| definitional  |   45 |           35 |
| descriptive   |   23 |           23 |
| pipeline      |   27 |           27 |
| structural    |   84 |            4 |
| transcribed   |   12 |            0 |

The extraction from the article and its supplement.

The coverage boundary is stated rather than assumed. Inside it are the
article’s body, from the abstract through the Discussion, and supplement
sections A through E, including every table body, figure caption and
table note. Outside it are three classes, each recorded in the
extraction as a row of its own: the numbered reference list and the
bracketed citation markers in the body; supplement Appendix F, which
reproduces MPD General Order SPT-302.13 verbatim; and supplement
Appendix G, which reprints the preanalysis plan as a separately
paginated document. The last two are transcriptions of prior documents,
so none of their numbers can move with the pipeline. Page numbers, ZIP
codes, statute numbers, disposition codes, an IRB protocol number and
the DOI are recorded as structural rows and are not claims about
anything the data could contradict.

The extraction also counts what each published float prints, which is
what makes partial coverage visible.

| Published float | Floats | Numbers published | Covered | Reproduced by the rewrite |
|:---|---:|---:|---:|---:|
| Appendix Tables A.1 and A.4 | 2 | 46 | 46 | 43 |
| Appendix Tables A.2 and A.3 | 2 | 20 | 0 | 0 |
| Figures 1 and C.1 | 2 | 96 | 48 | 48 |
| Figures D.2, E.3, E.4 and E.5 | 4 | 90 | 0 | 0 |
| Appendix Tables C.5 to C.37, odd numbered | 17 | 280 | 280 | 280 |
| Appendix Tables C.6 to C.36, even numbered | 16 | 706 | 0 | 0 |

What each published float prints, and how much of it the ground truth
compares. The two coefficient plots print no estimate on their faces, so
their count is what they plot.

374 of the 1238 numbers the published floats carry are compared cell by
cell. The rest are the sixteen covariate-adjusted tables, the two
pretreatment covariate tables and the alternate-strategy figure, all of
which rest on officer covariates the deposit cannot contain.

`maintained/in_text_claims.R` is the second instrument. Every claim the
extraction marks as needing a block, 89 of them, is recomputed there
from `maintained/output/` beside the sentence that states it, and
printed as a labelled line. It reads the extraction, so that a block can
name the article’s own precision, and it never reads the ground truth,
because agreeing with the comparison would prove nothing. Where
`build_ground_truth.R` reaches a quantity through one of the
`text_*.csv` summaries, this file goes back to the table or the cleaned
data that summary was built from, and where the build goes through a
table, the claims file goes through the summary. The two derivations are
separate on purpose: where they disagree, one of them is wrong.

`build_ground_truth.R` runs the coverage gate, in this order. Checks
that depend only on the extraction come first, so that a wrong precision
trips its own check rather than the value comparison downstream:
identifiers are unique, claim types and comparison operators are drawn
from the allowed sets, every `pipeline` and `descriptive` row is marked
as needing a block, and every stored published value survives a round
trip through the number of decimals recorded beside it. The locus rule
follows in all three of its states: a row where either verdict is
adverse must name where the fault lies, a clean match must not, and a
row with no verdict may. The extraction is then reconciled against the
ground truth’s own transcription of the same pages, and the float
inventory against what the ground truth covers. Last, the claims file is
run non-interactively into its own environment, its output is captured,
and the printed claim lines are counted: 89 printed against 89 required,
with the identifiers equal in both directions, and each printed value
compared against the ground truth’s at the precision the page itself
uses.

The gate was tested by breaking it three ways. Deleting a block fails
the count. Corrupting a value in the claims file fails the
cross-instrument comparison. Corrupting a precision in the extraction
fails the round-trip check, and fails it before anything else reads that
precision.

# Errata

The five corrections to the published text are collected in
`yokum_ravishankar_coppock_2019_errata.pdf`, built from `errata.qmd` at
the root of this repository with every corrected value computed at
render time from `maintained/output/`. That file also writes
`errata_entries.csv`, the spine every entry is defined in and the source
of the count above. None changes a conclusion and none touches an
estimate.

1.  The captions of supplementary Figures E.3 and E.4 say the figures
    cover 90 days before and after deployment. They cover 690 days
    before and 510 days after. The deposited `time_series_plot.R`
    applies a 90-day filter to a pooled version of each figure that the
    supplement does not print; the district-by-district version it does
    print carries no such filter.
2.  The Methods section says treatment officers uploaded about 665
    videos a year. The figure implied by the article’s own Table C.37,
    and produced by the analysis sample, is 663.
3.  Appendix A says 180 officers in the pilot were not given cameras.
    The article’s own Table A.1 gives 79 in 5D and 99 in 7D, which
    is 178. The treated count in the same sentence, 325, is exactly
    right.
4.  Appendix A.1 says the alternate measurement plots are “provided in
    Section 4.” The supplement’s sections are lettered A through G; the
    plots are Figure D.2, in Appendix D.

This is separate from the corrections the rewrite makes to the deposited
code, which are described above and are errors in the archive rather
than in the article.

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
The published axis runs from 750 days before deployment to 500 days
after, and the underlying panel covers 690 days before and 510 after.
The window in the caption is not the window in the plot, and the
correction is the first entry in the errata.

# Verification

Every script runs in a clean session and the whole pipeline runs end to
end from `run_all.R`. Running it twice returns byte-identical output,
every file included: R’s `pdf()` device stamps the wall clock into each
figure’s `/CreationDate` and `/ModDate`, and `run_all.R` blanks those
two fields after the last analysis script, so the determinism check
covers the figures rather than exempting them. No estimator used
anywhere here draws a random number, so there is no seed to set and no
dependence on which sampler the running version of R provides.

`run_all.R` begins by sourcing `download_original.R`, so every run
re-verifies `original/` against the manifest before any analysis reads
from it, and stops if a file has changed or if a file the manifest does
not list has appeared. The deposit’s own scripts are never executed
inside `original/`, which is what a checksum gate placed after the fact
would fail to catch.

| Package    | Version    |
|:-----------|:-----------|
| tidyverse  | 2.0.0      |
| estimatr   | 2.0.0.9000 |
| broom      | 1.0.13     |
| ggplot2    | 4.0.3      |
| readr      | 2.2.0      |
| dplyr      | 1.2.1      |
| purrr      | 1.2.2      |
| knitr      | 1.51       |
| kableExtra | 1.4.0      |
| here       | 1.0.2      |
| openssl    | 2.4.2      |

R environment. Rendered under R version 4.6.0 (2026-04-24).
