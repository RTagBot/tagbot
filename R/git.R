git_latest_tag <- function() {
    tags <- strsplit1(git::git("tag"), "\n")
    semver <- as_semver(tags)
    tags <- tags[vapply(semver, function(x) x == max(semver), logical(1))]
    if (length(tags) == 0) {
        NULL
    } else if (length(tags) >= 1) {
        tags[1]
    }
}


git_upstream_from_active_branch <- function() {
    git::git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
}


git_format_refs <- function(from, to) {
    if (is.null(from) && is.null(to)) {
        from_to <- "HEAD"
    } else if (is.null(from)) {
        from_to <- to
    } else if (is.null(to)) {
        from_to <- glue("{from}..HEAD")
    } else {
        from_to <- glue("{from}..{to}")
    }
    from_to
}


git_commit_hashes_between <- function(from = NULL, to = NULL) {
    git::git("log", "--format=%H", git_format_refs(from, to)) %>%
        strsplit1("\n")
}

git_commits_between <- function(from = NULL, to = NULL) {
    git::git("log", "--format=%H%x03%B%x04", git_format_refs(from, to)) %>%
        strsplit1("\x04\n") %>%
        map(function(x) {
            strsplit1(x, "\x03") %>%
            as.list() %>%
            set_names(c("sha", "message"))
        })
}


git_file_content <- function(commit, path) {
    git::git("ls-tree", commit, path) %>%
        strsplit1("\\s+") %>%
        pluck(3) %>%
        git::git("show", .)
}


git_list_modified_files <- function(commit, work_tree) {
    git::git(
        glue("--work-tree={work_tree}"),
        "diff",
        "--name-only",
        "--diff-filter=AM",
        commit) %>%
        strsplit1("\n")
}
