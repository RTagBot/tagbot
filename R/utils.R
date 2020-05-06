re_match <- function(x, pattern) {
    regmatches(x, regexec(pattern, x, perl = T))
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
