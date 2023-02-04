aws ecr get-login-password --region us-east-1 | \
docker login --username AWS --password-stdin 947734355387.dkr.ecr.us-east-1.amazonaws.com

docker build . -t 947734355387.dkr.ecr.us-east-1.amazonaws.com/spotify-api-backend:latest

docker push 947734355387.dkr.ecr.us-east-1.amazonaws.com/spotify-api-backend:latest
