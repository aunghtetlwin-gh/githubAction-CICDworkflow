FROM alpine:latest

RUN apk add --no-cache ca-certificates curl bind-tools iputils

WORKDIR /app

COPY dashboard-service /app/dashboard-service

RUN chmod +x /app/dashboard-service

ENV COUNTING_SERVICE_URL="http://counting-service:9003"

EXPOSE 9002

CMD ["/app/dashboard-service"]
