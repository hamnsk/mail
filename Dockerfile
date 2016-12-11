FROM centos:7
MAINTAINER Sergey Visman (admin@sergeyvisman.ru)

ENV container docker

# Install initial requirements
RUN \
  yum update -y && \
  yum install -y epel-release && \
  yum install -y iproute python-setuptools hostname inotify-tools yum-utils which && \
  yum -y install openssl postfix dovecot dovecot-pigeonhole opendkim opendkim-tools rsyslog && \
  yum clean all


# Make some folders & users & stuff
RUN groupadd vmail -g 2222 && useradd vmail -d /var/vmail -M -s /usr/sbin/nologin -g 2222 -u 2222 && \
	mkdir -m 0755 /etc/ssl/mailcerts && \
	mkdir -m 0755 /etc/vmail && \
	mkdir -m 0751 /var/vmail && \
	chown vmail:vmail /var/vmail

# Remove base config files
RUN rm /etc/postfix/main.cf /etc/postfix/master.cf /etc/dovecot/dovecot.conf /etc/dovecot/conf.d/* rm /etc/rsyslog.conf /etc/rsyslog.d/*

# Postfix config
ADD conf/main.cf /etc/postfix/main.cf
ADD conf/master.cf /etc/postfix/master.cf

# Dovecot config
ADD conf/dovecot.conf /etc/dovecot/dovecot.conf
ADD conf/15-lda.conf /etc/dovecot/conf.d/15-lda.conf
ADD conf/20-managesieve.conf /etc/dovecot/conf.d/20-managesieve.conf
ADD conf/90-sieve-extprograms.conf /etc/dovecot/conf.d/90-sieve-extprograms.conf
ADD conf/90-sieve.conf /etc/dovecot/conf.d/90-sieve.conf

# OpenDKIM config
ADD conf/opendkim.conf /etc/opendkim.conf
ADD conf/TrustedHosts /etc/opendkim/TrustedHosts

# rsyslog config
ADD conf/rsyslog.conf /etc/rsyslog.conf

# Copy in scripts & make them executable
ADD scripts/add_mail_user /usr/bin/add_mail_user
ADD scripts/add_mail_domain /usr/bin/add_mail_domain
ADD scripts/add_mail_alias /usr/bin/add_mail_alias
ADD scripts/get_dkim_record /usr/bin/get_dkim_record
ADD scripts/change_mail_password /usr/bin/change_mail_password
ADD scripts/start.sh /start.sh

RUN chmod +x /usr/bin/add_mail_user /usr/bin/add_mail_domain /usr/bin/add_mail_alias /usr/bin/get_dkim_record /usr/bin/change_mail_password && \
	chmod 755 /start.sh

# Setup Volume
VOLUME ["/var/vmail", "/etc/vmail", "/etc/ssl/mailcerts", "/etc/opendkim", "/etc/dovecot", "/etc/postfix"]

# Expose Ports
EXPOSE 25 110 143 465 587 993 995

CMD ["/bin/bash", "/start.sh"]
