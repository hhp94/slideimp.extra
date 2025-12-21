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
  hash_raw = c(
    "052e360bfe68b249dab782cfb5a70b06",
    "045b7b261943ec623ac850f033c528bf",
    "950a4e10b191b919d241a3bbee536786",
    "6f2ec1fd41060a39a23942fc94a2ea4c"
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
