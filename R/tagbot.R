#' @docType package
#' @importFrom utils available.packages download.file untar
#' @import purrr
#' @importFrom glue glue
#' @importFrom git git
"_PACKAGE"


## quiets concerns of R CMD check re: the .'s that appear in pipelines
# from https://github.com/jennybc/googlesheets/blob/master/R/googlesheets.R
utils::globalVariables(c("."))


tagged_releases <- function(pkgnm, releases = NULL, tags = NULL) {
    if (is.null(tags)) {
        tags <- git_tag()
    }
    if (length(tags) == 0) {
        return(NULL)
    }
    tagnms_stripped <- gsub("^v", "", map_chr(tags, "tag"))

    if (is.null(releases)) {
        releases <- pkg_releases(pkgnm)
    }
    if (length(releases) == 0) {
        return(NULL)
    }

    releases %>%
        keep(~ .$version %in% tagnms_stripped) %>%
        map(function(r) {
            tag <- tags %>%
                detect(~ gsub("^v", "", .$tag) == r$version)
            list(
                version = r$version,
                url = r$url,
                release_time = r$time,
                latest = r$latest,
                tag = tag$tag,
                tag_time = tag$time,
                sha = tag$sha
            )
        })
}


checkout_release <- function(pkgnm, releases, version) {
    if (is.null(version)) {
        release <- releases %>% pluck(length(.))
        if (is.null(release)) {
            stop(glue("cannot find any releases for package '{pkgnm}'"))
        }
        version <- release$version
    } else {
        release <- releases %>% detect(~ .$version == version)
        if (is.null(release)) {
            stop(glue("version {version} is invalid for package '{pkgnm}'"), call. = FALSE)
        }
    }
    release
}


search_for_release <- function(release, since, until) {
    work_tree <- pkg_release_download(release)
    watched_files <- readLines(file.path(work_tree, "MD5")) %>%
        re_match("[0-9a-f]+ \\*(.*)$") %>%
        map_chr(2)
    if (is.null(since)) {
        hashes <- git_rev_list(until)
    } else {
        hashes <- git_rev_list(glue("{since}..{until}"))
    }

    work_tree_desc <- describe(file.path(work_tree, "DESCRIPTION"))
    for (hash in hashes) {
        modified_files <- git_list_modified_files(hash, work_tree)
        modified_files <- intersect(modified_files, watched_files)
        if (length(modified_files) == 0) {
            return(hash)
        } else if (identical(modified_files, "DESCRIPTION")) {
            desc <- describe(textConnection(git_file_content(hash, "DESCRIPTION")))
            if (desc$Package == release$package && desc$Version == release$version) {
                nms1 <- names(desc)
                nms2 <- names(work_tree_desc)
                for (nm in intersect(nms1, nms2)) {
                    if (gsub("\\s", "", desc[[nm]]) != gsub("\\s", "", work_tree_desc[[nm]])) {
                        warning("the field", nm, "are different")
                    }
                }
                return(hash)
            }
        }
    }
    return(NULL)
}



#' find a release with a given version
#' @param version the version string. Use the latest release version if `NULL`.
#' @export
find_release <- function(version = NULL) {
    pkgnm <- pkg_name()
    releases <- pkg_releases(pkgnm)
    tags <- git_tag()
    release <- checkout_release(pkgnm, releases, version)

    t_releases <- tagged_releases(pkgnm, releases, tags)
    t_release <- t_releases %>% detect(~.$version == release$version)
    if (!is.null(t_release)) {
        return(t_release)
    }

    # determine search range
    if (is.null(version)) {
        since <- t_releases %>% pluck(length(.), "sha")
        until <- "HEAD"
    } else {
        since <- t_releases %>%
            keep(possibly(~ compare_version(.$version, release$version) < 0, FALSE)) %>%
            pluck(length(.), "sha")
        until <- t_releases %>%
            keep(possibly(~ compare_version(.$version, release$version) > 0, FALSE)) %>%
            pluck(1, "sha", .default = "HEAD")
    }

    hash <- search_for_release(release, since, until)
    if (is.null(hash)) {
        stop("cannot determine release", call. = FALSE)
    }
    list(
        version = release$version,
        url = release$url,
        release_time = release$time,
        latest = release$latest,
        tag = NULL,
        tag_time = NA,
        sha = hash
    )
}
