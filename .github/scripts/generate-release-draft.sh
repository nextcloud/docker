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
export PREVIOUS_TAG=""
export RELEASE_TAG=""
export TARGET_SHA=""

if [[ -n "${INPUT_OFFICIAL_IMAGES_PR:-}" ]]; then
  OFFICIAL_IMAGES_PR="${INPUT_OFFICIAL_IMAGES_PR}"
else
  OFFICIAL_IMAGES_PR="$(
    gh pr list \
      --repo "$official_repo" \
      --search 'is:merged label:"library/nextcloud"' \
      --state merged \
      --limit 20 \
      --json number,mergedAt \
      --jq 'sort_by(.mergedAt) | reverse | .[0].number'
  )"
fi

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
    --json number,title,mergedAt,url,labels,author
)"

OFFICIAL_IMAGES_PR_URL="$(jq -r '.url' <<<"$official_pr_json")"
official_pr_merged_at="$(jq -r '.mergedAt' <<<"$official_pr_json")"

existing_tags="$(
  gh release list \
    --repo "$REPO" \
    --limit 100 \
    --json tagName \
    --jq '.[].tagName'
)"

if [[ -n "$existing_tags" ]]; then
  while read -r tag; do
    [[ -z "$tag" ]] && continue
    description="$(
      gh release view "$tag" \
        --repo "$REPO" \
        --json description \
        --jq '.description // ""'
    )"
    if grep -q "docker-library/official-images/pull/${OFFICIAL_IMAGES_PR}" <<<"$description"; then
      SKIP_RELEASE=true
      SKIP_REASON="A release already references docker-library/official-images PR #${OFFICIAL_IMAGES_PR}."
      {
        echo "SKIP_RELEASE=true"
        echo "SKIP_REASON=$SKIP_REASON"
      } >> "$GITHUB_ENV"
      exit 0
    fi
  done <<< "$existing_tags"
fi

PREVIOUS_TAG="$(
  gh release list \
    --repo "$REPO" \
    --exclude-drafts \
    --limit 20 \
    --json tagName,publishedAt \
    --jq 'sort_by(.publishedAt) | reverse | .[0].tagName'
)"

if [[ -z "$PREVIOUS_TAG" || "$PREVIOUS_TAG" == "null" ]]; then
  echo "Could not determine the previous published release tag." >&2
  exit 1
fi

previous_release_json="$(
  gh release view "$PREVIOUS_TAG" \
    --repo "$REPO" \
    --json tagName,publishedAt,targetCommitish
)"

previous_published_at="$(jq -r '.publishedAt' <<<"$previous_release_json")"

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
      sed -n "s/^${year_month}\.\([0-9][0-9]*\)$/\1/p" <<<"$existing_month_tags" \
      | sort -n \
      | tail -1
    )"
    if [[ -n "$max_n" ]]; then
      next_n=$((max_n + 1))
    fi
  fi

  RELEASE_TAG="${year_month}.${next_n}"
fi

TARGET_SHA="$(git rev-parse origin/master)"

repo_prs_json="$(
  gh pr list \
    --repo "$REPO" \
    --search "is:merged merged:>${previous_published_at}" \
    --state merged \
    --limit 100 \
    --json number,title,url,author,mergedAt
)"

change_count="$(jq 'length' <<<"$repo_prs_json")"

{
  echo "## What's Changed"
  echo

  if [[ "$change_count" -eq 0 ]]; then
    echo "* No merged pull requests were found since ${PREVIOUS_TAG}"
  else
    jq -r '.[] | "* \(.title) by @\(.author.login) in \(.url)"' <<<"$repo_prs_json"
  fi

  echo
  echo "## New Contributors"
  echo

  first_time_contributors="$(
    jq -r '.[].author.login' <<<"$repo_prs_json" | sort -u | while read -r login; do
      [[ -z "$login" ]] && continue
      count="$(
        gh pr list \
          --repo "$REPO" \
          --search "is:merged author:${login}" \
          --state merged \
          --limit 100 \
          --json number \
          --jq 'length'
      )"
      if [[ "$count" -eq 1 ]]; then
        echo "$login"
      fi
    done
  )"

  if [[ -z "$first_time_contributors" ]]; then
    echo "* No new contributors in this release"
  else
    while read -r login; do
      [[ -z "$login" ]] && continue
      echo "* @${login} made their first contribution"
    done <<<"$first_time_contributors"
  fi

  echo
  echo "**Full Changelog**:"
  echo "* Image: https://github.com/${REPO}/compare/${PREVIOUS_TAG}...master"
  echo "* Nextcloud Server: https://nextcloud.com/changelog/"
  echo "* Docker Official Image: ${OFFICIAL_IMAGES_PR_URL}"
  echo
  echo "<!-- release-meta:"
  echo "official_images_pr=${OFFICIAL_IMAGES_PR}"
  echo "official_images_merged_at=${official_pr_merged_at}"
  echo "previous_tag=${PREVIOUS_TAG}"
  echo "target_sha=${TARGET_SHA}"
  echo "generated_at=$(date -u +%FT%TZ)"
  echo "-->"
} > "$tmp_notes"

{
  echo "SKIP_RELEASE=false"
  echo "OFFICIAL_IMAGES_PR=$OFFICIAL_IMAGES_PR"
  echo "OFFICIAL_IMAGES_PR_URL=$OFFICIAL_IMAGES_PR_URL"
  echo "PREVIOUS_TAG=$PREVIOUS_TAG"
  echo "RELEASE_TAG=$RELEASE_TAG"
  echo "TARGET_SHA=$TARGET_SHA"
} >> "$GITHUB_ENV"

echo "Prepared release draft notes at $tmp_notes"
