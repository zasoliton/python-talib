ARG PYTHON_VERSION=3.8.9
ARG DEBIAN_VERSION=buster

FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION} AS builder
ENV PYTHONUNBUFFERED 1

RUN mkdir -p /out/packages
RUN mkdir -p /out/wheels
WORKDIR /install

ARG DEBIAN_VERSION

RUN echo deb http://deb.debian.org/debian ${DEBIAN_VERSION}-backports main >> /etc/apt/sources.list.d/sources.list

RUN apt update && apt install -y checkinstall build-essential wget automake

# Build TA-Lib Core
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz \
    && tar -xvzf ta-lib-0.4.0-src.tar.gz \
    && cd ta-lib/ \
    && cp /usr/share/automake-1.16/config.guess . \
    && ./configure --prefix=/usr \
    && checkinstall -y --pakdir=/out/packages \
    && cd .. \
    && rm -R ta-lib-0.4.0-src.tar.gz \
    && rm -R ta-lib

# Build Python Wheel Packages
COPY ./requirements.txt /wheels/requirements.txt

WORKDIR /out/wheels

RUN pip install -U pip \
   && pip wheel -r /wheels/requirements.txt



# Release Build
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION}

ARG TARGETARCH

COPY --from=builder /out /install

# Install ta-lib package
RUN dpkg -i /install/packages/ta-lib_0.4.0-1_${TARGETARCH}.deb

# Install python wheel packages
RUN pip install --no-cache-dir -U pip \
    && pip install \
            --only-binary :all: \
            --no-cache-dir \
            /install/wheels/* \
    && rm -rf /root/.cache/pip/*

CMD "bash"
# Ref https://www.merixstudio.com/blog/docker-multi-stage-builds-python-development/
