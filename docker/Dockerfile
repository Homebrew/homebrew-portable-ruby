# We want sufficiently old glibc
FROM centos:centos5
MAINTAINER Xu Cheng <xucheng@me.com>

RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
RUN yum groupinstall 'Development Tools' -y
RUN yum install sudo vim-enhanced which curl git python-setuptools libyaml-devel openssl-devel \
                readline-devel zlib-devel -y
RUN git clone --depth=1 https://github.com/rbenv/rbenv.git /opt/rbenv && \
    echo 'export PATH=/opt/rbenv/bin:$PATH; \
          export RBENV_ROOT=/opt/rbenv/var/rbenv; \
          eval "$(rbenv init -)"' >>/etc/profile && \
    echo 'source /etc/profile' >>/etc/bashrc
RUN source /etc/profile && \
    git clone --depth=1 https://github.com/rbenv/ruby-build.git \
        /opt/rbenv/plugins/ruby-build && \
    (cd /opt/rbenv/plugins/ruby-build; ./install.sh) && \
    rbenv install 2.0.0-p648 && \
    rbenv global 2.0.0-p648
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
RUN source /etc/profile && \
    git clone --depth=1 https://github.com/Linuxbrew/brew /home/linuxbrew/.linuxbrew && \
    /home/linuxbrew/.linuxbrew/bin/brew analytics off && \
    /home/linuxbrew/.linuxbrew/bin/brew tap homebrew/core && \
    /home/linuxbrew/.linuxbrew/bin/brew tap homebrew/portable && \
    ln -s $(which gcc) /home/linuxbrew/.linuxbrew/bin/gcc-$(gcc -dumpversion|cut -d. -f1,2) && \
    ln -s $(which g++) /home/linuxbrew/.linuxbrew/bin/g++-$(g++ -dumpversion|cut -d. -f1,2) && \
    chown -R linuxbrew:linuxbrew /home/linuxbrew/.linuxbrew
USER linuxbrew
WORKDIR /home/linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/opt/rbenv/bin:$PATH \
    SHELL=/bin/bash \
    HOMEBREW_BUILD_FROM_SOURCE=1 \
    HOMEBREW_BUILD_BOTTLE=1 \
    HOMEBREW_NO_ANALYTICS=1
