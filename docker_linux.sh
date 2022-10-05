TAG=${1:-swift:latest}

docker run \
    --rm \
    --volume "$(pwd):/src" \
    --workdir "/src" \
    -it \
    --privileged \
    -e SPOTIFY_DATA_DUMP_FOLDER="/logs" \
    -e CLIENT_ID=$SPOTIFY_SWIFT_TESTING_CLIENT_ID \
    -e CLIENT_SECRET=$SPOTIFY_SWIFT_TESTING_CLIENT_SECRET \
    -e REDIRECT_URI=$REDIRECT_URI \
    -e SECRET_KEY=$SECRET_KEY \
    $TAG

# swift test --filter "GeneralTests|ClientCredentialsFlowTests"
