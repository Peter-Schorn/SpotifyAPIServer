aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin 947734355387.dkr.ecr.us-east-1.amazonaws.com

docker buildx build . --platform linux/amd64,linux/arm64/v8 -t 947734355387.dkr.ecr.us-east-1.amazonaws.com/spotify-api-backend:arm-latest \
--push

# docker push 947734355387.dkr.ecr.us-east-1.amazonaws.com/spotify-api-backend:arm-latest
