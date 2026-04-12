## code to prepare `slideimp_arrays` dataset goes here

slideimp_arrays <- c("EPICv2", "MSA", "EPICv2_deduped", "MSA_deduped", "EPICv1", "450K")

usethis::use_data(slideimp_arrays, overwrite = TRUE, internal = FALSE)
