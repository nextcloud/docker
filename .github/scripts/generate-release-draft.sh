#!/usr/bin/env bash
set -Eeuo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${REPO:?REPO is required}"

official_repo="docker-library/official-images"
tmp_notes="${RUNNER_TEMP}/release-notes.md"

export SKIP_RELEASE=false
export SKIP_REASON=""
export OFFICIAL_IMAGES_PR=""
export OFFICIAL_IMAGES_PR_URL=""
export PREVIOUS_OFFICIAL_IMAGES_PR=""
export PREVIOUS_OFFICIAL_IMAGES_PR_URL=""
export PREVIOUS_TAG=""
export RELEASE_TAG=""
export TARGET_SHA=""
export CHANGED_GIT_COMMITS=""
export ALLOW_EXISTING_OFFICIAL_IMAGES_PR="${INPUT_ALLOW_EXISTING_OFFICIAL_IMAGES_PR:-false}"

get_official_images_pr_number() {
  if [[ -n "${INPUT_OFFICIAL_IMAGES_PR:-}" ]]; then
    printf '%s\n' "$INPUT_OFFICIAL_IMAGES_PR"
    return 0
  fi

  local prs_json
  prs_json="$(
    gh pr list \
      --repo "$official_repo" \
      --state merged \
      --search 'label:"library/nextcloud"' \
      --limit 20 \
      --json number,mergedAt,url,title
  )"

  jq -r 'sort_by(.mergedAt) | reverse | .[0].number // empty' <<<"$prs_json"
}

extract_previous_official_images_pr_from_release_body() {
  local body="$1"

  local pr=""
  pr="$(
    { grep -oE 'official_images_pr=[0-9]+' <<<"$body" | head -1 | cut -d= -f2; } || true
  )"

  if [[ -z "$pr" ]]; then
    pr="$(
      { grep -oE 'docker-library/official-images/pull/[0-9]+' <<<"$body" | head -1 | grep -oE '[0-9]+$'; } || true
    )"
  fi

  printf '%s\n' "$pr"
}

get_library_nextcloud_patch() {
  local pr_number="$1"

  gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/${official_repo}/pulls/${pr_number}/files?per_page=100" \
  | jq -r '.[] | select(.filename == "library/nextcloud") | .patch // empty'
}

get_library_nextcloud_file_at_ref() {
  local ref="$1"

  gh api \
    -H "Accept: application/vnd.github.raw+json" \
    "/repos/${official_repo}/contents/library/nextcloud?ref=${ref}"
}

extract_target_sha_from_library_header() {
  local file="$1"

  sed -n '1p' <<<"$file" \
    | grep -oE '[0-9a-f]{40}' \
    | head -1 || true
}

extract_added_gitcommits_from_patch() {
  local patch="$1"

  grep '^\+GitCommit:' <<<"$patch" \
    | sed -n 's/^\+GitCommit: //p' \
    | sort -u || true
}

join_by() {
  local delimiter="$1"
  shift || true
  local first=1

  for item in "$@"; do
    if [[ $first -eq 1 ]]; then
      printf '%s' "$item"
      first=0
    else
      printf '%s%s' "$delimiter" "$item"
    fi
  done
}

human_join() {
  local items=("$@")
  local count="${#items[@]}"

  if [[ "$count" -eq 0 ]]; then
    return 0
  elif [[ "$count" -eq 1 ]]; then
    printf '%s' "${items[0]}"
  elif [[ "$count" -eq 2 ]]; then
    printf '%s and %s' "${items[0]}" "${items[1]}"
  else
    local last_index=$((count - 1))
    local last="${items[$last_index]}"
    unset 'items[$last_index]'
    printf '%s, and %s' "$(join_by ', ' "${items[@]}")" "$last"
  fi
}

extract_base_version_from_tags_csv() {
  local csv="$1"
  grep -oE '\b[0-9]+\.[0-9]+\.[0-9]+\b' <<<"$csv" | head -1 || true
}

csv_has_tag() {
  local csv="$1"
  local needle="$2"
  tr ',' '\n' <<<"$csv" | sed 's/^ *//; s/ *$//' | grep -Fxq "$needle"
}

flavor_from_directory() {
  local directory="$1"
  case "$directory" in
    */apache) printf '%s\n' "apache" ;;
    */fpm) printf '%s\n' "fpm" ;;
    */fpm-alpine) printf '%s\n' "fpm-alpine" ;;
    *) printf '%s\n' "$directory" ;;
  esac
}

parse_library_file_to_state() {
  local file="$1"

  awk '
    BEGIN {
      tags = ""
      gitcommit = ""
      dir = ""
    }

    /^Tags:/ {
      tags = $0
      sub(/^Tags:[[:space:]]*/, "", tags)
      next
    }

    /^GitCommit:/ {
      gitcommit = $0
      sub(/^GitCommit:[[:space:]]*/, "", gitcommit)
      next
    }

    /^Directory:/ {
      dir = $0
      sub(/^Directory:[[:space:]]*/, "", dir)
      print dir "\t" tags "\t" gitcommit
      tags = ""
      gitcommit = ""
      dir = ""
      next
    }
  ' <<<"$file"
}

find_state_line_for_flavor() {
  local state="$1"
  local flavor="$2"

  awk -F'\t' -v f="$flavor" '
    {
      dir = $1
      if ((dir ~ /\/apache$/ && f=="apache") ||
          (dir ~ /\/fpm$/ && f=="fpm") ||
          (dir ~ /\/fpm-alpine$/ && f=="fpm-alpine")) {
        print $0
      }
    }
  ' <<<"$state" | tail -1 || true
}

role_flavor_phrase() {
  local role="$1"
  local flavor="$2"
  printf '%s `%s` tag' "$flavor" "$role"
}

summarize_role_movements_from_files() {
  local role="$1"
  local old_state="$2"
  local new_state="$3"

  local flavors=(apache fpm fpm-alpine)
  local moved_flavors=()
  local common_from="" common_to=""
  local common_from_set=1
  local common_to_set=1

  for flavor in "${flavors[@]}"; do
    local old_line new_line old_tags new_tags old_version new_version
    old_line="$(find_state_line_for_flavor "$old_state" "$flavor")"
    new_line="$(find_state_line_for_flavor "$new_state" "$flavor")"

    old_tags="$(cut -f2 <<<"$old_line" || true)"
    new_tags="$(cut -f2 <<<"$new_line" || true)"
    old_version="$(extract_base_version_from_tags_csv "${old_tags:-}")"
    new_version="$(extract_base_version_from_tags_csv "${new_tags:-}")"

    if [[ -n "${old_tags:-}" && -n "${new_tags:-}" ]] \
      && csv_has_tag "$old_tags" "$role" \
      && csv_has_tag "$new_tags" "$role" \
      && [[ -n "$old_version" && -n "$new_version" && "$old_version" != "$new_version" ]]; then
      moved_flavors+=("$flavor")

      if [[ -z "$common_from" ]]; then
        common_from="$old_version"
      elif [[ "$common_from" != "$old_version" ]]; then
        common_from_set=0
      fi

      if [[ -z "$common_to" ]]; then
        common_to="$new_version"
      elif [[ "$common_to" != "$new_version" ]]; then
        common_to_set=0
      fi
    fi
  done

  if [[ "${#moved_flavors[@]}" -eq 3 && "$common_from_set" -eq 1 && "$common_to_set" -eq 1 ]]; then
    case "$role" in
      latest)
        printf '%s\n' "Move \`latest\` tag from ${common_from} to ${common_to} across apache, fpm, and fpm-alpine variants"
        ;;
      stable|production)
        printf '%s\n' "Bump \`$role\` tag to ${common_to} across apache, fpm, and fpm-alpine variants"
        ;;
    esac
    return 0
  fi

  for flavor in "${moved_flavors[@]}"; do
    local old_line new_line old_tags new_tags old_version new_version
    old_line="$(find_state_line_for_flavor "$old_state" "$flavor")"
    new_line="$(find_state_line_for_flavor "$new_state" "$flavor")"

    old_tags="$(cut -f2 <<<"$old_line" || true)"
    new_tags="$(cut -f2 <<<"$new_line" || true)"
    old_version="$(extract_base_version_from_tags_csv "${old_tags:-}")"
    new_version="$(extract_base_version_from_tags_csv "${new_tags:-}")"

    [[ -n "$old_tags" && -n "$new_tags" ]] || continue
    csv_has_tag "$old_tags" "$role" || continue
    csv_has_tag "$new_tags" "$role" || continue
    [[ -n "$old_version" && -n "$new_version" && "$old_version" != "$new_version" ]] || continue

    case "$role" in
      latest)
        printf '%s\n' "Move $(role_flavor_phrase "$role" "$flavor") from ${old_version} to ${new_version}"
        ;;
      stable|production)
        printf '%s\n' "Bump $(role_flavor_phrase "$role" "$flavor") to ${new_version}"
        ;;
    esac
  done
}

summarize_new_variants_from_files() {
  local old_state="$1"
  local new_state="$2"

  local new_pairs_file="${RUNNER_TEMP}/nextcloud-new-variants.$$"
  : > "$new_pairs_file"

  while IFS=$'\t' read -r new_dir new_tags new_git; do
    [[ -z "${new_dir:-}" || -z "${new_tags:-}" ]] && continue

    local old_line old_tags old_version new_version flavor
    old_line="$(awk -F'\t' -v d="$new_dir" '$1==d {print $0}' <<<"$old_state" | tail -1 || true)"
    old_tags="$(cut -f2 <<<"$old_line" || true)"
    old_version="$(extract_base_version_from_tags_csv "${old_tags:-}")"
    new_version="$(extract_base_version_from_tags_csv "${new_tags:-}")"
    flavor="$(flavor_from_directory "$new_dir")"

    if [[ -n "$new_version" && ( -z "$old_version" || "$old_version" != "$new_version" ) ]]; then
      printf '%s\t%s\n' "$new_version" "$flavor" >> "$new_pairs_file"
    fi
  done <<<"$new_state"

  sort -u -o "$new_pairs_file" "$new_pairs_file"

  if [[ ! -s "$new_pairs_file" ]]; then
    rm -f "$new_pairs_file"
    return 0
  fi

  local versions
  versions="$(awk -F'\t' '{print $1}' "$new_pairs_file" | sort -Vu || true)"

  while read -r version; do
    [[ -z "$version" ]] && continue
    local flavors=()
    while read -r flavor; do
      [[ -z "$flavor" ]] && continue
      flavors+=("$flavor")
    done < <(awk -F'\t' -v v="$version" '$1==v {print $2}' "$new_pairs_file" | sort -u)

    if [[ "${#flavors[@]}" -gt 0 ]]; then
      printf '%s\n' "Add Nextcloud ${version} $(human_join "${flavors[@]}") variants"
    fi
  done <<<"$versions"

  rm -f "$new_pairs_file"
}

emit_tag_change_bullets_from_files() {
  local old_file="$1"
  local new_file="$2"

  local old_state new_state
  old_state="$(parse_library_file_to_state "$old_file")"
  new_state="$(parse_library_file_to_state "$new_file")"

  summarize_role_movements_from_files "latest" "$old_state" "$new_state"
  summarize_role_movements_from_files "stable" "$old_state" "$new_state"
  summarize_role_movements_from_files "production" "$old_state" "$new_state"
  summarize_new_variants_from_files "$old_state" "$new_state"
}

extract_semver_changes_from_patch() {
  local patch="$1"

  local new_versions
  new_versions="$(
    grep '^\+' <<<"$patch" \
      | grep -oE '\b[0-9]+\.[0-9]+\.[0-9]+\b' \
      | sort -Vu || true
  )"

  if [[ -n "$new_versions" ]]; then
    local versions=()
    while read -r v; do
      [[ -z "$v" ]] && continue
      versions+=("$v")
    done <<<"$new_versions"

    if [[ "${#versions[@]}" -gt 0 ]]; then
      printf '%s\n' "Bump Nextcloud Server to $(join_by ' / ' "${versions[@]}")"
      return 0
    fi
  fi

  return 1
}

extract_dependency_bumps_from_patch() {
  local patch="$1"
  local emitted=0

  if grep -qi 'alpine' <<<"$patch"; then
    local alpine_version
    local added_lines
    added_lines="$(grep '^\+[^+]' <<<"$patch" || true)"
    alpine_version="$(
      grep -oE 'Alpine[[:space:]]+[0-9]+\.[0-9]+' <<<"$added_lines" | tail -1 || true
    )"
    if [[ -n "$alpine_version" ]]; then
      printf '%s\n' "Bump alpine images to ${alpine_version}"
      emitted=1
    fi
  fi

  for dep in APCu imagick redis smbclient; do
    local version
    version="$(
      grep -iE "${dep}[^0-9]*[0-9]+\.[0-9]+(\.[0-9]+)?" <<<"$patch" \
        | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' \
        | tail -1 || true
    )"
    if [[ -n "$version" ]]; then
      printf '%s\n' "Bump PHP ${dep} to ${version}"
      emitted=1
    fi
  done

  if [[ "$emitted" -eq 1 ]]; then
    return 0
  fi

  return 1
}

render_generator_commit_bullets() {
  local sha="$1"
  local subject="$2"
  local patch="$3"

  local emitted=0

  if extract_semver_changes_from_patch "$patch"; then
    emitted=1
  fi

  if extract_dependency_bumps_from_patch "$patch"; then
    emitted=1
  fi

  if [[ "$emitted" -eq 0 ]]; then
    printf '%s\n' "${subject} (${sha:0:7})"
  fi
}

render_merge_pr_bullet() {
  local sha="$1"
  local subject="$2"

  if [[ "$subject" =~ ^Merge[[:space:]]pull[[:space:]]request[[:space:]]#([0-9]+) ]]; then
    local pr_number="${BASH_REMATCH[1]}"
    local pr_json
    pr_json="$(
      gh pr view "$pr_number" \
        --repo "$REPO" \
        --json number,title,url,author \
        2>/dev/null || true
    )"

    if [[ -n "$pr_json" && "$pr_json" != "null" ]]; then
      local title url author
      title="$(jq -r '.title // empty' <<<"$pr_json")"
      url="$(jq -r '.url // empty' <<<"$pr_json")"
      author="$(jq -r '.author.login // empty' <<<"$pr_json")"

      if [[ -n "$title" && -n "$url" && -n "$author" ]]; then
        printf '%s\n' "${title} by @${author} in [#${pr_number}](${url})"
        return 0
      fi
    fi
  fi

  return 1
}

render_subject_pr_bullet() {
  local subject="$1"
  local author="$2"

  if [[ "$subject" =~ ^(.+)[[:space:]]\(#([0-9]+)\)$ ]]; then
    local title="${BASH_REMATCH[1]}"
    local pr_number="${BASH_REMATCH[2]}"
    local pr_url="https://github.com/${REPO}/pull/${pr_number}"
    printf '%s\n' "${title} by @${author} in [#${pr_number}](${pr_url})"
    return 0
  fi

  return 1
}

render_regular_commit_bullet() {
  local sha="$1"
  local subject="$2"
  local author="$3"

  if render_subject_pr_bullet "$subject" "$author"; then
    return 0
  fi

  printf '%s\n' "${subject} (${sha:0:7}) by ${author}"
}

render_commit_bullets() {
  local sha="$1"
  local subject="$2"
  local author="$3"

  local patch
  patch="$(git show --format= --unified=0 "$sha")"

  if render_merge_pr_bullet "$sha" "$subject"; then
    return 0
  fi

  case "$subject" in
    "Runs update.sh"*|"Run update.sh"*|"Run update.sh script"*|"Runs update.sh script"*)
      render_generator_commit_bullets "$sha" "$subject" "$patch"
      return 0
      ;;
  esac

  render_regular_commit_bullet "$sha" "$subject" "$author"
}

OFFICIAL_IMAGES_PR="$(get_official_images_pr_number)"

if [[ -z "$OFFICIAL_IMAGES_PR" || "$OFFICIAL_IMAGES_PR" == "null" ]]; then
  SKIP_RELEASE=true
  SKIP_REASON="No merged docker-library/official-images pull request with label library/nextcloud was found."
  {
    echo "SKIP_RELEASE=true"
    echo "SKIP_REASON=$SKIP_REASON"
  } >> "$GITHUB_ENV"
  exit 0
fi

official_pr_json="$(
  gh pr view "$OFFICIAL_IMAGES_PR" \
    --repo "$official_repo" \
    --json number,title,mergedAt,url,labels,author,baseRefOid,headRefOid
)"

if ! jq -e '.labels[]? | select(.name == "library/nextcloud")' <<<"$official_pr_json" >/dev/null; then
  echo "Selected PR #$OFFICIAL_IMAGES_PR does not have label library/nextcloud" >&2
  exit 1
fi

OFFICIAL_IMAGES_PR_URL="$(jq -r '.url' <<<"$official_pr_json")"
official_pr_merged_at="$(jq -r '.mergedAt' <<<"$official_pr_json")"
official_pr_base_oid="$(jq -r '.baseRefOid // empty' <<<"$official_pr_json")"
official_pr_head_oid="$(jq -r '.headRefOid // empty' <<<"$official_pr_json")"

if [[ -z "$official_pr_base_oid" || -z "$official_pr_head_oid" ]]; then
  echo "Could not determine base/head OIDs for official-images PR #${OFFICIAL_IMAGES_PR}." >&2
  exit 1
fi

existing_tags="$(
  gh release list \
    --repo "$REPO" \
    --limit 100 \
    --json tagName \
    --jq '.[].tagName'
)"

if [[ "$ALLOW_EXISTING_OFFICIAL_IMAGES_PR" != "true" && -n "$existing_tags" ]]; then
  while read -r tag; do
    [[ -z "$tag" ]] && continue
    body="$(
      gh release view "$tag" \
        --repo "$REPO" \
        --json body \
        --jq '.body // ""'
    )"
    if grep -qF "docker-library/official-images/pull/${OFFICIAL_IMAGES_PR}" <<<"$body"; then
      SKIP_RELEASE=true
      SKIP_REASON="A release already references docker-library/official-images PR #${OFFICIAL_IMAGES_PR}."
      {
        echo "SKIP_RELEASE=true"
        echo "SKIP_REASON=$SKIP_REASON"
      } >> "$GITHUB_ENV"
      exit 0
    fi
  done <<<"$existing_tags"
fi

if [[ -n "${INPUT_PREVIOUS_TAG:-}" ]]; then
  PREVIOUS_TAG="${INPUT_PREVIOUS_TAG}"
else
  PREVIOUS_TAG="$(
    gh release list \
      --repo "$REPO" \
      --exclude-drafts \
      --limit 20 \
      --json tagName,publishedAt \
      --jq 'sort_by(.publishedAt) | reverse | .[0].tagName'
  )"
fi

if [[ -z "$PREVIOUS_TAG" || "$PREVIOUS_TAG" == "null" ]]; then
  echo "Could not determine the previous published release tag." >&2
  exit 1
fi

if [[ -n "${INPUT_PREVIOUS_OFFICIAL_IMAGES_PR:-}" ]]; then
  PREVIOUS_OFFICIAL_IMAGES_PR="${INPUT_PREVIOUS_OFFICIAL_IMAGES_PR}"
else
  previous_release_body="$(
    gh release view "$PREVIOUS_TAG" \
      --repo "$REPO" \
      --json body \
      --jq '.body // ""'
  )"

  PREVIOUS_OFFICIAL_IMAGES_PR="$(
    extract_previous_official_images_pr_from_release_body "$previous_release_body"
  )"
fi

if [[ -z "$PREVIOUS_OFFICIAL_IMAGES_PR" ]]; then
  echo "Could not determine the previous official-images PR from release ${PREVIOUS_TAG}." >&2
  exit 1
fi

previous_official_pr_json="$(
  gh pr view "$PREVIOUS_OFFICIAL_IMAGES_PR" \
    --repo "$official_repo" \
    --json number,title,mergedAt,url
)"

PREVIOUS_OFFICIAL_IMAGES_PR_URL="$(jq -r '.url' <<<"$previous_official_pr_json")"

current_patch="$(get_library_nextcloud_patch "$OFFICIAL_IMAGES_PR")"
if [[ -z "$current_patch" ]]; then
  echo "Could not find library/nextcloud patch in official-images PR #${OFFICIAL_IMAGES_PR}." >&2
  exit 1
fi

old_library_file="$(get_library_nextcloud_file_at_ref "$official_pr_base_oid")"
new_library_file="$(get_library_nextcloud_file_at_ref "$official_pr_head_oid")"

if [[ -z "$old_library_file" || -z "$new_library_file" ]]; then
  echo "Could not fetch library/nextcloud contents for base/head of official-images PR #${OFFICIAL_IMAGES_PR}." >&2
  exit 1
fi

added_git_commits="$(
  extract_added_gitcommits_from_patch "$current_patch"
)"

if [[ -n "$added_git_commits" ]]; then
  while read -r sha; do
    [[ -z "$sha" ]] && continue
    if ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
      git fetch --quiet origin "$sha" || true
    fi
    if ! git cat-file -e "${sha}^{commit}" 2>/dev/null; then
      echo "GitCommit ${sha} is not available locally." >&2
      exit 1
    fi
  done <<<"$added_git_commits"
fi

if [[ -n "${INPUT_RELEASE_TAG:-}" ]]; then
  RELEASE_TAG="${INPUT_RELEASE_TAG}"
else
  year_month="$(date -u +v%Y.%m)"
  existing_month_tags="$(
    gh release list \
      --repo "$REPO" \
      --limit 100 \
      --json tagName \
      --jq '.[].tagName' \
      | grep "^${year_month}\." || true
  )"

  next_n=1
  if [[ -n "$existing_month_tags" ]]; then
    max_n="$(
      sed -n "s/^${year_month//./\\.}\.\([0-9][0-9]*\)$/\1/p" <<<"$existing_month_tags" \
      | sort -n \
      | tail -1
    )"
    if [[ -n "$max_n" ]]; then
      next_n=$((max_n + 1))
    fi
  fi

  RELEASE_TAG="${year_month}.${next_n}"
fi

if [[ -n "${INPUT_TARGET_SHA:-}" ]]; then
  TARGET_SHA="${INPUT_TARGET_SHA}"
else
  TARGET_SHA="$(extract_target_sha_from_library_header "$new_library_file")"
fi

if [[ -z "$TARGET_SHA" ]]; then
  unique_added_git_commit_count="$(
    printf '%s\n' "$added_git_commits" | sed '/^$/d' | sort -u | wc -l | tr -d ' '
  )"
  if [[ "$unique_added_git_commit_count" -eq 1 ]]; then
    TARGET_SHA="$(printf '%s\n' "$added_git_commits" | sed '/^$/d' | sort -u | head -1)"
  fi
fi

if [[ -z "$TARGET_SHA" ]]; then
  echo "Could not determine TARGET_SHA from library/nextcloud generated header or added GitCommit entries for official-images PR #${OFFICIAL_IMAGES_PR}." >&2
  exit 1
fi

tag_bullets="$(
  emit_tag_change_bullets_from_files "$old_library_file" "$new_library_file" || true
)"

commit_bullets="$(
  if [[ -n "$added_git_commits" ]]; then
    while read -r sha; do
      [[ -z "$sha" ]] && continue
      subject="$(git log -1 --format=%s "$sha")"
      author="$(git log -1 --format=%an "$sha")"
      render_commit_bullets "$sha" "$subject" "$author"
    done <<<"$added_git_commits"
  fi
)"

bullet_lines="$(
  {
    printf '%s\n' "$tag_bullets"
    printf '%s\n' "$commit_bullets"
  } | sed '/^$/d' | awk '!seen[$0]++'
)"

change_count=0
if [[ -n "$bullet_lines" ]]; then
  change_count="$(printf '%s\n' "$bullet_lines" | grep -c '^' | tr -d ' ')"
fi

current_git_range_display="$(
  paste -sd',' <(printf '%s\n' "$added_git_commits") || true
)"

{
  echo "## What's Changed"
  echo

  if [[ "$change_count" -eq 0 ]]; then
    echo "* No relevant changes were inferred from official-images PR #${OFFICIAL_IMAGES_PR}"
  else
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      echo "* $line"
    done <<<"$bullet_lines"
  fi

  echo
  echo "**Full Changelog**:"
  echo "* Image: [${REPO} ${PREVIOUS_TAG}...${TARGET_SHA:0:7}](https://github.com/${REPO}/compare/${PREVIOUS_TAG}...${TARGET_SHA})"
  echo "* Nextcloud Server: [Changelog](https://nextcloud.com/changelog/)"
  echo "* Docker Official Image: [${official_repo}#${OFFICIAL_IMAGES_PR}](${OFFICIAL_IMAGES_PR_URL})"
  echo
  echo "<!-- release-meta:"
  echo "official_images_pr=${OFFICIAL_IMAGES_PR}"
  echo "official_images_merged_at=${official_pr_merged_at}"
  echo "previous_official_images_pr=${PREVIOUS_OFFICIAL_IMAGES_PR}"
  echo "previous_tag=${PREVIOUS_TAG}"
  echo "changed_git_commits=${current_git_range_display}"
  echo "target_sha=${TARGET_SHA}"
  echo "generated_at=$(date -u +%FT%TZ)"
  echo "-->"
} > "$tmp_notes"

{
  echo "SKIP_RELEASE=false"
  echo "OFFICIAL_IMAGES_PR=$OFFICIAL_IMAGES_PR"
  echo "OFFICIAL_IMAGES_PR_URL=$OFFICIAL_IMAGES_PR_URL"
  echo "PREVIOUS_OFFICIAL_IMAGES_PR=$PREVIOUS_OFFICIAL_IMAGES_PR"
  echo "PREVIOUS_OFFICIAL_IMAGES_PR_URL=$PREVIOUS_OFFICIAL_IMAGES_PR_URL"
  echo "PREVIOUS_TAG=$PREVIOUS_TAG"
  echo "CHANGED_GIT_COMMITS<<EOF"
  printf '%s\n' "$added_git_commits"
  echo "EOF"
  echo "RELEASE_TAG=$RELEASE_TAG"
  echo "TARGET_SHA=$TARGET_SHA"
} >> "$GITHUB_ENV"

echo "Prepared release draft notes at $tmp_notes"
