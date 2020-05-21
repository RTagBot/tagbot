#' Show the closed github issues and merged pull requests between commits.
#' @param after character, the start commit
#' @param before character, the end commit
#' @export
changelog_between <- function(after, before = "HEAD") {
    commits <- git_log(glue("{trimws(after)}..{trimws(before)}"))

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
        map(list("body", github_extract_issues)) %>%
        flatten_chr()

    closed_by_commits <- commits %>%
        map("message") %>%
        map(github_extract_issues) %>%
        as_vector()

    numbers <- sort(union(closed_by_prs, closed_by_commits))

    closed_issues <- issues %>%
        keep(~.$number %in% numbers) %>%
        map(~list(number = .$number, title = .$title, body = .$body))
    merged_prs <- prs %>%
        discard(~.$number %in% numbers) %>%
        map(~list(number = .$number, title = .$title, body = .$body))
    structure(
        list(issues = closed_issues, pull_requests = merged_prs), class = "changelog"
    )
}


#' Show changelog of a particular release
#' @param release the result of `find_release`
#' @param new_release is it the first release?
#' @export
changelog <- function(release, new_release = FALSE) {
    if (new_release) {
        after <- git::git("rev-list", "--max-parents=0", "HEAD")
    } else {
        prev_release <- attr(release, "previous")
        if (is.null(prev_release)) {
            stop("cannot determine previous release")
        }
        after <- git::git("merge-base", prev_release$sha, "HEAD")
    }
    changelog_between(after, release$sha)
}



format_changelog <- function(chlog) {
    msg <- ""
    if (length(chlog$issues) > 0) {
        msg <- paste0(
            msg,
            "**Closed issues:**\n",
            paste0(chlog$issues %>%
                        map(~glue("- {.$title} (#{.$number})")), collapse = "\n"),
            "\n"
        )
    }
    if (length(chlog$pull_requests) > 0) {
        if (length(chlog$issues) > 0) {
            msg <- paste0(msg, "\n")
        }
        msg <- paste0(
            msg,
            "**Merged pull requests:**\n",
            paste0(chlog$pull_requests %>%
                        map(~glue("- {.$title} (#{.$number})")), collapse = "\n"),
            "\n\n"
        )
    }
    msg
}


#' @export
#' @method print changelog
print.changelog <- function(x, ...) {
    cat(format_changelog(x))
}