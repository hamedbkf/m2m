#!/bin/bash

norm="\033[1;0m"
red="\033[1;31m"
green="\033[1;32m"
yellow="\033[1;33m"
blue="\033[1;34m"

#Script natives
VERSION="2.3.2"

#Making arrangements before executing the script

YTDIR="$HOME/Music/ytdownloads"
MULTI_DIR="$YTDIR/multi_mode"
ERROR_LOG="$HOME/.local/m2m_error_log"
mkdir -p "$YTDIR"
mkdir -p "$MULTI_DIR"
mkdir -p "$ERROR_LOG"
DATE=$(date +'%a_%b_%d_%H_%M_%S')
LINK=""
file_name="placeholder"
multiple_switch=false
ouput_dir_switch=false

multi_dnc(){
	dest_dir=$1
	counter=1
	for file in "${!multiple_download_dict[@]}";do
		url="${multiple_download_dict[$file]}"

		echo -e "$blue[*] Initiating download for stream $counter $norm"
		if [[ $file == *"wav"* ]] || [[ $file == *"mp3"* ]];then
			yt-dlp -f bestaudio $url -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>$ERROR_LOG/$DATE-yt-dlp-multi-download.log
		else
			yt-dlp -f best $url -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>$ERROR_LOG/$DATE-yt-dlp-multi-download.log
		fi
		
		if [[ $? -eq 0 ]];then
	
			echo -e "$green[✓] Stream $counter downloaded $norm"
			echo -e "$blue[*] Converting stream $counter $norm"
			
			if [[ $file == *"wav"* ]] || [[ $file == *"mp3"* ]];then
				ffmpeg -i "$dest_dir/ytvideo.webm" "$dest_dir/$file" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-multi-download.log"
			else
				ffmpeg -i "$dest_dir/ytvideo.webm" -map 0:a:0 -map 0:v:0 -c copy "$dest_dir/$file" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg-multi-download.log"
			fi

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

show_help(){
	echo -e "
 __  __ ____  __  __ 		
|  \/  |___ \|  \/  |	
| |\/| | __) | |\/| |	m2m v"$VERSION"
| |  | |/ __/| |  | |	
|_|  |_|_____|_|  |_|           

Usage: For single downloads
m2m <url> <filename.ext> [-o <output_directory>]

For mutliple downloads: (put number of downloads as 'n' for infinite downloads)
m2m -m <number_of_files_to_download> [-o <output_direcotory>]

Flags:
	-h|--help|-? 		Show this help message
	-m|--multi-download	Use multi download mode (described above)
	-o|--output		Use the provided output directory rather than the default one
	"
}

main(){
for ((i=1; i<=$#; i++)); do
	arg="${!i}"
	case $arg in
		-m|--multi-download)
			
			multiple_switch=true; 
			next=$((i+1));
			multiple_switch_counter=${!next}
			i=$next       # <-- skips 'n' from the argument check
			;;

        	-o|--output)

            		if [ $i -eq $# ]; then
                		echo -e "$red[!] Usage:m2m <universal_resource_locater> <filename.ext> [-o <output_directory>]$norm"
                		exit 1;
            		fi
            		output_dir_switch=true;
            		dir_arg=$(($i+1))
            		output_dir="${!dir_arg}"

	    		if [[ "$output_dir" == "-"* ]] || [[ -z "$file_name" && $multiple_switch == false ]];then
		    		echo -e "$yellow[!] m2m: Error: Missing path variable for output directory after $red-o$yellow (got $output_dir)$norm"
		    		echo -e "$red[!] Usage: m2m <universal_resource_locater> <filename.ext> [-o <output_directory>] $norm"
		    		exit 1
	    		fi
            		;;

    		http*://*)	
			LINK="$arg"
	    		;;

    		-h|--help|-?)
	    		
			show_help
	    		exit 0
	    		;;

    		*)  #Would assign the non flag value to $file_name
			file_name="$arg"
	esac
done


if [[ true ]]; then
	if [[ $multiple_switch == false && $# -lt 2 ]];then
		echo -e "$red[!] Usage:m2m <universal_resource_locater> <filename.ext> [-o <output_directory>]$norm"
		exit 1
	elif [[ $multiple_switch == true && $# -lt 2 ]];then
		echo -e "$red[!] Usage: m2m -m <download_count> [-o <output_directory>]$norm"
		echo "For infinite downloads"
		echo -e "$red[!] Usage: m2m -m n [-o <output_directory>]$norm"
		exit 1
	fi
fi



if [[ $multiple_switch != true ]];then

	if [[ $output_dir_switch == true ]];then
		dest_dir=$output_dir
	else
		dest_dir=$YTDIR
	fi
	echo -e  "$blue[*] Downloading stream from youtube $norm"

	if [[ $file_name == *"wav"* ]] || [[ $file_name == *"mp3"*  ]];then
		yt-dlp -f bestaudio $LINK -o "$dest_dir/ytvideo.webm" 1>/dev/null 2>"$ERROR_LOG/$DATE-yt-dlp.log"
	else
		yt-dlp -f best $LINK -o "$dest_dir/ytvideo.webm" 1> /dev/null 2>$ERROR_LOG/$DATE-yt-dlp.log
	fi
	#Block telling the user whether the stream was downloaded or not

	if [[ $? -eq 0 ]];then
	
		echo -e "$blue[*] Stream downloaded $norm"
		
		if [[ $output_dir_switch == true ]];then
			file_save_location=$output_dir
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
	
	echo -e "$blue[*] Converting the stream...$norm"
	
	if [[ "$file_name" == *"wav"* ]] || [[ $file_name == *"mp3"* ]];then
		ffmpeg -i "$dest_dir/ytvideo.webm" "$file_save_location/$file_name" 1>/dev/null 2>"$ERROR_LOG/$DATE-ffmpeg.log"
	else
		ffmpeg -i "$dest_dir/ytvideo.webm" -map 0:a:0 -map 0:v:0 -c copy "$file_save_location/$file_name" 1> /dev/null 2>"$ERROR_LOG/$DATE-ffmpeg.log"
	fi

	#Block telling the user the final action and removing the ghost file.

	if [[ $? -eq 0  ]];then
		rm "$dest_dir"/ytvideo.web*
		echo -e "$green[*] Streams Saved to filesystem at $file_save_location !! $norm" 
	else
		echo -e "$red[!] An error occured $norm"
		echo -e "$red[!] Error saved at $ERROR_LOG $norm"
	fi

fi

if [[ $multiple_switch == true && $multiple_switch_counter != "n" ]];then
	#Taking the multiple links and file names from the user
	declare -A multiple_download_dict

	for((i=1;i<=$multiple_switch_counter;i++));do
	read -p "Enter the URL: " url
	read -p "Enter the name to save it as: " save_file
	multiple_download_dict["$save_file"]="$url"
	done

    if [[ $output_dir_switch != true ]];then
		multi_dnc "$MULTI_DIR"
	else
		multi_dnc "$output_dir"
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

    if [[ $output_dir_switch != true ]];then
		multi_dnc "$MULTI_DIR"
	else
		multi_dnc "$output_dir"
	fi
fi
}


main "$@"
