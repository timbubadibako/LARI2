# syntax=docker/dockerfile:1

# --- Stage 1: Build ---
FROM golang:1.26-alpine AS builder
RUN apk add --no-cache git gcc musl-dev
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o /lari-server cmd/server/main.go

# --- Stage 2: Runtime ---
FROM alpine:latest

# Install PostGIS & CA Certificates
RUN apk add --no-cache ca-certificates postgis

# Hugging Face Best Practice: Run as non-root user (UID 1000)
RUN adduser -D -u 1000 user
USER user
WORKDIR /home/user/app

# Copy binary
COPY --from=builder --chown=user:user /lari-server .

# HF Spaces menggunakan port 7860 secara default
ENV PORT=7860
EXPOSE 7860

CMD ["./lari-server"]
