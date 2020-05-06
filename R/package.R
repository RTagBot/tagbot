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


download_info <- function(pkgnm, version = NULL, repos = getOption("repos")) {
    if (is.null(repos)) {
        repos <- "https://cran.rstudio.com"
    }

    ava_pkgs <- available.packages(type = "source", repos = repos)
    if (pkgnm %in% row.names(ava_pkgs)) {
        row <- ava_pkgs[which(row.names(ava_pkgs) == pkgnm)[1], ]
        url <- paste0(row[["Repository"]], "/", row[["Package"]], "_", row[["Version"]], ".tar.gz")
        current <- list(
            version = ava_pkgs[pkgnm, "Version"],
            url = url
        )
        if (is.null(version) || current$version == version) {
            return(current)
        }
    } else if (is.null(version)) {
        stop("cannot find package '", pkgnm, "'", call. = FALSE)
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
