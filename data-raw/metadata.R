# Metadata ----
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

# List of rows to remove for EPICv2 and MSA deduped ----
library(data.table)
library(fst)
library(slideimp)
set_slideimp_path("dev")

## EPICv2
EPICv2 <- read_fst(get_manifest("EPICv2", rawdir = "dev"), as.data.table = TRUE)
EPICv2dd <- unique(EPICv2[, list(feature = Name, group = CHR_38)])
EPICv2dd
# a couple of probes that maps to chr 0 and other chr
EPICv2dd[feature %in% EPICv2dd[, .N, by = feature][N > 1, feature]]
EPICv2dd_excl <- EPICv2dd[feature %in% EPICv2dd[, .N, by = feature][N > 1, feature]][group == "0", ]
EPICv2dd_excl

## MSA
MSA <- read_fst(get_manifest("MSA", rawdir = "dev"), as.data.table = TRUE)
MSAdd <- unique(MSA[, list(feature = Name, group = CHR_38)])
# it's just a couple of probes that maps to both chr 0 and something else.
dcast(MSAdd[feature %in% MSAdd[, .N, by = feature][N > 1, feature]], feature ~ group)
all(
  dcast(MSAdd[feature %in% MSAdd[, .N, by = feature][N > 1, feature]], feature ~ group) |> is.na() |> rowSums()
  == 4
)

MSAdd_excl <- MSAdd[feature %in% MSAdd[, .N, by = feature][N > 1, feature]][group == "0", ]
MSAdd_excl

## Test it out
EPICv2_clean <- EPICv2dd[!EPICv2dd_excl, on = c("feature", "group")]

cn <- EPICv2[, unique(Name)]
sim_mat <- matrix(rnorm(10 * length(cn)), dimnames = list(NULL, cn), ncol = length(cn), nrow = 10)

prep_groups(colnames(sim_mat), group = EPICv2_clean) |> print(n = Inf)

MSA_clean <- MSAdd[!MSAdd_excl, on = c("feature", "group")]

cn <- MSA[, unique(Name)]
sim_mat <- matrix(rnorm(10 * length(cn)), dimnames = list(NULL, cn), ncol = length(cn), nrow = 10)

prep_groups(colnames(sim_mat), group = MSA_clean) |> print(n = Inf)

# Export ----
usethis::use_data(ilmn_meth_mani, MSAdd_excl, EPICv2dd_excl, overwrite = TRUE, internal = TRUE)
