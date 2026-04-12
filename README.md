
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
```

Clear the downloaded files with `clear_cache()`

``` r
clear_cache()
# The following files will be deleted:
#   - 'dev/MSA/MSA.fst'
# confirm deletion? [y/n]: y
```
