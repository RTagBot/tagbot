<!-- README.md is generated from README.Rmd. Please edit that file -->

# Git Tag Helper for CRAN Releases

<!-- badges: start -->

[![R-CMD-check](https://github.com/randy3k/tagbot/workflows/R-CMD-check/badge.svg)](https://github.com/randy3k/tagbot/actions)
[![codecov](https://codecov.io/gh/randy3k/tagbot/branch/master/graph/badge.svg)](https://codecov.io/gh/randy3k/tagbot)
[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/tagbot)](https://cran.r-project.org/package=tagbot)
[![](https://cranlogs.r-pkg.org/badges/grand-total/tagbot)](https://cran.r-project.org/package=tagbot)
<!-- badges: end -->

Github: <https://github.com/randy3k/tagbot>

Documentation: <https://randy3k.github.io/tagbot>

Identify which commit corresponds to a specific cran release.

## Installation

You can install the released version of tagbot from [CRAN](https://CRAN.R-project.org) with:

``` r
install.packages("tagbot")
```

And the development version from [GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("randy3k/tagbot")
```

## Example

``` r
library(tagbot)
# cd into your package repo

find_commit_to_tag(version = "0.3.0")
#> [1] "5d33096cdd9390a12398f617feee127d129a6c86"
```
