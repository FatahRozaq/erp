FROM docker.io/library/alpine:3.22.2
ADD --checksum=sha256:7c5bd8512c6e966455b1d198209358b2d191c77a83ab377c4073281065fb855f \
    https://github.com/minio/minio/releases/download/RELEASE.2025-09-07T16-13-09Z/minio.linux-amd64.RELEASE.2025-09-07T16-13-09Z \
    /usr/local/bin/minio
RUN chmod 0755 /usr/local/bin/minio \
    && addgroup -S minio && adduser -S -G minio minio \
    && mkdir /data && chown minio:minio /data
USER minio:minio
EXPOSE 9000 9001
ENTRYPOINT ["/usr/local/bin/minio"]
