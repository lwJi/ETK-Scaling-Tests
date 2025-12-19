# Repository Guidelines

## Project Structure & Module Organization

- `Utils/`: Julia modules and helper scripts (e.g., `misc_stdout.jl`, `plt_tools.jl`, `cp_files.sh`).
- `Meshes/`: Jupyter notebooks used to generate meshes and test setups.
- `frontier/` and `vista/`: Analysis notebooks plus large simulation outputs organized by machine/date.
- `README.md` and `CLAUDE.md`: Project overview and agent-specific notes.

Simulation runs are stored in nested data folders with naming patterns like
`Z4c_L{levels}_N{block}-MPI{procs}_r{run}` or `magTOV_Cow_UNI_N{nodes}_r{run}`.

## Build, Test, and Development Commands

There is no build system in this repository; work is driven by notebooks and scripts.

- Copy a set of output files into a local folder:
  `./Utils/cp_files.sh /path/to/Z4c_L7_N128`
- Run analysis notebooks (Julia kernel required):
  `jupyter lab`

## Coding Style & Naming Conventions

- Julia code uses 4-space indentation and standard module/function naming
  (e.g., `load_data`, `plot_scaling`).
- Prefer explicit module names and short helper functions in `Utils/`.
- Keep new data directories aligned to existing naming patterns and include
  `stdout.txt`, `stderr.txt`, and `*.par` files when copying runs.

## Testing Guidelines

There is no automated test suite. Validate changes by:
- Running the relevant notebook and checking plots/summary tables.
- Spot-checking parsed metrics from `stdout.txt` against expected values.

## Commit & Pull Request Guidelines

- Commit messages are short, imperative, and descriptive (e.g., `Add ...`, `Fix ...`).
- Scope prefixes are occasionally used for data drops (e.g., `frontier: add data 2025Dec`).
- PRs should include a brief summary, the data/notebooks touched, and any
  plots or performance deltas that justify the change.

## Data & Notebook Tips

- Large data directories are common; avoid duplicating runs unless necessary.
- Keep notebook outputs readable and avoid committing huge cell outputs unless
  they support the analysis.
