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
EOF
}

declare url=""
declare time_range=""
declare format=""
declare cut_option=false
declare compress_option=false
declare browser_option=""
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

declare -A BROWSER_MAPPING=(
	[brave - beta]="brave"
	[brave - nightly]="brave"
	[chrome - beta]="chrome"
	[chrome - canary]="chrome"
	[chrome - dev]="chrome"
	[chromium - dev]="chromium"
	[edge - beta]="edge"
	[edge - canary]="edge"
	[edge - dev]="edge"
	[firefox - beta]="firefox"
	[firefox - developer]="firefox"
	[firefox - nightly]="firefox"
	[floorp]="firefox"
	[librewolf]="firefox"
	[opera - beta]="opera"
	[opera - developer]="opera"
	[opera - gx]="opera"
	[ungoogled - chromium]="chromium"
	[vivaldi - snapshot]="vivaldi"
	[waterfox]="firefox"
	[zen]="firefox"
)

get_browser_profile_path() {
	local browser="$1"
	# local browser_paths_var

	if [[ "$OSTYPE" == "darwin"* ]]; then
		local app_support="$HOME/Library/Application Support"
		case "$browser" in
		firefox-beta) echo "$app_support/Firefox Beta" ;;
		firefox-developer) echo "$app_support/Firefox Developer Edition" ;;
		firefox-nightly) echo "$app_support/Firefox Nightly" ;;
		floorp) echo "$app_support/Floorp" ;;
		librewolf) echo "$app_support/LibreWolf" ;;
		ungoogled-chromium) echo "$app_support/Ungoogled Chromium" ;;
		waterfox) echo "$app_support/Waterfox" ;;
		zen) echo "$app_support/zen" ;;
		*) return 1 ;;
		esac
	else
		local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
		case "$browser" in
		firefox-beta) echo "$HOME/.mozilla/firefox-beta" ;;
		firefox-developer) echo "$HOME/.mozilla/firefox-developer-edition" ;;
		firefox-nightly) echo "$HOME/.mozilla/firefox-nightly" ;;
		floorp) echo "$HOME/.floorp" ;;
		librewolf) echo "$HOME/.librewolf" ;;
		ungoogled-chromium) echo "$config_dir/ungoogled-chromium" ;;
		waterfox) echo "$HOME/.waterfox" ;;
		zen) echo "$config_dir/zen" ;;
		*) return 1 ;;
		esac
	fi
}

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

detect_browsers() {
	local -A browser_paths=()
	local app_support config_dir

	if [[ "$OSTYPE" == "darwin"* ]]; then
		app_support="$HOME/Library/Application Support"
		browser_paths=(
			# Chromium-based browsers
			["brave - beta"]="$app_support/BraveSoftware/Brave-Browser-Beta"
			["brave - nightly"]="$app_support/BraveSoftware/Brave-Browser-Nightly"
			["chrome - beta"]="$app_support/Google/Chrome Beta"
			["chrome - canary"]="$app_support/Google/Chrome Canary"
			["chrome - dev"]="$app_support/Google/Chrome Dev"
			["edge - beta"]="$app_support/Microsoft Edge Beta"
			["edge - canary"]="$app_support/Microsoft Edge Canary"
			["edge - dev"]="$app_support/Microsoft Edge Dev"
			["opera - beta"]="$app_support/com.operasoftware.OperaNext"
			["opera - gx"]="$app_support/com.operasoftware.OperaGX"
			["ungoogled - chromium"]="$app_support/Ungoogled Chromium"
			["vivaldi - snapshot"]="$app_support/Vivaldi Snapshot"
			[arc]="$app_support/Arc"
			[brave]="$app_support/BraveSoftware/Brave-Browser"
			[chrome]="$app_support/Google/Chrome"
			[chromium]="$app_support/Chromium"
			[edge]="$app_support/Microsoft Edge"
			[opera]="$app_support/com.operasoftware.Opera"
			[vivaldi]="$app_support/Vivaldi"

			# Firefox-based browsers
			["firefox - beta"]="$app_support/Firefox Beta"
			["firefox - developer"]="$app_support/Firefox Developer Edition"
			["firefox - nightly"]="$app_support/Firefox Nightly"
			[firefox]="$app_support/Firefox"
			[floorp]="$app_support/Floorp"
			[librewolf]="$app_support/LibreWolf"
			[waterfox]="$app_support/Waterfox"
			[zen]="$app_support/zen"

			# WebKit-based browsers
			[orion]="$app_support/Orion"
			[safari]="$HOME/Library/Safari"
		)
	else
		config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
		browser_paths=(
			# Chromium-based browsers
			["brave - beta"]="$config_dir/BraveSoftware/Brave-Browser-Beta"
			["brave - nightly"]="$config_dir/BraveSoftware/Brave-Browser-Nightly"
			["chrome - beta"]="$config_dir/google-chrome-beta"
			["chrome - dev"]="$config_dir/google-chrome-unstable"
			["chromium - dev"]="$config_dir/chromium-dev"
			["edge - beta"]="$config_dir/microsoft-edge-beta"
			["edge - dev"]="$config_dir/microsoft-edge-dev"
			["opera - beta"]="$config_dir/opera-beta"
			["opera - developer"]="$config_dir/opera-developer"
			["ungoogled - chromium"]="$config_dir/ungoogled-chromium"
			["vivaldi - snapshot"]="$config_dir/vivaldi-snapshot"
			[brave]="$config_dir/BraveSoftware/Brave-Browser"
			[chrome]="$config_dir/google-chrome"
			[chromium]="$config_dir/chromium"
			[edge]="$config_dir/microsoft-edge"
			[opera]="$config_dir/opera"
			[vivaldi]="$config_dir/vivaldi"

			# Firefox-based browsers
			["firefox - beta"]="$HOME/.mozilla/firefox-beta"
			["firefox - developer"]="$HOME/.mozilla/firefox-developer-edition"
			["firefox - nightly"]="$HOME/.mozilla/firefox-nightly"
			[firefox]="$HOME/.mozilla/firefox"
			[floorp]="$HOME/.floorp"
			[librewolf]="$HOME/.librewolf"
			[waterfox]="$HOME/.waterfox"
			[zen]="$config_dir/zen"
		)
	fi

	# Check which browsers are installed using modern bash
	local -a detected_browsers=()
	local browser path
	for browser in "${!browser_paths[@]}"; do
		path="${browser_paths[$browser]}"
		if [[ -d "$path" ]]; then
			case "$browser" in
			safari) [[ "$OSTYPE" == "darwin"* ]] && detected_browsers+=("$browser") ;;
			*) detected_browsers+=("$browser") ;;
			esac
		fi
	done

	printf "%s\n" "${detected_browsers[@]}"
}

is_auth_error() {
	local error_output="$1"
	local -a auth_patterns=(
		"Sign in to confirm your age"
		"This video requires payment"
		"Private video"
		"This video is unavailable"
		"Video unavailable"
		"members-only"
		"Join this channel"
		"Sign in to confirm you're not a bot"
		"This video is only available to Music Premium members"
		"age-restricted"
		"age restricted"
		"Login required"
		"Please sign in"
		"403.*Forbidden"
		"401.*Unauthorized"
	)

	local pattern
	for pattern in "${auth_patterns[@]}"; do
		[[ "$error_output" =~ $pattern ]] && return 0
	done
	return 1
}

is_format_error() {
	local error_output="$1"
	local -a format_patterns=(
		"Requested format is not available"
		"No video formats found"
		"Only images are available"
		"format.*not available"
		"No suitable formats found"
		"Unable to extract video data"
	)

	local pattern
	for pattern in "${format_patterns[@]}"; do
		[[ "$error_output" =~ $pattern ]] && return 0
	done
	return 1
}

fetch_json_metadata() {
	local -a metadata_cmd=(yt-dlp "$url" -j "${final_args[@]}")
	local error_output attempt=1 max_attempts=2

	log_info "Fetching metadata with: ${metadata_cmd[*]}"

	while ((attempt <= max_attempts)); do
		if error_output=$(yt-dlp "$url" -j "${final_args[@]}" 2>&1); then
			json_metadata="$error_output"
			return 0
		fi

		# Check if this is the first attempt and we have an auth error
		if ((attempt == 1)) && is_auth_error "$error_output" && [[ -z "$browser_option" ]]; then
			log_warning "Authentication or access issue detected"
			log_question "Would you like to try using browser cookies?"

			local response
			response=$(printf "%s\n" "Yes" "No" "Skip" | gum choose) || response="Skip"

			case "$response" in
			"Yes")
				if prompt_browser_selection; then
					local browser_arg="$browser_option"
					local custom_path

					# Check if browser needs mapping and custom path
					if [[ -v "BROWSER_MAPPING[$browser_option]" ]]; then
						local mapped_browser="${BROWSER_MAPPING[$browser_option]}"
						if custom_path="$(get_browser_profile_path "$browser_option")"; then
							browser_arg="${mapped_browser}:${custom_path}"
							log_info "Using browser mapping: $browser_option -> $mapped_browser with custom path: $custom_path"
						else
							browser_arg="$mapped_browser"
							log_info "Using browser mapping: $browser_option -> $mapped_browser"
						fi
					fi

					final_args+=("--cookies-from-browser" "$browser_arg")
					log_info "Retrying with browser cookies..."
					((attempt++))
					continue
				else
					log_error "Browser selection failed"
					exit 1
				fi
				;;
			"No")
				log_info "Continuing without browser cookies..."
				break
				;;
			"Skip")
				log_info "Skipping download"
				exit 0
				;;
			esac
		fi
		break
	done

	log_error "Failed to fetch JSON metadata after $attempt attempt(s)"
	log_error "Error output:"
	printf "%s\n" "$error_output" >&2
	exit 1
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

	# Use a temporary file to capture stderr while allowing stdout to pass through
	local stderr_file
	stderr_file="$(mktemp)"

	if ! "${yt_dlp_cmd[@]}" 2>"$stderr_file"; then
		local error_output
		error_output="$(cat "$stderr_file")"
		rm -f "$stderr_file"

		if is_format_error "$error_output"; then
			log_warning "Requested format not available"
			log_question "Would you like to see available formats or try with best available quality?"

			local response
			response=$(printf "%s\n" "List formats" "Use best quality" "Cancel" | gum choose) || response="Cancel"

			case "$response" in
			"List formats")
				log_info "Available formats:"
				yt-dlp "$url" --list-formats "${final_args[@]}"
				log_question "Try again with best available quality?"
				local retry_response
				retry_response=$(printf "%s\n" "Yes" "No" | gum choose) || retry_response="No"
				[[ "$retry_response" == "Yes" ]] && retry_with_fallback || exit 1
				;;
			"Use best quality")
				retry_with_fallback
				;;
			"Cancel")
				log_info "Download cancelled"
				exit 0
				;;
			esac
		else
			log_error "Download failed"
			log_error "Error output:"
			printf "%s\n" "$error_output" >&2
			exit 1
		fi
	else
		rm -f "$stderr_file"
	fi

	if [[ "$compress_option" == true ]]; then
		compress_video "$temp_dir" "$time_suffix"
		rm -rf "$temp_dir"
	fi
}

retry_with_fallback() {
	log_info "Retrying with fallback format options..."

	# Use more flexible format selection
	local -a fallback_cmd=(
		yt-dlp
		"$url"
		"${COMMON_ARGS[@]}"
		"${OUTPUT_ARGS[@]}"
		"${final_args[@]}"
		--postprocessor-args "ffmpeg:-hide_banner"
	)

	# Add format-specific fallbacks
	case "$format" in
	mp4* | "")
		fallback_cmd+=(-f "best[ext=mp4]/best")
		;;
	m4a* | mp3*)
		fallback_cmd+=(--extract-audio --audio-format "${format%-cut}" --audio-quality 0)
		[[ "$format" == *-cut ]] && fallback_cmd+=("--download-sections=*${time_range}" "--force-keyframes-at-cuts")
		;;
	esac

	log_info "Executing fallback: ${fallback_cmd[*]}"

	# Same approach for fallback - capture stderr only
	local stderr_file
	stderr_file="$(mktemp)"

	if ! "${fallback_cmd[@]}" 2>"$stderr_file"; then
		local error_output
		error_output="$(cat "$stderr_file")"
		rm -f "$stderr_file"
		log_error "Fallback download also failed"
		log_error "Error output:"
		printf "%s\n" "$error_output" >&2
		exit 1
	else
		rm -f "$stderr_file"
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

prompt_browser_selection() {
	local -a detected_browsers
	readarray -t detected_browsers < <(detect_browsers)

	case ${#detected_browsers[@]} in
	0)
		log_warning "No browsers detected in standard locations"
		return 1
		;;
	1)
		browser_option="${detected_browsers[0]}"
		log_info "Auto-selected browser: $browser_option"
		return 0
		;;
	*)
		log_question "Multiple browsers detected. Choose one for cookie extraction:"
		if browser_option="$(printf "%s\n" "${detected_browsers[@]}" | gum choose)"; then
			log_info "Selected browser: $browser_option"
			return 0
		else
			log_info "No browser selected"
			return 1
		fi
		;;
	esac
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
