############################
# STEP 1 build executable binary
############################
FROM docker.io/library/golang@sha256:d78cd58c598fa1f0c92046f61fde32d739781e036e3dc7ccf8fdb50129243dd8 as builder
# Install git + SSL ca certificates.
# Git is required for fetching the dependencies.
# Ca-certificates is required to call HTTPS endpoints.
USER root
#RUN apk update && apk add --no-cache git ca-certificates && update-ca-certificates && apk add --no-cache upx
# Create appuser
ENV USER=appuser
ENV UID=10001
# See https://stackoverflow.com/a/55757473/12429735RUN 
RUN adduser \    
    --disabled-password \    
    --gecos "" \    
    --home "/nonexistent" \    
    --shell "/sbin/nologin" \    
    --no-create-home \    
    --uid "${UID}" \    
    "${USER}"
WORKDIR $GOPATH/src/mypackage/myapp/
COPY resizer/resizer /tmp/resizer
RUN chmod u+x /tmp/resizer
############################
# STEP 2 build a small image
############################
FROM scratch
# Import from builder.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
# Copy our static executable
COPY --from=builder /tmp/resizer /go/bin/resizer
# Use an unprivileged user.
USER appuser:appuser
# Expose the port
EXPOSE 8080
# Run the resizer binary.
ENTRYPOINT ["/go/bin/resizer" ]]
