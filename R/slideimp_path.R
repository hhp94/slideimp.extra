#' Get Path for slideimp Data
#'
#' Retrieves the path to the slideimp data directory.
#'
#' @details
#' The path is determined by:
#' \enumerate{
#'   \item Environment variable `SLIDEIMP` (if set)
#'   \item Base R default via `tools::R_user_dir("slideimp", "data")`
#' }
#'
#' To override permanently, add to your `~/.Renviron` (i.e., `file.edit("~/.Renviron")`):
#' \preformatted{
#' SLIDEIMP="/your/custom/path"
#' }
#'
#' To override temporarily, use [set_slideimp_path()].
#'
#' @param create Logical. If `TRUE`, creates the directory if it doesn't exist
#'   and checks writability. Default is `FALSE`.
#'
#' @return A character string with the normalized path.
#' @export
#'
#' @examples
#' get_slideimp_path()
#'
get_slideimp_path <- function(create = FALSE) {
  checkmate::assert_flag(create, null.ok = FALSE)

  path <- Sys.getenv("SLIDEIMP", unset = "")

  if (!nzchar(path)) {
    path <- tools::R_user_dir("slideimp", which = "data")
  }

  path <- fs::path_norm(fs::path_expand(path))

  if (create) {
    if (!fs::dir_exists(path)) {
      fs::dir_create(path, recurse = TRUE)
    }
    if (!fs::file_access(path, "write")) {
      stop("Directory is not writable: ", path, call. = FALSE)
    }
  }

  return(fs::as_fs_path(path))
}

#' Set Path for slideimp Data
#'
#' Sets the slideimp data directory path for the current R session.
#'
#' @param path Character string specifying the directory path, or `NULL` to
#'   reset to default.
#'
#' @return Invisibly returns `NULL`.
#' @export
#'
#' @examples
#' # default path
#' get_slideimp_path()
#'
#' # set path for this session
#' set_slideimp_path("test")
#' get_slideimp_path()
#'
#' # reset to default
#' set_slideimp_path(NULL)
#' get_slideimp_path()
set_slideimp_path <- function(path) {
  checkmate::assert_string(path, null.ok = TRUE)

  if (is.null(path)) {
    Sys.unsetenv("SLIDEIMP")
  } else {
    Sys.setenv(SLIDEIMP = path)
  }

  invisible(NULL)
}
