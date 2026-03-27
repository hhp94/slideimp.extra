
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
#> Found cleaned manifest for 'MSA'
head(msa)
#>          features group
#> 1 cg06185909_TC11     4
#> 2 cg18975462_BC11     8
#> 3 cg20516119_TC11    11
#> 4 cg10149399_BC11     6
#> 5 cg24004665_BC11    10
#> 6 cg12923664_BC11     8
# simulate some data
obj <- matrix(runif(10 * 20), nrow = 10, dimnames = list(seq_len(10), sample(msa$features, size = 20)))
obj[1:4, 1:4]
#>   cg14302909_TC22 cg27125641_BC21 cg09643312_TC21 cg20043937_TC21
#> 1       0.4841736       0.5346202       0.9785727       0.6110280
#> 2       0.4191149       0.9988116       0.9976588       0.4657359
#> 3       0.2546880       0.4220848       0.8610029       0.3019090
#> 4       0.7868505       0.7702517       0.5032576       0.3093622
group_df <- group_features(obj, msa)
head(group_df)
#> # A tibble: 6 × 2
#>   features  group
#>   <list>    <chr>
#> 1 <chr [1]> 1    
#> 2 <chr [1]> 10   
#> 3 <chr [1]> 11   
#> 4 <chr [1]> 12   
#> 5 <chr [2]> 14   
#> 6 <chr [1]> 15
```

Clear the downloaded files with `clear_cache()`

``` r
clear_cache()
# Removed cache: 'MSA'
```
