msg <- function(verbose) {
  function(...) if (verbose) message(...)
}

#' Download Raw Illumina Methylation Manifest
#'
#' Downloads the raw manifest file for a specified Illumina methylation array chip.
#' Integrity is not verified at this stage; verification happens on the cleaned
#' output in [get_manifest()] via `hash_clean`. If Illumina re-uploads a file
#' with cosmetic changes (line endings, BOM, etc.), the cleaned hash will still
#' match as long as the relevant columns are unchanged.
#'
#' @inheritParams ilmn_manifest
#'
#' @return The path to the downloaded manifest file as a character string,
#' or `invisible(NULL)` if the chip is invalid or not specified.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' download_manifest("EPICv1")
#' }
download_manifest <- function(chip = NULL, rawdir = NULL, ask = TRUE, verbose = TRUE) {
  checkmate::assert_string(chip, null.ok = TRUE, .var.name = "chip")
  checkmate::assert_string(rawdir, null.ok = TRUE, .var.name = "rawdir")
  checkmate::assert_flag(ask, null.ok = FALSE, .var.name = "ask")
  checkmate::assert_flag(verbose, null.ok = FALSE, .var.name = "verbose")
  if (is.null(rawdir)) rawdir <- withr::local_tempdir()
  m <- msg(verbose)
  if (is.null(chip) || !chip %in% ilmn_meth_mani$chip) {
    m(sprintf(
      "Selected '%s'. Available options are: %s",
      if (is.null(chip)) "NULL" else chip,
      paste(sprintf("'%s'", ilmn_meth_mani$chip), collapse = ", ")
    ))
    return(invisible(NULL))
  }
  url <- ilmn_meth_mani$links[chip]
  fn <- ilmn_meth_mani$filename[chip]
  fn_path <- fs::path(rawdir, fn)
  tryCatch(
    {
      if (fs::file_exists(fn_path)) {
        m(sprintf("Cache found for '%s' at '%s'", chip, fn_path))
      } else {
        m(sprintf("'%s' manifest not found, downloading...", chip))
        if (ask && interactive()) {
          answer <- readline(sprintf("Download '%s' manifest? [y/n]: ", chip))
          if (!tolower(trimws(answer)) %in% c("y", "yes")) {
            m("Download aborted.")
            return(invisible(NULL))
          }
        }
        utils::download.file(url = url, destfile = fn_path, mode = "wb", quiet = !verbose)
        m(sprintf("Successfully downloaded '%s' manifest", chip))
      }
      return(invisible(fn_path))
    },
    error = function(e) {
      stop(sprintf(
        "Download failed for '%s': %s\nManual download: %s",
        chip, conditionMessage(e), url
      ))
    }
  )
}

#' Create Manifest Cleaning Function
#'
#' A factory function that generates a cleaning function for a specific
#' Illumina methylation manifest based on the provided cleaning logic,
#' chip type, and optional hash for verification.
#'
#' @param clean_fn The function that performs the cleaning on the raw manifest file.
#' @param hash Downloaded file hash.
#'
#' @inheritParams ilmn_manifest
#'
#' @return A function that takes a path to the raw manifest and an optional force flag,
#' cleans the manifest, saves it as an .fst file, and returns the path to the cleaned file.
#'
#' @noRd
#' @keywords internal
#'
clean_factory <- function(clean_fn, chip, hash = NULL) {
  function(path = NULL, force = FALSE) {
    checkmate::assert_string(path, null.ok = TRUE)
    if (is.null(path)) {
      return(invisible(NULL))
    }
    checkmate::assert_flag(force)
    outdir <- fs::path(get_slideimp_path(TRUE), chip)
    fs::dir_create(outdir)
    if (!fs::file_access(outdir, "write")) {
      stop("Directory is not writable: ", outdir)
    }
    outfile <- fs::path(outdir, paste0(chip, ".fst"))
    if (!fs::file_exists(outfile) || force) {
      clean_fn(path, outfile = outfile)
    }
    if (!is.null(hash) && rlang::hash_file(outfile) != hash) {
      stop(sprintf(
        paste0(
          "Hash mismatch for cleaned '%s' manifest.\n",
          "This usually means Illumina updated the upstream file.\n",
          "Try: check_ilmn_manifest_update() to see if a package update is available,\n",
          "or retry with `force = TRUE` to rebuild from the raw file."
        ),
        chip
      ))
    }
    outfile
  }
}

clean_450K <- clean_factory(
  function(path, outfile) {
    manifest <- data.table::fread(
      path,
      nrows = 485577,
      skip = 7,
      select = c("IlmnID", "CHR", "MAPINFO")
    )
    data.table::set(manifest, i = which(manifest$CHR == ""), j = "CHR", value = "0")
    names(manifest) <- c("IlmnID", "CHR_37", "MAPINFO_37")
    fst::write_fst(manifest, outfile)
  },
  "450K",
  hash = ilmn_meth_mani$hash_clean["450K"]
)

clean_EPICv1 <- clean_factory(
  function(path, outfile) {
    manifest <- data.table::fread(
      path,
      nrows = 865918,
      skip = 7,
      select = c("IlmnID", "CHR", "MAPINFO")
    )
    data.table::set(manifest, i = which(manifest$CHR == ""), j = "CHR", value = "0")
    names(manifest) <- c("IlmnID", "CHR_37", "MAPINFO_37")
    fst::write_fst(manifest, outfile)
  },
  "EPICv1",
  hash = ilmn_meth_mani$hash_clean["EPICv1"]
)

clean_EPICv2 <- clean_factory(
  function(path, outfile) {
    tempdir <- withr::local_tempdir()
    utils::unzip(
      path,
      files = "MethylationEPIC v2.0 Files/EPIC-8v2-0_A2.csv",
      exdir = tempdir
    )
    manifest <- data.table::fread(
      fs::path(tempdir, "MethylationEPIC v2.0 Files", "EPIC-8v2-0_A2.csv"),
      nrows = 937055,
      skip = 7,
      select = c("IlmnID", "Name", "CHR", "MAPINFO")
    )
    names(manifest) <- c("IlmnID", "Name", "CHR_38", "MAPINFO_38")
    fst::write_fst(manifest, outfile)
    fs::dir_delete(fs::path(tempdir, "MethylationEPIC v2.0 Files"))
  },
  "EPICv2",
  hash = ilmn_meth_mani$hash_clean["EPICv2"]
)

clean_MSA <- clean_factory(
  function(path, outfile) {
    manifest <- data.table::fread(
      path,
      nrows = 281806,
      skip = 7,
      select = c("IlmnID", "Name", "CHR", "MAPINFO")
    )
    names(manifest) <- c("IlmnID", "Name", "CHR_38", "MAPINFO_38")
    fst::write_fst(manifest, outfile)
  },
  "MSA",
  hash = ilmn_meth_mani$hash_clean["MSA"]
)

#' Retrieve Cleaned Illumina Methylation Manifest
#'
#' Retrieves the cleaned manifest for the specified Illumina methylation array chip.
#' If not already cleaned, it downloads the raw manifest, applies the appropriate
#' cleaning function, and stores the result as an .fst file.
#'
#' @inheritParams ilmn_manifest
#'
#' @return The path to the cleaned manifest file as a character string,
#' or `invisible(NULL)` if the chip is invalid.
#' @export
#'
#' @examples
#' \dontrun{
#' get_manifest("450K")
#' }
get_manifest <- function(
  chip = NULL, rawdir = NULL, force = FALSE,
  clean_up = FALSE, ask = TRUE, verbose = TRUE
) {
  checkmate::assert_string(rawdir, null.ok = TRUE, .var.name = "rawdir")
  checkmate::assert_flag(clean_up, .var.name = "clean_up")
  checkmate::assert_flag(ask, .var.name = "ask")
  checkmate::assert_flag(verbose, .var.name = "verbose")
  if (is.null(rawdir)) rawdir <- withr::local_tempdir()
  m <- msg(verbose)
  if (!is.null(chip) && chip %in% ilmn_meth_mani$chip && !force) {
    clean_path <- fs::path(get_slideimp_path(TRUE), chip, paste0(chip, ".fst"))
    expected_hash <- ilmn_meth_mani$hash_clean[chip]
    if (fs::file_exists(clean_path) && rlang::hash_file(clean_path) == expected_hash) {
      m(sprintf("Found cleaned manifest for '%s'", chip))
      return(clean_path)
    }
  }
  cleaners <- list(
    "450K" = clean_450K,
    "EPICv1" = clean_EPICv1,
    "EPICv2" = clean_EPICv2,
    "MSA" = clean_MSA
  )
  raw_path <- download_manifest(
    chip = chip, rawdir = rawdir, ask = ask, verbose = verbose
  )
  if (is.null(raw_path)) {
    return(invisible(NULL))
  }
  cleaner <- cleaners[[chip]]
  clean_path <- cleaner(path = raw_path, force = force)
  if (clean_up && fs::file_exists(raw_path)) {
    fs::file_delete(raw_path)
    m(sprintf("Cleaned up raw file: '%s'", raw_path))
  }
  return(clean_path)
}


#' Clear Cached Manifests
#'
#' Removes cleaned manifest files from the slideimp data directory.
#'
#' @inheritParams ilmn_manifest
#' @param chip Character string specifying which chip's cache to clear,
#'   or `NULL` to clear all cached manifests. Default is `NULL`.
#' @param verbose Logical. Print messages. Default is `TRUE`.
#'
#' @return Invisibly returns a character vector of deleted paths.
#' @export
#'
#' @examples
#' \dontrun{
#' clear_cache("EPICv2")
#' clear_cache()
#' }
clear_cache <- function(chip = NULL, verbose = TRUE, ask = TRUE) {
  checkmate::assert_string(chip, null.ok = TRUE)
  checkmate::assert_flag(verbose)
  checkmate::assert_flag(ask)
  m <- msg(verbose)
  cache_dir <- get_slideimp_path(create = FALSE)
  if (!fs::dir_exists(cache_dir)) {
    m("No cache directory found.")
    return(invisible(character(0)))
  }
  chips <- if (is.null(chip)) {
    ilmn_meth_mani$chip
  } else {
    if (!chip %in% ilmn_meth_mani$chip) {
      m(sprintf(
        "Unknown chip '%s'. Available: %s",
        chip, paste(sprintf("'%s'", ilmn_meth_mani$chip), collapse = ", ")
      ))
      return(invisible(character(0)))
    }
    chip
  }
  targets <- fs::path(cache_dir, chips, paste0(chips, ".fst"))
  targets <- targets[fs::file_exists(targets)]
  if (length(targets) == 0) {
    m("Nothing to clear.")
    return(invisible(character(0)))
  }
  if (ask && interactive()) {
    m(paste(
      c("The following files will be deleted:", sprintf("  - '%s'", targets)),
      collapse = "\n"
    ))
    answer <- readline("confirm deletion? [y/n]: ")
    if (!tolower(trimws(answer)) %in% c("y", "yes")) {
      m("Aborted.")
      return(invisible(character(0)))
    }
  }
  fs::file_delete(targets)
  m(paste(sprintf("Removed: '%s'", targets), collapse = "\n"))
  invisible(targets)
}

#' Load Illumina Methylation Manifest Data
#'
#' Loads the cleaned manifest data for a specified Illumina methylation array chip,
#' returning a unique data.frame with feature identifiers and their corresponding
#' chromosomal groups.
#'
#' @param chip The name of the Illumina methylation chip. If `NULL`, then all available
#' options are returned
#' @param dedupped Use deduplicated probe names for EPICv2 and MSA chips (`TRUE`)
#' or IlmnID (`FALSE`). Default is `FALSE`.
#' @param rawdir Directory where raw manifest files are downloaded and stored.
#' Defaults to NULL (a temporary directory).
#' @param force Forces re-download and re-cleaning of the manifest.
#' Default to `FALSE`.
#' @param ask Ask for permission to download or delete the cache. Default is `TRUE`.
#' @param clean_up deletes the raw manifest file after cleaning. Useful if
#' `rawdir` is not a temporary folder. Default to `FALSE`.
#' @param verbose prints messages. Default is `TRUE`.
#' @param ... Additional arguments passed to [fst::read_fst()] for reading the
#' cleaned file.
#'
#' @return A `data.frame()` with columns "feature" (probe identifiers) and
#' "group" (chromosomal locations), or `invisible(NULL)` if the chip is invalid.
#'
#' @export
#'
#' @examples
#'
#' ilmn_manifest()
#'
#' \dontrun{
#' ilmn_manifest("EPICv2")
#' }
ilmn_manifest <- function(
  chip = NULL,
  dedupped = FALSE,
  rawdir = NULL,
  force = FALSE,
  clean_up = FALSE,
  ask = TRUE,
  verbose = TRUE,
  ...
) {
  checkmate::assert_string(rawdir, null.ok = TRUE, .var.name = "rawdir")
  if (is.null(rawdir)) rawdir <- withr::local_tempdir()
  path <- get_manifest(
    chip = chip,
    rawdir = rawdir, force = force, clean_up = clean_up,
    ask = ask, verbose = verbose
  )
  if (is.null(path)) {
    return(invisible(NULL))
  }
  if (chip %in% c("450K", "EPICv1")) {
    cols <- c("IlmnID", "CHR_37")
  } else if (chip %in% c("EPICv2", "MSA")) {
    if (dedupped) {
      cols <- c("Name", "CHR_38")
    } else {
      cols <- c("IlmnID", "CHR_38")
    }
  }
  dt <- unique(fst::read_fst(path, columns = cols, as.data.table = TRUE, ...))
  names(dt) <- c("feature", "group")
  if (chip %in% c("EPICv2", "MSA")) {
    if (dedupped) {
      remove <- switch(chip, EPICv2 = EPICv2dd_excl, MSA = MSAdd_excl)
      dt <- dt[!remove, on = c("feature", "group")]
    }
  }
  stopifnot("Please report this error to pkg author"=anyDuplicated(dt$feature) == 0)
  return(dt)
}

#' Check for Manifest Updates
#'
#' Checks whether the manifest hashes pinned in this package version are still
#' current, by comparing against an authoritative index hosted outside the
#' package release cycle.
#'
#' @return Invisibly, a logical or a data.frame describing which chips are
#' out of date. Currently a placeholder.
#'
#' @noRd
#' @keywords internal
check_ilmn_manifest_update <- function() {
  # DESIGN NOTES — pin-based update check
  #
  # Goal: let users know when their installed `ilmn_meth_mani` (with its
  # pinned hash_clean values) is out of date, without forcing a package
  # reinstall every time Illumina re-uploads a file.
  #
  # Important, add min_pkg_version into the index from day one so we can change
  # the .fst files
  #
  # Proposed mechanism with {pins}:
  #
  #   1. Maintain a board on GitHub (board_url() pointed at a raw GitHub
  #      Pages URL, or board_folder() committed to a `pins/` branch). The
  #      pin is a small data.frame mirroring `ilmn_meth_mani` but with
  #      potentially newer hash_clean / version / filename / links values.
  #      Call it e.g. "ilmn_meth_mani_index".
  #
  #   2. check_ilmn_manifest_update() does:
  #         remote <- pins::pin_read(board, "ilmn_meth_mani_index")
  #         diff <- remote$hash_clean != ilmn_meth_mani$hash_clean
  #      and reports any chips where the remote hash differs.
  #
  #   3. When a diff is found, the user is told to either:
  #         (a) update the package (preferred — code + data move together,
  #             in case cleaning logic also changed), or
  #         (b) opt into the remote index for this session, which would
  #             override `ilmn_meth_mani` in-memory. Probably gated behind
  #             an explicit `use_remote = TRUE` flag — silent overrides of
  #             package data are a debugging nightmare.
  #
  # Offline / online problem on .onAttach:
  #
  #   - DO NOT call this from .onAttach unconditionally. Reasons:
  #       * CRAN/Bioc forbid network calls on attach (not relevant here
  #         since the package is GitHub-only, but still good hygiene).
  #       * Slows library() noticeably on bad connections.
  #       * Fails loudly in airgapped / HPC / CI environments where users
  #         can't do anything about it anyway.
  #       * Users running batch jobs don't want a stochastic network call
  #         in their pipeline startup.
  #
  #   - Better pattern: cache the result of the last check on disk
  #     (e.g. get_slideimp_path()/update_check.rds) with a timestamp.
  #     On attach, read the cached result only — no network. If the cache
  #     is older than N days (7? 30?) AND interactive(), print a soft
  #     packageStartupMessage() suggesting the user run
  #     check_ilmn_manifest_update() manually. The check itself only runs
  #     when the user invokes it (or get_manifest() hits a hash mismatch).
  #
  #   - Network failure inside check_ilmn_manifest_update() should be a
  #     warning(), not an error — "couldn't reach the index, using pinned
  #     values" — so offline users aren't blocked.
  #
  #   - Respect tools::R_user_dir() / get_slideimp_path() for the pins
  #     cache so we don't pollute the user's home dir, and so the {pins}
  #     cache and our .fst cache live together.
  #
  # Open questions:
  #   - Do we also want to surface *cleaning logic* version, not just data
  #     hashes? If clean_EPICv2() changes, hash_clean changes, but that's
  #     a code change that requires reinstall — the index can't fix it.
  #     Maybe the index should also carry a `min_pkg_version` field.
  #   - Rate limiting: pins handles ETag caching for board_url(), so
  #     repeat checks are cheap. Good.

  message("check_ilmn_manifest_update() is not yet implemented.")
  invisible(NULL)
}
