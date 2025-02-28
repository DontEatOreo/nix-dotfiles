#! /usr/bin/env nix-shell
#! nix-shell --pure -i bash -p bc cacert coreutils ffmpeg_7-full jq ncurses yt-dlp
# shellcheck shell=bash

# Help menu
show_help() {
	printf "Usage: URL [TIME_RANGE] [ADDITIONAL_ARGS]
Arguments:
	URL                 The URL of the video to download.
	TIME_RANGE          Optional. The time range to cut (e.g., '30-60').
						Required if using a '-cut' format.
	ADDITIONAL_ARGS     Optional. Any additional arguments to pass to yt-dlp.

Options:
	--compress          Download and compress the video.
	--crf VALUE         Specify the CRF value for compression (default: 26).

Examples:
https://example.com/video
https://example.com/video 30-60
https://example.com/video 30-60 --compress
https://example.com/video --compress
https://example.com/video --compress --crf 22
"
}

log_error() {
	echo "[error] $1"
}

log_info() {
	echo "[info] $1"
}

log_compress() {
	echo "[compress] $1"
}

log_warning() {
	echo "[warning] $1"
}

log_question() {
	echo "[?] $1"
}

log_success() {
	echo "[success] $1"
}

# Constants
declare -a COMMON_ARGS=(--progress --console-title --embed-metadata)
declare -a AUDIO_ARGS=(--embed-thumbnail --extract-audio --audio-quality 0)
declare -a VIDEO_ARGS=(-S "vcodec:h264,ext:mp4:m4a")
declare -a OUTPUT_ARGS=(-o "%(display_id)s%(time_range)s.%(ext)s")

# Variables
url=""
timeRange=""
cutOption=false
compressOption=false
crf=26
format=""
declare -a final_args=("--ignore-config")
json_metadata=""

# Format to arguments mapping
declare -A FORMAT_ARGS=(
	["m4a"]="${AUDIO_ARGS[*]} --audio-format m4a"
	["mp3"]="${AUDIO_ARGS[*]} --audio-format mp3"
	["mp4"]="${VIDEO_ARGS[*]}"
	["m4a-cut"]="${AUDIO_ARGS[*]} --audio-format m4a"
	["mp3-cut"]="${AUDIO_ARGS[*]} --audio-format mp3"
	["mp4-cut"]="${VIDEO_ARGS[*]}"
)

# Parse arguments
parse_arguments() {
	local argument="$1"
	local urlRegex="^(http|https)://"
	local timeRangeRegex="^([0-9]+(\.[0-9]+)?)-([0-9]+(\.[0-9]+)?)$"

	if [[ $argument =~ $urlRegex ]]; then
		url="$argument"
	elif [[ $argument =~ $timeRangeRegex ]]; then
		timeRange="${argument}"
	elif [[ ${FORMAT_ARGS[$argument]+_} ]]; then
		format="${argument}"
		# Set cutOption to true only if the format includes '-cut'
		[[ $format == *"-cut" ]] && cutOption=true
	elif [[ $argument == "--compress" ]]; then
		compressOption=true
	elif [[ $argument == "--crf" ]]; then
		crf="$2"
		shift
	elif [[ $argument == "--help" || $argument == "-h" ]]; then
		show_help
		exit 0
	else
		final_args+=("$argument")
	fi
}

# Validate required arguments
check_arguments() {
	[[ -z "$url" ]] && {
		log_error "Missing URL"
		show_help
		exit 1
	}

	if [[ "$cutOption" == true ]]; then
		[[ -z "$timeRange" ]] && {
			log_error "Missing time range for -cut option"
			show_help
			exit 1
		}

		local startTime endTime
		startTime=$(echo "$timeRange" | cut -d'-' -f1)
		endTime=$(echo "$timeRange" | cut -d'-' -f2)

		(($(echo "$startTime > $endTime" | bc -l))) && {
			log_error "Start time is greater than end time in time range"
			exit 1
		}
		(($(echo "$startTime < 0" | bc -l))) && {
			log_error "Start time cannot be negative"
			exit 1
		}

		# Check if the end time is valid
		duration=$(echo "$json_metadata" | jq '.duration')
		(($(echo "$endTime > $duration" | bc -l))) && {
			log_error "End time exceeds video duration"
			exit 1
		}
	fi
}

# Format time range for output file name
format_time_range() {
	local startTime endTime
	startTime=$(echo "$timeRange" | cut -d'-' -f1)
	endTime=$(echo "$timeRange" | cut -d'-' -f2)

	# Format time for the output file name
	local formattedStartTime formattedEndTime
	if [[ $startTime == *.* ]]; then
		formattedStartTime=$(printf "%02d_%02d" "${startTime%.*}" "${startTime#*.}")
	else
		formattedStartTime=$(printf "%02d" "$startTime")
	fi

	if [[ $endTime == *.* ]]; then
		formattedEndTime=$(printf "%02d_%02d" "${endTime%.*}" "${endTime#*.}")
	else
		formattedEndTime=$(printf "%02d" "$endTime")
	fi

	echo "-${formattedStartTime}-${formattedEndTime}"
}

execute_yt_dlp() {
	local formatArgs
	IFS=' ' read -r -a formatArgs <<<"${FORMAT_ARGS[$format]}"

	# Check if the video has chapters and append --no-embed-chapters if it does
	local has_chapters
	has_chapters=$(echo "$json_metadata" | jq '(.chapters // []) | length > 0')
	if [[ "$has_chapters" == "true" ]]; then
		formatArgs+=("--no-embed-chapters")
	fi

	# Append the time range to --download-sections if cutOption is true
	if [[ "$cutOption" == true ]]; then
		formatArgs+=("--download-sections=*${timeRange}")
		formatArgs+=("--force-keyframes-at-cuts")
		time_range=$(format_time_range)
		OUTPUT_ARGS=(-o "%(display_id)s${time_range}.%(ext)s")
	else
		OUTPUT_ARGS=(-o "%(display_id)s.%(ext)s") # When no time range is provided
	fi

	if [[ "$compressOption" == true ]]; then
		temp_dir=$(mktemp -d)
		OUTPUT_ARGS=(-o "$temp_dir/%(display_id)s.%(ext)s")
	fi

	yt-dlp "$url" "${formatArgs[@]}" "${COMMON_ARGS[@]}" "${OUTPUT_ARGS[@]}" "${final_args[@]}" \
		--postprocessor-args "ffmpeg:-hide_banner"

	if [[ "$compressOption" == true ]]; then
		compress_video "$temp_dir"
		rm -rf "$temp_dir"
	fi
}

get_file_size() {
	local file="$1"
	if [[ "$(uname)" == "Darwin" ]]; then
		# macOS - use wc -c as more reliable alternative
		wc -c <"$file" 2>/dev/null || echo "0"
	else
		stat --printf="%s" "$file" 2>/dev/null || echo "0"
	fi
}

format_size() {
	local size="$1"
	local power=0
	local units=("B" "KB" "MB" "GB")

	while [ "$(echo "$size > 1024" | bc -l)" -eq 1 ]; do
		size=$(echo "scale=2; $size/1024" | bc)
		power=$((power + 1))
	done

	printf "%.2f %s" "$size" "${units[$power]}"
}

create_stats_box() {
	local original_size=$1
	local compressed_size=$2
	local size_saved=$3

	# Default to ANSI color codes as fallback
	local GREEN RED WHITE NC
	GREEN='\033[0;32m'
	RED='\033[0;31m'
	WHITE='\033[1;37m'
	NC='\033[0m'

	if command -v tput >/dev/null 2>&1; then
		if ! GREEN=$(tput setaf 2 2>/dev/null); then
			echo "[warning] tput setaf 2 failed, using fallback colors" >&2
		fi
		if ! RED=$(tput setaf 1 2>/dev/null); then
			echo "[warning] tput setaf 1 failed, using fallback colors" >&2
		fi
		if ! WHITE=$(tput bold 2>/dev/null && tput setaf 7 2>/dev/null); then
			echo "[warning] tput bold/setaf 7 failed, using fallback colors" >&2
		fi
		if ! NC=$(tput sgr0 2>/dev/null); then
			echo "[warning] tput sgr0 failed, using fallback colors" >&2
		fi
	else
		echo "[warning] tput not found, using fallback colors" >&2
	fi

	# Disable colors if not in a terminal
	if [[ ! -t 1 ]]; then
		GREEN="" RED="" WHITE="" NC=""
	fi

	# Convert sizes to human readable format
	local original_hr
	original_hr=$(format_size "$original_size")
	local compressed_hr
	compressed_hr=$(format_size "$compressed_size")

	# Create the content strings first
	local title=" COMPRESSION STATISTICS"
	local original_line=" Original Size:    $original_hr"
	local compressed_line=" Compressed Size:  $compressed_hr"
	local saved_line=" Space Saved:      $size_saved%"

	# Calculate required width based on longest line
	local min_width=40 # Minimum width for aesthetics
	local max_len=0
	for line in "$title" "$original_line" "$compressed_line" "$saved_line"; do
		local len=${#line}
		((len > max_len)) && max_len=$len
	done

	# Add padding for box characters and spacing
	local width=$((max_len + 4))
	((width < min_width)) && width=$min_width

	local horizontal_line
	horizontal_line=$(printf '─%.0s' $(seq 1 $((width - 2))))
	local middle_line
	middle_line=$(printf '─%.0s' $(seq 1 $((width - 2))))

	printf '\n'
	printf "${WHITE}╭%s╮${NC}\n" "$horizontal_line"
	printf "${WHITE}│${NC}%-*s${WHITE}│${NC}\n" "$((width - 2))" "$title"
	printf "${WHITE}│${NC}%s${WHITE}│${NC}\n" "$middle_line"
	printf "${WHITE}│${NC}${RED}%-*s${NC}${WHITE}│${NC}\n" "$((width - 2))" "$original_line"
	printf "${WHITE}│${NC}${GREEN}%-*s${NC}${WHITE}│${NC}\n" "$((width - 2))" "$compressed_line"
	printf "${WHITE}│${NC}${GREEN}%-*s${NC}${WHITE}│${NC}\n" "$((width - 2))" "$saved_line"
	printf "${WHITE}╰%s╯${NC}\n" "$horizontal_line"
	printf '\n'
}

compress_video() {
	local temp_dir="$1"
	local input_file output_file
	input_file=$(find "$temp_dir" -type f)

	# Check if input file exists
	if [[ ! -f "$input_file" ]]; then
		log_error "Input file not found"
		return 1
	fi

	# Get original file size
	local original_size
	original_size=$(get_file_size "$input_file")
	log_info "Original file size: $(format_size "$original_size")"

	# Extract the base name without extension
	local base_name
	base_name=$(basename "$input_file" | sed 's/\.[^.]*$//')

	# Add the time range if it exists
	local time_range_suffix=""
	if [[ -n "$timeRange" ]]; then
		time_range_suffix=$(format_time_range)
	fi

	output_file="${PWD}/${base_name}${time_range_suffix}.mp4"

	local tune
	local tune_options=("1) film" "2) animation" "3) grain" "4) stillimage" "5) none")

	while true; do
		log_question "Choose a tune for compression:"
		for option in "${tune_options[@]}"; do
			echo "$option"
		done

		read -r tune_choice

		case "$tune_choice" in
		1)
			tune="film"
			break
			;;
		2)
			tune="animation"
			break
			;;
		3)
			tune="grain"
			break
			;;
		4)
			tune="stillimage"
			break
			;;
		5)
			tune="none"
			break
			;;
		*) log_error "Invalid option. Please choose a number between 1 and 5." ;;
		esac
	done

	local ffmpeg_cmd=("ffmpeg" "-hide_banner" "-i" "$input_file" "-c:v" "libx264" "-profile:v" "high" "-preset" "veryslow" "-crf" "$crf" "-c:a" "copy")

	# Add the -tune option only if it's not "none"
	if [[ "$tune" != "none" ]]; then
		ffmpeg_cmd+=("-tune" "$tune")
	fi

	# Add output file
	ffmpeg_cmd+=("$output_file")

	# Execute the ffmpeg command
	if ! "${ffmpeg_cmd[@]}"; then
		log_error "Compression failed"
		return 1
	fi

	# Check if output file exists
	if [[ ! -f "$output_file" ]]; then
		log_error "Compressed file was not created"
		return 1
	fi

	# Get compressed file size and calculate savings
	local compressed_size
	compressed_size=$(get_file_size "$output_file")

	local size_saved
	size_saved=$(echo "scale=2; ($original_size - $compressed_size) * 100 / $original_size" | bc)

	create_stats_box "$original_size" "$compressed_size" "$size_saved"

	# Check if savings are less than 25%
	if (($(echo "$size_saved < 25" | bc -l))); then
		log_warning "Compression only saved ${size_saved}% of space"
		log_question "Would you like to delete the compressed file and download without compression? (y/n)"
		read -r response
		if [[ "$response" =~ ^[Yy]$ ]]; then
			log_info "Removing compressed file..."
			rm "$output_file"
			log_info "Re-downloading without compression..."
			# Set compressOption to false for re-download
			compressOption=false
			# Re-download without compression
			OUTPUT_ARGS=(-o "%(display_id)s${time_range_suffix}.%(ext)s")
			execute_yt_dlp
		fi
	fi
}

# Change file creation date to uploader date
change_file_date() {
	local upload_date display_id
	upload_date=$(echo "$json_metadata" | jq -r '.upload_date')
	display_id=$(echo "$json_metadata" | jq -r '.display_id')

	if [[ -n "$upload_date" ]]; then
		local formatted_date

		if [[ "$OSTYPE" == "darwin"* ]]; then
			# macOS format: use string manipulation
			year=${upload_date:0:4}
			month=${upload_date:4:2}
			day=${upload_date:6:2}
			formatted_date="${year}${month}${day}0000.00"
		else
			# Linux format: use GNU date
			formatted_date=$(date -d "${upload_date:0:4}-${upload_date:4:2}-${upload_date:6:2}" +"%Y%m%d%H%M.%S")
		fi

		# Use find to handle filenames with special characters
		find . -maxdepth 1 -name "${display_id}*" -print0 | while IFS= read -r -d '' file; do
			touch -t "$formatted_date" "$file"
		done
	fi
}

# Main
for arg in "$@"; do
	parse_arguments "$arg"
done

# Check if URL is provided before fetching metadata
if [[ -z "$url" ]]; then
	log_error "Missing URL"
	show_help
	exit 1
fi

# Fetch JSON metadata once
json_metadata=$(yt-dlp "$url" -j) || {
	log_error "Failed to fetch JSON metadata"
	exit 1
}

check_arguments
execute_yt_dlp
change_file_date
