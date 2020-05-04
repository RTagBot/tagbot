get_latest_tag <- function() {
    tags <- strsplit(git::git("tag"), "\n")[[1]]
    semver <- as_semver(tags, simplify = FALSE)
    tags[sapply(semver, function(x) x == max(semver))]
}


get_commit_between <- function(commit1, commit2) {
    strsplit(
        git::git("log", "--format=%H", sprintf("%s..%s", commit1, commit2)),
        "\n")[[1]]
}


get_content <- function(commit, path) {
    object <- strsplit(git::git("ls-tree", commit, path), "\\s+")[[1]][3]
    git::git("show", object)
}
