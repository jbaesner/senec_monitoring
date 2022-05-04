#!/bin/bash

IP="192.168.178.83"

DATE=`date '+%Y-%m-%d'`
ALL_LOGS_FROM_DATE="0"
OUTPUT_FOLDER="/tmp/senec-logs"

isInvalidDate() {
    local format="%Y-%m-%d" date="$1"
    [[ "$(date "+$format" -d "$date" 2>/dev/null)" != "$date" ]]
}

isInvalidIp() {
    local ip=$1
    if expr "$ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
        for i in 1 2 3 4; do
            if [ $(echo "$ip" | cut -d. -f$i) -gt 255 ]; then
                return 0
            fi
        done
        return 1
    else
        return 0
    fi
}

getLog() {
    local ip=$1 date=$2
    curl -o ${OUTPUT_FOLDER%/}/$date.log -O http://$ip/log/`date --date $date '+%Y/%m/%d'`.log && gzip --best ${OUTPUT_FOLDER%/}/$date.log
}

# https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/
while getopts ":d:i:o:a" opt; do
    case ${opt} in
        d ) # process option d expecting a date in the format YYYY-MM-DD
            DATE=$OPTARG
        ;;
        i ) # process option i expecting the IP address of the battery
            IP=$OPTARG
        ;;
        o ) # process option o expecting a valid directory
            OUTPUT_FOLDER=$OPTARG
        ;;
        a ) # process all dates from DATE
            ALL_LOGS_FROM_DATE="1"
        ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            exit 1
        ;;
        : )
            echo "Invalid option: $OPTARG requires an argument" 1>&2
            exit 1
        ;;
  esac
done

# ensure the DATE is valid
if isInvalidDate ${DATE}; then
	echo "invalid date (${DATE}) given with '-d' parameter"
    exit 1
fi

# ensure if the IP is valid
if isInvalidIp ${IP}; then
	echo "invalid IP (${IP}) given with '-i' parameter"
    exit 1
fi

if [ ! -d "${OUTPUT_FOLDER}" ]; then
    echo "invalid OUTPUT_FOLDER (${OUTPUT_FOLDER}) given with '-o' parameter"
    exit 1
fi

if [ "${ALL_LOGS_FROM_DATE}" = "1" ]; then
    DAYS=$(echo $((($(date +%s)-$(date +%s --date ${DATE}))/(3600*24))))
    if [ "${DAYS}" == "0" ]; then
        getLog ${IP} ${DATE}
    else
        for i in $(seq 1 ${DAYS}); do
            getLog ${IP} `date -d "$i days ago" '+%Y-%m-%d'`
        done
    fi
else
    getLog ${IP} ${DATE}
fi
