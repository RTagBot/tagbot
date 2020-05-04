describe <- function(path) {
    self <- environment()
    desc <- read.dcf(path)
    get <- function(field) {
        desc[colnames(desc) == field]
    }
    self
}


match_description <- function(d1, d2) {
    for (field in c("Package", "Title", "Version", "Description")) {
        if (d1$get(field) != d2$get(field)) {
            return(FALSE)
        }
    }
    TRUE
}


download_info <- function(pkgnm, version = NULL, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }
    if (is.null(version)) {
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
    } else {
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
            stop("cannot find package '", pkgnm, "'", call. = FALSE)
        }
        url_path <- sprintf("%s/%s_%s.tar.gz", pkgnm, pkgnm, version)
        if (!(url_path %in% row.names(archive[["collections"]]))) {
            stop("version ", version, " is not valid for '", pkgnm, "'", call. = FALSE)
        }
        list(
            version = version,
            url = paste0(repo, "/src/contrib/Archive/", url_path)
        )
    }
}
