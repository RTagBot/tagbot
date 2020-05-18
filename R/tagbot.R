#' @docType package
#' @importFrom utils available.packages download.file untar capture.output hasName
#' @import purrr
#' @importFrom glue glue
#' @importFrom git git
"_PACKAGE"


## quiets concerns of R CMD check re: the .'s that appear in pipelines
# from https://github.com/jennybc/googlesheets/blob/master/R/googlesheets.R
utils::globalVariables(c("."))


#' @export
tagbot <- function() {
    release <- find_release()
    prev_release <- attr(release, "previous")
    merge_base <- git::git("merge-base", prev_release$sha, "HEAD")
    github_closed_issues(merge_base, "HEAD")
}
