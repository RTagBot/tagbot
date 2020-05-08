describe <- function(path) {
    desc <- read.dcf(path)
    structure(as.list(desc), names = colnames(desc))
}


match_description <- function(dcran, d) {
    nms1 <- names(dcran)
    nms2 <- names(d)
    # for (nm in intersect(nms1, nms2)) {
    for (nm in c("Package", "Version")) {
        if (dcran[[nm]] != d[[nm]]) {
            return(FALSE)
        }
    }
    return(TRUE)
}


pkg_archived_releases <- function(pkgnm, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }
    archive <- NULL
    for (repo in repos) {
        archive <- tryCatch({
                con <- gzcon(url(sprintf("%s/src/contrib/Meta/archive.rds", repo), "rb"))
                on.exit(close(con))
                readRDS(con)
            },
            warning = function(e) NULL,
            error = function(e) NULL)
        if (!is.null(archive) && pkgnm %in% names(archive)) {
            break
        }
    }
    if (is.null(archive) || !(pkgnm %in% names(archive))) {
        stop("cannot find package '", pkgnm, "' in archive", call. = FALSE)
    }
    row.names(archive[[pkgnm]]) %>%
        re_match(sprintf("%s/%s_(.*?)\\.tar.gz", pkgnm, pkgnm)) %>%
        map_chr(2) %>%
        map(function(v) list(
            version = v,
            url = paste0(
                repo,
                "/src/contrib/Archive/",
                sprintf("%s/%s_%s.tar.gz", pkgnm, pkgnm, v))
        ))
}


pkg_latest_release <- function(pkgnm, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }
    ava_pkgs <- available.packages(type = "source", repos = repos)
    if (!pkgnm %in% row.names(ava_pkgs)) {
        stop("cannot find package '", pkgnm, "'", call. = FALSE)
    }
    row <- ava_pkgs[which(row.names(ava_pkgs) == pkgnm)[1], ]
    url <- paste0(row[["Repository"]], "/", row[["Package"]], "_", row[["Version"]], ".tar.gz")
    list(
        version = ava_pkgs[pkgnm, "Version"],
        url = url
    )
}


pkg_download_link <- function(pkgnm, version = NULL, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }

    if (is.null(version)) {
        return(pkg_latest_release(pkgnm, repos))
    }

    release <- pkg_archived_releases(pkgnm, repos = repos) %>%
        detect(~ .$version == version)
    if (!is.null(release)) {
        return(release)
    }
    release <- pkg_latest_release(pkgnm, repos)
    if (version == release$version) {
        return(release)
    }

    stop("version ", version, " is not valid for '", pkgnm, "'", call. = FALSE)
}
