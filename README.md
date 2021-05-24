# python-talib
Docker Image with TA-Lib

# Multi architecture build
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t zasoliton/python-talib:3.8.9 -t zasoliton/python-talib:latest --push .
