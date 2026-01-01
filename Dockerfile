# Core Keeper Dedicated Server - Alpine-based Dockerfile
# Using Debian Slim as Alpine has compatibility issues with SteamCMD and Core Keeper
FROM debian:bookworm-slim

# Build arguments for versioning
ARG CORE_KEEPER_VERSION=latest
ARG BUILD_DATE
ARG VCS_REF

# Labels
LABEL maintainer="daniel@tlach.cz" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.version="${CORE_KEEPER_VERSION}" \
      org.label-schema.name="Core Keeper Dedicated Server" \
      org.label-schema.description="Core Keeper Dedicated Server in Docker"

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    STEAMCMD_DIR=/opt/steamcmd \
    SERVER_DIR=/home/corekeeper/server \
    DATA_DIR=/home/corekeeper/data \
    GAME_ID=1963720 \
    PUID=1000 \
    PGID=1000 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6-i386 \
        libsdl2-2.0-0:i386 \
        libglu1-mesa:i386 \
        xvfb \
        xauth \
        wget \
        tar \
        locales \
        procps \
        && \
    # Generate and set locale
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user and directories
RUN groupadd -g ${PGID} corekeeper && \
    useradd -u ${PUID} -g ${PGID} -m -s /bin/bash corekeeper && \
    mkdir -p ${STEAMCMD_DIR} ${SERVER_DIR} ${DATA_DIR} && \
    chown -R corekeeper:corekeeper ${STEAMCMD_DIR} ${SERVER_DIR} ${DATA_DIR} && \
    mkdir -p /tmp/.X11-unix && \
    chmod 1777 /tmp/.X11-unix

# Switch to corekeeper user
USER corekeeper

# Download and install SteamCMD
RUN cd ${STEAMCMD_DIR} && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Initialize SteamCMD (downloads updates and configs)
RUN ${STEAMCMD_DIR}/steamcmd.sh +quit || true

# Download Core Keeper Server
RUN ${STEAMCMD_DIR}/steamcmd.sh \
    +@sSteamCmdForcePlatformType linux \
    +force_install_dir "${SERVER_DIR}" \
    +login anonymous \
    +app_update 1007 validate \
    +app_update ${GAME_ID} validate \
    +quit && \
    chmod +x ${SERVER_DIR} && \
    chown -R corekeeper:corekeeper ${STEAMCMD_DIR} ${SERVER_DIR} ${DATA_DIR}

WORKDIR ${SERVER_DIR}

# Expose ports (optional - SDR mode doesn't need them)
# 27015-27016/udp for game traffic
# 27015-27016/tcp for RCON
EXPOSE 27015/udp 27015/tcp 27016/udp 27016/tcp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "CoreKeeperServer" > /dev/null || exit 1

# Copy launch script
COPY --chown=corekeeper:corekeeper --chmod=755 ./scripts/launch.sh ${SERVER_DIR}/launch.sh

# Start the server
CMD ["./launch.sh"]
