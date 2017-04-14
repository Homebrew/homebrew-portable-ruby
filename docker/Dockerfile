# We want a sufficiently old glibc to be backwards compatible.
FROM centos:centos5
MAINTAINER Homebrew Maintainers <homebrew-discuss@googlegroups.com>

# CentOS 5 has reached end-of-life, as result all of mirrors have stopped working.
# Switch to use http://vault.centos.org/ instead.
RUN sed -i '/mirrorlist=.*/d' /etc/yum.repos.d/{CentOS-Base,libselinux}.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org/centos/$releasever|baseurl=http://vault.centos.org/5.11|g' /etc/yum.repos.d/{CentOS-Base,libselinux}.repo

RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
RUN yum groupinstall 'Development Tools' -y
RUN yum install sudo vim-enhanced which curl git -y
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

USER linuxbrew
RUN echo 'insecure' >> /home/linuxbrew/.curlrc
RUN export HOMEBREW_FORCE_VENDOR_RUBY=1 && \
    export PATH=/home/linuxbrew/.linuxbrew/bin:$PATH && \
    git clone --depth=1 https://github.com/Linuxbrew/brew /home/linuxbrew/.linuxbrew && \
    brew analytics off && \
    brew tap homebrew/core && \
    brew tap homebrew/portable && \
    ln -s $(which gcc) /home/linuxbrew/.linuxbrew/bin/gcc-$(gcc -dumpversion|cut -d. -f1,2) && \
    ln -s $(which g++) /home/linuxbrew/.linuxbrew/bin/g++-$(g++ -dumpversion|cut -d. -f1,2) && \
    chown -R linuxbrew:linuxbrew /home/linuxbrew/.linuxbrew

WORKDIR /home/linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH \
    SHELL=/bin/bash \
    CURL_HOME=/home/linuxbrew \
    HOMEBREW_BUILD_BOTTLE=1 \
    HOMEBREW_BUILD_FROM_SOURCE=1 \
    HOMEBREW_FORCE_VENDOR_RUBY=1 \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_AUTO_UPDATE=1
