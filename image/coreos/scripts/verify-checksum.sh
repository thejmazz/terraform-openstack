#!/bin/bash

# needs jq, curl, gpg, and optionally pget

function error_exit() {
  echo "$1" 1>&2
  exit 1
}

# TODO check deps with command -v and exit if not present

# TODO nicer way to make this giant line?
eval "$(jq -r '@sh "export PUBLIC_KEY=\(.public_key) BASE_URL=\(.base_url) IMAGE=\(.image) SIGNATURE=\(.signature) CHECKSUMS=\(.checksums) CACHE_PATH=\(.cache_path)"')"

[[ "$CACHE_PATH" = "null" ]] && export CACHE_PATH="$HOME/.terraform/image_cache"

[[ ! -d "$CACHE_PATH/$IMAGE" ]] && mkdir -p "$CACHE_PATH/$IMAGE"
cd "$CACHE_PATH/$IMAGE"

if [[ ! -f "$IMAGE" ]]; then
    pget "$BASE_URL/$IMAGE" > /dev/null 2>&1 || curl -sO "$BASE_URL/$IMAGE"
    # TODO optional pget, fallback to curl
    # pget "$BASE_URL/$IMAGE"
fi

curl -sO "$BASE_URL/$SIGNATURE"
curl -sO "$BASE_URL/$CHECKSUMS"

# gpg --keyserver $KEYSERVER --recv-keys $KEY_ID > /dev/null 2>&1
# [[ "$?" != "0" ]] && error_exit "Could not import key $KEY_ID from keyserver $KEYSERVER"

# gpg --verify $SIGNATURE $CHECKSUMS > /dev/null 2>&1
# [[ "$?" != 0 ]] && error_exit "Could not verify $CHECKSUMS against signature $SIGNATURE"
curl -sSL $PUBLIC_KEY | gpg --import - > /dev/null 2>&1

# CHECKSUM=$(cat $CHECKSUMS | grep $IMAGE | awk -F' ' '{print $1}')
CHECKSUM=$(cat $CHECKSUMS | grep "# SHA512 HASH" -A 1 | tail -n 1 | awk '{print $1}')

# Confirm OK for our image
# if [[ "$IMAGE" = "$(sha256sum --check $CHECKSUMS 2>&1 | grep OK | awk -F':' '{print $1}')" ]]; then
if [[ "$IMAGE" = "$(sha512sum --check $CHECKSUMS 2>&1 | grep OK | awk -F':' '{print $1}')" ]]; then
    UNZIPPED_IMAGE=$(echo $IMAGE | sed 's/\.bz2//')
    if [[ ! -f "$CACHE_PATH/$IMAGE/$UNZIPPED_IMAGE" ]]; then
        cat "$CACHE_PATH/$IMAGE/$IMAGE" | bzip2 -d > "$CACHE_PATH/$IMAGE/$UNZIPPED_IMAGE"
    fi

    jq -n \
        --arg path "$CACHE_PATH/$IMAGE/$UNZIPPED_IMAGE" \
        --arg checksum "$CHECKSUM" \
        '{"path":$path, "checksum": $checksum}'
else
    error_exit "Checksum $CHECKSUM did not match $CACHE_PATH/$IMAGE/$IMAGE"
fi
