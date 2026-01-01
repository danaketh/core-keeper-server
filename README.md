# Core Keeper Dedicated Server

![corekeeper](https://user-images.githubusercontent.com/136487/168213246-7f561105-136e-47fa-abd9-fac1c97ca48d.png)

Explore an endless cavern of creatures, relics and resources in a mining sandbox adventure
for 1-8 players. Mine, build, fight, craft and farm to unravel the mystery of the ancient Core.
[Get Core Keeper at the Steam Store](https://store.steampowered.com/app/1621690/Core_Keeper/)

A Docker-based Core Keeper dedicated server with automated versioning based on official Steam builds.

## Features

- **Automated Versioning**: Images automatically tagged with Core Keeper build numbers
- **Weekly Updates**: Automatic checks for new Core Keeper versions
- **Easy Configuration**: Simple environment variables for server setup
- **Persistent Data**: Separate volume for world saves
- **Lightweight**: Debian-based image optimized for server deployment

## Versioning

This project uses automated versioning based on Core Keeper's official Steam build numbers.
Docker images are automatically built and tagged when new Core Keeper versions are released.

### Available Tags

- `latest` - Most recent Core Keeper build
- `build-XXXXXXXX` - Specific build number (e.g., `build-21036907`)
- `XXXXXXXX` - Short build number (e.g., `21036907`)

### Using Pre-built Images

Pull from GitHub Container Registry:

```bash
# Use latest version
docker pull ghcr.io/danaketh/core-keeper-server:latest

# Use specific build
docker pull ghcr.io/danaketh/core-keeper-server:21036907
```

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 2GB RAM available
- Internet connection for Steam downloads
- 5GB+ disk space for server files

### Using Docker Compose (Recommended)

1. Clone this repository:
   ```bash
   git clone https://github.com/danaketh/core-keeper-server.git
   cd core-keeper-server
   ```

2. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` to configure your server:
   ```bash
   nano .env
   ```

4. Start the server:
   ```bash
   docker compose up -d
   ```

5. Check the logs to monitor server startup:
   ```bash
   docker compose logs -f
   ```

6. Get server information once started:
   ```bash
   # The GameInfo.txt will be displayed in the logs
   docker compose logs core-keeper
   ```

### Using Docker CLI with Pre-built Image

```bash
docker run -d \
  --name core-keeper-server \
  -e WORLD_NAME="My Core Keeper Server" \
  -e WORLD_INDEX=0 \
  -v ./server-data:/home/corekeeper/server/CoreKeeperServer_Data \
  ghcr.io/danaketh/core-keeper-server:latest
```

## Configuration

### Environment Variables

All configuration is done through environment variables in the `.env` file.

| Variable            | Default              | Description                                      |
|---------------------|----------------------|--------------------------------------------------|
| `WORLD_INDEX`       | `0`                  | World slot index (0-4)                           |
| `WORLD_NAME`        | `Core Keeper Server` | Server name displayed in-game                    |
| `WORLD_SEED`        | `0`                  | World generation seed (0 = random)               |
| `WORLD_MODE`        | `0`                  | Game mode: Normal (0), Hard (1), Creative (4)    |
| `GAME_ID`           | _(auto)_             | Unique game identifier (auto-generated if empty) |
| `HASHED_WORLD_SEED` | _(auto)_             | Hashed world seed (auto-generated if empty)      |

### Example Configuration

```env
# .env file
WORLD_INDEX=0
WORLD_NAME=My Awesome Server
WORLD_SEED=12345
WORLD_MODE=0
GAME_ID=
HASHED_WORLD_SEED=
```

## Connecting to Your Server

1. Start the server and wait for it to fully initialize
2. Check the logs for the **Game ID**:
   ```bash
   docker compose logs core-keeper
   ```
3. Look for output like:
   ```
   ==================================================
   Server Information:
   ==================================================
   Game ID: XXXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
   ==================================================
   ```
4. In Core Keeper, use this Game ID to connect to your server

## Volume Management

The server uses one volume for data persistence:

### server-data
- **Path**: `./server-data` (maps to `/home/corekeeper/server/CoreKeeperServer_Data`)
- **Contains**: World saves, GameInfo.txt, server configurations
- **Critical**: Back this up regularly to preserve your worlds!

## Building from Source

### Local Build

```bash
docker compose build
```

### Manual Build

```bash
docker build -t core-keeper-server:latest .
```

### Build with Specific Version

```bash
docker build \
  --build-arg CORE_KEEPER_VERSION=21036907 \
  --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
  --build-arg VCS_REF=$(git rev-parse --short HEAD) \
  -t core-keeper-server:21036907 .
```

## Updating

### Update to Latest Core Keeper Version

Using pre-built images:
```bash
docker compose pull
docker compose up -d
```

Building from source:
```bash
docker compose build --no-cache
docker compose up -d
```

The server automatically updates Core Keeper files on container start.

## Troubleshooting

### Server won't start

1. **Check logs**:
   ```bash
   docker compose logs -f
   ```

2. **Verify file permissions** on server-data volume:
   ```bash
   sudo chown -R 1000:1000 ./server-data
   ```

3. **Ensure sufficient resources**:
   - At least 2GB RAM
   - At least 5GB disk space

4. **Verify environment variables** in `.env` file

### Can't connect to server

1. **Get Game ID** from logs:
   ```bash
   docker compose logs core-keeper | grep "Game ID"
   ```

2. **Verify server is running**:
   ```bash
   docker ps | grep core-keeper
   ```

3. **Check server logs** for errors:
   ```bash
   docker compose logs -f
   ```

### World not saving

1. **Check volume mapping** in `docker-compose.yml`
2. **Verify permissions** on `./server-data` directory
3. **Check disk space**:
   ```bash
   df -h
   ```

## Backup

Back up your world saves regularly:

```bash
# Create backup
tar -czf core-keeper-backup-$(date +%Y%m%d).tar.gz ./server-data

# Restore backup
tar -xzf core-keeper-backup-YYYYMMDD.tar.gz
```

### Automated Backups

Add to crontab for automatic backups:

```bash
# Backup every 6 hours
0 */6 * * * cd /path/to/core-keeper-server && tar -czf backups/backup-$(date +\%Y\%m\%d-\%H\%M).tar.gz ./server-data
```

## Advanced Configuration

### Resource Limits

Edit `docker-compose.yml` to set resource limits:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 4G
    reservations:
      cpus: '1'
      memory: 2G
```

### Running Multiple Servers

To run multiple Core Keeper servers:

1. Duplicate the project directory
2. Change `container_name` in `docker-compose.yml`
3. Use different volume paths to avoid conflicts
4. Use different `.env` files for each server

Example:
```bash
# Server 1
cd ~/core-keeper-server-1
docker compose up -d

# Server 2
cd ~/core-keeper-server-2
docker compose up -d
```

## Project Structure

```
core-keeper-server/
├── .github/
│   └── workflows/
│       └── build.yml    # Automated versioning workflow
├── scripts/
│   └── launch.sh                # Server launch script
├── .env.example                 # Example configuration
├── docker-compose.yml           # Docker Compose configuration
├── Dockerfile                   # Docker image definition
└── README.md                    # This file
```

## How Automated Versioning Works

1. **Weekly Check**: Every Monday at 09:00 UTC, GitHub Actions checks SteamDB for new builds
2. **Build Detection**: If a new Core Keeper build is found, the workflow:
   - Builds a new Docker image
   - Tags it with the build number
   - Pushes to GitHub Container Registry
   - Creates a git tag for version tracking
3. **Skip if Exists**: If the build already exists, the workflow skips building
4. **Manual Override**: You can manually trigger a rebuild from GitHub Actions

## License

This project is licensed under the MIT License.

Core Keeper is developed by Pugstorm and published by Fireshine Games.

## Credits

- Core Keeper: [Pugstorm](https://pugstorm.com/) & [Fireshine Games](https://fireshinegames.co.uk/)

## Support

For issues and questions:

- **Check logs**: `docker compose logs -f`
- **Review configuration**: Verify `.env` file settings
- **GitHub Issues**: [Report issues](https://github.com/danaketh/core-keeper-server/issues)
