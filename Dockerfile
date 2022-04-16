ARG img=homebrew/debian7
# hadolint ignore=DL3006
FROM ${img}
ARG img

ENV HOMEBREW_FORCE_HOMEBREW_ON_LINUX=1
ENV HOMEBREW_DEVELOPER=1
ENV HOMEBREW_NO_AUTO_UPDATE=1

# Needs to run as root for GitHub Actions
# hadolint ignore=DL3002
USER root

RUN if [ "x${img}" = "xhomebrew/debian7" ]; then \
      apt-get update \
      && apt-get install -y --no-install-recommends gcc-4.9-backport=4.9.2-10+deb7u1 \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*; \
    fi

# Don't want to pin package versions
# hadolint ignore=DL3008
RUN mkdir -p /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/homebrew/homebrew-portable
