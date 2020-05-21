wrap_release <- function(
    package,
    version,
    url = NULL, release_time = NULL, latest = NULL,
    tag = NULL, tag_time = NULL, sha = NULL) {
    structure(
        list(
            package = package,
            version = version,
            url = url,
            release_time = release_time,
            latest = latest,
            tag = tag,
            tag_time = tag_time,
            sha = sha
        ),
        class = "release"
    )
}


#' @export
#' @method print release
print.release <- function(x, ...) {
    cat(x$package, paste0("v", x$version))
    cat(sprintf(" [tag:%s, sha:%s]",
        x$tag %||% "nil", if (is.null(x$sha)) "nil" else substr(x$sha, 1, 7)))
    cat("\n")
}


checkout_release <- function(releases, version) {
    if (is.null(version)) {
        release <- releases %>% pluck(length(.))
        if (is.null(release)) {
            stop(glue("cannot find any releases for the package"))
        }
        version <- release$version
    } else {
        release <- releases %>% detect(~ .$version == version)
        if (is.null(release)) {
            stop(glue("version {version} is invalid for the package"), call. = FALSE)
        }
    }
    release
}


search_range <- function(version, releases, latest = FALSE) {
    pkgnm <- pkg_name()

    since <- releases %>%
        discard(~ is.null(.$sha)) %>%
        keep(possibly(~ compare_version(.$version, version) < 0, FALSE)) %>%
        pluck(length(.))
    until <- releases %>%
        discard(~ is.null(.$sha)) %>%
        keep(possibly(~ compare_version(.$version, version) > 0, FALSE)) %>%
        pluck(1)
    list(since = since, until = until)
}


search_for_release <- function(release, after, before) {
    work_tree <- pkg_release_download(release)
    watched_files <- readLines(file.path(work_tree, "MD5")) %>%
        re_match("[0-9a-f]+ \\*(.*)$") %>%
        map_chr(2)
    if (is.null(before)) {
        before <- "HEAD"
    }
    if (is.null(after)) {
        hashes <- git_rev_list(before)
    } else {
        hashes <- git_rev_list(glue("{after}..{before}"))
    }

    work_tree_desc <- describe(file.path(work_tree, "DESCRIPTION"))

    for (hash in hashes) {
        modified_files <- git_list_modified_files(hash, work_tree)
        modified_files <- intersect(modified_files, watched_files)
        if (length(modified_files) == 0) {
            return(hash)
        } else if (identical(modified_files, "DESCRIPTION")) {
            desc <- describe(textConnection(git_file_content(hash, "DESCRIPTION")))
            gonext <- FALSE
            for (nm in intersect(names(desc), names(work_tree_desc))) {
                if (gsub("\\s", "", desc[[nm]]) != gsub("\\s", "", work_tree_desc[[nm]])) {
                    gonext <- TRUE
                    break
                }
            }
            if (gonext) {
                next
            }
            return(hash)
        }
    }
    return(NULL)
}



#' List all the releases of the package.
#' @export
list_releases <- function() {
    # TODO: integrate with github releases API
    releases <- pkg_releases()

    if (length(releases) == 0) {
        return(list())
    }

    tags <- git_tag()

    releases %>%
        map(function(r) {
            tag <- tags %>%
                detect(~ gsub("^v", "", .$tag) == r$version)
            wrap_release(
                package = r$package,
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


#' Find a release that matches the CRAN release.
#' @param version the version to find. Use `NULL` to find the latest release version.
#' @export
find_release <- function(version = NULL) {
    pkgnm <- pkg_name()
    latest <- is.null(version)

    releases <- list_releases()
    release <- checkout_release(releases, version)

    bracket_releases <- search_range(release$version, releases, latest = latest)

    if (is.null(release$sha)) {
        hash <- search_for_release(release, bracket_releases$since$sha, bracket_releases$until$sha)

        if (is.null(hash)) {
            stop("cannot determine release", call. = FALSE)
        }
        release$sha <- hash
    }

    pervious_release_version <- releases %>%
        keep(possibly(~ compare_version(.$version, release$version) < 0, FALSE)) %>%
        pluck(length(.), "version", .default = "")

    pervious_tagged_release <- bracket_releases$since
    if (!is.null(pervious_tagged_release) &&
            pervious_tagged_release$version == pervious_release_version) {
        attr(release, "previous") <- pervious_tagged_release
    }

    release
}
