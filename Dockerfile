# Comentario for Railway.
# Official image (Alpine, statically linked binary), pinned by version and
# multi-arch index digest. To update: bump both together, add a CHANGELOG.md
# entry, and merge to main (deployers get Railway's update notice).
FROM registry.gitlab.com/comentario/comentario:v3.19.0@sha256:3e11eb383e9d48b643970c5f33abc0c554607206d786256c5172823330e47602

# Listen on all interfaces (IPv4 for Railway's proxy and health check, IPv6 for
# the private network) on Railway's PORT.
ENV HOST=:: \
    PORT=8080 \
    LOG_NO_COLOR=true

# Small start wrapper: creates the first (superuser) account from ADMIN_EMAIL and
# ADMIN_PASSWORD on a loopback-only instance before the public port opens.
COPY --chmod=755 start.sh /usr/local/bin/comentario-railway-start

ENTRYPOINT ["/usr/local/bin/comentario-railway-start"]
CMD ["-v"]
