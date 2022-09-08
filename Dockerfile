FROM ubuntu:22.04

ARG PW="root"

RUN yes | unminimize

# sshd
RUN mkdir /run/sshd; \
    apt-get install -y sudo wget openssh-server; \
    sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config; \
    sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config; \
    apt-get clean;

RUN echo 'AuthorizedKeysFile %h/.ssh/authorized_keys' >> /etc/ssh/sshd_config

# zsh
COPY zsh-in-docker.sh /tmp
RUN /tmp/zsh-in-docker.sh \
    -t https://github.com/denysdovhan/spaceship-prompt \
    -a 'SPACESHIP_PROMPT_ADD_NEWLINE="false"' \
    -a 'SPACESHIP_PROMPT_SEPARATE_LINE="false"' \
    -p git \
    -p https://github.com/zsh-users/zsh-autosuggestions \
    -p https://github.com/zsh-users/zsh-completions \
    -p https://github.com/zsh-users/zsh-history-substring-search \
    -p https://github.com/zsh-users/zsh-syntax-highlighting \
    -p 'history-substring-search' \
    -p mvn \
    -p npm \
    -p node \
    -p ng \
    -p terraform \
    -p helm \
    -p kubectl \
    -p docker \
    -a 'bindkey "\$terminfo[kcuu1]" history-substring-search-up' \
    -a 'bindkey "\$terminfo[kcud1]" history-substring-search-down'

RUN usermod --shell /usr/bin/zsh root

# admin tools
RUN apt-get install -y curl vim

# Code server
RUN curl -fsSL https://code-server.dev/install.sh | sh
# run via: `docker run --rm -e "ROOT_PASSWORD=foobar" zsh-in-docker -- code-server`

# Difftastic
ARG DIFFT_VERSION=0.35.0
RUN wget -c "https://github.com/Wilfred/difftastic/releases/download/${DIFFT_VERSION}/difft-x86_64-unknown-linux-gnu.tar.gz" -O - | tar -xz -C /usr/local/bin/
RUN git config --global diff.external difft
RUN git config --global diff.tool difft
RUN git config --global --add difftool.prompt false
RUN git config --global difftool.difft.cmd 'difft "$LOCAL" "$REMOTE"'

# TheF***
RUN apt-get install -y python3-dev python3-pip python3-setuptools
RUN pip3 install thefuck
RUN echo 'eval $(thefuck --alias fix)' >> $HOME/.zshrc

# Install httpie
RUN curl -SsL https://packages.httpie.io/deb/KEY.gpg | apt-key add -
RUN curl -SsL -o /etc/apt/sources.list.d/httpie.list https://packages.httpie.io/deb/httpie.list
RUN apt-get update
RUN apt-get install httpie

# Developers `cat`
RUN apt-get install -y bat
RUN alias cat='batcat --style=plain'

# Developers `ps`
ARG PROCS_VERSION=0.13.0
RUN apt-get install -y gzip
RUN wget -c "https://github.com/dalance/procs/releases/download/v${PROCS_VERSION}/procs-v${PROCS_VERSION}-x86_64-linux.zip" -O - | gunzip -c > /usr/local/bin/procs
RUN chmod u+x /usr/local/bin/procs

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'echo "root:${ROOT_PASSWORD}" | chpasswd'; \
    echo 'mkdir -p $HOME/.ssh'; \
    echo 'chmod 700 $HOME/.ssh'; \
    echo 'authorized_keys=$HOME/.ssh/authorized_keys'; \
    echo 'curl -s "https://github.com/${GH_USER}.keys" >> $authorized_keys'; \
    echo 'chmod 600 $authorized_keys'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entry_point.sh; \
    chmod +x /usr/local/bin/entry_point.sh;


ENV ROOT_PASSWORD ${PW}

EXPOSE 22

ENTRYPOINT ["entry_point.sh"]
CMD    ["/usr/sbin/sshd", "-D", "-e"]