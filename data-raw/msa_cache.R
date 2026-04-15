## code to prepare `msa_cache` dataset goes here

set_slideimp_path("dev")

msa_cache <- ilmn_manifest("MSA")
msa_cache <- msa_cache[!group %in% c("M", "0"), ]

saveRDS(msa_cache$feature, here::here("inst/extdata/msa_cache.rds"), compress = "xz")
