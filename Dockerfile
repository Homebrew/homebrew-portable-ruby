ARG img=homebrew/debian7
# hadolint ignore=DL3006
FROM ${img}
ARG img

ENV HOMEBREW_FORCE_HOMEBREW_ON_LINUX=1
ENV HOMEBREW_ON_DEBIAN7=1
ENV HOMEBREW_DEVELOPER=1
ENV HOMEBREW_CURL_PATH=/usr/bin/curl
ENV HOMEBREW_GIT_PATH=/usr/bin/git
ENV HOMEBREW_NO_AUTO_UPDATE=1

# Needs to run as root for GitHub Actions
# hadolint ignore=DL3002
USER root

# Don't want to pin package versions
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
       bzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /home/linuxbrew/.linuxbrew/Homebrew/Library/Taps/homebrew/homebrew-portable
