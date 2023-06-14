FROM debian:bookworm

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y \
        build-essential \
        devscripts \
        debhelper \
        dh-make \
        fakeroot \
        lintian

COPY . /build
WORKDIR /build
RUN dpkg-buildpackage -us -uc
RUN mkdir /packages && cp ../*.deb /packages/
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /build
WORKDIR /packages
