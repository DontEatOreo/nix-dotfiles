#! /usr/bin/env nix-shell
#! nix-shell -i bash -p jq wl-clipboard delta libnotify
# shellcheck shell=bash

# We time out "notify-send" because it can hang for pretty long time if there is no notification server running

# ---------- VARIABLES ----------

readonly MODEL_NAME="llama3.2:3b-instruct-fp16"
readonly NOTIFY_TIMEOUT="3s"
readonly NOTIFY_TITLE="AI Grammar Fix"

read -r -d '' system_json <<'EOF'
Act as a spelling corrector and improver. 

Here are the rules you must follow:
- Fix spelling, grammar and punctuation
- Retain the exact formatting of the input
- Retain original names of stuff in backticks
- Improve clarity and conciseness
- Reduce repetition
- Prefer active voice
- Prefer simple words
- Keep the meaning same
- Keep the tone of voice same
- Return in the same language as the input

ONLY reply with the correct text verbatim. Do not add any additional information.
EOF
read -r -d '' template_json <<'EOF'

EOF

read -r -d '' stops_json <<'EOF'
"<|start_header_id|>", "<|end_header_id|>", "<|eot_id|>"
EOF

TEMP_FILES=()
ERROR_OCCURRED=false

# ---------- FUNCTIONS ----------

cleanup() {
	for temp_file in "${TEMP_FILES[@]}"; do
		if [ ! -f "$temp_file" ]; then
			timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "Cannot delete $temp_file: File does not exist"
			continue
		fi
		if [ ! -w "$temp_file" ]; then
			timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "Cannot delete $temp_file: No write permission"
			continue
		fi
		rm -f "$temp_file"
	done
	if $ERROR_OCCURRED; then
		if [ -n "$1" ]; then
			timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "$1"
		fi
		exit 1
	else
		exit 0
	fi
}

trap cleanup EXIT

create_temp_files() {
	temp_before="$(mktemp)"
	temp_after="$(mktemp)"
	# If temp files weren't created
	if [ -z "$temp_before" ] || [ -z "$temp_after" ]; then
		ERROR_OCCURRED=true
		return
	fi
	TEMP_FILES+=("$temp_before" "$temp_after")
}

generate_ai_response() {
	# Check if the model exists
	if ! curl -s http://localhost:11434/api/tags | jq -e ".models[] | select (.name | contains(\"$MODEL_NAME\"))" >/dev/null; then
		timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "Error: '$MODEL_NAME' does not exist."
		exit 1
	fi

	ai_json="$(jq -n \
		--arg model_name "$MODEL_NAME" \
		--arg system "$system_json" \
		--arg template "$template_json" \
		--arg prompt "Input: $clipboard_content" \
		--arg stops "$stops_json" \
		'{
					"model": $model_name,
					"system": $system,
					"template": $template,
					"stream": false,
					"keep_alive": "5m",
					"prompt": $prompt,
					"options": {
						"temperature": 0.3,
						"num_ctx": 4096,
						"stop": [ $stops ]
					}
				}')"

	ai_response="$(curl -s http://localhost:11434/api/generate -d "$ai_json")"
	if echo -n "$ai_response" | jq -e '.error' >/dev/null; then
		error_msg="$(echo -n "$ai_response" | jq -r '.error')"
		timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "$error_msg"
		exit 1
	fi
	ai_response_time_seconds="$(echo -n "$ai_response" | jq -r '.total_duration' | awk '{print $1 / 1000000000}' | bc -l | awk '{printf "%.2f", $0}')"

	ai_output="$(echo -n "$ai_response" | jq -r '.response')"
	ai_output="${ai_output//Output: /}"
	ai_output="$(echo -n "$ai_output" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

	timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "Response time: $ai_response_time_seconds seconds"
}

save_content_to_files() {
	echo -n "$clipboard_content" >"$temp_before"
	echo -n "$ai_output" >"$temp_after"
}

compare_and_output() {
	diff_output="$(delta "$temp_before" "$temp_after" || true)"

	if [ -z "$diff_output" ]; then
		timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "No changes needed"
	else
		timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "Fixed grammar"
		echo -n "$diff_output"
		echo -n "$ai_output" | wl-copy
	fi
}

# ---------- MAIN ----------

clipboard_content="$(wl-paste)"
if [ "$clipboard_content" = "Nothing is copied" ]; then
	timeout "$NOTIFY_TIMEOUT" notify-send "$NOTIFY_TITLE" "Clipboard is empty"
	exit 1
fi

create_temp_files

generate_ai_response

save_content_to_files
compare_and_output
