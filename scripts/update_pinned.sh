#!/bin/bash
set -e

USERNAME="KAwasthi2889"

if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  exit 1
fi

# Fetch pinned repositories using GitHub GraphQL API
response=$(curl -s -H "Authorization: bearer $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST -d " \
 { \
   \"query\": \"query { user(login: \\\"$USERNAME\\\") { pinnedItems(first: 6, types: REPOSITORY) { nodes { ... on Repository { name } } } } }\" \
 } \
" https://api.github.com/graphql)

# Parse repos using jq
repos=$(echo "$response" | jq -r '.data.user.pinnedItems.nodes[].name')

# Generate markdown
MARKDOWN=""
COUNT=0

for repo in $repos; do
  if [ $COUNT -gt 0 ] && [ $((COUNT % 2)) -eq 0 ]; then
    MARKDOWN="$MARKDOWN<br/><br/>\n\n"
  elif [ $COUNT -gt 0 ]; then
    MARKDOWN="$MARKDOWN&nbsp;\n"
  fi

  MARKDOWN="$MARKDOWN<a href=\"https://github.com/$USERNAME/$repo\">\n  <img src=\"https://github-readme-stats.vercel.app/api/pin/?username=${USERNAME,,}&repo=$repo&theme=dracula&bg_color=0d1117&hide_border=true&description_lines_count=2\" alt=\"$repo\"/>\n</a>\n"
  
  COUNT=$((COUNT + 1))
done

# Replace between markers in README.md
awk -v new_content="$MARKDOWN" '
  /<!-- PINNED_PROJECTS_START -->/ {
    print
    printf "%s", new_content
    skip=1
    next
  }
  /<!-- PINNED_PROJECTS_END -->/ {
    skip=0
  }
  !skip { print }
' README.md > README.md.tmp && mv README.md.tmp README.md

echo "Successfully updated README.md with pinned projects!"
