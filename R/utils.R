re_match <- function(x, pattern, perl = TRUE) {
    regmatches(x, regexec(pattern, x, perl = perl))
}

re_match_all <- function(x, pattern, perl = TRUE) {
    lapply(re_search_all(x, pattern, perl),
        function(x) {
            re_match(x, pattern, perl)
        }
    )
}

re_search <- function(x, pattern, perl = TRUE) {
    regmatches(x, regexpr(pattern, x, perl = perl))
}

re_search_all <- function(x, pattern, perl = TRUE) {
    regmatches(x, gregexpr(pattern, x, perl = perl))
}

re_match1 <- function(x, pattern, perl = TRUE) {
    stopifnot(length(x) == 1)
    re_match(x, pattern, perl)[[1]]
}

re_match_all1 <- function(x, pattern, perl = TRUE) {
    stopifnot(length(x) == 1)
    re_match_all(x, pattern, perl)[[1]]
}

re_search1 <- function(x, pattern, perl = TRUE) {
    stopifnot(length(x) == 1)
    re_search(x, pattern, perl)[[1]]
}

re_search_all1 <- function(x, pattern, perl = TRUE) {
    stopifnot(length(x) == 1)
    re_search_all(x, pattern, perl)[[1]]
}

strsplit1 <- function(x, pattern, fixed = FALSE, perl = TRUE) {
    stopifnot(length(x) == 1)
    strsplit(x, fixed = fixed, pattern, perl = perl)[[1]]
}


random_letters <- function(n) {
    paste(sample(letters, n, replace = TRUE), collapse = "")
}


as_semver <- function(x) {
    semver::parse_version(gsub("^v", "", x))
}

download_and_untar <- function(url, temp_dir) {
    cwd <- getwd()
    on.exit({
        setwd(cwd)
    })
    setwd(temp_dir)
    target <- file.path(temp_dir, basename(url))
    download.file(url, target, quiet = TRUE)
    untar(target)
}
