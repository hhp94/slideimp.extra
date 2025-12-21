msg <- function(verbose) {
  function(...) if (verbose) message(...)
}

#' Download Raw Illumina Methylation Manifest
#'
#' Downloads the raw manifest file for a specified Illumina methylation array chip.
#' It checks for existing files and verifies integrity using a pre-defined hash.
#' If the file is missing or the hash mismatches, it re-downloads the file.
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
download_manifest <- function(chip = NULL, rawdir = withr::local_tempdir(), verbose = TRUE) {
  checkmate::assert_string(chip, null.ok = TRUE, .var.name = "chip")
  checkmate::assert_string(rawdir, null.ok = FALSE, .var.name = "rawdir")
  checkmate::assert_flag(verbose, null.ok = FALSE, .var.name = "verbose")
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
  hs <- ilmn_meth_mani$hash_raw[chip]
  fn_path <- fs::path(rawdir, fn)
  tryCatch(
    {
      dl <- TRUE
      if (fs::file_exists(fn_path)) {
        if (rlang::hash_file(fn_path) == hs) {
          m(sprintf("Cache found for '%s' at '%s'", chip, fn_path))
          dl <- FALSE
        } else {
          m(sprintf("Hash mismatch for '%s', re-downloading...", chip))
        }
      } else {
        m(sprintf("'%s' manifest not found, downloading...", chip))
      }
      if (dl) {
        utils::download.file(url = url, destfile = fn_path, mode = "wb", quiet = !verbose)
        if (rlang::hash_file(fn_path) != hs) {
          stop(sprintf("Hash verification failed for '%s'", chip))
        } else {
          m(sprintf("Successfully downloaded '%s' manifest", chip))
        }
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
      stop("Hash mismatch. Retry with `force = TRUE`")
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
  chip = NULL, rawdir = withr::local_tempdir(), force = FALSE,
  clean_up = FALSE, verbose = TRUE
) {
  checkmate::assert_flag(clean_up, .var.name = "clean_up")
  checkmate::assert_flag(verbose, .var.name = "verbose")
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
  raw_path <- download_manifest(chip = chip, rawdir = rawdir, verbose = verbose)
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
#' Defaults to a temporary directory.
#' @param force Forces re-download and re-cleaning of the manifest.
#' Default to `FALSE`.
#' @param clean_up deletes the raw manifest file after cleaning. Useful if
#' `rawdir` is not a temporary folder. Default to `FALSE`.
#' @param verbose prints messages. Default is `TRUE`.
#' @param ... Additional arguments passed to [fst::read_fst()] for reading the
#' cleaned file.
#'
#' @return A `data.frame()` with columns "feature_id" (probe identifiers) and
#' "group" (chromosomal locations), or `invisible(NULL)` if the chip is invalid.
#'
#' @export
#'
#' @examples
#'
#' ilmn_manifest()
#'
#' \dontrun{
#' ilmn_manifest("EPICv2", dedupped = TRUE)
#' }
ilmn_manifest <- function(
  chip = NULL,
  dedupped = FALSE,
  rawdir = withr::local_tempdir(),
  force = FALSE,
  clean_up = FALSE,
  verbose = TRUE,
  ...
) {
  path <- get_manifest(
    chip = chip,
    rawdir = rawdir, force = force, clean_up = clean_up, verbose = verbose
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
  dt <- unique(fst::read_fst(path, columns = cols, ...))
  names(dt) <- c("feature_id", "group")
  return(dt)
}

fn <- function() {
  data.table::fread
}
