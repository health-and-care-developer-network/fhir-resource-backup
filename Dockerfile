FROM alpine
RUN apk add --update zip
COPY backup.sh /
ENTRYPOINT ["/backup.sh"] 

