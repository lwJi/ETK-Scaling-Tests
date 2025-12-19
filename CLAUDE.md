# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ETK-Scaling-Tests is a scientific computing repository for analyzing scaling performance of Einstein Toolkit (ETK) relativistic astrophysical simulations on supercomputers (primarily Frontier, Vista). The project benchmarks GRMHD (General Relativistic Magnetohydrodynamics) simulations across different configurations to measure computational efficiency.

## Technology Stack

- **Analysis**: Julia with Jupyter notebooks (Plots.jl, LaTeXStrings.jl)
- **Simulation Framework**: Einstein Toolkit (CarpetX, Z4c, Z4cowGPU, AsterX)
- **Test Scenarios**: magTOV (magnetized neutron star), singleBH (single black hole), BBHCloud (binary black hole in Cloud)

## Key Commands

Copy simulation output files (parameter files and stdout/stderr) from run directories matching a prefix:
```bash
./Utils/cp_files.sh <directory_prefix>
# Example: ./Utils/cp_files.sh /path/to/Z4c_L3_N128
# Copies from all directories matching /path/to/Z4c_L3_N128*/
```

Run Jupyter notebooks with Julia kernel for analysis.

## Code Architecture

### Utils/ - Julia Modules

**misc_stdout.jl** (`MiscStdout` module): Parses simulation stdout files to extract metrics.
- `load_avgs(dir_patterns, parent_dir; option, fname)` - Main function for loading averaged metrics
- `load_data(dirs, parent_dir, option)` - Raw data loading from stdout files
- `get_matched_dirs(parent_dir, dir_pattern, fname)` - Find simulation directories matching a pattern
- Options: `"TotalComputeTime"`, `"ZcsPerSecond"`, `"ZcsPerSecond2"`

**plt_tools.jl** (`PltTools` module): Plotting utilities for scaling analysis.
- `plot_scaling()` - Plot scaling curves
- `plot_efficiency()` - Plot efficiency (Zcs/sec/node normalized)

### Data Organization

Simulation runs are organized by naming convention:
```
Z4c_L{levels}_N{block_size}-MPI{procs}_r{run_number}
magTOV_Cow_UNI_N{nodes}_r{run_number}
```

Each run directory contains:
- `*.par` - ETK parameter file
- `stdout.txt` / `stderr.txt` - Simulation output logs

### Analysis Workflow

1. Parse simulation stdout using regex patterns in `MiscStdout`
2. Extract key metrics: "Grid cell updates per second", "total evolution compute time", grid cells, iterations
3. Calculate averages and generate scaling/efficiency plots

### Notebooks Pattern

Notebooks in `frontier/2025May/ipynb/` follow this structure:
```julia
include("../../../Utils/misc_stdout.jl")
patt_dirss = [([(regex_pattern, label), ...], parent_dir, marker), ...]
dats, labs = MiscStdout.load_avgs(patterns, parent_dir; option="ZcsPerSecond")
```