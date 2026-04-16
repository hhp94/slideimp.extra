utils::globalVariables(c(".N", "IlmnID", "N", "value"))

#' @import data.table
NULL

.onLoad <- function(libname, pkgname) {
  ns <- asNamespace(pkgname)
  for (nm in c("EPICv2dd_excl", "MSAdd_excl")) {
    if (exists(nm, envir = ns, inherits = FALSE)) {
      data.table::setalloccol(get(nm, envir = ns))
    }
  }

  if (requireNamespace("slideimp", quietly = TRUE)) {
    slideimp::register_group_resolver(function(group) {
      checkmate::assert_choice(group, choices = slideimp_arrays)
      deduped <- group %in% c("EPICv2_deduped", "MSA_deduped")
      if (deduped) {
        group <- switch(group, EPICv2_deduped = "EPICv2", MSA_deduped = "MSA")
      }
      ilmn_manifest(chip = group, deduped = deduped)
    })
  }
}
