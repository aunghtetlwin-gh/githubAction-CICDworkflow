FROM alpine:latest

RUN apk add --no-cache ca-certificates curl bind-tools iputils

WORKDIR /app

COPY counting-service /app/counting-service

RUN chmod +x /app/counting-service

EXPOSE 9003

CMD ["/app/counting-service"]
