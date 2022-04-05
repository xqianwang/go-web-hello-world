FROM golang:1.18

WORKDIR /usr/src/app

COPY ./go-web/* ./ 
RUN go build -v -o /usr/local/bin/app ./
EXPOSE 8081

CMD ["app"]
