#!/bin/bash

# custom terminal prompt stuff
export PROMPT_COMMAND="prompt_command";
function prompt_command {
    prompt_working_dir="../$(basename $(pwd))";
    if [ "$(realpath $prompt_working_dir)" = "$(realpath $HOME)" ]; then
        prompt_working_dir='~';
    elif [ "$prompt_working_dir" = "..//" ]; then
        prompt_working_dir='/';
    fi;
    prompt_git='';
    local git_root="$(git rev-parse --show-toplevel 2>/dev/null)";
    if [ ! -z "$git_root" ]; then
        local git_status="$(git --git-dir $git_root/.git status)";
        local git_branch="$(echo "$git_status" | sed -n 's/On branch \(.*\)/\1/p')";
        local git_upstream_relative="$(echo "$git_status" | sed -n "s/Your branch is \([^']*\) '.*/\1/p")";
        local git_repo_name="$(git  --git-dir $git_root/.git remote -v | grep '^origin' | awk '{print $2}' | sort | uniq | sed -n 's/.*:\(.*\)\.git/\1/p')";
        local git_color='yellow';

        if [ -z "$git_branch" ]; then
            git_branch="a detatched HEAD";
        fi
        if [ "$git_upstream_relative" = "up to date with" ]; then
            git_color='green';
        fi

        local colored_git_branch="$(color $git_color $git_branch)";
        local colored_git_repo_name="$(color $git_color $git_repo_name)";
        prompt_git=", working on $colored_git_branch for $colored_git_repo_name";
    fi

    prompt_time="$(color white $(date -u +"%Y-%m-%d %H:%M:%S UTC"))"
    if [ ! -z "$prompt_allow_short" ] && [ "$prompt_working_dir" = "$old_prompt_working_dir" ] && [ "$prompt_git" = "$old_prompt_git" ]; then
        PS1="$(printf '\xE2\x94\x93')\n$(printf '\xE2\x94\x97\xE2\x94\x81') at $prompt_time $(printf '\xE2\x94\x81')\\$ ";
    else
        PS1="\n$(printf '\xE2\x94\xb3') $(color white \\u) in $(color white $prompt_working_dir)${prompt_git}\n$(printf '\xE2\x94\x97\xE2\x94\x81') at $prompt_time $(printf '\xE2\x94\x81')\\$ ";
    fi    
    old_prompt_working_dir="$prompt_working_dir";
    old_prompt_git="$prompt_git";
}
