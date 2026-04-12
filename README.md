
<!-- README.md is generated from README.Rmd. Please edit that file -->

# slideimp.extra

<!-- badges: start -->

<!-- badges: end -->

`{slideimp.extra}` contains helpful tools for
[`{slideimp}`](https://github.com/hhp94/slideimp) such as the
downloading of Illumina manifests for the `slideimp::prep_groups()`
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
`slideimp::prep_groups()` function from `{slideimp}` to perform grouped
imputation with `slideimp::group_imp()`.

``` r
library(slideimp)
set.seed(1234)
msa <- ilmn_manifest("MSA")
#> Found cleaned manifest for 'MSA'
head(msa)
#>            feature  group
#>             <char> <char>
#> 1: cg06185909_TC11      4
#> 2: cg18975462_BC11      8
#> 3: cg20516119_TC11     11
#> 4: cg10149399_BC11      6
#> 5: cg24004665_BC11     10
#> 6: cg12923664_BC11      8
#           feature group
# 1 cg06185909_TC11     4
# 2 cg18975462_BC11     8
# 3 cg20516119_TC11    11
# 4 cg10149399_BC11     6
# 5 cg24004665_BC11    10
# 6 cg12923664_BC11     8

# simulate some data
obj <- matrix(
  runif(10 * 20),
  nrow = 10,
  dimnames = list(seq_len(10), sample(msa$feature, size = 20))
)

obj[1:4, 1:4]
#>   cg17139861_TC21 cg06879777_TC21 cg23447905_BC21 cg12347757_TC11
#> 1       0.1137034       0.6935913      0.31661245       0.4560915
#> 2       0.6222994       0.5449748      0.30269337       0.2651867
#> 3       0.6092747       0.2827336      0.15904600       0.3046722
#> 4       0.6233794       0.9234335      0.03999592       0.5073069
#   cg04747704_TC21 cg20470442_BC11 cg23607994_BC11 cg00464814_TC21
# 1      0.09159897       0.7819234       0.8687001       0.4644673
# 2      0.32974132       0.4722311       0.4081508       0.5321599
# 3      0.01260905       0.9077130       0.2654032       0.7748766
# 4      0.11912636       0.6653247       0.4493103       0.2432860

group_df <- prep_groups(colnames(obj), msa)
#> Groups 1, 3, 6, 7, 9, 12, 14, 15, 16, 19, 20, 22, 23, 24, 25, 26 dropped: no features remaining after matching obj columns.
head(group_df)
#> # slideimp table: 6 x 4
#>  group         feature             aux parameters
#>      1 <character [1]> <character [0]> <list [0]>
#>     11 <character [1]> <character [0]> <list [0]>
#>     12 <character [1]> <character [0]> <list [0]>
#>     15 <character [1]> <character [0]> <list [0]>
#>     17 <character [4]> <character [0]> <list [0]>
#>     18 <character [2]> <character [0]> <list [0]>
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
# The following files will be deleted:
#   - 'dev/MSA/MSA.fst'
# confirm deletion? [y/n]: y
```
