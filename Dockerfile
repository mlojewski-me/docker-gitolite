FROM alpine:3.20

MAINTAINER Michael Elsdorfer <michael@elsdoerfer.com>

ARG UID=1024
RUN adduser -S -G users -u ${UID} -s /bin/sh git

RUN apk add --no-cache openssh-server gitolite

# https://github.com/docker/docker/issues/5892
RUN chown -R git:git /home/git

# Remove SSH host keys, so they will be generated by /init
RUN rm -f /etc/ssh/ssh_host_*

# Use dumb-init as PID1
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_amd64 /usr/sbin/init
RUN chmod +x /usr/sbin/init

# Our init script will do some setup work such as generating host keys on a per-container basis.
ADD ./init.sh /init
RUN chmod +x /init

ADD ./sshd_config /etc/sshd_config

# Make sure that the VOLUME intructions work on top of an existing directory which is already
# accessible by the "git" user (would be root otherwise).
RUN mkdir /home/git/repositories
RUN chown -R git:git /home/git/repositories

RUN chown -R git:git /etc/ssh
# Addind volume to repositories directory
VOLUME /home/git/repositories
VOLUME /etc/ssh


# Try to run this as non-root
USER git

ENTRYPOINT ["/usr/sbin/init"]
CMD ["/init", "/usr/sbin/sshd", "-D", "-f", "/etc/sshd_config"]

EXPOSE 8022
