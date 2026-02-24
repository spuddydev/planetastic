# Planetastic

> **Status: Work in Progress**

A spherical map generator built in Godot 4.6. Uses Delaunay/Voronoi tessellation to divide a sphere into regions, then simulates tectonics and climate to assign biomes and elevation.

## Prerequisites

- [Godot 4.6](https://godotengine.org/) (Forward Plus renderer, Jolt Physics)
- [GUT](https://gut.readthedocs.io/) — Godot Unit Testing framework (install via AssetLib or manually into `addons/gut/`)
- [gdtoolkit 4.x](https://github.com/Scony/godot-gdscript-toolkit) — linting and formatting
  ```bash
  pipx install "gdtoolkit==4.*"
  ```
- [pre-commit](https://pre-commit.com/) — optional, for automatic lint/format on commit
  ```bash
  pre-commit install
  ```

## Setup

1. Clone the repository.
2. Install GUT into `addons/gut/` if not already present.
3. Open the project in Godot 4.6.

## Usage

Open the project in the Godot editor and run the main scene.

## Testing

Tests use [GUT](https://gut.readthedocs.io/) and live in `tests/`, prefixed with `test_`.

```bash
# Run all tests (headless)
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit

# Run a single test file
godot --headless -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gtest=res://tests/unit/test_example.gd -gexit
```

## Project Structure

```
src/
├── planet/       # Top-level planet scene and orchestration
├── sphere/       # Sphere tessellation (Delaunay/Voronoi mesh generation)
├── tectonics/    # Tectonic plate simulation and boundaries
├── climate/      # Wind, moisture, biome classification
└── common/       # Shared math and mesh utilities

shaders/          # Shared shaders
resources/        # Shared materials, noise configs (.tres)
autoloads/        # Singletons registered in Project Settings
tests/            # Unit and integration tests
```
