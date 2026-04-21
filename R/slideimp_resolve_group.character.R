#' Resolve a chip name to a manifest data.frame
#'
#' Method for [slideimp::slideimp_resolve_group()] that handles character
#' input by looking up the corresponding Illumina manifest.
#'
#' @param x A character scalar naming a supported chip (see
#' `slideimp_arrays`).
#'
#' @return A data.frame with `feature` and related manifest columns.
#'
#' @examples
#'
#' \dontrun{
#' slideimp::slideimp_resolve_group("EPICv2")
#' }
#'
#' @keywords internal
#' @exportS3Method slideimp::slideimp_resolve_group
slideimp_resolve_group.character <- function(x) {
  checkmate::assert_choice(x, choices = slideimp_arrays)
  deduped <- x %in% c("EPICv2_deduped", "MSA_deduped")
  if (deduped) {
    x <- switch(x,
      EPICv2_deduped = "EPICv2",
      MSA_deduped = "MSA"
    )
  }
  ilmn_manifest(chip = x, deduped = deduped)
}

#' @importFrom slideimp slideimp_resolve_group
NULL
