<!-- README.md is generated from README.Rmd. Please edit that file -->

# Git Tag Helper for CRAN Releases

<!-- badges: start -->

[![R-CMD-check](https://github.com/rtagbot/tagbot/workflows/R-CMD-check/badge.svg)](https://github.com/rtagbot/tagbot/actions)
[![codecov](https://codecov.io/gh/rtagbot/tagbot/branch/master/graph/badge.svg)](https://codecov.io/gh/rtagbot/tagbot)
[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/tagbot)](https://cran.r-project.org/package=tagbot)
[![](https://cranlogs.r-pkg.org/badges/grand-total/tagbot)](https://cran.r-project.org/package=tagbot)
<!-- badges: end -->

Github: <https://github.com/RTagBot/tagbot>

Documentation: <https://rtagbot.github.io/tagbot>

Identify which commit corresponds to a specific cran release.

## Installation

You can install the released version of tagbot from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("tagbot")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rtagbot/tagbot")
```

## Example

``` r
library(tagbot)
# cd into your package repo

find_release(version = "0.3.1")
#> $version
#> [1] "0.3.1"
#> 
#> $url
#> [1] "https://cran.rstudio.com/src/contrib/collections_0.3.1.tar.gz"
#> 
#> $release_time
#> [1] NA
#> 
#> $latest
#> [1] TRUE
#> 
#> $tag
#> [1] "v0.3.1"
#> 
#> $tag_time
#> [1] "2020-04-30 03:32:56 UTC"
#> 
#> $sha
#> [1] "30341faa249dfd52aa35849081a9e253fee748d9"
```

## Docker

A docker image with tagbot preinstalled in avaiable at docker [hub](https://hub.docker.com/r/rtagbot/tagbot).
