# =====================================================================
# STAGE 1: Build OpenPrinting stack
# Debian 12 = same Debian major version used by TrueNAS 25.10
# =====================================================================

FROM debian:12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Make locally-installed libraries/pkg-config files visible while building.
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/share/pkgconfig
ENV LD_LIBRARY_PATH=/usr/local/lib

# ---------------------------------------------------------------------
# Build dependencies
# ---------------------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    git \
    wget \
    ca-certificates \
    autoconf \
    automake \
    libtool \
    pkg-config \
    gettext \
    autopoint \
    \
    # PDF / PostScript tools
    ghostscript \
    mupdf-tools \
    poppler-utils \
    \
    # USB / image / CUPS development
    libusb-1.0-0-dev \
    liblcms2-dev \
    libcups2-dev \
    libcupsimage2-dev \
    libexif-dev \
    libfontconfig1-dev \
    libjpeg-dev \
    libpng-dev \
    libpoppler-cpp-dev \
    libtiff-dev \
    \
    # System libraries
    libglib2.0-dev \
    libdbus-1-dev \
    libavahi-client-dev \
    libavahi-common-dev \
    libgnutls28-dev \
    libqpdf-dev \
    zlib1g-dev \
    \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

ARG PAPPL_VERSION=1.4.12
ARG LIBCUPS_FILTERS_VERSION=2.1.1
ARG LIBPPD_VERSION=2.1.1

# =====================================================================
# 1. Build PAPPL
# =====================================================================

RUN wget -q --show-progress \
        "https://github.com/michaelrsweet/pappl/archive/refs/tags/v${PAPPL_VERSION}.tar.gz" \
        -O /tmp/pappl.tar.gz \
    && tar -xzf /tmp/pappl.tar.gz -C /build \
    && mv "/build/pappl-${PAPPL_VERSION}" /build/pappl \
    && rm -f /tmp/pappl.tar.gz

WORKDIR /build/pappl

RUN echo "==============================================" && \
    echo "PAPPL source" && \
    echo "==============================================" && \
    ls -la

RUN ./configure \
        --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install


# =====================================================================
# 2. Build libcupsfilters
# =====================================================================

WORKDIR /build

RUN wget -q --show-progress \
        "https://github.com/OpenPrinting/libcupsfilters/archive/refs/tags/${LIBCUPS_FILTERS_VERSION}.tar.gz" \
        -O /tmp/libcupsfilters.tar.gz \
    && tar -xzf /tmp/libcupsfilters.tar.gz -C /build \
    && mv "/build/libcupsfilters-${LIBCUPS_FILTERS_VERSION}" /build/libcupsfilters \
    && rm -f /tmp/libcupsfilters.tar.gz

WORKDIR /build/libcupsfilters

RUN echo "==============================================" && \
    echo "libcupsfilters source" && \
    echo "==============================================" && \
    ls -la

RUN ./autogen.sh \
    && ./configure \
        --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install


# =====================================================================
# 3. Build libppd
# =====================================================================

WORKDIR /build

RUN wget -q --show-progress \
        "https://github.com/OpenPrinting/libppd/archive/refs/tags/${LIBPPD_VERSION}.tar.gz" \
        -O /tmp/libppd.tar.gz \
    && tar -xzf /tmp/libppd.tar.gz -C /build \
    && mv "/build/libppd-${LIBPPD_VERSION}" /build/libppd \
    && rm -f /tmp/libppd.tar.gz

WORKDIR /build/libppd

RUN echo "==============================================" && \
    echo "libppd source" && \
    echo "==============================================" && \
    ls -la

RUN ./autogen.sh \
    && ./configure \
        --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install


# =====================================================================
# 4. Verify CUPS headers
#
# pappl-retrofit master requires the newer CUPS side-channel API.
# Debian 12 provides CUPS 2.4.2.
# =====================================================================

WORKDIR /build

RUN echo "==============================================" && \
    echo "CUPS environment" && \
    echo "==============================================" && \
    command -v cups-config && \
    cups-config --version && \
    echo "--- CUPS include files ---" && \
    ls -la /usr/include/cups/ && \
    echo "--- CUPS sidechannel symbols ---" && \
    grep -E \
      'CUPS_SC_STATE_MARKER_EMPTY|cups_sc_status_t|CUPS_SC_CMD_GET_DEVICE_ID|CUPS_SC_STATUS_OK' \
      /usr/include/cups/sidechannel.h \
      || true


# =====================================================================
# 5. Verify CUPS via pkg-config where available
#
# Debian's CUPS development package does not necessarily provide a
# cups.pc file, so this is informational only.
# =====================================================================

RUN echo "==============================================" && \
    echo "CUPS pkg-config information" && \
    echo "==============================================" && \
    pkg-config --list-all | grep -i cups || true


# =====================================================================
# 6. Build pappl-retrofit
#
# IMPORTANT:
# Do NOT use the old 1.0b2 release here.
#
# The old release expects CUPS side-channel symbols that do not match
# the CUPS headers in the current Debian 12 environment.
#
# Use current upstream master instead.
# =====================================================================

WORKDIR /build

RUN rm -rf /build/pappl-retrofit && \
    git clone --depth 1 \
        https://github.com/OpenPrinting/pappl-retrofit.git \
        /build/pappl-retrofit

WORKDIR /build/pappl-retrofit

RUN echo "==============================================" && \
    echo "pappl-retrofit source" && \
    echo "==============================================" && \
    git log -1 --oneline && \
    ls -la

RUN ./autogen.sh \
    && ./configure \
        --prefix=/usr/local \
    && make -j"$(nproc)" \
    && make install


# =====================================================================
# 7. Configure runtime linker
# =====================================================================

RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf \
    && ldconfig


# =====================================================================
# 8. Build-stage verification
# =====================================================================

RUN echo "==============================================" && \
    echo "OpenPrinting build complete" && \
    echo "==============================================" && \
    \
    echo "--- PAPPL ---" && \
    ls -lh /usr/local/lib/libpappl* && \
    \
    echo "--- libcupsfilters ---" && \
    ls -lh /usr/local/lib/libcupsfilters* && \
    \
    echo "--- libppd ---" && \
    ls -lh /usr/local/lib/libppd* && \
    \
    echo "--- pappl-retrofit ---" && \
    ls -lh /usr/local/lib/libpappl-retrofit*


# =====================================================================
# STAGE 2: Runtime
# =====================================================================

FROM debian:12-slim AS runner

ENV DEBIAN_FRONTEND=noninteractive

# /usr/local/lib contains PAPPL/libcupsfilters/libppd/pappl-retrofit.
ENV LD_LIBRARY_PATH=/usr/local/lib

# ---------------------------------------------------------------------
# Runtime packages
# ---------------------------------------------------------------------

RUN apt-get update && apt-get install -y --no-install-recommends \
    \
    gosu \
	avahi-daemon \
    avahi-utils \
    dbus \
    libnss-mdns \
    # CUPS
    libcups2 \
    libcupsimage2 \
    cups-daemon \
    cups-client \
    # PAPPL dependencies
	libcap2-bin \
    libfontconfig1 \
    liblcms2-2 \
    libusb-1.0-0 \
    libjpeg62-turbo \
    libpng16-16 \
    libtiff6 \
    libglib2.0-0 \
    libpoppler-cpp0v5 \
    libdbus-1-3 \
    libavahi-client3 \
    libavahi-common3 \
    libgnutls30 \
    libqpdf29 \
    zlib1g \
    \
    # Printing infrastructure
    cups-filters \
    # not in debian 12: foomatic-filters \
    ghostscript \
    mupdf-tools \
    poppler-utils \
    \
    # OKI / foo2zjs / foo2hiperc
    printer-driver-foo2zjs \
    \
    # Diagnostics
    wget \
    ca-certificates \
    netcat-openbsd \
    # netstat
	net-tools \
    # ps
	procps \
    strace \
    binutils \
    \
    && rm -rf /var/lib/apt/lists/*


# =====================================================================
# Copy locally-built OpenPrinting stack
# =====================================================================

COPY --from=builder /usr/local/ /usr/local/

# Configure runtime linker.
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf \
    && ldconfig

RUN setcap 'cap_net_bind_service=+ep' /usr/local/bin/legacy-printer-app
RUN getcap /usr/local/bin/legacy-printer-app

# =====================================================================
# Runtime test 1: OpenPrinting libraries exist
# =====================================================================

RUN echo "==============================================" && \
    echo "Checking OpenPrinting libraries" && \
    echo "==============================================" && \
    \
    ls -lh /usr/local/lib/libpappl* && \
    ls -lh /usr/local/lib/libcupsfilters* && \
    ls -lh /usr/local/lib/libppd* && \
    ls -lh /usr/local/lib/libpappl-retrofit*


# =====================================================================
# Runtime test 2: Check shared-library dependencies
#
# This catches:
#
#     libXYZ.so => not found
#
# before the container is actually started.
# =====================================================================

RUN set -eux; \
    for lib in \
        /usr/local/lib/libpappl.so.1 \
        /usr/local/lib/libcupsfilters.so.2 \
        /usr/local/lib/libppd.so.2 \
        /usr/local/lib/libpappl-retrofit.so.1; \
    do \
        echo "=============================================="; \
        echo "ldd: $lib"; \
        echo "=============================================="; \
        ldd "$lib"; \
        if ldd "$lib" | grep -q "not found"; then \
            echo "ERROR: missing runtime dependency for $lib"; \
            exit 1; \
        fi; \
    done


# =====================================================================
# Runtime test 3: Check foo2hiperc
# =====================================================================

RUN echo "==============================================" && \
    echo "Checking foo2hiperc" && \
    echo "==============================================" && \
    command -v foo2hiperc && \
    foo2hiperc --help >/dev/null 2>&1 || true


# =====================================================================
# Runtime test 4: Check legacy-printer-app
#
# This is critical because it is the executable used by CMD.
# =====================================================================

RUN echo "==============================================" && \
    echo "Checking legacy-printer-app" && \
    echo "==============================================" && \
    command -v legacy-printer-app && \
    legacy-printer-app --help >/dev/null 2>&1 || true


# =====================================================================
# Runtime test 5: Check legacy-printer-app shared libraries
# =====================================================================

RUN set -eux; \
    APP="$(command -v legacy-printer-app)"; \
    echo "legacy-printer-app: $APP"; \
    echo "=============================================="; \
    echo "ldd: $APP"; \
    echo "=============================================="; \
    ldd "$APP" | tee /tmp/legacy-printer-app.ldd; \
    if grep -q "not found" /tmp/legacy-printer-app.ldd; then \
        echo "ERROR: legacy-printer-app has missing libraries"; \
        exit 1; \
    fi


# =====================================================================
# Runtime test 6: Check important executables
# =====================================================================

RUN echo "==============================================" && \
    echo "Checking external tools" && \
    echo "==============================================" && \
    command -v gs && \
    gs --version && \
    command -v mutool && \
    mutool -v 2>&1 || true


# =====================================================================
# Runtime test 7: Search for OKI / C5800 files
#
# This is informational. The image is allowed to build if none are
# found because the Legacy Printer Application may supply its own
# printer definitions.
# =====================================================================

RUN echo "==============================================" && \
    echo "Searching for OKI / C5800 files" && \
    echo "==============================================" && \
    find /usr/share/cups \
         /usr/share/ppd \
         /usr/lib/cups \
         -type f \
         \( \
             -iname '*oki*' -o \
             -iname '*c5800*' \
         \) \
         -print 2>/dev/null || true


# =====================================================================
# Runtime test 8: Show foo2zjs filters
# =====================================================================

RUN echo "==============================================" && \
    echo "foo2zjs / foo2hiperc tools" && \
    echo "==============================================" && \
    command -v foo2hiperc || true && \
    command -v foo2zjs || true && \
    command -v foo2zjs-wrapper || true && \
    command -v foomatic-rip || true

# =====================================================================
# Persistent PAPPL state
# =====================================================================

#RUN mkdir -p /var/lib/pappl
#RUN chmod 777 /var/lib/pappl

RUN mkdir -p /var/lib/legacy-printer-app \
    && chmod 777 /var/lib/legacy-printer-app

RUN mkdir -p /var/spool/legacy-printer-app \
    && chmod 777 /var/spool/legacy-printer-app

#RUN mkdir -p /usr/lib/legacy-printer-app/backend
#RUN mkdir -p /usr/lib/legacy-printer-app
#RUN chmod 777 /usr/lib/legacy-printer-app
#RUN chmod 777 /usr/lib/legacy-printer-app/backend

# pappl-retrofit expects this to expose the normal CUPS
# filters and backends.
RUN rm -rf /usr/lib/legacy-printer-app \
    && ln -s /usr/lib/cups /usr/lib/legacy-printer-app

RUN mkdir -p /var/spool/legacy-printer-app
RUN chmod 777 /var/spool/legacy-printer-app


#VOLUME ["/var/lib/pappl"]

#WORKDIR /var/lib/pappl

VOLUME ["/var/lib/legacy-printer-app"]

WORKDIR /var/lib/legacy-printer-app


# =====================================================================
# Container startup
# =====================================================================

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh


# =====================================================================
# PAPPL / Legacy Printer Application
# =====================================================================

#default
#EXPOSE 8000
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["legacy-printer-app", "server", "-o", "server-port=80"]
#CMD ["legacy-printer-app", "server"]
