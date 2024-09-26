#! /usr/bin/env nix-shell
# shellcheck shell=bash
#! nix-shell -i bash -p jq wl-clipboard delta libnotify

# We time out "notify-send" because it can hang for pretty long time if there is no notification server running

# ---------- VARIABLES ----------

readonly MODEL_NAME="phi3:14b"
readonly NOTIFY_TIMEOUT="3s"
readonly NOTIFY_TITLE="AI Grammar Fix"

read -r -d '' system_json <<'EOF'
Please correct the user's grammar and spelling while retaining their writing style and flow. Here are some examples of issues to look out for:

1. Incorrect verb tense
2. Subject-verb agreement
3. Spelling mistakes
4. Punctuation errors
5. Misplaced modifiers

Input/Output Examples:

Input: I has went to the store and buyed some apple's, it was a good day.
Output: I went to the store and bought some apples. It was a good day.

Input: She dont like going too the park becuz it always rain there.
Output: She doesn't like going to the park because it always rains there.

Input: Their going too see a movie, but they dont know what time its start.
Output: They're going to see a movie, but they don't know what time it starts.

Input: The cats is playing with there toys and it's very cute to watch.
Output: The cats are playing with their toys, and it's very cute to watch.

Input:
EOF
read -r -d '' template_json <<'EOF'
{{ if .System }}<|system|>
<|system|>
{{ .System }}<|end|>
{{ end }}{{ if .Prompt }}<|user|>
<|user|>
{{ .Prompt }}<|end|>
{{ end }}<|assistant|>
{{ .Response }}<|end|>
EOF

read -r -d '' stops_json <<'EOF'
"<|start_header_id|>", "<|user|>", "<|assistant|>"
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
