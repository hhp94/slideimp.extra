test_that("dedup_matrix correctly deduplicates CpGs using mean", {
  manifest <- data.frame(
    IlmnID = c("probe_A1", "probe_B1", "probe_C1", "probe_C2", "probe_D1", "probe_D2"),
    Name   = c("CpG_A", "CpG_B", "CpG_C", "CpG_C", "CpG_D", "CpG_D")
  )
  input_mat <- matrix(
    runif(18),
    nrow = 3,
    byrow = TRUE,
    dimnames = list(
      c("sample_1", "sample_2", "sample_3"),
      c("probe_A1", "probe_B1", "probe_C1", "probe_C2", "probe_D1", "probe_D2")
    )
  )
  expected_mat <- cbind(
    CpG_A = input_mat[, "probe_A1"],
    CpG_B = input_mat[, "probe_B1"],
    CpG_C = rowMeans(input_mat[, c("probe_C1", "probe_C2")]),
    CpG_D = rowMeans(input_mat[, c("probe_D1", "probe_D2")])
  )
  result <- dedup_matrix(input_mat, chip = manifest, method = "mean", verbose = FALSE)
  result <- result[, colnames(expected_mat)]
  expect_equal(result, expected_mat)
})

