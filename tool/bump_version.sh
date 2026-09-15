#!/usr/bin/env bash
# Version bump + release tag. Rewrites `version:` in pubspec.yaml, commits it
# and tags the commit; with --push it also pushes the branch and the tag —
# and the tag push is what fires the Release workflow
# (.github/workflows/release.yml). See docs/release.md.
#
# Nothing leaves the machine without --push: the commit and tag are made
# locally, the commit is printed for review, and the branch push and the tag
# push are each confirmed on their own — so a bump can be read (and undone)
# before any of it is public.
#
# Play requires the version code (the `+N` part) to be strictly higher than
# any build already uploaded, so every bump increments it; the argument only
# decides what happens to the name.
#
# Usage: tool/bump_version.sh [patch|minor|major|build|X.Y.Z] [options]
#
#   patch (default)   1.0.0+3 -> 1.0.1+4
#   minor             1.0.0+3 -> 1.1.0+4
#   major             1.0.0+3 -> 2.0.0+4
#   build             1.0.0+3 -> 1.0.0+4   (same name, fresh upload)
#   X.Y.Z             set the name outright (must be higher than the current)
#
# Options:
#       --push        push the branch and the tag to origin (asks for each);
#                     without it the bump stays local
#   -y, --yes         answer every prompt yes
#   -n, --dry-run     print the plan and change nothing
#       --check       run `flutter analyze --fatal-infos` + `flutter test` first
#       --no-tag      commit the bump only, no tag
#       --tag NAME    use this tag name instead of the derived one
#       --no-fetch    skip the fetch that checks the branch/tag against origin
#       --any-branch  allow cutting from a branch other than main
set -euo pipefail

cd "$(dirname "$0")/.."

readonly MAIN_BRANCH=main
bump=""
tag_name=""
yes=0 dry_run=0 check=0 push=0 tag=1 any_branch=0 fetch=1

die() { echo "bump_version: $*" >&2; exit 1; }
confirm() {
  [ "$yes" -eq 0 ] || return 0
  [ -t 0 ] || die "not a terminal — pass --yes to run unattended"
  local reply
  read -r -p "$1 [y/N] " reply
  case "$reply" in [yY]|[yY][eE][sS]) return 0 ;; *) return 1 ;; esac
}
usage() { awk 'NR == 1 {next} !/^#/ {exit} {sub(/^# ?/, ""); print}' "$0"; }

while [ $# -gt 0 ]; do
  case "$1" in
    patch|minor|major|build)
      [ -z "$bump" ] || die "two version arguments: '$bump' and '$1'"
      bump=$1 ;;
    [0-9]*.[0-9]*.[0-9]*)
      [ -z "$bump" ] || die "two version arguments: '$bump' and '$1'"
      bump=$1 ;;
    [0-9]*) die "'$1' is not X.Y.Z" ;;
    -y|--yes) yes=1 ;;
    -n|--dry-run) dry_run=1 ;;
    --check) check=1 ;;
    --push) push=1 ;;
    --no-tag) tag=0 ;;
    --any-branch) any_branch=1 ;;
    --no-fetch) fetch=0 ;;
    --tag) shift; tag_name=${1:-}; [ -n "$tag_name" ] || die "--tag needs a name" ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done
bump=${bump:-patch}

# --- the version in pubspec.yaml -------------------------------------------

current=$(sed -n 's/^version: *//p' pubspec.yaml | head -1 | tr -d '[:space:]')
[ -n "$current" ] || die "no 'version:' line in pubspec.yaml"
case "$current" in
  *+*) ;;
  *) die "pubspec version '$current' has no '+code' part" ;;
esac
name=${current%%+*}
code=${current##*+}
[[ "$name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version name '$name' is not X.Y.Z"
[[ "$code" =~ ^[0-9]+$ ]] || die "version code '$code' is not a number"

IFS=. read -r major minor patch <<<"$name"

# Sortable key, so 1.10.0 beats 1.9.0.
version_key() { local a b c; IFS=. read -r a b c <<<"$1"; printf '%05d%05d%05d' "$a" "$b" "$c"; }

case "$bump" in
  major) new_name="$((major + 1)).0.0" ;;
  minor) new_name="$major.$((minor + 1)).0" ;;
  patch) new_name="$major.$minor.$((patch + 1))" ;;
  build) new_name="$name" ;;
  *)
    new_name=$bump
    [[ "$new_name" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "'$new_name' is not X.Y.Z"
    [ "$(version_key "$new_name")" -gt "$(version_key "$name")" ] \
      || die "$new_name is not higher than the current $name" ;;
esac
new_code=$((code + 1))
new_version="$new_name+$new_code"

# --- the git side ----------------------------------------------------------

git rev-parse --git-dir >/dev/null 2>&1 || die "not a git repository"
branch=$(git rev-parse --abbrev-ref HEAD)
[ "$branch" != HEAD ] || die "HEAD is detached — check out a branch first"
if [ "$any_branch" -eq 0 ] && [ "$branch" != "$MAIN_BRANCH" ]; then
  die "on '$branch', not '$MAIN_BRANCH' — releases are cut from $MAIN_BRANCH (--any-branch overrides)"
fi
[ -z "$(git status --porcelain --untracked-files=no)" ] \
  || die "working tree has uncommitted changes — commit or stash them first"

# Network calls get the same backoff the release notes ask for.
retry() {
  local delay=2 attempt
  for attempt in 1 2 3 4; do
    if "$@"; then return 0; fi
    echo "bump_version: '$*' failed, retrying in ${delay}s ($attempt/4)" >&2
    sleep "$delay"
    delay=$((delay * 2))
  done
  "$@"
}

if [ "$fetch" -eq 1 ]; then
  # A branch that is not on origin yet is fine; only an unreachable origin isn't.
  retry git fetch --quiet --tags origin "$branch" \
    || retry git fetch --quiet --tags origin \
    || die "cannot reach origin (--no-fetch skips this check)"
  if git rev-parse --verify --quiet "refs/remotes/origin/$branch" >/dev/null; then
    behind=$(git rev-list --count "HEAD..origin/$branch")
    [ "$behind" -eq 0 ] \
      || die "$branch is $behind commit(s) behind origin — 'git pull origin $branch' first"
  fi
fi

tag_exists() { git rev-parse --verify --quiet "refs/tags/$1" >/dev/null; }

if [ "$tag" -eq 1 ]; then
  if [ -z "$tag_name" ]; then
    tag_name="v$new_name"
    # A `build` bump keeps the name, so the plain tag is already taken; fall
    # back to one that carries the code, which still matches the v* trigger.
    if tag_exists "$tag_name"; then tag_name="v$new_name+$new_code"; fi
  fi
  if tag_exists "$tag_name"; then die "tag $tag_name already exists"; fi
fi

# --- the plan --------------------------------------------------------------

echo "bump_version:"
echo "  version   $current  ->  $new_version"
echo "  commit    Bump version to $new_version   (on $branch)"
if [ "$tag" -eq 1 ]; then
  echo "  tag       $tag_name"
else
  echo "  tag       (skipped)"
fi
if [ "$push" -eq 1 ]; then
  echo "  push      origin $branch$([ "$tag" -eq 1 ] && echo ", then $tag_name") (asked for separately)"
else
  echo "  push      no — stays local (--push pushes)"
fi

if [ "$dry_run" -eq 1 ]; then
  echo "bump_version: dry run, nothing changed"
  exit 0
fi

confirm "Proceed?" || die "aborted"

# --- do it -----------------------------------------------------------------

if [ "$check" -eq 1 ]; then
  echo "bump_version: analyzing"
  flutter analyze --fatal-infos
  echo "bump_version: testing"
  flutter test
fi

sed -i.bak "s/^version: .*/version: $new_version/" pubspec.yaml
rm -f pubspec.yaml.bak
[ "$(sed -n 's/^version: *//p' pubspec.yaml | head -1 | tr -d '[:space:]')" = "$new_version" ] \
  || die "pubspec.yaml did not take the new version"

git add pubspec.yaml
git commit --quiet --message "Bump version to $new_version"
echo "bump_version: committed $(git rev-parse --short HEAD)"

undo="git reset --hard HEAD~1"
if [ "$tag" -eq 1 ]; then
  git tag --annotate "$tag_name" --message "Arrow $new_name ($new_code)"
  echo "bump_version: tagged $tag_name"
  undo="$undo && git tag -d $tag_name"
fi

# What is about to be pushed, in full — it is one line, so print the patch.
echo
git --no-pager show --no-color HEAD
echo

push_commands() {
  echo "    git push -u origin $branch"
  if [ "$tag" -eq 1 ]; then echo "    git push origin $tag_name"; fi
  echo "    (undo instead: $undo)"
}

if [ "$push" -eq 0 ]; then
  echo "bump_version: nothing pushed. When it looks right:"
  push_commands
  exit 0
fi

if ! confirm "Push $branch to origin?"; then
  echo "bump_version: nothing pushed. When it looks right:"
  push_commands
  exit 0
fi
if ! retry git push -u origin "$branch"; then
  echo "bump_version: push failed. The commit is local; undo it with:" >&2
  echo "    $undo" >&2
  exit 1
fi
echo "bump_version: pushed $branch"

[ "$tag" -eq 1 ] || exit 0

# The tag is asked separately because it is the one that starts a release.
if ! confirm "Push $tag_name to origin? (this starts the Release workflow)"; then
  echo "bump_version: tag $tag_name is local only. Push it with:"
  echo "    git push origin $tag_name"
  exit 0
fi
if ! retry git push origin "$tag_name"; then
  echo "bump_version: the commit is pushed but the tag is not. Retry with:" >&2
  echo "    git push origin $tag_name" >&2
  exit 1
fi
echo "bump_version: pushed $tag_name — the Release workflow is building $new_version"
