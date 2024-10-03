#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq yt-dlp ffmpeg_7-full bc coreutils
# shellcheck shell=bash

# Help menu
show_help() {
printf "Usage: URL [TIME_RANGE] [ADDITIONAL_ARGS]
Arguments:
	URL                 The URL of the video to download.
	TIME_RANGE          Optional. The time range to cut (e.g., '30-60').
						Required if using a '-cut' format.
	ADDITIONAL_ARGS     Optional. Any additional arguments to pass to yt-dlp.

Examples:
https://example.com/video
https://example.com/video 30-60
https://example.com/video 30-60 --no-playlist
https://example.com/video --no-playlist
"
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
format=""
final_args="--ignore-config"
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
	elif [[ $argument == *"-cut"* ]] || [[ ${FORMAT_ARGS[$argument]+_} ]]; then
		format="${argument}"
		cutOption=true  # Set cutOption to true if a -cut format is detected
	elif [[ $argument == "--help" || $argument == "-h" ]]; then
		show_help
		exit 0
	else
		final_args+=" $argument"
	fi
}

# Validate required arguments
check_arguments() {
	[[ -z "$url" ]] && {
		echo "Error: Missing URL"
		show_help
		exit 1
	}

	if [[ "$cutOption" == true ]]; then
		[[ -z "$timeRange" ]] && {
			echo "Error: Missing time range for -cut option"
			show_help
			exit 1
		}

		local startTime endTime
		startTime=$(echo "$timeRange" | cut -d'-' -f1)
		endTime=$(echo "$timeRange" | cut -d'-' -f2)

		(($(echo "$startTime > $endTime" | bc -l))) && {
			echo "Error: Start time is greater than end time in time range"
			exit 1
		}
		(($(echo "$startTime < 0" | bc -l))) && {
			echo "Error: Start time cannot be negative"
			exit 1
		}

		# Check if the end time is valid
		duration=$(echo "$json_metadata" | jq '.duration')
		(($(echo "$endTime > $duration" | bc -l))) && {
			echo "Error: End time exceeds video duration"
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
    fi

    IFS=' ' read -r -a final_args_array <<<"$final_args"

    yt-dlp "$url" "${formatArgs[@]}" "${COMMON_ARGS[@]}" "${OUTPUT_ARGS[@]}" "${final_args_array[@]}"
}

# Change file creation date to uploader date
change_file_date() {
    local upload_date display_id
    upload_date=$(echo "$json_metadata" | jq -r '.upload_date')
    display_id=$(echo "$json_metadata" | jq -r '.display_id')

    if [[ -n "$upload_date" ]]; then
        local formatted_date
        formatted_date=$(date -d "$upload_date" +"%Y%m%d%H%M.%S")

        for file in "${display_id}"*; do
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
    echo "Error: Missing URL"
    show_help
    exit 1
fi

# Fetch JSON metadata once
json_metadata=$(yt-dlp "$url" -j) || {
    echo "Error: Failed to fetch JSON metadata"
    exit 1
}

check_arguments
execute_yt_dlp
change_file_date
