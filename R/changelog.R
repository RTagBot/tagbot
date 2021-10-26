#' Show the closed github issues and merged pull requests between commits.
#' @param ref character, revision range
#' @export
changelog_between <- function(ref) {
    commits <- git_log(ref)

    chlog <- structure(
        list(issues = list(), pull_requests = list()), class = "changelog"
    )

    if (length(commits) == 0) {
        return(chlog)
    }

    hashes <- map_chr(commits, "sha")

    since <- commits %>% pluck(length(.), "time")
    until <- commits %>% pluck(1, "time")
    issues <- github_issues(since = since - lubridate::dhours(1))

    prs <- issues %>%
        keep(~ hasName(., "pull_request")) %>%
        keep(~ lubridate::ymd_hms(.$closed_at) <= until) %>%
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

    chlog$issues <- issues %>%
        keep(~.$number %in% numbers) %>%
        map(~list(number = .$number, title = .$title, body = .$body))
    chlog$pull_requests <- prs %>%
        discard(~.$number %in% numbers) %>%
        map(~list(number = .$number, title = .$title, body = .$body))

    chlog
}


#' Show changelog of a particular release
#' @param release the result of `find_release` or NULL to show the current dev changelog.
#' @param new_release is it the first release?
#' @export
changelog <- function(release = NULL, new_release = FALSE) {
    if (is.null(release)) {
        release <- find_release()
        return(changelog_between(glue("{release$sha}..HEAD")))
    }
    if (new_release) {
        after <- git("rev-list", "--max-parents=0", "HEAD")
    } else {
        prev_release <- attr(release, "previous")
        if (is.null(prev_release)) {
            stop("cannot determine previous release")
        }
        after <- git("merge-base", prev_release$sha, "HEAD")
    }
    changelog_between(glue("{trimws(after)}^..{release$sha}"))
}



format_changelog <- function(chlog) {
    msg <- ""
    if (length(chlog$issues) > 0) {
        msg <- paste0(
            msg,
            "**Closed issues:**\n\n",
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
            "**Merged pull requests:**\n\n",
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
