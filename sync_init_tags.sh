#!/bin/bash
set -euo pipefail
export PATH=$PWD/tools:$PATH

echo "------ sync_init_tags ------"
echo "TES_ENV: ${TES_ENV}"
echo "ALIAS_GITHUB_REPOSITORY: ${ALIAS_GITHUB_REPOSITORY}"
echo "IMAGE_REPO: ${IMAGE_REPO}"
echo "NEW_TAG: ${NEW_TAG}"

APP_CHART_NAME=$(echo ${ALIAS_GITHUB_REPOSITORY} | awk -F "/" '{print $2}')
if [ -z "$APP_CHART_NAME" ]; then
  echo "err, failed to extract chart name from ALIAS_GITHUB_REPOSITORY: ${ALIAS_GITHUB_REPOSITORY}"
  exit 1
fi

# Validate required inputs
if [ -z "$IMAGE_REPO" ]; then
  echo "err, IMAGE_REPO is required"
  exit 1
fi
if [ -z "$NEW_TAG" ]; then
  echo "err, NEW_TAG is required"
  exit 1
fi

# Verify yq is available (v3 syntax)
yq -V || { echo "err, yq not found in PATH"; exit 1; }

if [ "$TES_ENV" == "mixed" ]; then
  cd env-${TES_ENV}/${APP_CHART_NAME}-${GITHUB_REF_NAME}
else
  cd env-${TES_ENV}/${APP_CHART_NAME}
fi

SYNCED=0
echo "------ checking initContainer repositories ------"
PATHS=$(yq r --printMode p values.yaml "common*.initContainer.repository" || true)
if [ -z "$PATHS" ]; then
  echo "------ no initContainers found in values.yaml ------"
  echo "------ sync_init_tags done (0 updated) ------"
  exit 0
fi
for path in $PATHS; do
  section=$(echo "$path" | sed 's/.initContainer.repository//')
  INIT_REPO=$(yq r values.yaml "$path")
  if [ "$INIT_REPO" == "$IMAGE_REPO" ]; then
    CURRENT=$(yq r values.yaml "${section}.initContainer.tag")
    if [ "$CURRENT" != "$NEW_TAG" ]; then
      echo "  SYNC  ${section}.initContainer.tag: ${CURRENT} -> ${NEW_TAG}"
      yq w -i values.yaml "${section}.initContainer.tag" --style=double "${NEW_TAG}"
      SYNCED=$((SYNCED + 1))
    else
      echo "  OK    ${section}.initContainer.tag: already ${NEW_TAG}"
    fi
  else
    echo "  SKIP  ${section}.initContainer (image: ${INIT_REPO})"
  fi
done

echo "------ sync_init_tags done (${SYNCED} updated) ------"
