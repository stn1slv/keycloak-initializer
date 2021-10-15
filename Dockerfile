FROM alpine:3.8

RUN apk add --no-cache curl bash 

WORKDIR /opt/kk
COPY . /opt/kk/

CMD bash ./start.sh