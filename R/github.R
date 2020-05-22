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
    if (startsWith(upstream, "https://github.com/")) {
        upstream <- gsub("https://github.com/", "", upstream)
    }
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
    if (hasName(.github_repo_cache, getwd())) {
        return(.github_repo_cache[[getwd()]])
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
    .github_repo_cache[[getwd()]] <- out
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
github_extract_issues <- function(message) {
    re_match_all1(
        tolower(message),
        "\\b(?:close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved) #(\\d+)\\b"
    ) %>%
        map_chr(2)
}


github_releases <- function() {
    ghrepo <- github_repo()
    gh::gh(
        "GET /repos/:owner/:repo/releases",
        owner = ghrepo$owner,
        repo = ghrepo$repo
    )
}


github_has_release <- function(tag_name) {
    gh_releases <- tryCatch(
        github_releases(),
        error = function(e) NULL
    )
    if (is.null(gh_releases)) {
        return(FALSE)
    }
    release_tag_names <- gh_releases %>% map_chr("tag_name")
    return(tag_name %in% release_tag_names)
}
