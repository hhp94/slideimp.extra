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
}
