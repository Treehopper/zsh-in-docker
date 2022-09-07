FROM ubuntu:22.04

ARG PW="root"

RUN yes | unminimize

# sshd
RUN mkdir /run/sshd; \
    apt-get install -y sudo wget openssh-server; \
    sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config; \
    sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config; \
    apt-get clean;

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
    -a 'bindkey "\$terminfo[kcuu1]" history-substring-search-up' \
    -a 'bindkey "\$terminfo[kcud1]" history-substring-search-down'

RUN usermod --shell /usr/bin/zsh root

# admin tools
RUN apt-get install -y vim

# Code server
RUN curl -fsSL https://code-server.dev/install.sh | sh
# run via: `docker run -e "ROOT_PASSWORD=foobar" zsh-in-docker -- code-server`

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'echo "root:${ROOT_PASSWORD}" | chpasswd'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entry_point.sh; \
    chmod +x /usr/local/bin/entry_point.sh;


ENV ROOT_PASSWORD ${PW}

EXPOSE 22

ENTRYPOINT ["entry_point.sh"]
CMD    ["/usr/sbin/sshd", "-D", "-e"]