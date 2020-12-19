ARG PYTHON_VERSION=3.7.8
ARG DEBIAN_VERSION=buster

FROM python:${PYTHON_VERSION}-${DEBIAN_VERSION} AS builder
ENV PYTHONUNBUFFERED 1

RUN mkdir /install
WORKDIR /install

# Build TA-Lib Core
RUN wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz \
    && tar -xvzf ta-lib-0.4.0-src.tar.gz \
    && cd ta-lib/ \
    && ./configure --prefix=/usr \
    && make \
    && make install \
    && cd .. \
    && rm -R ta-lib-0.4.0-src.tar.gz
    # && rm -R ta-lib

# Build Python Wheel Packages
WORKDIR /wheels
# Build TA-Lib Python
COPY ./requirements.txt /wheels/requirements.txt

RUN pip install -U pip \
    && pip wheel -r ./requirements.txt

# Release Build
FROM python:${PYTHON_VERSION}-slim-${DEBIAN_VERSION}

COPY --from=builder /install /build/ta-lib
COPY --from=builder /wheels /wheels

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gcc \
        libc6-dev \
        make \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build/ta-lib

RUN cd ta-lib \
    && make install

RUN pip install -U pip \
    && pip install -r /wheels/requirements.txt \
                   -f /wheels \
    && rm -rf /wheels \
    && rm -rf /root/.cache/pip/*


# Ref https://www.merixstudio.com/blog/docker-multi-stage-builds-python-development/
