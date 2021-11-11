#!/bin/bash

# Main command for chaging to the root of a local git repo
function cdrepo {
    local printonly='';
    OPTIND=1;
    while getopts 'ph?' opt; do
      case "$opt" in
        p )
          printonly='true';
          ;;
        h|\? )
            echo "Change to (or print the path to) the specified repo.";
            echo "";
            echo 'Usage: cdrepo [-p] $repo_name [$search_in]';
            echo '  - -p:         Use this option to simply print the path of the repo, '
            echo '                instead of changing to it.'
            echo '  - $repo_name: The "owner/name" identifier for the desired repo.'
            echo '  - $search_in: (optional) The directory to search for the repo, defaults to ~/.'
            echo "";
            echo "Other related commands include: "
            declare -F | grep cdrepo- | sort | awk '{print "  - "$NF}'
            return 0;
            ;;
        esac
    done
    shift $((OPTIND-1))
    [ "${1:-}" = "--" ] && shift

    local repo="$(echo "$1" | tr '[:upper:]' '[:lower:]')";
    local search="$(realpath "$2" 2>/dev/null)";
    local cache_dir="$(_cdrepo_get_cache_dir)";
    local cached_repo_name="$(_cdrepo_get_cached_repo_name $repo)";

    cached="$(find "$cache_dir" -type l -name "$cached_repo_name" 2>/dev/null| head -1)";
    if [ ! -z "$cached" ]; then
        if [ -d "$cached" ]; then
            if [ ! -z "$printonly" ]; then
                echo "$(realpath $cached)";
            else
                cd "$(realpath $cached)";
            fi
            return 0;
        else
            rm $cached;
        fi
    fi

    # if not, find the repo and go to it.
    if [ -z "$search" ]; then
        search="$HOME";
    elif [ ! -d "$search" ]; then
        >&2 echo "$search isn't a directory!";
        return 1;
    fi
    for git_dir in $(find $search -type d -name .git 2>/dev/null | xargs); do
        # TODO: this should be refactored to work with multiple upstreams.
        local reponame="$(git --git-dir="$git_dir" remote -v | grep 'origin' | sed -n 's/.*:\([^\.]*\).*/\1/p' | sort | uniq | head -1 | tr '[:upper:]' '[:lower:]')";
        if [ "$repo" = "$reponame" ]; then
            local repo_path="$git_dir/../";
            
            cdrepo-register "$repo_path" "$reponame";
            
            if [ ! -z "$printonly" ]; then
                echo "$(realpath $repo_path)";
            else
                cd "$(realpath repo_path)";
            fi
            return 0;
        fi
    done
    >&2 echo "Couldn't find repository $repo!";
    return 1;
}

# Repo-aware directory change functions
function cdrepo-discover {
    OPTIND=1;
    while getopts 'h?' opt; do
      case "$opt" in
        h|\? )
            echo "Discovers and registers new repos in the specified directory.";
            echo "";
            echo 'Usage: cdrepo-discover [$search_dir]';
            echo '  - $search_dir: The directory to search for new repos. Defaults to the current working directory.'
            return 0;
            ;;
        esac
    done
    shift $((OPTIND-1))
    [ "${1:-}" = "--" ] && shift

    local search="$1";
    if [ -z "$search" ]; then
        search="$(pwd)";
    fi
    search="$(realpath "$search")";
    for git_dir in $(find $search -type d -name .git 2>/dev/null | xargs); do
        local reponame="$(git --git-dir="$git_dir" remote -v | grep 'origin' | sed -n 's/.*:\([^\.]*\).*/\1/p' | sort | uniq | head -1 | tr '[:upper:]' '[:lower:]')";
        if [ ! -z "$reponame" ]; then
            local cached_repo_name="$(echo "$reponame" | sed 's,/,:,g')";
            local repo_path="$git_dir/../";

            cdrepo-register "$repo_path" "$reponame" > /dev/null;
            echo "Discovered $reponame at $(realpath $repo_path)";
        fi
    done
}

function cdrepo-register {
    OPTIND=1;
    while getopts 'h?' opt; do
      case "$opt" in
        h|\? )
            echo "Registers the path for the specified repo name.";
            echo "";
            echo 'Usage: cdrepo-register $target_path $repo_name';
            echo '  - $target_path: The path in the filesystem that should be associated with $repo_name'
            echo '  - $repo_name: The repo name that should be associated with $target_path.'
            return 0;
            ;;
        esac
    done
    shift $((OPTIND-1))
    [ "${1:-}" = "--" ] && shift

    local target_path=$(realpath $1);
    local repo_name="$2";

    if [ -z "$target_path" ]; then
        >&2 echo "Could not resolve target path: $1.";
        return 1;
    fi
    if [ -z "$repo_name" ]; then
        >&2 echo "No repo name specified!";
        return 1;
    fi

    local cache_dir="$(_cdrepo_get_cache_dir)";
    local cached_repo_name="$(_cdrepo_get_cached_repo_name $repo_name)";

    # first, check if we've got a cached repo to go to
    if [ ! -d "$cache_dir" ]; then
        mkdir "$cache_dir";
    fi
    # add the repo to cache
    rm -f "$cache_dir/$cached_repo_name";
    ln -s "$target_path" "$cache_dir/$cached_repo_name";
    echo "Registered $repo_name at $target_path.";
    return 0;
}

# Links a specified path to the specified repo.
function cdrepo-sub-path {
    OPTIND=1;
    while getopts 'h?' opt; do
      case "$opt" in
        h|\? )
            echo "Substitute the specified path with a link to the specified repo's location in the filesystem.";
            echo "";
            echo 'Usage: cdrepo-link-path $target_path $source_repo';
            echo '  - $target_path: The path in the filesystem that should be replaced with a link to $source_repo.'
            echo '  - $source_repo: The repo that should be linked to $target_path.'
            return 0;
            ;;
        esac
    done
    shift $((OPTIND-1))
    [ "${1:-}" = "--" ] && shift

    # Arg relative target path, arg 2 is the name of the source repo.
    local target_path=$1;
    local source_repo=$2;

    # Validate that target path is actually a directory that can be replaced with a link.
    if [ ! -d "$target_path" ]; then
        >&2 echo "Target path $target_path is not a directory!";
        return 1;
    fi

    # Resolve and validate source repo path.
    local source_dir=$(cdrepo -p "$source_repo");
    if [ ! -d "$source_dir" ]; then
        >&2 echo "Could not locate source repo $source_repo!";
        return 1;
    fi
    local target_dir=$(realpath "$target_path");

    # Check if we're trying to link the source repo to itself.
    if [ "$source_dir" == "$target_dir" ]; then
        >&2 echo "Cannot link $source_dir to itself!";
        return 1;
    fi

    # Move the original target directory to a .bak for safe-keeping.
    local target_bak=$target_dir.link-path-to-repo-bak-$(date +%s);
    mv "$target_dir" "$target_bak";

    # Link the now-vacant target directory path to the source repo directory.
    ln -s "$source_dir" "$target_dir";

    # Check that the link was successfully created. If not, move the original back to its place.
    if [ ! -L "$target_dir" ] || [ ! -d "$target_dir" ]; then
        >&2 echo "Failed to link $target_path to $source_repo at $source_dir.";
        mv "$target_bak" "$target_dir";
        return 1;
    fi

    >&2 echo "Linked $target_path to $source_repo at $source_dir.";
    return 0;
}

function _cdrepo_get_cache_dir {
    echo "$HOME/.cache-cdrepo";
}

function _cdrepo_get_cached_repo_name {
    echo "$1" | sed 's,/,:,g';
}

function _cdrepo_complete {
    local replies='';
    local repo_part="$(echo "$2" | tr '[:upper:]' '[:lower:]' | sed 's,/,:,g')";
    local cache_dir="$HOME/.cache-cdrepo";
    
    # If part of a repo name was specified, search the cache directory for anything matching that name.
    if [ ! -z "$repo_part" ] && [ -d "$cache_dir" ]; then
        replies=$(find "$cache_dir" -type l -name "$repo_part*" -exec basename {} \; 2>/dev/null | sed 's,:,/,g' | sort | xargs);
    # if no repo name was specified, respond with everything in cache.
    elif [ -d "$cache_dir" ]; then
        replies=$(find "$cache_dir" -type l -exec basename {} \; 2>/dev/null | sed 's,:,/,g' | sort | xargs);
    fi
    if [ ! -z "$replies" ]; then
        for reply in $replies; do
            COMPREPLY+=("$reply");
        done
    fi
}

complete -F _cdrepo_complete cdrepo