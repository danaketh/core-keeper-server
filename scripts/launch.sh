#!/bin/bash

# Core Keeper Server Launch Script
# Combined from original _launch.sh with environment variable configuration
# Uses environment variables from Docker Compose

xvfbpid=""
ckpid=""
installdir="$(dirname -- "$0")"
exepath="./CoreKeeperServer"

pushd "$installdir" || exit 1

# Cleanup function to properly kill processes
function kill_corekeeperserver {
    if [[ ! -z "$ckpid" ]]; then
        echo "Stopping Core Keeper server (PID: $ckpid)..."
        kill $ckpid 2>/dev/null || true
        wait $ckpid 2>/dev/null || true
    fi
    if [[ ! -z "$xvfbpid" ]]; then
        echo "Stopping Xvfb (PID: $xvfbpid)..."
        kill $xvfbpid 2>/dev/null || true
        wait $xvfbpid 2>/dev/null || true
    fi
}

trap kill_corekeeperserver EXIT

# Display startup configuration
echo "=================================================="
echo "Core Keeper Dedicated Server"
echo "=================================================="
echo "World Index: ${WORLD_INDEX:-0}"
echo "World Name: ${WORLD_NAME:-Core Keeper Server}"
echo "World Seed: ${WORLD_SEED:-0}"
echo "World Mode: ${WORLD_MODE:-0}"
echo "Game ID: ${GAME_ID}"
echo "Data Path: ${DATA_PATH:-${STEAMAPPDATADIR}}"
echo "=================================================="
echo ""

# Remove old GameInfo.txt
rm -f GameInfo.txt

# Make server executable
chmod +x "$exepath"

# Build command arguments from environment variables
ARGS=("-batchmode" "-logfile" "CoreKeeperServerLog.txt")

# Add world configuration if set
if [ -n "${WORLD_INDEX}" ]; then
    ARGS+=("-world" "${WORLD_INDEX}")
fi

if [ -n "${WORLD_NAME}" ]; then
    ARGS+=("-worldname" "${WORLD_NAME}")
fi

if [ -n "${WORLD_SEED}" ]; then
    ARGS+=("-worldseed" "${WORLD_SEED}")
fi

if [ -n "${WORLD_MODE}" ]; then
    ARGS+=("-worldmode" "${WORLD_MODE}")
fi

if [ -n "${HASHED_WORLD_SEED}" ]; then
    ARGS+=("-hashedworldseed" "${HASHED_WORLD_SEED}")
fi

if [ -n "${GAME_ID}" ]; then
    ARGS+=("-gameid" "${GAME_ID}")
fi

if [ -n "${DATA_PATH}" ]; then
    ARGS+=("-datapath" "${DATA_PATH}")
elif [ -n "${STEAMAPPDATADIR}" ]; then
    ARGS+=("-datapath" "${STEAMAPPDATADIR}")
fi

# Start Xvfb virtual framebuffer (required for Unity headless mode)
set -m
rm -f /tmp/.X99-lock

echo "Starting Xvfb virtual display..."
Xvfb :99 -screen 0 1x1x24 -nolisten tcp &
xvfbpid=$!

# Start Core Keeper server
echo "Starting Core Keeper server with arguments: ${ARGS[@]}"
DISPLAY=:99 LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$installdir/linux64/" \
    "$exepath" "${ARGS[@]}" &

ckpid=$!

echo "Started server process with PID $ckpid"

# Wait for GameInfo.txt to be created (contains game session info)
while [ ! -f GameInfo.txt ]; do
    sleep 0.1
done

echo "=================================================="
echo "Server Information:"
echo "=================================================="
cat GameInfo.txt
echo "=================================================="

# Wait for server process to complete
wait $ckpid
ckpid=""
popd
