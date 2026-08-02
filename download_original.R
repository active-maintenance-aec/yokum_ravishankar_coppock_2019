# yokum_ravishankar_coppock_2019/download_original.R
# Output: original/ (the deposited archive, which this repository does not redistribute)
# Depends on: original_manifest.csv
# Description: Fetch the deposited archive from the Open Science Framework and verify
#   every file. Run this once before anything in maintained/. Re-running costs
#   nothing: a file already present with the right checksum is not fetched again.
#
#   The deposit is 176 MB, almost all of it the officer-day panel, so the first run
#   takes a few minutes.
#
#   OSF publishes two checksums per file, an MD5 and a SHA-256, and both describe
#   the stored bytes that the download endpoint returns. This script verifies both.
#   That is a different arrangement from a Dataverse deposit, where the two
#   checksums worth recording are the MD5 of what the server sends and the MD5 the
#   catalogue displays, which are not always the same number. OSF has no derived
#   representation of a data file and no second copy of the checksum to disagree
#   with, so here the two hashes are two algorithms over one set of bytes.
#
#   The deposit has two folders. Their names, including the space and the
#   parentheses in "Pre-Analysis Plan (PAP)", are part of the deposited paths and
#   are reproduced exactly; maintained/helpers.R reads from them under those names.

library(tidyverse)
library(here)

here::i_am("download_original.R")

archive_doi <- "10.17605/OSF.IO/P6VUH"
osf_node <- "p6vuh"
base_url <- "https://files.osf.io/v1/resources"

manifest <- read_csv(here::here("original_manifest.csv"), show_col_types = FALSE)

walk(unique(dirname(here::here("original", manifest$file))),
     function(d) dir.create(d, showWarnings = FALSE, recursive = TRUE))

planned <- manifest |>
  mutate(
    path = here::here("original", file),
    url = str_glue("{base_url}/{osf_node}/providers/osfstorage/{osf_file_id}"),
    md5_local = unname(tools::md5sum(path)),
    needs_download = is.na(md5_local) | md5_local != md5
  )

walk2(
  planned$url[planned$needs_download],
  planned$path[planned$needs_download],
  function(url, path) download.file(url, destfile = path, mode = "wb", quiet = TRUE)
)

print(str_glue("Downloaded {sum(planned$needs_download)} of {nrow(planned)} files; ",
               "{sum(!planned$needs_download)} already present and verified."))

sha256_file <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  as.character(openssl::sha256(con))
}

verified <- planned |>
  mutate(
    bytes_local = file.size(path),
    md5_downloaded = unname(tools::md5sum(path)),
    sha256_downloaded = map_chr(path, sha256_file),
    md5_matches = md5_downloaded == md5,
    sha256_matches = sha256_downloaded == sha256,
    bytes_match = bytes_local == bytes
  ) |>
  select(file, bytes, bytes_match, md5_matches, sha256_matches)

print(verified, n = nrow(verified), width = 200)

if (!all(verified$md5_matches, verified$sha256_matches, verified$bytes_match)) {
  stop("Checksum mismatch: the downloaded archive is not what OSF published for this deposit.")
}

# The deposit is the whole of original/, so anything else under it came from
# somewhere other than OSF and should not be treated as part of the archive. This runs
# after the checksums, so a deposited file renamed by hand fails on its own checksum
# rather than passing here as an unlisted extra. all.files = TRUE is not optional:
# without it a stray dotfile passes unseen, and a deposit can ship dotfiles of its own,
# which the manifest then has to list.
extra <- setdiff(
  list.files(here::here("original"), recursive = TRUE, all.files = TRUE, no.. = TRUE),
  manifest$file
)

if (length(extra) > 0) {
  stop("original/ holds files the manifest does not list: ",
       paste(extra, collapse = ", "),
       ". Move them elsewhere; original/ is the deposit and only the deposit.")
}

print(str_glue("All {nrow(verified)} deposited files verified on MD5, SHA-256 and byte ",
               "size, and original/ contains nothing else. Archive: {archive_doi}"))
