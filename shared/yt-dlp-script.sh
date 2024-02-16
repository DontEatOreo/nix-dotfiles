#!/bin/bash

# Define constants
declare -a COMMON_ARGS=(--progress --console-title)
declare -a AUDIO_ARGS=(--embed-thumbnail --extract-audio --audio-quality 0)
declare -a VIDEO_ARGS=(-S vcodec:h264,ext:mp4:m4a)
declare -a OUTPUT_ARGS=(-o "%(display_id)s.%(ext)s")

# Define variables
url=""
timeRange=""
cutOption=false
format=""

# Any additional arguments to be passed to the yt-dlp command
final_args="--ignore-config"

# Define format to arguments mapping
declare -A FORMAT_ARGS
FORMAT_ARGS["m4a"]="${AUDIO_ARGS[@]} --audio-format m4a --embed-metadata"
FORMAT_ARGS["mp3"]="${AUDIO_ARGS[@]} --audio-format mp3 --embed-metadata"
FORMAT_ARGS["mp4"]="${VIDEO_ARGS[@]} --embed-metadata"
FORMAT_ARGS["m4a-cut"]="${AUDIO_ARGS[@]} --audio-format m4a --download-sections"
FORMAT_ARGS["mp3-cut"]="${AUDIO_ARGS[@]} --audio-format mp3 --download-sections"
FORMAT_ARGS["mp4-cut"]="${VIDEO_ARGS[@]} --download-sections"

# Function to parse arguments and assign them to the correct variable
parse_arguments() {
  local argument="$1"

  # If the argument is a URL, assign it to url variable
  if [[ $argument =~ ^http ]]; then
    url=$argument

  # If the argument is a time range, assign it to timeRange variable
  elif [[ $argument =~ ^[0-9]+(\.[0-9]+)?-[0-9]+(\.[0-9]+)?$ ]]; then
    timeRange=$argument

  # If the argument is a cut option, set cutOption to true and set the format
  elif [[ $argument == *"-cut"* ]]; then
    cutOption=true
    format=$argument

  # If the argument is a valid format, assign it to format variable
  elif [[ -n ${FORMAT_ARGS[$argument]} ]]; then
    format=$argument

  # If the argument doesn't match any of the above options, display an error message and exit the script
  else
    echo "Error: Unexpected argument $argument"
    exit 1
  fi
}

# Function to check if all required arguments are provided
check_arguments() {
  # If URL is not provided, display an error message and exit the script
  if [[ -z $url ]]; then
    echo "Error: Missing URL"
    exit 1
  fi
  
  # If cut option is true but time range is not provided, display an error message and exit the script
  if [[ $cutOption == true && -z $timeRange ]]; then
    echo "Error: Missing time range for -cut option"
    exit 1
  fi
}

# Function to construct and execute the yt-dlp command using the provided arguments
execute_yt_dlp() {
  local cutArgs=(--force-keyframes-at-cuts)
  local formatArgs=(${FORMAT_ARGS[$format]})
  
  # If cut option is true, add cut arguments and time range to the format arguments
  if [[ $cutOption == true ]]; then
    formatArgs+=("${cutArgs[@]}" "${timeRange}")
  fi

  # Execute the yt-dlp command with the constructed argument set
  yt-dlp "${url}" "${formatArgs[@]}" "${COMMON_ARGS[@]}" "${OUTPUT_ARGS[@]}" "${final_args}"
}

# Loop through all provided arguments and parse them
for arg in "$@"; do
  parse_arguments "$arg"
done

# Check if all required arguments are provided
check_arguments

# Execute the yt-dlp command
execute_yt_dlp
