#' De-duplicate Matrix
#'
#' The `EPICv2` and `MSA` chips can return duplicated CpG names. This function de-duplicate
#' the beta matrix.
#'
#' @param obj A numeric matrix with unique column and row names.
#' @param chip Either "MSA", "EPICv2", or a data.frame with `IlmnID` and `Name` columns.
#' @param method Aggregation method for duplicates: "mean" or "median".
#' @param verbose Logical; if TRUE, print informative messages.
#'
#' @return A de-duplicated matrix.
#' @export
#' @import data.table
dedup_matrix <- function(obj, chip, method = c("mean", "median"), verbose = TRUE) {
  method <- match.arg(method)
  method <- if (method == "mean") mean else stats::median

  checkmate::assert_matrix(
    obj,
    mode = "numeric",
    col.names = "unique",
    row.names = "unique",
    null.ok = FALSE,
    .var.name = "obj"
  )

  stopifnot(
    "please remove column `__sample_id__` from `obj`" = !"__sample_id__" %in% colnames(obj)
  )

  checkmate::assert(
    checkmate::check_choice(chip, choices = c("MSA", "EPICv2")),
    checkmate::check_data_frame(chip, min.cols = 1),
    null.ok = FALSE,
    .var.name = "chip"
  )

  if (is.data.frame(chip)) {
    stopifnot(
      "if 'chip' is a data.frame, it must have the `IlmnID` and `Name` columns" =
        all(c("IlmnID", "Name") %in% names(chip))
    )
    if (!is.data.table(chip)) {
      chip <- as.data.table(chip)
    }
  } else {
    chip <- fst::read_fst(
      get_manifest(chip, verbose = verbose),
      as.data.table = TRUE,
      columns = c("IlmnID", "Name")
    )
  }

  setkeyv(chip, cols = "IlmnID")
  chip <- chip[colnames(obj), nomatch = NULL, on = "IlmnID"]

  if (nrow(chip) == 0) {
    stop(
      "None of the colnames(obj) found in the indicated manifest. ",
      "Has this matrix already been dedupped or is it on a different chip?"
    )
  }

  nomatch <- setdiff(colnames(obj), chip[["IlmnID"]])
  if (length(nomatch) > 0) {
    warning(sprintf("%d column(s) not found in the provided chip manifest", length(nomatch)))
  }

  # handle duplicated part
  dupped <- chip[, .N, by = "Name"][N > 1, ]

  if (nrow(dupped) == 0) {
    if (verbose) message("No duplicated CpGs found")
    return(obj)
  }

  dupped_manifest <- chip[dupped, on = "Name"]

  dupped_matrix <- as.data.table(
    obj[, dupped_manifest[["IlmnID"]]],
    keep.rownames = "__sample_id__"
  )

  dupped_matrix <- melt(
    dupped_matrix,
    id.vars = "__sample_id__",
    variable.factor = FALSE,
    variable.name = "IlmnID",
    na.rm = TRUE
  )

  dupped_matrix <- merge(dupped_matrix, dupped_manifest, by = "IlmnID")

  dedupped_matrix <- dupped_matrix[,
    list(value = method(value, na.rm = TRUE)),
    by = c("__sample_id__", "Name")
  ]

  dedupped_matrix <- dcast(
    dedupped_matrix,
    formula = `__sample_id__` ~ Name,
    value.var = "value"
  )

  dedupped_matrix <- as.matrix(dedupped_matrix, rownames = "__sample_id__")
  new_row_names <- row.names(dedupped_matrix)

  # non dup CpGs
  single_manifest <- chip[!IlmnID %in% dupped_manifest[["IlmnID"]]]
  single_matrix <- obj[new_row_names, single_manifest[["IlmnID"]]]
  colnames(single_matrix) <- single_manifest$Name

  return(cbind(single_matrix, dedupped_matrix, obj[new_row_names, nomatch])[row.names(obj), ])
}
