#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq yt-dlp ffmpeg_7-full bc
# shellcheck shell=bash

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

# Format to arguments mapping
declare -A FORMAT_ARGS=(
	["m4a"]="${AUDIO_ARGS[*]} --audio-format m4a"
	["mp3"]="${AUDIO_ARGS[*]} --audio-format mp3"
	["mp4"]="${VIDEO_ARGS[*]}"
	["m4a-cut"]="${AUDIO_ARGS[*]} --audio-format m4a --download-sections"
	["mp3-cut"]="${AUDIO_ARGS[*]} --audio-format mp3 --download-sections"
	["mp4-cut"]="${VIDEO_ARGS[*]} --download-sections"
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
	elif [[ $argument == *"-cut"* ]]; then
		cutOption=true
		format="${argument}"
	else
		if [[ -n "${FORMAT_ARGS[$argument]}" ]]; then
			format="$argument"
		else
			final_args+=" $argument"
		fi
	fi
}

# Validate required arguments
check_arguments() {
	[[ -z "$url" ]] && {
		echo "Error: Missing URL"
		exit 1
	}

	if [[ "$cutOption" == true ]]; then
		[[ -z "$timeRange" ]] && {
			echo "Error: Missing time range for -cut option"
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
		duration=$(yt-dlp "$url" -j | jq '.duration')
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

# Execute yt-dlp with the constructed argument set
execute_yt_dlp() {
	local formatArgs
	IFS=' ' read -r -a formatArgs <<<"${FORMAT_ARGS[$format]}"
	# NOTE: On some players, keeping the embedded chapters for trimmed
	# or cut videos can cause an inaccurate video duration report
	[[ "$cutOption" == true ]] && formatArgs+=("*${timeRange}" "--force-keyframes-at-cuts" "--no-embed-chapters")

	# Add time range to OUTPUT_ARGS if cutOption is true
	if [[ "$cutOption" == true ]]; then
		time_range=$(format_time_range)
		OUTPUT_ARGS=(-o "%(display_id)s${time_range}.%(ext)s")
	fi

	IFS=' ' read -r -a final_args_array <<<"$final_args"

	yt-dlp "$url" "${formatArgs[@]}" "${COMMON_ARGS[@]}" "${OUTPUT_ARGS[@]}" "${final_args_array[@]}"
}

# Main
for arg in "$@"; do
	parse_arguments "$arg"
done

check_arguments
execute_yt_dlp
