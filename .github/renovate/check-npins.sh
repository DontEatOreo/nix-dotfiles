#!/usr/bin/env bash

set -euo pipefail

lock_file=${1:-npins/sources.json}

problems=$(
	jq -r '
    def github_archive_url($pin):
      "https://github.com/" + $pin.repository.owner + "/" +
      $pin.repository.repo + "/archive/" + $pin.revision + ".tar.gz";
    def github_release_url($pin):
      "https://api.github.com/repos/" + $pin.repository.owner + "/" +
      $pin.repository.repo + "/tarball/refs/tags/" + $pin.version;

    .pins as $pins
    | [
        (
          $pins
          | to_entries[]
          | . as $entry
          | $entry.value as $pin
          | if (
              $pin.type == "Git"
              and $pin.repository.type == "GitHub"
              and ($pin.submodules | not)
            ) then
              github_archive_url($pin) as $expected
              | select($pin.url != $expected)
              | "\($entry.key): revision \($pin.revision) requires URL \($expected), got \($pin.url)"
            elif (
              $pin.type == "GitRelease"
              and $pin.repository.type == "GitHub"
              and ($pin.submodules | not)
            ) then
              github_release_url($pin) as $expected
              | select($pin.url != $expected)
              | "\($entry.key): version \($pin.version) requires URL \($expected), got \($pin.url)"
            else
              empty
            end
        ),
        (
          $pins
          | to_entries[]
          | select(.key | endswith("_archive"))
          | . as $archive
          | (.key | rtrimstr("_archive")) as $source_name
          | select($pins[$source_name] != null)
          | select($archive.value.url != $pins[$source_name].url)
          | "\($archive.key): URL differs from \($source_name)"
        ),
        (
          $pins
          | to_entries[]
          | select(.value.type == "Git" or .value.type == "GitRelease" or .value.type == "Url")
          | select((.value.hash // "") | test("^sha256-[A-Za-z0-9+/]{43}=$") | not)
          | "\(.key): missing or malformed SHA-256 SRI hash"
        )
      ]
    | .[]
  ' "$lock_file"
)

if [[ -n $problems ]]; then
	printf 'inconsistent npins lock metadata:\n%s\n' "$problems" >&2
	exit 1
fi
