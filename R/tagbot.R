#' @docType package
#' @importFrom utils available.packages download.file untar
#' @import purrr
#' @importFrom glue glue
"_PACKAGE"


## quiets concerns of R CMD check re: the .'s that appear in pipelines
# from https://github.com/jennybc/googlesheets/blob/master/R/googlesheets.R
if (getRversion() >= "2.15.1") utils::globalVariables(c("."))


#' find a commit to tag
#' @param version a character in semetic version. Use the latest CRAN release version if `NULL`.
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
        latest_tag <- git_latest_tag()
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
    hashes <- git_commit_hashes_between(latest_tag, "HEAD")
    for (hash in hashes) {
        modified_files <- git_list_modified_files(hash, work_tree)
        modified_files <- intersect(modified_files, watched_files)
        if (length(modified_files) == 0 || identical(modified_files, "DESCRIPTION")) {
            desc_commit <- describe(textConnection(git_file_content(hash, "DESCRIPTION")))
            if (match_description(desc_cran, desc_commit)) {
                return(hash)
            }
        }
    }
    stop("cannot determine commit to tag", call. = FALSE)
}
