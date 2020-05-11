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


compare_version <- function(ver1 , ver2) {
    ver1 <- as.integer(strsplit1(ver1, "[.-]"))
    ver2 <- as.integer(strsplit1(ver2, "[.-]"))
    dlen <- length(ver2) - length(ver1)
    if (dlen > 0) {
        ver1 <- c(ver1, integer(dlen))
    } else {
        ver2 <- c(ver2, integer(-dlen))
    }
    for (i in seq_len(length(ver1))) {
        if (ver1[i] < ver2[i]) {
            return(-1L)
        } else if (ver1[i] > ver2[i]) {
            return(1L)
        }
    }
    return(0L)
}
