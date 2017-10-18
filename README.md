# docker-c9
C9 Docker image

## About

Sets up C9 IDE to install in a container and run on port 8181

## Usage

```
docker run --rm --env-file .c9rc -p 8181:8181 -v $PWD:/workspace r351574nc3/c9:latest
```
Run c9 inside docker on port 8181

### c9rc

It's just an rc file with environment variables for username and password
```
C9_USER=c9
C9_PASS=changeme
```