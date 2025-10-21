#!/bin/bash
norm="\033[0;0m"
red="\033[0;31m"
green="\033[0;32m"

if [ $# -ne 2  ]; then
	echo -e "$red [!] Usage:m2m <universal_resource_locater> <filename.ext> $norm"
	exit 1
fi	


mkdir -p $HOME/Music/ytdownloads
YTDIR="$HOME/Music/ytdownloads"

yt-dlp $1 -o $YTDIR/ytvideo.webm
ffmpeg -i $YTDIR/ytvideo.web* -c copy  $YTDIR/$2
rm $YTDIR/ytvideo.web*
echo -e "$green Done downloading !! $norm" 
