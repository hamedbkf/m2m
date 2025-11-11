#!/bin/bash

norm="\033[1;0m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"

#Script natives
VERSION="2.3.7-1"

#Making arrangements before executing the script

YTDIR="$HOME/Music/ytdownloads"
MULTI_DIR="$YTDIR/multi_mode"
PLAYLIST_DIR="$YTDIR/playlists"
ERROR_LOG="$HOME/.local/share/m2m_error_log"
mkdir -p "$YTDIR"
mkdir -p "$MULTI_DIR"
mkdir -p "$ERROR_LOG"
DATE=$(date +'%a_%b_%d_%H_%M_%S')
READ_TIMEOUT=15
LINK=""
file_name="placeholder"
playlist_switch=false
multiple_switch=false
opt_dest_dir_switch=false

#Processing spinner/indicator
spinner(){
    color=$1            #Color applied before spinner
    step_output=$2      #Step/Operation text
    pid=$!              #PID of most recent process (now in background)
    spin="/-\\|/-\\|";
    spinner_len=${#spin}

    while kill -0 $pid 2>/dev/null  #While the process PID still exists
    do
        i=$(( (i+1) % $spinner_len ))
        echo -ne "\r$color[${spin:i:1}] $step_output"
        sleep .3
    done

    #Step done
    echo -ne "\r$color[*] $step_output"
    echo -e
}

multi_dnc(){
	dest_dir=$1
	#counter=1
	for file in "${!multiple_download_dict[@]}";do
		url="${multiple_download_dict[$file]}"
		counter=$(yt-dlp -J "$url" 2>/dev/null | jq -r '.title' | tr -cd '[:alnum:] ' | tr ' ' '_')
		if [[ $file == *"wav"* ]] || [[ $file == *"mp3"* ]];then
			yt-dlp -f bestaudio $url -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>$ERROR_LOG/$DATE-yt-dlp-multi-download.log &
		else
			yt-dlp -f best $url -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>$ERROR_LOG/$DATE-yt-dlp-multi-download.log &
		fi
		spinner "$blue" "Initiating download for stream $yellow $counter $norm"
		
		if [[ $? -eq 0 ]];then
	
			echo -e "$green[✓] Stream downloaded $norm"
			
			if [[ $file == *"wav"* ]] || [[ $file == *"mp3"* ]];then
				ffmpeg -i "$dest_dir/ytvideo.webm" "$dest_dir/$file" -y 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-multi-download.log" &
			else
				ffmpeg -i "$dest_dir/ytvideo.webm" -map 0:a:0 -map 0:v:0 -c copy "$dest_dir/$file" -y 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-multi-download.log" &
			fi
			spinner "$blue" "Converting$yellow $counter$blue to $yellow$file $norm"

			if [[ $? -eq 0  ]];then
				echo -e "$green[✓] Stream $file saved to filesystem$norm \n"
				rm "$dest_dir"/ytvideo.*
			else
				echo -e "$red[!] An error occured $norm"
				echo -e "$red[!] Error saved at $ERROR_LOG $norm"
				continue
			fi

		else
			echo -e "$red[!] Stream $counter not downloaded $norm"
			echo -e "$red[!] Error saved at $ERROR_LOG $norm \n"
			continue
		fi
		#counter=$(($counter+1))	
	done

}

download_pl(){

	if [[ $opt_dest_dir_switch == true ]];then
		dest_dir=$opt_dest_dir
	else
		dest_dir=$PLAYLIST_DIR
	fi

	pl_url="$1"
	if [[ "$pl_url" != *list=* ]];then
		echo -e "$red[!] m2m: Error: Invalid playlist link$norm"
		exit 1
	fi
	echo -e "$blue[*] Acquiring playlist data from YouTube$norm"
	json=$(yt-dlp --flat-playlist -J "$pl_url")
    playlist_title="$(echo "$json" | jq -r '.title' | tr -cd '[:alnum:] ' |tr ' ' '_')"
	dest_dir="$dest_dir/$playlist_title"
	mkdir -p "$dest_dir"
	declare -A playlist_data
	
	# Getting the video titles and urls from youtube

	while IFS=$'\t' read -r vd_url title;do
		safe_title=$(echo "$title" | tr -cd '[:alnum:] ' | tr ' ' '_')
		playlist_data["$safe_title"]="$vd_url"
	done < <(echo "$json" | jq -r '.entries[] | [.url,.title] | @tsv') 	#<--- The core of the playlist method

	echo -e "$blue[*] Playlist data aquired, choose an extension (default: wav)$norm"

	if ! read -t "$READ_TIMEOUT" -p ">>" filetype; then
		echo -e "$yellow[!] Extension time out, using default (wav)$norm"
		filetype="wav"
	elif [[ $filetype == "" ]];then
		filetype="wav"
	fi
	
	counter=1
	for name in ${!playlist_data[@]};do
		url=${playlist_data[$name]}

		if [[ $filetype == *"wav"* ]] || [[ $filetype == *"mp3"* ]];then
			yt-dlp -f bestaudio $url -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>$ERROR_LOG/$DATE-yt-dlp-playlist-download.log &
		else
			yt-dlp -f best $url -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>$ERROR_LOG/$DATE-yt-dlp-playlist-download.log &
		fi
		spinner "$blue" "Downloading stream $counter ($name)"

		if [[ $? -eq 0 ]];then
	
			echo -e "$green[✓] Stream $counter downloaded $norm"
			
			if [[ $filetype == *"wav"* ]] || [[ $filetype == *"mp3"* ]];then
				ffmpeg -i "$dest_dir/ytvideo.webm" "$dest_dir/$name.$filetype" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-playlist-download.log" &
			else
				ffmpeg -i "$dest_dir/ytvideo.webm" -map 0:a:0 -map 0:v:0 -c copy "$dest_dir/$name.$filetype" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-playlist-download.log" &
			fi
            spinner "$blue" "Converting stream $counter $norm"

			if [[ $? -eq 0  ]];then
				echo -e "$green[✓] Stream $counter saved to filesystem$norm \n"
				rm "$dest_dir"/ytvideo.*
			else
				echo -e "$red[!] An error occured $norm"
				echo -e "$red[!] Error saved at $ERROR_LOG $norm"
				continue
			fi

		else
			echo -e "$red[!] Stream $counter not downloaded $norm"
			echo -e "$red[!] Error saved at $ERROR_LOG $norm \n"
			continue
		fi
		counter=$(($counter+1))
	done
}

show_version(){
	echo -e "$blue[*] m2m: Version: $VERSION $norm"
	exit 0
}

show_help(){
	echo -e "
 __  __ ____  __  __ 		
|  \/  |___ \|  \/  |	
| |\/| | __) | |\/| |	m2m v"$VERSION"
| |  | |/ __/| |  | |	
|_|  |_|_____|_|  |_|           

Usage: For single downloads
m2m <url> <filename.ext> [-d <destination_dir>]

For multiple downloads: (put number of downloads as 'n' for infinite downloads)
m2m -m <number_of_files_to_download> [-d <destination_dir>]

For downloading playlists:
m2m -pl <playlist_url>

Flags:
	-h|--help|-? 		Show this help message
	-m|--multi-download	Use multi download mode (described above)
	-d|--destination	Use the provided destination directory rather than the default one
	-pl|--playlist|-PL 	Download an entire playlist not just a video
	"
}

main(){

# OLD OUTPUT PARSING LOGIC

# for ((i=1; i<=$#; i++)); do
# 	arg="${!i}"
# 	case $arg in
# 		-m|--multi-download)
# 			multiple_switch=true;
# 			next=$((i+1));
# 			multiple_switch_counter=${!next}
# 			i=$next       # <-- skips 'n' from the argument check 
# 			;;
#
#         -d|--destination)
#             if [ $i -eq $# ]; then      #Check if there is no more arguments
#                 echo -e "$yellow[!] m2m: Error: Missing path variable for destination directory after $red-d$yellow$norm"
#                 echo -e "$red[!] Usage:m2m <universal_resource_locater> <filename.ext> [-d <destination_dir>]$norm"
#                 exit 1;
#             fi
#             opt_dest_dir_switch=true;
#             dir_arg=$(($i+1))
#             opt_dest_dir="${!dir_arg}"
#
#             if [[ "$opt_dest_dir" == "-"* ]];then     #Check if directory starts with "-"
#                 echo -e "$yellow[!] m2m: Error: Missing path variable for destination directory after $red-d$yellow (got $opt_dest_dir)$norm"
#                 echo -e "$red[!] Usage: m2m <universal_resource_locater> <filename.ext> [-d <destination_dir>] $norm"
#                 exit 1
#             elif [[ ! -d "$opt_dest_dir" ]]; then      #Check if directory does not exist
#                 echo -e "$yellow[!] m2m: Error: Output directory ($red$opt_dest_dir$yellow) does not exist! $norm"
#                 exit 1
#
#             fi
#             ;;
#
#         http*://*)
#             if [[ $i -eq $#  && $playlist_switch == false ]]; then
#                 echo -e "$red[!] Usage:m2m <universal_resource_locater> <filename.ext> [-d <destination_dir>]$norm"
#                 exit 1;
#             fi
#
# 			LINK="$arg"
#             file_arg=$(($i+1))
#             file_name="${!file_arg}"
#
#             if [[ "$file_name" == "-"* ]];then     #Check if file_name starts with "-"
#                 echo -e "$yellow[!] m2m: Error: Missing missing file name variable after$red link$yellow (got $file_name)$norm"
#                 echo -e "$red[!] Usage: m2m <universal_resource_locater> <filename.ext> [-d <destination_dir>] $norm"
#                 exit 1
#             fi
#             ;;
#
#     -pl|--playlist|-PL)
# 	    playlist_switch=true
# 	    next=$((i+1))
# 	    playlist_url=${!next}
# 	    if [[ -z "$playlist_url" ]] || [[ "$playlist_url" == "-"* ]];then
# 		    echo -e "$yellow[!] m2m: Error: Missing playlist URL after $red$arg$norm"
#             echo -e "$red[!] Usage: m2m -pl|--playlist|-PL <universal_resource_locater> [-d <destination_dir>]$norm"
#             exit 1
# 	    elif [[ "$playlist_switch" == true && $# -gt 4 ]];then
# 		    echo -e "$yellow[!] m2m: Error: Using playlist flag cannot have more than 3 arguments,$red $(($#-1)) provided.$norm"
# 		    echo -e "$red[!] m2m: Usage: m2m -pl|--playlist|-PL <universal_resource_locater> [-d <destination_dir>]$norm"
# 		    exit 1
# 	    fi
#
# 	    i=$((i+1))  #Skip playlist link we just got or it will break next iteration in the https link case
#                     #TODO: Cleaner arguments parsing to avoid such cases
# 	    ;;
#
#         -v|--version|-V)
#             show_version
#             return 0
#             ;;
#
# 		-h|--help|-?)
# 			show_help
#             exit 0
#             ;;
# 	esac
# done

for arg in "$@";do
	case $arg in
		-pl)
			set -- "${@/-pl/-p}";;
		--playlist)
			set -- "${@/--playlist/-p}";;
		--destination)
			set -- "${@/--destination/-d}";;
	esac
done

while getopts ":m:o:p:vh" arg;do
	case $arg in
		m)
			multiple_switch=true
			multiple_switch_counter="$OPTARG"
			;;
		o)
			opt_dest_dir_switch=true
			opt_dest_dir="$OPTARG"
			if [[ ! -d "$opt_dest_dir" ]]; then
                echo -e "$yellow[!] m2m: Error: Output directory ($red$opt_dest_dir$yellow) does not exist!$norm"
                exit 1
            fi
			;;
		p)
			playlist_switch=true
			playlist_url="$OPTARG"
			if [[ -z "$playlist_url" ]]; then
                echo -e "$yellow[!] m2m: Error: Missing playlist URL after $red-p$norm"
                exit 1
            fi
			;;
		v)
			show_version
			exit 0
			;;
		h|\?)
			show_help
			exit 0
			;;
		:)
			echo -e "$red[! m2m: Error: Missing argument for -$OPTARG$norm"

	esac
done

shift $((OPTIND-1))

for arg in "$@";do
	case $arg in
		http*://*)
			LINK="$arg"
			;;
		*)
			file_name=$arg
	esac
done

if [[ -z "$LINK" && $playlist_switch == false && $multiple_switch == false ]]; then
    echo -e "$red[!] Usage: m2m <url> <filename.ext> [-d <destination_dir>]$norm"
    exit 1
fi

if [[ -z "$file_name" && $playlist_switch == false && $multiple_switch == false ]]; then
    echo -e "$yellow[!] m2m: Error: Missing filename argument after URL$norm"
    exit 1
fi



if [[ $multiple_switch != true  && $playlist_switch != true ]];then

	if [[ $opt_dest_dir_switch == true ]];then
		dest_dir=$opt_dest_dir
	else
		dest_dir=$YTDIR
	fi
	title=$(yt-dlp -J "$LINK" 2>/dev/null | jq '.title' | tr -cd '[:alnum:] ' | tr ' ' '_')

	if [[ $file_name == *"wav"* ]] || [[ $file_name == *"mp3"*  ]];then
		yt-dlp -f bestaudio $LINK -o "$dest_dir/ytvideo.webm" 1> /dev/null  2>"$ERROR_LOG/$DATE-yt-dlp.log" & 
	else
		yt-dlp -f best $LINK -o "$dest_dir/ytvideo.webm" 1> /dev/null 2>$ERROR_LOG/$DATE-yt-dlp.log &
	fi
	spinner "$blue" "Downloading stream $yellow$title$norm"

	#Block telling the user whether the stream was downloaded or not
	if [[ $? -eq 0 ]];then
		echo -e "$blue[*] Stream downloaded $norm"
		
		if [[ $opt_dest_dir_switch == true ]];then
			file_save_location=$opt_dest_dir
		else
			echo -e "These are the directories in $dest_dir \n$(ls $dest_dir)\nWhere do you want to save this one?"
			read -p ">> " file_save_location
			file_save_location="$dest_dir/$file_save_location"
		fi
	else
		echo -e "$red[!] Stream not downloaded $norm"
		echo -e "$red[!] Error saved at $ERROR_LOG $norm"
		exit 1
	fi
	
	if [[ "$file_name" == *"wav"* ]] || [[ $file_name == *"mp3"* ]];then
		ffmpeg -i "$dest_dir/ytvideo.webm" "$file_save_location/$file_name" -y 1>/dev/null 2>"$ERROR_LOG/$DATE-ffmpeg.log" &
	else
		ffmpeg -i "$dest_dir/ytvideo.webm" -map 0:a:0 -map 0:v:0 -c copy "$file_save_location/$file_name" -y 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg.log" &
	fi
	spinner "$blue" "Converting stream $yellow$title$blue to $yellow$file_name$norm"

	#Block telling the user the final action and removing the ghost file.
	if [[ $? -eq 0  ]];then
		rm "$dest_dir"/ytvideo.web*
		echo -e "$green[*] Streams Saved to filesystem at $file_save_location !! $norm" 
	else
		echo -e "$red[!] An error occured $norm"
		echo -e "$red[!] Error saved at $ERROR_LOG $norm"
	fi

fi


if [[ $playlist_switch == true ]];then
	download_pl "$playlist_url"
fi


if [[ $multiple_switch == true && $multiple_switch_counter != "n" ]];then
	#Taking the multiple links and file names from the user
	declare -A multiple_download_dict

	for((i=1;i<=$multiple_switch_counter;i++));do
	read -p "Enter the URL: " url
	read -p "Enter the name to save it as: " save_file
	multiple_download_dict["$save_file"]="$url"
	done

    if [[ $opt_dest_dir_switch != true ]];then
		multi_dnc "$MULTI_DIR"
	else
		multi_dnc "$opt_dest_dir"
	fi
fi

if [[ $multiple_switch_counter == "n" ]];then
	declare -A multiple_download_dict
	declare url=""

	while true;do
		read -p "Enter the URL(type 'done' when you are done): " url
		if [[ "$url" == "done" ]];then break; fi
		read -p "Enter the name to save it as: " save_file
		multiple_download_dict["$save_file"]="$url"
	done

    if [[ $opt_dest_dir_switch != true ]];then
		multi_dnc "$MULTI_DIR"
	else
		multi_dnc "$opt_dest_dir"
	fi
fi
}


main "$@"
