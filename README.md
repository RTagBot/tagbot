<!-- README.md is generated from README.Rmd. Please edit that file -->

# Publish GitHub Releases

<!-- badges: start -->

[![R-CMD-check](https://github.com/rtagbot/tagbot/workflows/R-CMD-check/badge.svg)](https://github.com/rtagbot/tagbot/actions)
[![test](https://github.com/rtagbot/tagbot/workflows/test/badge.svg)](https://github.com/rtagbot/tagbot/actions)
[![docker](https://github.com/rtagbot/tagbot/workflows/docker/badge.svg)](https://github.com/rtagbot/tagbot/actions)
[![codecov](https://codecov.io/gh/rtagbot/tagbot/branch/master/graph/badge.svg)](https://codecov.io/gh/rtagbot/tagbot)
[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/tagbot)](https://cran.r-project.org/package=tagbot)
[![](https://cranlogs.r-pkg.org/badges/grand-total/tagbot)](https://cran.r-project.org/package=tagbot)
<!-- badges: end -->

Github: <https://github.com/RTagBot/tagbot>

Documentation: <https://rtagbot.github.io/tagbot>

Simplify the process of making a GitHub release. There are three major features provided by ‘tagbot’. 1. It performs ‘diff’ between the source file of a release and the package’s git repo to decide which commit is corresponding to the release. 2. It generates a changelog of closed issues and merged pull requested from GitHub API. 3. It publishes a GitHub release with the changelog.

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

Here is an example of [languageserver](https://github.com/REditorSupport/languageserver).

``` r
library(tagbot)
# cd into a local git clone of `languageserver`

(release <- tagbot::find_release("0.3.5"))
#> languageserver v0.3.5 [tag:v0.3.5, sha:e3ab335]

# changelog for a particular release
tagbot::changelog(release)
#> **Closed issues:**
#> - .lintr defaults are not respected (#235)
#> - Upgrade to roxygen2 7.x (#233)
#> - respect client capability of snippetSupport (#231)
#> - Diagnostics not working for one-line document (#222)
#> - lsp crash on didOpen single file without a workspace folder (#219)
#> - diagnostics_task error on certain parsing error (#218)
#>
#> **Merged pull requests:**
#> - Respect linter_file in diagnostics (#236)
#> - Use roxygen2 7.1 (#234)
#> - Respect client snippetSupport (#232)
#> - Remove dependency on stringr (#230)
#> - Remove dependency on readr (#229)
#> - Always use content in diagnose_file (#223)
#> - Fix handling null rootUri (#221)
#> - Call diagnostics_callback on diagnostics_task error (#220)

# for dev changelog
tagbot::changelog()
#> **Closed issues:**
#> - Rmd Color coding doesn't work if there is a space after the backticks and the bracket (#255)
#> - Language server crash when open a single file without a workspace folder (#249)
#> - language server uses excessive CPU (#245)
#>
#> **Merged pull requests:**
#> - Generalize rmd chunk pattern (#256)
#> - Add a test case for null workspace root (#252)
#> - respect NAMESPACE file (#248)
#> - Run tasks with delay to reduce CPU usage on input (#246)
#> - requires collections 0.3.0 (#243)
#> - experiemental setting to disable snippets (#240)
#> - fix enclosed_by_quotes (#239)
```

## GitHub workflows

  - Check and publish github release every six hours.

Put the following in `.github/workflows/tagbot.yml`

``` yml
on:
  schedule:
    # every six hour
    - cron: 0 */6 * * *
jobs:
  publish-github-release:
    runs-on: ubuntu-latest
    container: rtagbot/tagbot:latest
    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 0
      - name: fetch all tags
        run: git fetch --depth=1 origin +refs/tags/*:refs/tags/*
      - name: check and publish release
        run: |
          tagbot::publish_release()
        shell: Rscript {0}
```

## Docker

A docker image with tagbot preinstalled in avaiable at docker [hub](https://hub.docker.com/r/rtagbot/tagbot).
