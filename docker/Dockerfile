# We want sufficiently old glibc
FROM centos:centos6
MAINTAINER Xu Cheng <xucheng@me.com>

RUN yum groupinstall 'Development Tools' -y && \
    yum install sudo curl git python-setuptools libyaml-devel openssl-devel readline-devel zlib-devel -y
RUN git clone --depth=1 https://github.com/rbenv/rbenv.git /opt/rbenv && \
    echo 'export PATH=/opt/rbenv/bin:$PATH; export RBENV_ROOT=/opt/rbenv/var/rbenv; eval "$(rbenv init -)"' >>/etc/profile && \
    echo 'source /etc/profile' >>/etc/bashrc
RUN source /etc/profile && \
    git clone --depth=1 https://github.com/rbenv/ruby-build.git /opt/rbenv/plugins/ruby-build && \
    (cd /opt/rbenv/plugins/ruby-build; ./install.sh) && \
    rbenv install 2.0.0-p648 && \
    rbenv global 2.0.0-p648
RUN localedef -i en_US -f UTF-8 en_US.UTF-8 && \
    useradd -m -s /bin/bash linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
RUN source /etc/profile && \
    git clone --depth=1 https://github.com/Linuxbrew/linuxbrew.git /home/linuxbrew/.linuxbrew && \
    git clone --depth=1 https://github.com/xu-cheng/homebrew-portable /home/linuxbrew/.linuxbrew/Library/Taps/xu-cheng/homebrew-portable && \
    ln -s $(which gcc) /home/linuxbrew/.linuxbrew/bin/gcc-$(gcc -dumpversion | cut -d. -f1,2) && \
    ln -s $(which g++) /home/linuxbrew/.linuxbrew/bin/g++-$(g++ -dumpversion | cut -d. -f1,2) && \
    chown -R linuxbrew:linuxbrew /home/linuxbrew/.linuxbrew
USER linuxbrew
WORKDIR /home/linuxbrew
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/opt/rbenv/bin:$PATH SHELL=/bin/bash
