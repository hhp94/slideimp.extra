
<!-- README.md is generated from README.Rmd. Please edit that file -->

# slideimp.extra

<!-- badges: start -->

<!-- badges: end -->

`{slideimp.extra}` contains helpful tools for
[`{slideimp}`](https://github.com/hhp94/slideimp) such as the
downloading of Illumina manifests for the `slideimp::group_features()`
function.

## Installation

You can install the development version of `{slideimp.extra}` with
`{pak}` or `remotes::install_github()`:

``` r
pak::pak("hhp94/slideimp.extra")
```

## Path Management

The `slideimp` package manages its data directory path via the
environment variable `SLIDEIMP`, with options for session-based or
consistent overrides.

``` r
# **Get default path**:
get_slideimp_path()
# **Create and verify writable path**:
get_slideimp_path(create = TRUE)
# **Set temporary path for session**:
set_slideimp_path("/your/custom/path")
# **Reset to default**:
set_slideimp_path(NULL)
```

- **Consistent override**: Add to `~/.Renviron` (i.e.,
  `file.edit("~/.Renviron")`) and reset your R session:

``` bash
SLIDEIMP=/your/custom/path
```

## Download Manifests

Use `ilmn_manifest()` to download the included manifests. Run without an
argument to print available options:

``` r
ilmn_manifest()
#> Selected 'NULL'. Available options are: '450K', 'EPICv1', 'EPICv2', 'MSA'
```

The first time the function is called for a manifest, it attempts to
download, clean, and store it under the path at `get_slideimp_path()`.

``` r
# Download and clean the MSA manifest and store the object at `get_slideimp_path()`
ilmn_manifest("MSA")
# Download 'MSA' manifest? [y/n]: y
```

The path to the cleaned manifest can be fetched with `get_manifest()`.

``` r
get_manifest("MSA")
```

We can now read the manifest into memory and use it with the
`slideimp::group_features()` function from `{slideimp}` to perform
grouped imputation with `slideimp::group_imp()`.

``` r
library(slideimp)
msa <- ilmn_manifest("MSA")
head(msa)
#           feature group
# 1 cg06185909_TC11     4
# 2 cg18975462_BC11     8
# 3 cg20516119_TC11    11
# 4 cg10149399_BC11     6
# 5 cg24004665_BC11    10
# 6 cg12923664_BC11     8
# simulate some data
obj <- matrix(runif(10 * 20), nrow = 10, dimnames = list(seq_len(10), sample(msa$feature, size = 20)))
obj[1:4, 1:4]
#   cg04747704_TC21 cg20470442_BC11 cg23607994_BC11 cg00464814_TC21
# 1      0.09159897       0.7819234       0.8687001       0.4644673
# 2      0.32974132       0.4722311       0.4081508       0.5321599
# 3      0.01260905       0.9077130       0.2654032       0.7748766
# 4      0.11912636       0.6653247       0.4493103       0.2432860
group_df <- group_features(obj, msa)
head(group_df)
# # A tibble: 6 × 2
#   feature   group
#   <list>    <chr>
# 1 <chr [1]> 1    
# 2 <chr [1]> 10   
# 3 <chr [1]> 11   
# 4 <chr [1]> 14   
# 5 <chr [3]> 15   
# 6 <chr [2]> 18 
```

Clear the downloaded files with `clear_cache()`

``` r
clear_cache()
# ask deletion? [y/n]: y
# Removed cache: 'MSA'
```
