FROM alpine:3.16

RUN apk add --no-cache curl bash 

WORKDIR /opt/kk
COPY . /opt/kk/

CMD bash ./start.sh