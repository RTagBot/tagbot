describe <- function(path) {
    # make sure the file is imported as cran
    desc <- read.dcf(textConnection(capture.output(write.dcf(read.dcf(path), ""))))
    structure(as.list(desc), names = colnames(desc))
}


pkg_name <- function() {
    projroot <- rprojroot::find_package_root_file(".")
    desc <- describe(file.path(projroot, "DESCRIPTION"))
    desc$Package
}


pkg_archived_releases <- function(pkgnm, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }
    for (repo in repos) {
        archive <- NULL
        rdsurl <- sprintf("%s/src/contrib/Meta/archive.rds", repo)
        target <- file.path(tempdir(), gsub("[:/]", "%", rdsurl))
        if (file.exists(target)) {
            archive <- tryCatch(
                readRDS(target),
                warning = function(e) NULL,
                error = function(e) NULL
            )
        }
        if (is.null(archive)) {
            archive <- tryCatch({
                    download.file(rdsurl, target, quiet = TRUE)
                    readRDS(target)
                },
                warning = function(e) NULL,
                error = function(e) NULL)
        }
        if (!is.null(archive) && pkgnm %in% names(archive)) {
            break
        }
    }
    if (is.null(archive) || !(pkgnm %in% names(archive))) {
        return(list())
    }
    pkgdata <- archive[[pkgnm]]
    versions <- row.names(pkgdata) %>%
        re_match(sprintf("%s/%s_(.*?)\\.tar.gz", pkgnm, pkgnm)) %>%
        map_chr(2)
    ctimes <- lubridate::with_tz(pkgdata$mtime, tzone = "UTC")
    ord <- order(ctimes)
    map2(versions[ord], ctimes[ord],
        function(v, t) list(
            package = pkgnm,
            version = v,
            url = paste0(
                repo,
                "/src/contrib/Archive/",
                sprintf("%s/%s_%s.tar.gz", pkgnm, pkgnm, v)),
            time = if (is.na(t)) NULL else t,
            latest = FALSE
        )
    )
}


pkg_latest_release <- function(pkgnm, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }
    ava_pkgs <- available.packages(type = "source", repos = repos)
    if (!pkgnm %in% row.names(ava_pkgs)) {
        return(list())
    }
    row <- ava_pkgs[which(row.names(ava_pkgs) == pkgnm)[1], ]
    url <- paste0(row[["Repository"]], "/", row[["Package"]], "_", row[["Version"]], ".tar.gz")
    list(
        package = pkgnm,
        version = ava_pkgs[pkgnm, "Version"],
        url = url,
        time = NULL,
        latest = TRUE
    )
}


.releases_cache <- new.env(parent = emptyenv())


pkg_releases <- function(pkgnm, repos = getOption("repos")) {
    if (missing(pkgnm)) {
        pkgnm <- pkg_name()
    }
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }
    if (hasName(.releases_cache, pkgnm)) {
        cache <- .releases_cache[[pkgnm]]
        if (cache$repos == repos) {
            return(cache$res)
        }
    }
    res <- c(
        pkg_archived_releases(pkgnm, repos),
        list(pkg_latest_release(pkgnm, repos))
    )
    .releases_cache[[pkgnm]] <- list(res = res, repos = repos)
    res
}


pkg_release <- function(pkgnm, version = NULL, repos = getOption("repos")) {
    if (missing(pkgnm)) {
        pkgnm <- pkg_name()
    }
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
    return(NULL)
}


pkg_release_download <- function(release) {
    td <- tempdir()
    pkgnm <- release$package
    pkgnm_ver <- paste0(pkgnm, "_", release$version)
    outdir <- file.path(td, pkgnm, pkgnm_ver)
    if (!dir.exists(outdir)) {
        tarfile <- file.path(td, pkgnm, basename(release$url))
        dir.create(dirname(tarfile), showWarnings = FALSE)
        download.file(release$url, tarfile, quiet = TRUE)
        cwd <- getwd()
        on.exit(setwd(cwd))
        setwd(dirname(tarfile))
        untar(tarfile)
        file.rename(pkgnm, pkgnm_ver)
    }
    return(outdir)
}
