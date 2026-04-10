## code to prepare `links` dataset goes here

ilmn_meth_mani <- tibble::tibble(
  chip = c("450K", "EPICv1", "EPICv2", "MSA"),
  links = c(
    "https://webdata.illumina.com/downloads/productfiles/humanmethylation450/humanmethylation450_15017482_v1-2.csv",
    "https://webdata.illumina.com/downloads/productfiles/methylationEPIC/infinium-methylationepic-v-1-0-b5-manifest-file-csv.zip",
    "https://support.illumina.com/content/dam/illumina-support/documents/downloads/productfiles/methylationepic/InfiniumMethylationEPICv2.0ProductFiles(ZIPFormat).zip",
    "https://support.illumina.com/content/dam/illumina-support/documents/downloads/productfiles/infiniummethylationscreening/MSA-48v1-0_20102838_A1.csv"
  ),
  version = c(
    "v1-2",
    "v-1-0-b5",
    "v2-0_A2",
    "v1-0_20102838_A1"
  ),
  filename = c(
    "humanmethylation450_15017482_v1-2.csv",
    "infinium-methylationepic-v-1-0-b5-manifest-file-csv.zip",
    "InfiniumMethylationEPICv2.0ProductFiles(ZIPFormat).zip",
    "MSA-48v1-0_20102838_A1.csv"
  ),
  hash_clean = c(
    "db5ddfd542306dd0cc7ec5be56daf37e",
    "aec2953466c178adee40bd8fba1f398e",
    "8d98377bcd507face7d3f0ae4d6ce08f",
    "180adee711c105e45593c0335c794c54"
  )
)

ilmn_meth_mani <- dplyr::mutate(
  ilmn_meth_mani,
  dplyr::across(.cols = dplyr::everything(), .fns = \(x) purrr::set_names(x, chip))
)

usethis::use_data(ilmn_meth_mani, overwrite = TRUE, internal = TRUE)
