FROM centos:7

ENV SUMMARY="Base image which allows using of source-to-image."	\
    DESCRIPTION="The s2i-core image provides any images layered on top of it \
with all the tools needed to use source-to-image functionality while keeping \
the image size as small as possible."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="s2i core" \
      io.openshift.s2i.scripts-url=image:///usr/libexec/s2i \
      io.s2i.scripts-url=image:///usr/libexec/s2i \
      com.redhat.component="s2i-core-container" \
      name="centos/s2i-core-centos7" \
      version="1" \
      release="1" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

ENV \
    # DEPRECATED: Use above LABEL instead, because this will be removed in future versions.
    STI_SCRIPTS_URL=image:///usr/libexec/s2i \
    # Path to be used in other layers to place s2i scripts into
    STI_SCRIPTS_PATH=/usr/libexec/s2i \
    APP_ROOT=/opt/app-root \
    # The $HOME is not set by default, but some applications needs this variable
    HOME=/opt/app-root/src \
    PATH=/opt/app-root/src/bin:/opt/app-root/bin:$PATH


# When bash is started non-interactively, to run a shell script, for example it
# looks for this variable and source the content of this file. This will enable
# the SCL for all scripts without need to do 'scl enable'.
ENV BASH_ENV=${APP_ROOT}/etc/scl_enable \
    ENV=${APP_ROOT}/etc/scl_enable \
    PROMPT_COMMAND=". ${APP_ROOT}/etc/scl_enable"

COPY MariaDB.repo /etc/yum.repos.d/MariaDB.repo

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
RUN rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm

RUN yum-config-manager --enable remi
RUN yum-config-manager --enable remi-php72

RUN yum update -y

RUN rpmkeys --import http://yum.mariadb.org/RPM-GPG-KEY-MariaDB

# This is the list of basic dependencies that all language container image can
# consume.
# Also setup the 'openshift' user that is used for the build execution and for the
# application runtime execution.
# TODO: Use better UID and GID values
RUN rpmkeys --import file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
  INSTALL_PKGS="bsdtar \
  findutils \
  gettext \
  groff-base \
  scl-utils \
  tar \
  unzip \
  yum-utils \
  httpd \
  php \
  php-common \
  php-pecl-apcu \
  php-cli \
  php-pear \
  php-pdo \
  php-mysqlnd \
  php-pgsql \
  php-pecl-mongodb \
  php-pecl-memcache \
  php-pecl-memcached \
  php-gd \
  php-json \
  php-mbstring \
  php-opcache \
  php-xml \
  php-xmlrpc \
  php-fpm \
  rsync \
  nmap \
  lsof \
  perl-DBI \
  nmap \
  libaio \
  boost-program-options \
  openssl \
  iproute \
  which \
  wget \
  gzip \
  vim-enhanced \
  MariaDB-server \
  MariaDB-client" && \
  mkdir -p ${HOME}/.pki/nssdb && \
  chown -R 1001:0 ${HOME}/.pki && \
  yum remove -y vim-minimal && \
  yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
  rpm -V $INSTALL_PKGS && \
  yum clean all -y

# Copy extra files to the image.
COPY ./root/ /
COPY httpd.conf /etc/httpd/conf/httpd.conf

# Directory with the sources is set as the working directory so all STI scripts
# can execute relative to this path.
WORKDIR ${HOME}

COPY container-entrypoint /usr/bin/container-entrypoint
COPY container-entrypoint /wkDir/root/usr/bin/container-entrypoint
COPY container-entrypoint /wkDir/s2i-base-container/core/root/usr/bin/container-entrypoint

EXPOSE 80

RUN wget -c https://ftp.drupal.org/files/projects/drupal-8.6.1.tar.gz && \
  tar -zxvf drupal-8.6.1.tar.gz
RUN mv drupal-8.6.1 /var/www/html/drupal && \
  cd /var/www/html/drupal/sites/default/ && \
  cp default.settings.php settings.php

COPY phpinfo.php /var/www/html/phpinfo.php

RUN chown -R apache:apache /var/www/html/drupal/

ENTRYPOINT ["container-entrypoint"]

# Reset permissions of modified directories and add default user
RUN rpm-file-permissions && \
  useradd -u 1001 -r -g 0 -d ${HOME} -s /sbin/nologin \
      -c "Default Application User" default && \
  chown -R 1001:0 ${APP_ROOT}

CMD ["httpd", "-DFOREGROUND", "-f", "/etc/httpd/conf/httpd.conf"]
