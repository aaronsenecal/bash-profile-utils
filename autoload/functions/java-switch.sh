#!/bin/bash

function java-switch {
    OPTIND=1;
    while getopts 'h?' opt; do
      case "$opt" in
        h|\? )
            echo "Sets JAVA_HOME based on available Java SDK versions";
            echo "";
            echo 'Usage: java-switch [$java_version]';
            echo '  - $java_version: The version of Java to switch to. Leave blank to restore defaults.'
            return 0;
            ;;
        esac
    done
    shift $((OPTIND-1))
    [ "${1:-}" = "--" ] && shift

    local java_version="$1"
    if [ -z "$java_version" ]; then
        export JAVA_HOME='';
        >&2 echo "Java version restored to default: $(java -version 2>&1 | head -1)";
        return 0;
    fi
    local new_version_path="$(/usr/libexec/java_home -v $java_version)";
    if [ -z "$new_version_path" ]; then
        >&2 echo "No Java SDK available for specified version: $java_version";
        return 1;
    fi;
    export JAVA_HOME="$new_version_path";
    >&2 echo "Java version updated to: $(java -version 2>&1 | head -1)";
    return 0;
}