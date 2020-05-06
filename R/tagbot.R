#' find a commit to tag
#' @param version a character in semetic version. Use the latest CRAN release version if `NULL`.
#' @importFrom utils available.packages download.file untar
#' @export
find_commit_to_tag <- function(version = NULL) {
    on.exit({
        unlink(tempd, recursive = TRUE)
    })
    tempd <- file.path(tempdir(), random_letters(6))
    dir.create(tempd, showWarnings = FALSE)

    projroot <- rprojroot::find_package_root_file(".")
    desc <- describe(file.path(projroot, "DESCRIPTION"))
    pkgnm <- desc$Package
    info <- download_info(pkgnm, version)

    if (is.null(version)) {
        latest_tag <- get_latest_tag()
        if (!is.null(latest_tag) && as_semver(latest_tag) == as_semver(info$version)) {
            stop("latest tag is the current version", call. = FALSE)
        }
    } else {
        latest_tag <- NULL
    }

    download_and_untar(info$url, tempd)
    work_tree <- file.path(tempd, pkgnm)
    watched_files <- re_match(
        readLines(file.path(work_tree, "MD5")),
        "[0-9a-f]+ \\*(.*)$"
    )
    watched_files <- sapply(watched_files, function(x) x[2])

    desc_cran <- describe(file.path(work_tree, "DESCRIPTION"))
    commits <- get_commits_between(latest_tag, "HEAD")
    for (commit in commits) {
        modified_files <- get_modified_files(commit, work_tree)
        modified_files <- intersect(modified_files, watched_files)
        if (length(modified_files) == 0 || identical(modified_files, "DESCRIPTION")) {
            desc_commit <- describe(textConnection(get_file_content(commit, "DESCRIPTION")))
            if (match_description(desc_cran, desc_commit)) {
                return(commit)
            }
        }
    }
    stop("cannot determine commit to tag", call. = FALSE)
}
