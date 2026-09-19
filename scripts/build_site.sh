#!/usr/bin/env bash
# Builds the GitHub Pages site into _site/ (or the directory given as $1).
#
# The page states which release it describes and when it was generated, and
# both are filled in here rather than fetched by the visitor's browser, so the
# site makes no request to any host but its own. The version comes from the
# latest published release; SITE_VERSION and SITE_DATE override it (used for
# local previews and when no release exists yet).
#
# The repository comes from GITHUB_REPOSITORY, which Actions sets, so renaming
# the repository needs no change here.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/_site}"
repository="${GITHUB_REPOSITORY:-trsdn/OpenCamraHub}"
# What conferencing apps list the virtual camera as.
camera="${SITE_CAMERA:-OpenCamraHub}"

version="${SITE_VERSION:-}"
if [[ -z "$version" ]]; then
  tag="$(gh release view --repo "$repository" --json tagName --jq .tagName 2>/dev/null || true)"
  version="${tag#v}"
fi
if [[ -z "$version" ]]; then
  echo "build_site: no release found and SITE_VERSION is not set" >&2
  exit 1
fi
# The values go into sed and into HTML; refuse anything that is not what it claims.
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)?$ ]]; then
  echo "build_site: '$version' is not a version number" >&2
  exit 1
fi
if [[ ! "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "build_site: '$repository' is not an owner/name repository" >&2
  exit 1
fi
if [[ ! "$camera" =~ ^[A-Za-z0-9\ ]+$ ]]; then
  echo "build_site: '$camera' is not a plain camera name" >&2
  exit 1
fi
date="${SITE_DATE:-$(date -u +%F)}"
if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "build_site: '$date' is not an ISO date" >&2
  exit 1
fi

rm -rf "$out"
mkdir -p "$out"
cp -R "$root/site/." "$out/"
sed -e "s/{{VERSION}}/$version/g" -e "s/{{DATE}}/$date/g" \
  -e "s#{{REPOSITORY}}#$repository#g" -e "s/{{CAMERA}}/$camera/g" \
  "$root/site/index.html" > "$out/index.html"

if grep -rqI '{{' "$out"; then
  echo "build_site: an unfilled placeholder is left in the output:" >&2
  grep -rnI '{{' "$out" >&2
  exit 1
fi
echo "Built site for version $version ($date) in $out"
