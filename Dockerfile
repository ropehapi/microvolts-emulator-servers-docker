# syntax=docker/dockerfile:1

FROM ubuntu:24.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    ninja-build \
    git \
    openssh-client \
    curl \
    ca-certificates \
    zip \
    unzip \
    tar \
    python3 \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/* \
    && cmake --version

RUN apt-get update && apt-get install -y gcc-14 g++-14 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the private MicrovoltsEmulator repository using the host SSH agent.
# The SSH key is mounted only for this build step and is not stored in the image.
RUN mkdir -p -m 0700 /root/.ssh \
    && ssh-keyscan github.com >> /root/.ssh/known_hosts
RUN --mount=type=ssh git clone --branch main --depth 1 \
    git@github.com:ropehapi/microvolts-emulator-servers.git .

# Clone and setup vcpkg
RUN git clone https://github.com/microsoft/vcpkg.git ExternalLibraries/vcpkg \
    && ./ExternalLibraries/vcpkg/bootstrap-vcpkg.sh

RUN ./ExternalLibraries/vcpkg/vcpkg install --triplet=x64-linux

RUN cmake -B build -S . -G Ninja \
        -DCMAKE_C_COMPILER=gcc-14 \
        -DCMAKE_CXX_COMPILER=g++-14 \
        -DCMAKE_TOOLCHAIN_FILE=ExternalLibraries/vcpkg/scripts/buildsystems/vcpkg.cmake \
        -DCMAKE_BUILD_TYPE=Release

# Build all three server targets explicitly.
RUN cmake --build build --config Release \
        --target AuthServer MainServer CastServer \
        --parallel 4

# Normalize build artifacts into a stable path for the runtime stage and fail
# early if any expected server binary was not produced.
RUN mkdir -p /app/Output \
    && find /app -maxdepth 3 -type f -name '*.elf' -exec cp -f {} /app/Output/ \; \
    && test -f /app/Output/AuthServer.elf \
    && test -f /app/Output/MainServer.elf \
    && test -f /app/Output/CastServer.elf

FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    libstdc++6 \
    libssl3 \
    libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=builder /app/Output/ /app/Output/

COPY --from=builder /app/Setup/ /app/Setup/
COPY --from=builder /app/ExternalLibraries/cgd_original/ /app/ExternalLibraries/cgd_original/
COPY --from=builder /app/microvolts-db.sql /app/

# Runtime entrypoint patches config.ini based on environment variables.
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

RUN mkdir -p /app/Output

ENV MV_DB_PW=default_password

EXPOSE 13000 13005 13006

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/bin/bash"]
