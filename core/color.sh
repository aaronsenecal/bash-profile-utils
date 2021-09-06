#!/bin/bash

# easily colorize text
function color {
    local text_color="$(echo $1 | sed 's/ //g' | awk '{print toupper($0)}')"; shift;
    case "$text_color" in
        'BLACK'       ) color_code='0;30';;
        'DARKGRAY'    ) color_code='1;30';;
        'RED'         ) color_code='0;31';;
        'LIGHTRED'    ) color_code='1;31';;
        'GREEN'       ) color_code='0;32';;
        'LIGHTGREEN'  ) color_code='1;32';;
        'BROWN'       ) color_code='0;33';;
        'ORANGE'      ) color_code='0;33';;
        'YELLOW'      ) color_code='0;33';;
        'BLUE'        ) color_code='0;34';;
        'LIGHTBLUE'   ) color_code='1;34';;
        'PURPLE'      ) color_code='0;35';;
        'LIGHTPURPLE' ) color_code='1;35';;
        'CYAN'        ) color_code='0;36';;
        'LIGHTCYAN'   ) color_code='1;36';;
        'LIGHTGRAY'   ) color_code='0;37';;
        'WHITE'       ) color_code='1;37';;
        '*'           ) color_code='0';;
    esac

    echo -e "\\[\\e[${color_code}m\\]$@\\[\\e[0m\\]";
}