# shellcheck shell=bash

BRIGHT_RED="${BRIGHT_RED:-131}"
ORANGE="${ORANGE:-215}"
YELLOW="${YELLOW:-187}"
BLUE="${BLUE:-110}"
GREEN="${GREEN:-71}"

log_style() {
	local color="$1"
	shift
	gum style --foreground="$color" "$@"
}
log_error() { log_style "$BRIGHT_RED" "[error] $*"; }
log_info() { log_style "$ORANGE" "[info] $*"; }
log_compress() { log_style "$ORANGE" "[compress] $*"; }
log_warning() { log_style "$YELLOW" "[warning] $*"; }
log_question() { log_style "$BLUE" "[?] $*"; }
log_success() { log_style "$GREEN" "[success] $*"; }

show_help() {
	cat <<EOF
Usage: URL [TIME_RANGE] [FORMAT] [OPTIONS] [ADDITIONAL_ARGS]
Arguments:
  URL                 The URL of the video to download.
  TIME_RANGE          Optional. The time range to cut (e.g., '30-60').
                      Required if using a '-cut' format.
  FORMAT              Optional. One of: m4a, mp3, mp4, m4a-cut, mp3-cut, mp4-cut.
  ADDITIONAL_ARGS     Optional. Any additional arguments to pass to yt-dlp.

Options:
  --compress          Download and compress the video.
  --crf VALUE         Specify the CRF value for compression (default: 26).
  -h, --help          Show this help message.

Examples:
  https://example.com/video
  https://example.com/video 30-60
  https://example.com/video 30-60 --compress
  https://example.com/video --compress
  https://example.com/video --compress --crf 22
  https://example.com/video mp4 --write-subs --write-auto-subs
  https://example.com/video mp4 --cookies-from-browser chrome
EOF
}

declare url=""
declare time_range=""
declare format=""
declare cut_option=false
declare compress_option=false
declare crf=26
declare -a final_args=("--ignore-config")
declare json_metadata=""
declare temp_dir=""
declare -A FORMAT_ARGS=(
	[m4a]='--embed-thumbnail --extract-audio --audio-quality 0 --audio-format m4a'
	[mp3]='--embed-thumbnail --extract-audio --audio-quality 0 --audio-format mp3'
	[mp4]='-f "bv*[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]/best" -S "ext:mp4:m4a"'
	[m4a - cut]='--embed-thumbnail --extract-audio --audio-quality 0 --audio-format m4a'
	[mp3 - cut]='--embed-thumbnail --extract-audio --audio-quality 0 --audio-format mp3'
	[mp4 - cut]='-f "bv*[ext=mp4][vcodec^=avc1]+ba[ext=m4a]/b[ext=mp4]/best" -S "ext:mp4:m4a"'
)
declare -a COMMON_ARGS=(--progress --console-title --embed-metadata)
declare -a OUTPUT_ARGS=()
declare -A arg_state=(
	[expecting_crf]=false
)

parse_arguments() {
	local arg
	local -a additional_args=()

	for arg in "$@"; do
		if [[ "${arg_state[expecting_crf]}" == true ]]; then
			crf="$arg"
			arg_state[expecting_crf]=false
			continue
		fi

		case "$arg" in
		-h | --help)
			show_help
			exit 0
			;;
		--compress)
			compress_option=true
			;;
		--crf)
			arg_state[expecting_crf]=true
			;;
		http://* | https://*)
			url="$arg"
			;;
		m4a | mp3 | mp4 | m4a-cut | mp3-cut | mp4-cut)
			format="$arg"
			[[ "$arg" == *-cut ]] && cut_option=true
			;;
		*)
			# Try time range regex first
			if [[ "$arg" =~ ^[0-9]+(\.[0-9]+)?-[0-9]+(\.[0-9]+)?$ ]]; then
				time_range="$arg"
			else
				# Collect additional arguments
				additional_args+=("$arg")
			fi
			;;
		esac
	done

	# Add additional arguments to final_args after processing
	final_args+=("${additional_args[@]}")
}

validate_arguments() {
	if [[ -z "$url" ]]; then
		log_error "Missing URL"
		show_help
		exit 1
	fi

	if [[ "$cut_option" == true && -z "$time_range" ]]; then
		log_error "Missing time range for -cut format"
		show_help
		exit 1
	fi
}

fetch_json_metadata() {
	# Use the same arguments for metadata fetch as for the main download
	local -a metadata_cmd=(yt-dlp "$url" -j "${final_args[@]}")
	log_info "Fetching metadata with: ${metadata_cmd[*]}"

	json_metadata="$(yt-dlp "$url" -j "${final_args[@]}")" || {
		log_error "Failed to fetch JSON metadata"
		log_error "This might be due to age restrictions, geo-blocking, or missing authentication"
		log_error "Make sure you're using the correct cookies or authentication method"
		exit 1
	}
}

validate_time_range() {
	[[ "$cut_option" != true ]] && return 0
	local start end duration

	IFS="-" read -r start end <<<"$time_range"
	duration=$(jq '.duration' <<<"$json_metadata")
	[[ -z "$duration" || "$duration" == "null" ]] && duration=0

	if (($(echo "$start > $end" | bc -l))); then
		log_error "Start time is greater than end time in time range"
		exit 1
	fi
	if (($(echo "$start < 0" | bc -l))); then
		log_error "Start time cannot be negative"
		exit 1
	fi
	if (($(echo "$end > $duration" | bc -l))); then
		log_error "End time exceeds video duration ($end > $duration)"
		exit 1
	fi
}

format_time_range() {
	local start end
	IFS="-" read -r start end <<<"$time_range"
	printf -- "-%s-%s" "${start//./_}" "${end//./_}"
}

execute_yt_dlp() {
	local format_args_string="${FORMAT_ARGS[$format]:-}"
	local -a format_args

	# Parse format args string into array, handling quoted arguments properly
	if [[ -n "$format_args_string" ]]; then
		eval "format_args=($format_args_string)"
	fi

	# Add --no-embed-chapters if chapters present
	if [[ "$(jq '(.chapters // []) | length > 0' <<<"$json_metadata")" == "true" ]]; then
		format_args+=("--no-embed-chapters")
	fi

	# Prepare output template
	local time_suffix=""
	if [[ "$cut_option" == true ]]; then
		format_args+=("--download-sections=*${time_range}")
		format_args+=("--force-keyframes-at-cuts")
		time_suffix="$(format_time_range)"
		OUTPUT_ARGS=(-o "%(display_id)s${time_suffix}.%(ext)s")
	else
		OUTPUT_ARGS=(-o "%(display_id)s.%(ext)s")
	fi

	if [[ "$compress_option" == true ]]; then
		temp_dir="$(mktemp -d)"
		OUTPUT_ARGS=(-o "$temp_dir/%(display_id)s.%(ext)s")
	fi

	# Build the complete command
	local -a yt_dlp_cmd=(
		yt-dlp
		"$url"
		"${format_args[@]}"
		"${COMMON_ARGS[@]}"
		"${OUTPUT_ARGS[@]}"
		"${final_args[@]}"
		--postprocessor-args "ffmpeg:-hide_banner"
	)

	log_info "Executing: ${yt_dlp_cmd[*]}"
	"${yt_dlp_cmd[@]}"

	if [[ "$compress_option" == true ]]; then
		compress_video "$temp_dir" "$time_suffix"
		rm -rf "$temp_dir"
	fi
}

format_size() {
	local size="$1"
	local power=0
	local units=("B" "KB" "MB" "GB")
	while (($(echo "$size > 1024" | bc -l))); do
		size=$(echo "scale=2; $size/1024" | bc)
		((power++))
	done
	printf "%.2f %s" "$size" "${units[$power]}"
}

create_stats_box() {
	local original="$1" compressed="$2" saved="$3"
	gum style --border normal --padding "1 2" --border-foreground 212 \
		"$(gum style --foreground 212 ' COMPRESSION STATISTICS ')" \
		"$(gum style --foreground "$BRIGHT_RED" " Original Size:    $(format_size "$original") ")" \
		"$(gum style --foreground "$GREEN" " Compressed Size:  $(format_size "$compressed") ")" \
		"$(gum style --foreground "$GREEN" " Space Saved:      $saved% ")"
	printf "\n"
}

compress_video() {
	local temp_dir="$1" time_suffix="$2"
	local input_file output_file
	input_file="$(fd -t f . "$temp_dir" | head -n 1)"

	[[ -f "$input_file" ]] || {
		log_error "Input file not found"
		return 1
	}

	local original_size
	original_size=$(dust -j -o b "$input_file" 2>/dev/null | jq '.size | gsub("B$";"") | tonumber' 2>/dev/null || echo "0")
	log_info "Original file size: $(format_size "$original_size")"

	local base_name
	base_name=$(basename "$input_file" | sd '\.[^.]*$' '')

	output_file="${PWD}/${base_name}${time_suffix}.mp4"

	local tune tune_options=("film" "animation" "grain" "stillimage" "none")
	log_question "Choose a tune for compression:"
	tune="$(printf "%s\n" "${tune_options[@]}" | gum choose)"

	local ffmpeg_cmd=(ffmpeg -hide_banner -i "$input_file" -c:v libx264 -profile:v high -preset veryslow -crf "$crf" -c:a copy)
	[[ "$tune" != "none" ]] && ffmpeg_cmd+=(-tune "$tune")
	ffmpeg_cmd+=("$output_file")

	if ! "${ffmpeg_cmd[@]}"; then
		log_error "Compression failed"
		return 1
	fi

	[[ -f "$output_file" ]] || {
		log_error "Compressed file was not created"
		return 1
	}

	local compressed_size
	compressed_size=$(dust -j -o b "$output_file" 2>/dev/null | jq '.size | gsub("B$";"") | tonumber' 2>/dev/null || echo "0")
	local size_saved
	size_saved=$(echo "scale=2; ($original_size - $compressed_size) * 100 / $original_size" | bc)

	create_stats_box "$original_size" "$compressed_size" "$size_saved"

	if (($(echo "$size_saved < 25" | bc -l))); then
		log_warning "Compression only saved ${size_saved}% of space"
		log_question "Would you like to delete the compressed file and download without compression?"
		local response
		response=$(printf "%s\n" "Yes" "No" | gum choose)
		if [[ "$response" == "Yes" ]]; then
			log_info "Removing compressed file..."
			rm "$output_file"
			log_info "Re-downloading without compression..."
			compress_option=false
			OUTPUT_ARGS=(-o "%(display_id)s${time_suffix}.%(ext)s")
			execute_yt_dlp
		fi
	fi
}

change_file_date() {
	local upload_date display_id
	upload_date=$(jq -r '.upload_date' <<<"$json_metadata")
	display_id=$(jq -r '.display_id' <<<"$json_metadata")
	[[ -z "$upload_date" ]] && return 0
	local formatted_date="${upload_date:0:8}0000.00"
	fd "^${display_id}.*" -d 1 -x touch -t "$formatted_date" '{}'
}

main() {
	parse_arguments "$@"
	validate_arguments
	fetch_json_metadata
	validate_time_range
	execute_yt_dlp
	change_file_date
}

main "$@"
