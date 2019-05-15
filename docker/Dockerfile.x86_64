FROM debian/eol:wheezy
LABEL maintainer="Shaun Jackman <sjackman@gmail.com>"

ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
    HOMEBREW_BUILD_BOTTLE=1 \
    HOMEBREW_DEVELOPER=1 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl file g++ git-core locales make patch \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && useradd -m -s /bin/bash linuxbrew \
    && git clone --depth=1 https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew \
    && mkdir /home/linuxbrew/.linuxbrew/bin \
    && ln -s ../Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/ \
    && brew tap homebrew/portable-ruby
