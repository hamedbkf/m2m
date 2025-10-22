#!/bin/bash

norm="\033[0;0m"
red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
blue="\033[0;34m"

if [ $# -ne 2  ]; then
	echo -e "$red [!] Usage:m2m <universal_resource_locater> <filename.ext> $norm"
	exit 1
fi	

#Making arrangements before executing the script

mkdir -p "$HOME/Music/ytdownloads"
mkdir -p "$HOME/.local/m2m_error_log"
YTDIR="$HOME/Music/ytdownloads"
ERROR_LOG="$HOME/.local/m2m_error_log"
DATE=$(date +'%a_%b_%d_%H_%M_%S')

echo -e  "$blue[*] Downloading stream from youtube $norm"

yt-dlp -f 91 $1 -o "$YTDIR/ytvideo.webm" 1> /dev/null 2>$ERROR_LOG/$DATE-yt-dlp.log

#Block telling the user whether the stream was downloaded or not

if [[ $? -eq 0 ]];then
	
	echo -e "$blue[*] Stream downloaded $norm"
	read -p "Press 1 to re-encode and 2 to copy existing streams: " choice

	echo -e "These are the directories in $YTDIR \n$(ls $YTDIR )\nWhere do you want to save this one?"
	read -p ">> " file_save_location 

else
	echo -e "$red[!] Stream not downloaded $norm"
	echo -e "$red[!] Error saved at $ERROR_LOG $norm"
	exit 1
fi


#Block asking the user to make a choice between re-encoding and copying 

if [[ "$choice" -eq 1 ]];then
	echo -e "$blue[*] Re-encoding the stream...$norm"
	ffmpeg -i "$YTDIR/ytvideo.webm" "$YTDIR/$file_save_location/$2" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-re-encode.log"
elif [[ "$choice" -eq 2  ]];then 
	echo -e "$blue[*] Copying the original streams...$norm"
	ffmpeg -i "$YTDIR/ytvideo.webm" -c copy  "$YTDIR/$file_save_location/$2" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-copy.log"
else
	echo -e "$red[!] Enter a valid choice $norm"
	exit 1
fi

#Block telling the user the final action and removing the ghost file.

if [[ $? -eq 0  ]];then
	rm $YTDIR/ytvideo.web*
	echo -e "$green[*] Streams Saved to filesystem at $YTDIR !! $norm" 
else
	echo -e "$red[!] An error occured $norm"
	echo -e "$red[!] Error saved at $ERROR_LOG $norm"
fi
