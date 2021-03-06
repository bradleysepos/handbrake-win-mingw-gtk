FROM mstorsjo/llvm-mingw:20200325

# The gdk-pixbuf build requires the glib-genmarshal tool (libglib2.0-dev-bin)
# Not sure how close the native glib version must be to the one we're cross compiling.
# gtk requires glib-compile-schemas (libglib2.0-bin) and gdk-pixbuf-pixdata (libgdk-pixbuf2.0-dev).

RUN apt-get update && \
    apt-get install -y --no-install-recommends gperf help2man python3-pip python3-setuptools libglib2.0-dev-bin libglib2.0-bin libgdk-pixbuf2.0-dev zip nasm libtool-bin && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install meson==0.54.0

WORKDIR /build

COPY build-gtk.sh cross.meson.in copy-runtime-dlls.sh copy-pregenerated.sh ./
COPY patches/ ./patches/
COPY generated/ ./generated/

ARG ARCH=aarch64

RUN mkdir build-$ARCH && \
    cd build-$ARCH && \
    ../build-gtk.sh && \
    ../copy-pregenerated.sh && \
    ../copy-runtime-dlls.sh

COPY patches-hb/ ./patches-hb/
COPY build-handbrake-gtk.sh ./
RUN cd build-$ARCH && \
    ../build-handbrake-gtk.sh

COPY strip-install.sh ./
RUN cd build-$ARCH && \
    ../strip-install.sh

RUN cp build-$ARCH/HandBrake/build/HandBrakeCLI.exe build-$ARCH/prefix/bin

RUN cd build-$ARCH/prefix && \
    zip -9r /ghb-$ARCH.zip *
