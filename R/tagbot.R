#' @export
find_commit_to_tag <- function(path = ".", version = NULL) {
    on.exit({
        unlink(tempd, recursive = TRUE)
    })
    tempd <- file.path(tempdir(), random_letters(6))

    desc <- describe(file.path(rprojroot::find_package_root_file(path), "DESCRIPTION"))
    pkgnm <- desc$get("Package")
    info <- download_info(pkgnm, version)
    tag <- get_latest_tag()

    if (as_semver(tag) >= as_semver(info$version)) {
        message("Version ", info$version, " has been taged.")
        return(invisible(tag))
    }

    dir.create(tempd, showWarnings = FALSE)

    download_and_untar(info$url, tempd)

    work_tree <- file.path(tempd, pkgnm)

    watched_files <- re_match(
        readLines(file.path(work_tree, "MD5")),
        "[0-9a-f]+ \\*(.*)$"
    )
    watched_files <- sapply(watched_files, function(x) x[2])

    desc_wt <- describe(file.path(work_tree, "DESCRIPTION"))
    commits <- get_commit_between(tag, "HEAD")
    for (commit in commits) {
        diff <- git::git(
            sprintf("--work-tree=%s", work_tree),
            "diff",
            "--name-only",
            commit)
        modified_files <- intersect(strsplit(diff, "\n")[[1]], watched_files)
        if (length(modified_files) == 0 || identical(modified_files, "DESCRIPTION")) {
            desc_commit <- describe(textConnection(get_content(commit, "DESCRIPTION")))
            if (match_description(desc_commit, desc_wt)) {
                return(commit)
            }
        }
    }
    stop("cannot determine commit to tag", call. = FALSE)
}
