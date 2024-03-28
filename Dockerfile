FROM python:3.10-alpine as builder
LABEL maintainer="Fanani M. Ihsan"

ENV LANG C.UTF-8
ENV ODOO_VERSION 15.0
ENV ODOO_RC /etc/odoo/odoo.conf

WORKDIR /build

# Install some dependencies
RUN apk add --no-cache \
    bash \
    build-base \
    cargo \
    ca-certificates \
    cairo-dev \
    fontconfig \
    font-noto-cjk \
    freetype \
    freetype-dev \
    grep \
    jpeg-dev \
    icu-data-full \
    libev-dev \
    libevent-dev \
    libffi-dev \
    libjpeg \
    libjpeg-turbo-dev \
    libpng \
    libpng-dev \
    libpq-dev \
    libstdc++ \
    libx11 \
    libxcb \
    libxext \
    libxml2-dev \
    libxrender \
    libxslt-dev \
    musl-dev \
    nodejs \
    npm \
    openldap-dev \
    openssl-dev \
    postgresql-dev \
    py-pip \
    python3-dev \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    zlib \
    zlib-dev

RUN npm install -g less rtlcss postcss
COPY --from=madnight/alpine-wkhtmltopdf-builder:0.12.5-alpine3.10 /bin/wkhtmltopdf /bin/wkhtmltopdf
COPY --from=madnight/alpine-wkhtmltopdf-builder:0.12.5-alpine3.10 /bin/wkhtmltoimage /bin/wkhtmltoimage

# Add Core Odoo
ADD https://github.com/odoo/odoo/archive/refs/heads/${ODOO_VERSION}.zip .
RUN unzip ${ODOO_VERSION}.zip
RUN echo 'INPUT ( libldap.so )' > /usr/lib/libldap_r.so
RUN sed -i "s/cryptography==2.6.1/cryptography==2.6.1 ; python_version <= '3.9'\ncryptography==3.3.2 ; python_version > '3.10'  # (Fanani)/g" odoo-${ODOO_VERSION}/requirements.txt
RUN pip install --upgrade setuptools && pip install --upgrade pip && pip install --upgrade wheel
RUN pip install -r odoo-${ODOO_VERSION}/requirements.txt
RUN cd odoo-${ODOO_VERSION} && python setup.py install

# Fix alpine python path
ADD https://raw.githubusercontent.com/odoo/docker/master/${ODOO_VERSION}/entrypoint.sh /usr/local/bin/odoo.sh
ADD https://raw.githubusercontent.com/odoo/docker/master/${ODOO_VERSION}/wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Clear Installation cache
RUN mkdir -p /mnt/addons && mv /build/odoo-${ODOO_VERSION}/addons /mnt/addons/community && rm -rf /build

FROM python:3.10-alpine as main

# Install some dependencies
RUN apk add --no-cache \
    bash \
    fontconfig \
    font-noto-cjk \
    freetype \
    nginx \
    syslog-ng \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation

# Copy base libs
COPY --from=builder /lib /lib
COPY --from=builder /var/lib /var/lib
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /bin /bin
COPY --from=builder /usr/bin /usr/bin
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /sbin /sbin
COPY --from=builder /usr/sbin /usr/sbin

# Odoo Community Addons
RUN mkdir -p /mnt && chown nginx:nginx -R /mnt
COPY --chown=nginx:nginx --from=builder /mnt/addons/community /mnt/addons/community

# Copy config files
COPY ./etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf
COPY ./etc/odoo/odoo.conf /etc/odoo/odoo.conf

# Copy entire supervisor configurations
COPY ./etc/profile.d/odoo.sh /etc/profile.d/odoo.sh
COPY ./etc/supervisord.conf /etc/supervisord.conf
COPY ./etc/syslog-ng/conf.d/odoo.conf /etc/syslog-ng/conf.d/odoo.conf
COPY ./etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY ./etc/supervisor/conf.d/odoo.conf /etc/supervisor/conf.d/odoo.conf

# Copy init script
COPY ./write_config.py write_config.py
COPY ./entrypoint.sh /entrypoint.sh

# # Expose web service
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
