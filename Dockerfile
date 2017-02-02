FROM debian:jessie
MAINTAINER Odoo S.A. <info@odoo.com>

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            wget \
            node-less \
            node-clean-css \
            python-pyinotify \
            python-renderpm \
            python-support \
		postgresql \
		postgresql-server-dev-all \
		postgresql-client \
		adduser \
		libxml2-dev \
		libxslt1-dev \
		libldap2-dev \
		libsasl2-dev \
		libssl-dev \
		libjpeg-dev \
		python-dev \
		python-pip \
		build-essential \
		python \
		python-dateutil \
		python-decorator \
		python-docutils \
		python-feedparser \
		python-imaging \
		python-jinja2 \
		python-ldap \
		python-libxslt1 \
		python-lxml \
		python-mako \
		python-mock \
		python-openid \
		python-passlib \
		python-psutil \
		python-psycopg2 \
		python-pybabel \
		python-pychart \
		python-pydot \
		python-pyparsing \
		python-pypdf \
		python-reportlab \
		python-requests \
		python-simplejson \
		python-tz \
		python-unittest2 \
		python-vatnumber \
		python-vobject \
		python-werkzeug \
		python-xlwt \
		python-yaml \
		python-unidecode -y \
        && curl -o wkhtmltox.deb -SL http://nightly.odoo.com/extra/wkhtmltox-0.12.1.2_linux-jessie-amd64.deb \
        && echo '40e8b906de658a2221b15e4e8cd82565a47d7ee8 wkhtmltox.deb' | sha1sum -c - \
        && dpkg --force-depends -i wkhtmltox.deb \
        && apt-get -y install -f --no-install-recommends \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false npm \
        && rm -rf /var/lib/apt/lists/* wkhtmltox.deb

# Install Odoo
ENV ODOO_VERSION 7.0
ENV ODOO_RELEASE 20140804-231303-1
RUN set -x; \
        curl -o odoo.deb -SL http://nightly.odoo.com/${ODOO_VERSION}/nightly/deb/openerp_${ODOO_VERSION}-${ODOO_RELEASE}_all.deb \
	&& curl -o openerp.tar.gz http://nightly.odoo.com/7.0/nightly/deb/openerp_7.0.latest.tar.gz \
        && dpkg --force-depends -i odoo.deb \
        && apt-get update \
        && apt-get -y install -f --no-install-recommends \
        && apt-get install python-setuptools \
        && rm -rf /var/lib/apt/lists/* odoo.deb

RUN apt-get update && apt-get install -y vim
ADD openerp-7.0_20160406-py2.7.egg /openerp.egg
RUN rm /usr/bin/openerp-server && easy_install /openerp.egg

# Copy entrypoint script and Odoo configuration file
COPY ./entrypoint.sh /
COPY ./openerp-server.conf /etc/odoo/
RUN useradd odoo
RUN chown odoo /etc/odoo/openerp-server.conf
RUN chmod +x /entrypoint.sh

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /mnt/extra-addons \
        && chown -R odoo /mnt/extra-addons
VOLUME ["/var/lib/odoo", "/mnt/extra-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV OPENERP_SERVER /etc/odoo/openerp-server.conf

# Set default user when running the container
USER odoo

#ENTRYPOINT ["/entrypoint.sh"]
CMD ["openerp-server"]
