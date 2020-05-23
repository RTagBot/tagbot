git_tag <- function() {
    git("tag", paste0(
            "--format=",
            "%(refname)%03",
            "%(*objectname)%03%(objectname)%03",
            "%(*committerdate:iso8601)%03%(committerdate:iso8601)")) %>%
        strsplit1("\n") %>%
        map(function(x) {
            strsplit1(x, "\x03") %>% {
                list(
                    tag = gsub("refs/tags/", "", .[1]),
                    sha = if (nzchar(.[2])) .[2] else .[3],
                    time = lubridate::ymd_hms(if (nzchar(.[4])) .[4] else .[5])
                )
            }
        })
}


git_latest_tag <- function() {
    tags <- git_tag()
    tags %>% detect(~ .$time == max(map_dbl(tags, "time")))
}


git_upstream_from_active_branch <- function() {
    git("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
}


git_rev_list <- function(ref, all = FALSE) {
    if (all) {
        git("rev-list", "--all", ref) %>%
            strsplit1("\n")
    } else {
        git("rev-list", ref) %>%
            strsplit1("\n")
    }
}


git_log <- function(ref, since = NULL, limit = NULL) {
    if (!is.null(since)) {
        since <- glue("--since={lubridate::format_ISO8601(since, usetz = TRUE)}")
    }
    if (!is.null(limit)) {
        limit <- glue("--max-count={limit}")
    }
    git(!!!c(
            "log",
            "--format=%H%x03%B%x03%cI%x04",
            since,
            limit,
            ref
        )) %>%
        strsplit1("\x04\n") %>%
        map(function(x) {
            strsplit1(x, "\x03") %>%
                as.list() %>%
                set_names(c("sha", "message", "time")) %>%
                modify_at(3, lubridate::ymd_hms)
        })
}


git_file_content <- function(commit, path) {
    git("ls-tree", commit, path) %>%
        strsplit1("\\s+") %>%
        pluck(3) %>%
        git("show", .)
}


git_list_modified_files <- function(commit, work_tree) {
    git(
        glue("--work-tree={work_tree}"),
        "diff",
        "--name-only",
        "--diff-filter=AM",
        commit) %>%
        strsplit1("\n")
}
