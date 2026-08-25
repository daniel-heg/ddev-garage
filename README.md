[![add-on registry](https://img.shields.io/badge/DDEV-Add--on_Registry-blue)](https://addons.ddev.com)
[![tests](https://github.com/daniel-heg/ddev-garage/actions/workflows/tests.yml/badge.svg?branch=main)](https://github.com/daniel-heg/ddev-garage/actions/workflows/tests.yml?query=branch%3Amain)
[![last commit](https://img.shields.io/github/last-commit/daniel-heg/ddev-garage)](https://github.com/daniel-heg/ddev-garage/commits)
[![release](https://img.shields.io/github/v/release/daniel-heg/ddev-garage)](https://github.com/daniel-heg/ddev-garage/releases/latest)

# DDEV Garage

## Overview

This add-on integrates Garage into your [DDEV](https://ddev.com/) project.

## Installation

```bash
ddev add-on get daniel-heg/ddev-garage
ddev restart
```

After installation, make sure to commit the `.ddev` directory to version control.

## Usage

| Command | Description |
| ------- | ----------- |
| `ddev describe` | View service status and used ports for Garage |
| `ddev logs -s garage` | Check Garage logs |

## Advanced Customization

To change the Docker image:

```bash
ddev dotenv set .ddev/.env.garage --garage-docker-image="ddev/ddev-utilities:latest"
ddev add-on get daniel-heg/ddev-garage
ddev restart
```

Make sure to commit the `.ddev/.env.garage` file to version control.

All customization options (use with caution):

| Variable | Flag | Default |
| -------- | ---- | ------- |
| `GARAGE_DOCKER_IMAGE` | `--garage-docker-image` | `ddev/ddev-utilities:latest` |

## Credits

**Contributed and maintained by [@daniel-heg](https://github.com/daniel-heg)**
