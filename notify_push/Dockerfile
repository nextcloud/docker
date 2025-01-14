FROM alpine:3.13

RUN apk add --no-cache ca-certificates

# https://github.com/nextcloud/notify_push/releases
ENV NOTIFY_PUSH_VERSION 0.1.6

RUN set -ex; \
	\
	apkArch="$(apk --print-arch)"; \
	npTriplet="unknown-linux-musl"; \
	case "$apkArch" in \
		aarch64|x86_64) npArch="$apkArch" ;; \
		armv7) npArch="$apkArch"; $npTriplet="${npTriplet}-eabihf" ;; \
		*) echo >&2 "error: unsupported arch: $apkArch"; exit 1 ;; \
	esac; \
	\
	wget -O /usr/local/bin/notify_push "https://github.com/nextcloud/notify_push/releases/download/v${NOTIFY_PUSH_VERSION}/notify_push-$npArch-$npTriplet"; \
	\
	chmod +x /usr/local/bin/notify_push; \
	notify_push --version

USER nobody

EXPOSE 7867

CMD ["notify_push"]
