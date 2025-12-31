
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
#>        feature_id group
#> 1 cg06185909_TC11     4
#> 2 cg18975462_BC11     8
#> 3 cg20516119_TC11    11
#> 4 cg10149399_BC11     6
#> 5 cg24004665_BC11    10
#> 6 cg12923664_BC11     8
# simulate some data
obj <- matrix(runif(10 * 20), nrow = 10, dimnames = list(seq_len(10), sample(msa$feature_id, size = 20)))
obj[1:5, 1:5]
#>   cg06073471_TC21 cg12391831_BC21 cg07906638_TC21 cg26682661_TC21
#> 1       0.6288666      0.05310159       0.1474317      0.01799378
#> 2       0.4261539      0.03797024       0.7840605      0.15483424
#> 3       0.1805790      0.07739894       0.8004576      0.97651777
#> 4       0.7118276      0.08357818       0.2607879      0.41817655
#> 5       0.3911712      0.77349369       0.4773668      0.84309656
#>   cg12687696_BC21
#> 1      0.78255899
#> 2      0.07970414
#> 3      0.60911729
#> 4      0.08739387
#> 5      0.58904865
group_df <- group_features(obj, msa)
group_df
#> # A tibble: 10 × 2
#>    features  group
#>    <list>    <chr>
#>  1 <chr [1]> 12   
#>  2 <chr [3]> 17   
#>  3 <chr [1]> 19   
#>  4 <chr [2]> 2    
#>  5 <chr [3]> 3    
#>  6 <chr [2]> 4    
#>  7 <chr [2]> 5    
#>  8 <chr [1]> 7    
#>  9 <chr [3]> 8    
#> 10 <chr [2]> X
```
