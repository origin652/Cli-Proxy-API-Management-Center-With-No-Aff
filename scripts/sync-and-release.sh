#!/usr/bin/env bash
# Sync from router-for-me/Cli-Proxy-API-Management-Center (origin), re-apply no-aff patch,
# push to noaff, and tag to trigger GitHub Release (management.html).
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-origin}"
FORK_REMOTE="${FORK_REMOTE:-noaff}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/router-for-me/Cli-Proxy-API-Management-Center.git}"
FORK_URL="${FORK_URL:-https://github.com/origin652/Cli-Proxy-API-Management-Center-With-No-Aff.git}"
BRANCH="${BRANCH:-main}"
PATCH_FILE="scripts/remove-quick-start.patch"
TAG_PREFIX="${TAG_PREFIX:-noaff}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

log() { printf '[sync-and-release] %s\n' "$*"; }
die() { printf '[sync-and-release] ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

require_cmd git

ensure_remote() {
  local name="$1" url="$2"
  if git remote get-url "$name" >/dev/null 2>&1; then
    return 0
  fi
  log "Adding remote $name -> $url"
  git remote add "$name" "$url"
}

if [[ ! -f "$PATCH_FILE" ]]; then
  die "Patch not found: $PATCH_FILE (run from repo root)"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  die "Working tree not clean. Commit or stash changes first."
fi

ensure_remote "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
ensure_remote "$FORK_REMOTE" "$FORK_URL"

log "Fetching $UPSTREAM_REMOTE..."
git fetch "$UPSTREAM_REMOTE"

CURRENT="$(git branch --show-current)"
if [[ "$CURRENT" != "$BRANCH" ]]; then
  die "Checkout $BRANCH first (current: $CURRENT)"
fi

log "Merging $UPSTREAM_REMOTE/$BRANCH..."
set +e
git merge --no-edit "$UPSTREAM_REMOTE/$BRANCH"
MERGE_STATUS=$?
set -e

if [[ "$MERGE_STATUS" -ne 0 ]]; then
  echo ""
  die "Merge conflict with upstream. Resolve manually, then:
  1) git add <resolved files>
  2) git commit   (if merge not finished)
  3) git apply $PATCH_FILE   (or fix by hand: MainLayout, DashboardPage, MainRoutes)
  4) Re-run: bash scripts/sync-and-release.sh"
fi

log "Applying no-aff patch ($PATCH_FILE)..."
set +e
git apply --check "$PATCH_FILE" 2>/dev/null
CHECK_STATUS=$?
set -e

if [[ "$CHECK_STATUS" -eq 0 ]]; then
  git apply "$PATCH_FILE"
  git add src/components/layout/MainLayout.tsx src/pages/DashboardPage.tsx src/router/MainRoutes.tsx
  if git diff --cached --quiet; then
    log "Patch applied but no staged changes (unexpected)."
  else
    git commit -m "chore: re-apply remove Quick Start after upstream merge"
    log "Committed no-aff patch."
  fi
else
  if git grep -q "quickStartNavItem" src/components/layout/MainLayout.tsx 2>/dev/null; then
    die "Patch does not apply and Quick Start still present in MainLayout.tsx — resolve manually, then re-run."
  fi
  log "Patch not needed (no-aff changes already present)."
fi

log "Pushing $BRANCH to $FORK_REMOTE..."
git push "$FORK_REMOTE" "$BRANCH"

# Latest upstream version tag reachable from HEAD (pure semver like v1.17.8).
# Falls back to the highest noaff base if no upstream tag is reachable.
upstream_base_tag() {
  local t
  while IFS= read -r t; do
    if [[ "$t" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      echo "$t"
      return
    fi
  done < <(git tag -l 'v[0-9]*' --merged HEAD --sort=-v:refname)
  # No upstream version tag reachable; reuse latest noaff base as fallback.
  local latest
  latest="$(git tag -l 'v*'"-$TAG_PREFIX"'.*' --sort=-v:refname | head -n 1 || true)"
  if [[ "$latest" =~ ^v(.+)-${TAG_PREFIX}\.[0-9]+$ ]]; then
    echo "v${BASH_REMATCH[1]}"
    return
  fi
  echo "v0.0.1"
}

next_tag() {
  local base
  base="$(upstream_base_tag)"
  base="${base#v}"  # strip leading 'v' -> e.g. 1.17.8
  local n=1 latest_n
  # Highest existing noaff suffix number for this exact base version.
  latest_n="$(git tag -l "v${base}-${TAG_PREFIX}.*" --sort=-v:refname | head -n 1 || true)"
  if [[ "$latest_n" =~ ^v${base}-${TAG_PREFIX}\.([0-9]+)$ ]]; then
    n=$(( ${BASH_REMATCH[1]} + 1 ))
  fi
  echo "v${base}-${TAG_PREFIX}.${n}"
}

NEW_TAG="$(next_tag)"
log "Creating tag $NEW_TAG (triggers Release workflow)..."
git tag -a "$NEW_TAG" -m "Release $NEW_TAG — Web UI without Quick Start (synced from upstream)"
git push "$FORK_REMOTE" "$NEW_TAG"

log "Done. Tag pushed: $NEW_TAG"
if command -v gh >/dev/null 2>&1; then
  log "Release workflow (watch with): gh run watch --repo origin652/Cli-Proxy-API-Management-Center-With-No-Aff"
  gh release view "$NEW_TAG" --repo origin652/Cli-Proxy-API-Management-Center-With-No-Aff 2>/dev/null \
    && log "Release: https://github.com/origin652/Cli-Proxy-API-Management-Center-With-No-Aff/releases/tag/$NEW_TAG" \
    || log "Waiting for Actions to create Release… refresh GitHub Releases in ~1 min."
else
  log "Install GitHub CLI (gh) to check release status."
fi