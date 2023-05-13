FROM python:3.7-alpine
LABEL maintainer="Fanani M. Ihsan"

ENV LANG C.UTF-8

# Install some dependencies
RUN apk add --no-cache \
    bash \
    build-base \
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
    libssl1.1 \
    libstdc++ \
    libx11 \
    libxcb \
    libxext \
    libxml2-dev \
    libxrender \
    libxslt-dev \
    nodejs \
    npm \
    nginx \
    openldap-dev \
    postgresql-dev \
    py-pip \
    python3-dev \
    supervisor \
    syslog-ng \
    ttf-dejavu \
    ttf-droid \
    ttf-freefont \
    ttf-liberation \
    zlib \
    zlib-dev

RUN npm install -g less rtlcss postcss
COPY --from=madnight/alpine-wkhtmltopdf-builder:0.12.5-alpine3.10 \
    /bin/wkhtmltopdf /bin/wkhtmltopdf
COPY --from=madnight/alpine-wkhtmltopdf-builder:0.12.5-alpine3.10 \
    /bin/wkhtmltoimage /bin/wkhtmltoimage

# Add Core Odoo
ADD https://github.com/odoo/odoo/archive/refs/heads/14.0.zip .
RUN unzip 14.0.zip && cd odoo-14.0 && python setup.py install && \
    sed -i "s/gevent==20.9.0 ; python_version >= '3.8'/gevent==20.9.0 ; python_version > '3.7' and python_version <= '3.9'\ngevent==21.8.0 ; python_version > '3.9'  # (Jammy)/g" requirements.txt && \
    sed -i "s/greenlet==0.4.17 ; python_version > '3.7'/greenlet==0.4.17 ; python_version > '3.7' and python_version <= '3.9'\ngreenlet==1.1.2 ; python_version  > '3.9'  # (Jammy)/g" requirements.txt && \
    sed -i "s/pyopenssl==19.0.0/pyopenssl==19.0.0 ; python_version > '3.7' and python_version <= '3.8'\npyopenssl==22.1.0 ; python_version > '3.8'  # (Fanani)/g" requirements.txt && \
    echo 'INPUT ( libldap.so )' > /usr/lib/libldap_r.so && \
    pip3 install --upgrade pip && \
    pip3 install setuptools && \
    pip3 install -r requirements.txt --no-cache-dir
# Clear Installation cache
RUN mv /odoo-14.0/addons /mnt/community_addons && rm -rf 14.0.zip odoo-14.0

# Fix alpine python path
ADD https://raw.githubusercontent.com/odoo/docker/master/14.0/entrypoint.sh /usr/local/bin/odoo.sh
ADD https://raw.githubusercontent.com/odoo/docker/master/14.0/wait-for-psql.py /usr/local/bin/wait-for-psql.py

# Copy config files
COPY ./etc/nginx/http.d/default.conf /etc/nginx/http.d/default.conf
COPY ./etc/odoo/odoo.conf /etc/odoo/odoo.conf

# Copy entire supervisor configurations
COPY ./etc/profile.d/odoo.sh /etc/profile.d/odoo.sh
COPY ./etc/supervisord.conf /etc/supervisord.conf
COPY ./etc/syslog-ng/conf.d/odoo.conf /etc/syslog-ng/conf.d/odoo.conf
COPY ./etc/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY ./etc/supervisor/conf.d/odoo.conf /etc/supervisor/conf.d/odoo.conf
COPY ./entrypoint.sh .

# Set permissions
RUN chown nginx:nginx -R /etc/odoo && chmod 755 /etc/odoo && \
    chown nginx:nginx -R /mnt && chmod 755 /mnt && \
    chmod 777 /usr/local/bin/odoo.sh && chmod 777 /usr/local/bin/wait-for-psql.py

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Expose web service
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]
