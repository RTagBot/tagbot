github_repo_name_from_desc <- function() {
    projroot <- rprojroot::find_package_root_file(".")
    desc <- describe(file.path(projroot, "DESCRIPTION"))
    if (!is.null(desc$URL) && startsWith(desc$URL, "https://github.com/")) {
        return(gsub("https://github.com/", "", desc$URL))
    }
    NULL
}


github_repo_name_from_remote <- function() {
    upstream <- tryCatch(
        git_upstream_from_active_branch(),
        error = function(e) "origin/master")
    remote <- strsplit1(upstream, "/")[1]
    url <- trimws(git::git("remote", "get-url", remote))
    if (startsWith(url, "git@github.com:")) {
        return(gsub("git@github.com:(.*?)\\.git", "\\1", url))
    } else if (startsWith(url, "https://github.com/")) {
        return(gsub("https://github.com/(.*?)\\.git", "\\1", url))
    }
    NULL
}


.github_repo_cache <- new.env(parent = emptyenv())


github_repo <- function() {
    if (!is.null(.github_repo_cache$value)) {
        return(.github_repo_cache$value)
    }
    repo <- tryCatch(
        github_repo_name_from_desc(),
        error = function(e) NULL)
    if (is.null(repo)) {
        # if URL doesn't work, we try to parse it from `git remote`
        repo <- github_repo_name_from_remote()
    }
    if (is.null(repo)) {
        stop("cannot determine repo name")
    }
    out <- structure(as.list(strsplit1(repo, "/")), names = c("owner", "repo"))
    .github_repo_cache$value <- out
    out
}


github_issues <- function(since = NULL) {
    ghrepo <- github_repo()
    gh::gh(
        "GET /repos/:owner/:repo/issues",
        owner = ghrepo$owner,
        repo = ghrepo$repo,
        state = "closed",
        sort = "updated",
        since = since,
        per_page = 100,
        .limit = Inf
    )
}


github_pull_request <- function(number) {
    ghrepo <- github_repo()
    gh::gh(
        "GET /repos/:owner/:repo/pulls/:pull_number",
        owner = ghrepo$owner,
        repo = ghrepo$repo,
        pull_number = number
    )
}



# https://help.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue
github_closed_issues_from_message <- function(message) {
    re_match_all1(
        tolower(message),
        "\\b(?:close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #(\\d+)\\b"
    ) %>%
        map_chr(2)
}


github_closed_issues_from_commits <- function(commits) {
    commits %>%
        map("message") %>%
        map(github_closed_issues_from_message) %>%
        as_vector()
}


github_closed_issues <- function(from, to) {
    commits <- git_log(glue("{trimws(from)}..{trimws(to)}"))

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

    sort(union(closed_by_prs, closed_by_commits))
}
