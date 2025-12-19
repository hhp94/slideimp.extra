ilmn_meth_mani

# 1 version/manifest only
download_manifest <- function(chip = NULL, rawdir = NULL) {
  checkmate::assert_string(chip, null.ok = TRUE)
  checkmate::assert_string(rawdir, null.ok = TRUE)

  if (is.null(chip) || !chip %in% ilmn_meth_mani$chip) {
    message(sprintf(
      "Invalid chip '%s'. Available options are: %s",
      if (is.null(chip)) "NULL" else chip,
      paste(sprintf("'%s'", ilmn_meth_mani$chip), collapse = ", ")
    ))
    return(invisible(NULL))
  }

  if (is.null(rawdir)) {
    message("Argument 'rawdir' must be specified.")
    return(invisible(NULL))
  }

  url <- ilmn_meth_mani$links[chip]
  fn <- ilmn_meth_mani$filename[chip]
  hs <- ilmn_meth_mani$hash[chip]
  fn_path <- fs::path(rawdir, fn)

  tryCatch(
    {
      dl <- TRUE

      if (fs::file_exists(fn_path)) {
        current_hash <- rlang::hash_file(fn_path)
        if (current_hash == hs) {
          message(sprintf("Cache found for '%s' at '%s'", chip, fn_path))
          dl <- FALSE
        } else {
          message(sprintf("Hash mismatch for '%s', re-downloading...", chip))
        }
      } else {
        message(sprintf("'%s' manifest not found, downloading...", chip))
      }

      if (dl) {
        download.file(url = url, destfile = fn_path, mode = "wb")

        if (rlang::hash_file(fn_path) != hs) {
          warning(sprintf("Hash verification failed for '%s'", chip))
        } else {
          message(sprintf("Successfully downloaded '%s' manifest", chip))
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

rlang::hash_file("temp/MSA-48v1-0_20102838_A1.csv")
download_manifest("450K")

use_package("withr")
