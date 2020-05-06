get_latest_tag <- function() {
    tags <- strsplit(git::git("tag"), "\n")[[1]]
    semver <- as_semver(tags)
    tags <- tags[vapply(semver, function(x) x == max(semver), logical(1))]
    if (length(tags) == 0) {
        NULL
    } else if (length(tags) >= 1) {
        tags[1]
    }
}


get_commits_between <- function(from = NULL, to = NULL) {
    if (is.null(from) && is.null(to)) {
        from_to <- "HEAD"
    } else if (is.null(from)) {
        from_to <- to
    } else if (is.null(to)) {
        from_to <- sprintf("%s..%s", from, "HEAD")
    } else {
        from_to <- sprintf("%s..%s", from, to)
    }

    strsplit(git::git("log", "--format=%H", from_to), "\n")[[1]]
}


get_file_content <- function(commit, path) {
    object <- strsplit(git::git("ls-tree", commit, path), "\\s+")[[1]][3]
    git::git("show", object)
}


get_modified_files <- function(commit, work_tree) {
    diff <- git::git(
        sprintf("--work-tree=%s", work_tree),
        "diff",
        "--name-only",
        "--diff-filter=AM",
        commit)
    strsplit(diff, "\n")[[1]]
}
