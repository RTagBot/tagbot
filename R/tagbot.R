#' @docType package
#' @importFrom utils available.packages download.file untar capture.output hasName
#' @import purrr
#' @importFrom glue glue
#' @importFrom git git
#' @aliases NULL
"_PACKAGE"


## quiets concerns of R CMD check re: the .'s that appear in pipelines
# from https://github.com/jennybc/googlesheets/blob/master/R/googlesheets.R
utils::globalVariables(c("."))


#' Publish a github release based on CRAN or CRAN-like releases
#' @param version the version to publish. Use `NULL` to publish the latest release.
#' @export
publish_release <- function(version = NULL) {
    release <- find_release(version = version)
    tag_name <- paste0("v", release$version)

    # check if github has the release
    if (github_has_release(tag_name)) {
        message(glue("Release {release$version} was published already!"))
        return(invisible(NULL))
    }

    pkgnm <- pkg_name()
    new_release <- length(pkg_releases(pkgnm)) <= 1

    chlog <- changelog(release, new_release = new_release)
    tag_msg <- paste0(
        tag_name,
        "\n\n",
        format_changelog(chlog))

    ghrepo <- github_repo()
    status <- gh::gh(
        "POST /repos/:owner/:repo/releases",
        owner = ghrepo$owner,
        repo = ghrepo$repo,
        tag_name = tag_name,
        target_commitish = release$sha,
        name = paste0(release$package, " v", release$version),
        body = tag_msg
    )
    message(glue("Release {tag_name} was published successfully\n{status$html_url}"))
}
