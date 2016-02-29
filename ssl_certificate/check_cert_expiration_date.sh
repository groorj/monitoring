#!/bin/bash

#########################################################################################
# Date:         Sat 30 Jan 2016 19:10:39 EST
# Version:      1.0.3
# Author:       gustavo.aguiar@gmail.com
# Github:       https://github.com/groorj/monitoring/
# LastChange:   Sat 30 Jan 2016 19:51:09 EST    <gustavo.aguiar@gmail.com>      <1.0.0>
# LastChange:   Sun 31 Jan 2016 11:47:46 EST    <gustavo.aguiar@gmail.com>      <1.0.1>
# LastChange:   Sun 31 Jan 2016 12:27:15 EST    <gustavo.aguiar@gmail.com>      <1.0.2>
# LastChange:   Fri Feb 26 18:22:36 BRT 2016    <fecotex@gmail.com>     	<1.0.3>
# LastChange:   Mon Feb 29 12:37:15 BRT 2016    <fecotex@gmail.com>     	<1.0.4>
# Request:      N/A
# Description:  Shell script to validate if ssl cert is about to expire
# Usage:        ./check_cert_expiration_date.sh -d <domain_name> -c <days_prior_expire>
# Example:
#               ./check_cert_expiration_date.sh -d google.com -c 30
# Return:       OK|ERROR
#########################################################################################

#########################################################################################
# Variables
#########################################################################################

RED='\033[0;31m'
LRED='\033[1;31m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
LGREEN='\033[1;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
LBLUE='\033[1;34m'
NC='\033[0m'
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
DEFAULT_PORT=443


#########################################################################################
# Functions
#########################################################################################

# convert date to days ;
convert_to_mjd() {
    local year month day
    year=${1:0:4}
    month="`echo "${1:4:2}" | sed "s/^0*//"`"  # here sed removes leading zeros
    day="`echo "${1:6:2}" | sed "s/^0*//"`"
    my_date=$(( (((year-1970)*1461)/4) + ((month-1)*30) + (day-1) ))
}

# print verbose information ;
function echo_verbose {
        if [ $VERBOSE ]; then
                echo "[`date '+%Y-%m-%d %H:%M:%S'`] - ${*}"
        fi
}


# print usage menu ;
function usage {
        echo ""
        echo "$(basename "$0") [-h] [-v] [-d] [-c] [-p] -- check ssl certificate for expiration information."
        echo ""
        echo "Usage:"
        printf "    $0 -h ${RED}->${NC} show this help text\n"
        printf "    $0 -v ${RED}->${NC} verbose\n"
        printf "    $0 -d ${RED}->${NC} domain to check (required)\n"
        printf "    $0 -c ${RED}->${NC} days before expire critical alarm (required)\n"
        printf "    $0 -p ${RED}->${NC} port (optional :: default is 443)\n"
        echo "Example:"
        echo "    $0 -d google.com -c 30"
        echo ""
        exit 0
}
 
function valid_neg {

        if [ $? -eq 1 ]; then
                echo ERROR
                exit 1
        fi

}


#########################################################################################
# Main code
#########################################################################################

# no arguments provided ;
if [ $# -eq 0 ]; then
        usage;
        exit 1
fi

# check for provided arguments ;
while getopts ':hvp:d:c:' option; do
  case $option in
    h)
        usage;
        exit 0
        ;;
    v)
        VERBOSE=true
        ;;
    p)
        PORT=$OPTARG
        ;;
    d)
        DOMAIN=$OPTARG
        ;;
    c)
        DAYS_TO_ALERT_CRITC=$OPTARG
        ;;
   \?)
        printf "\n${RED}Illegal option: -%s${NC}\n" "$OPTARG" >&2
        usage;
        exit 1
        ;;
    :)
        printf "\n${RED}Missing argument for -%s${NC}\n" "$OPTARG" >&2
        usage;
        exit 1
        ;;
  esac
done

# echo some basic verbose info ;
echo_verbose "DOMAIN: $DOMAIN"
echo_verbose "DAYS_TO_ALERT_CRITC: $DAYS_TO_ALERT_CRITC"

# check if -d and -c options are present ;
if [ -z $DOMAIN ] || [ -z $DAYS_TO_ALERT_CRITC ]; then
        printf "\n${RED}Options -d and -c are required${NC}\n" "$OPTARG" >&2
        usage;
        exit 1
fi

# check for SSL port ;
echo_verbose "PORT WAS: $PORT"
if [ -z $PORT ]; then
        echo_verbose "No port was provided lets use default port [$DEFAULT_PORT]."
        PORT=$DEFAULT_PORT
fi
echo_verbose "PORT: $PORT"

# Get cert info
echo | openssl s_client -connect $DOMAIN:$PORT 2>/dev/null | openssl x509 -noout -subject -nameopt multiline -dates > /tmp/cert_verify.info

# verify cert-cn X domain
CN_FROM_CERT=`cat /tmp/cert_verify.info | awk '/commonName/ {print$NF}'`
echo_verbose "CN_FROM_CERT: $CN_FROM_CERT"

(echo "$DOMAIN" | grep -Eq  ^$CN_FROM_CERT$)
valid_neg

# retrieve the expiration date from the SSL certificate using the openssl tool ;
DATE_FROM_CERT=`cat /tmp/cert_verify.info | tail -1 | tr -s " " |cut -d "=" -f2 | cut -d " " -f1,2,4`
echo_verbose "DATE_FROM_CERT: $DATE_FROM_CERT"

# convert the expitation date from the certificate ;
DATE_FROM_CERT_FORMATTED=`printf '== %s\n' "$DATE_FROM_CERT" | awk '{ printf "%04d%02d%02d\n", $4, (index("JanFebMarAprMayJunJulAugSepOctNovDec",$2)+2)/3, $3 }'`
echo_verbose "DATE_FROM_CERT_FORMATTED: $DATE_FROM_CERT_FORMATTED"
           
# retrieve the current date and format it ;
DATE_NOW=`date "+%b %d %Y"`
echo_verbose "DATE_NOW: $DATE_NOW"
DATE_NOW_FORMATTED=`printf '== %s\n' "$DATE_NOW" | awk '{ printf "%04d%02d%02d\n", $4, (index("JanFebMarAprMayJunJulAugSepOctNovDec",$2)+2)/3, $3 }'`
echo_verbose "DATE_NOW_FORMATTED: $DATE_NOW_FORMATTED"
           
# convert the current date to days ;
convert_to_mjd $DATE_NOW_FORMATTED
DATE1=$my_date

# convert the certificate expiration date to days ;
convert_to_mjd $DATE_FROM_CERT_FORMATTED
DATE2=$my_date

# calculate the difference between current date and expiration date in days ;
DATE_DIFF=`expr $DATE2 - $DATE1`

# verbose info ;
echo_verbose "DATE1: $DATE1"
echo_verbose "DATE2: $DATE2"
echo_verbose "DATE_DIFF: $DATE_DIFF"

# clean certificate.info tmp file
rm -f /tmp/cert_verify.info

# check if the result from the calulation is greater then the specified days to alarm ;
if [[ $DATE_DIFF -gt $DAYS_TO_ALERT_CRITC ]]; then
        echo "OK"
        exit 0
else
        echo "ERROR"
        exit 1
fi


# End ;
