make_release <- function(
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
    cat(x$package, x$version)
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


tagged_releases <- function(releases = NULL, tags = NULL) {
    if (is.null(tags)) {
        tags <- git_tag()
    }
    if (length(tags) == 0) {
        return(NULL)
    }
    tagnms_stripped <- gsub("^v", "", map_chr(tags, "tag"))

    pkgnm <- pkg_name()
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
            make_release(
                package = pkgnm,
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


search_range <- function(version, t_releases, latest = FALSE) {
    pkgnm <- pkg_name()

    if (latest) {
        since <- t_releases %>% pluck(length(.))
        until <- NULL
    } else {
        since <- t_releases %>%
            keep(possibly(~ compare_version(.$version, version) < 0, FALSE)) %>%
            pluck(length(.))
        until <- t_releases %>%
            keep(possibly(~ compare_version(.$version, version) > 0, FALSE)) %>%
            pluck(1)
    }
    list(since = since, until = until)
}


search_for_release <- function(release, since, until) {
    work_tree <- pkg_release_download(release)
    watched_files <- readLines(file.path(work_tree, "MD5")) %>%
        re_match("[0-9a-f]+ \\*(.*)$") %>%
        map_chr(2)
    if (is.null(until)) {
        until <- "HEAD"
    }
    if (is.null(since)) {
        hashes <- git_rev_list(since)
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


#' find a release with a given version
#' @param version the version to search. Use `NULL` to search the latest release version.
#' @export
find_release <- function(version = NULL, releases = NULL, tags = NULL) {
    pkgnm <- pkg_name()
    if (is.null(releases)) {
        releases <- pkg_releases(pkgnm)
    }
    if (is.null(tags)) {
        tags <- git_tag()
    }
    latest <- is.null(version)
    release <- checkout_release(releases, version)

    t_releases <- tagged_releases(releases, tags)
    t_release <- t_releases %>% detect(~.$version == release$version)
    if (!is.null(t_release)) {
        return(make_release(
            package = pkgnm,
            version = t_release$version,
            url = t_release$url,
            release_time = t_release$time,
            latest = t_release$latest,
            tag = t_release$tag,
            tag_time = t_release$tag_time,
            sha = t_release$sha
        ))
    }

    bracket <- search_range(release$version, t_releases, latest = latest)
    hash <- search_for_release(release, bracket$since$sha, bracket$until$sha)

    if (is.null(hash)) {
        stop("cannot determine release", call. = FALSE)
    }
    release <- make_release(
        package = pkgnm,
        version = release$version,
        url = release$url,
        release_time = release$time,
        latest = release$latest,
        tag = NULL,
        tag_time = NA,
        sha = hash
    )
    attr(release, "previous") <- bracket$since
    release
}
