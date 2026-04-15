## code to prepare `msa_cache` dataset goes here

set_slideimp_path("dev")

msa_cache <- ilmn_manifest("MSA")$feature

saveRDS(msa_cache, here::here("inst/extdata/msa_cache.rds"), compress = "xz")
