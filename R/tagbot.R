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



github_closed_issues_from_commits <- function(commits) {
    commits %>%
        map("message") %>%
        map(github_closed_issues_from_message) %>%
        as_vector()
}


github_closed_issues <- function(since, until) {
    commits <- git_log(glue("{trimws(since)}..{trimws(until)}"))

    hashes <- map_chr(commits, "sha")

    since <- commits %>% pluck(length(.), "time")
    issues <- github_issues(since = since)

    prs <- issues %>%
        keep(~ hasName(., "pull_request")) %>%
        keep(function(issue) {
            pr <- github_pull_request(issue$number)
            pr$merged && pr$merge_commit_sha %in% hashes
        })

    closed_by_prs <- prs %>%
        map(list("body", github_closed_issues_from_message)) %>%
        flatten_chr()

    closed_by_commits <- github_closed_issues_from_commits(commits)

    numbers <- sort(union(closed_by_prs, closed_by_commits))

    closed_issues <- issues %>%
        keep(~.$number %in% numbers) %>%
        map(~list(number = .$number, title = .$title, body = .$body))
    merged_prs <- prs %>%
        discard(~.$number %in% numbers) %>%
        map(~list(number = .$number, title = .$title, body = .$body))
    list(issues = closed_issues, pull_requests = merged_prs)
}


#' Automatically create a github release from CRAN release
#' @param version the version to search. Use `NULL` to search the latest release version.
#' @export
tagbot <- function(version = NULL) {
    releases <- pkg_releases()
    release <- find_release(version = version, releases = releases)
    tag_name <- paste0("v", release$version)

    # check if github has the release
    if (github_has_release(tag_name)) {
        message(glue("version {release$version} was released already!"))
        return(invisible(NULL))
    }
    if (length(releases) == 1) {
        merge_base <- git::git("rev-list", "--max-parents=0", "HEAD")
    } else {
        prev_release <- attr(release, "previous")
        if (is.null(prev_release)) {
            stop("cannot determine previous release")
        }
        merge_base <- git::git("merge-base", prev_release$sha, "HEAD")
    }
    issues <- github_closed_issues(merge_base, release$sha)
    tag_msg <- paste0(release$package, " v", release$version, "\n\n")
    if (length(issues$issues) > 0) {
        tag_msg <- paste0(
            tag_msg,
            "**Closed issues:**\n",
            paste0(issues$issues %>%
                        map(~glue("- {.$title} (#{.$number})")), collapse = "\n"),
            "\n\n"
        )
    }
    if (length(issues$pull_requests) > 0) {
        tag_msg <- paste0(
            tag_msg,
            "**Merged pull requests:**\n",
            paste0(issues$pull_requests %>%
                        map(~glue("- {.$title} (#{.$number})")), collapse = "\n"),
            "\n\n"
        )
    }
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
    message(glue("tag {tag} was created successfully\n{status$html_url}"))
}
