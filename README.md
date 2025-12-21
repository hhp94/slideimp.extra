
<!-- README.md is generated from README.Rmd. Please edit that file -->

# slideimp.extra

<!-- badges: start -->

<!-- badges: end -->

`{slideimp.extra}` contains helpful tools for
[`{slideimp}`](https://github.com/hhp94/slideimp) such as the
downloading of Illumina manifests for the `slideimp::group_features()`
function.

## Installation

You can install the development version of slideimp.extra with `{pak}`
or `remotes::install_github()`:

``` r
# install.packages("pak")
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

``` r
SLIDEIMP <- "/your/custom/path"
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
# simulate some data
obj <- matrix(runif(10*20), nrow = 10, dimnames = list(seq_len(10), sample(msa$feature_id, size = 20)))
obj[1:5, 1:5]
group_df <- group_features(obj, msa)
group_df
```
