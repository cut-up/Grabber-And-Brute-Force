#!/bin/bash
LOGIN="./login.txt"
TMPDIR="/tmp/grabber"
TMPPREVIEW="$TMPDIR/preview.tmp"
TMPFORUM="$TMPDIR/forum.tmp"
TMPTHREAD="$TMPDIR/thread.tmp"
SOCKS5="192.168.1.1:9100"
USER_AGENT="Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
COOKIE="cf=81920b0392c893f7fed928c97d04da2d%3A00dce1542862c1689d0f2355059751ac"
URL="http://example.onion/"
PREFIX="page-"
PAUSE="60"

forum()
{
  error "$1"
  sed -n '/<a href="forums\/.\+\/" data-description="#nodeDescription-.\+">/p' "$TMPPREVIEW" | cut -d '"' -f 4 | sed "s#^#$URL#" >> "$TMPFORUM"
  sed -n '/<a href="forums\/.\+\/" class="menuRow">/p' "$TMPPREVIEW" | cut -d '"' -f 4 | sed "s#^#$URL#" >> "$TMPFORUM"
  echo -e "\e[01;32m"$1" - "$(wc -l "$TMPFORUM" | cut -d " " -f 1)"\e[00m"
}

thread()
{
  error "$1"
  sed -n '/data-previewUrl=".\+\/preview"/p' "$TMPPREVIEW" | cut -d '"' -f 2 | sed 's/preview$//' | sed "s#^#$URL#" >> "$TMPTHREAD"
  echo -e "\e[01;32m"$1" ("$2")\e[00m"
}

login()
{
  error "$1"
  # reputation 10+ (.\+.\+)
  sed -n '/<span style="color: green; font-weight: bold;text-decoration: none; float:right; padding: 0 3px 0 1px;">.\+.\+<\/span>/,/<div class="topic-nickname">/p' "$TMPPREVIEW" | sed -n '/<div class=\"topic-nickname\">/p' | sed 's/^.*<div class="topic-nickname"><a href="users\/.*\/" class="username" dir="auto" itemprop="name">//' | sed 's/^<span class="style[0-9]\+">//' | sed 's/<\/a>.*$//' | sed 's/<\/span>.*$//' >> "$LOGIN"
  echo -e "\e[01;32m"$1" ("$2")\e[00m"
}

preview()
{
  while read LINK ; do
    PAGE="$(curl --socks5-hostname "$SOCKS5" --user-agent "$USER_AGENT" --cookie "$COOKIE" --location --progress-bar "$LINK" | sed -n '/data-last=".\+"/p' | cut -d '"' -f 2 | head -n 1)"
    if [ "$PAGE" == "" ]; then PAGE="1" ; fi
    for (( i=1; i<"$PAGE"+1; i++ )) ; do
      "$1" "$LINK""$PREFIX""$i" "$PAGE"
    done
  done < "$2"
}

error() {
  curl --socks5-hostname "$SOCKS5" --user-agent "$USER_AGENT" --cookie "$COOKIE" --location --progress-bar "$1" > "$TMPPREVIEW"
  if [ "$(stat -c %s "$TMPPREVIEW")" -lt 1024 ] ; then
    echo -en "\e[01;30m"$1"\e[00m"
    for (( i=0; i<"$PAUSE"; i++ )) ; do
      if [ "$i" == "$(echo $(( $PAUSE - 1 )))" ] ; then
        echo -e "\e[01;30m!\e[00m"
      else
        echo -en "\e[01;30m.\e[00m"
      fi
      sleep 1
    done
    error "$1"
  fi
}

mkdir -p "$TMPDIR"

forum "$URL"
preview "thread" "$TMPFORUM"
preview "login" "$TMPTHREAD"

exit 0