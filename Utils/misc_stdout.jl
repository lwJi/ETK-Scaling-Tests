"""
    MiscStdout

Module for parsing Einstein Toolkit simulation stdout files to extract performance metrics.

Provides functions to load and analyze simulation output, including compute times,
grid cell update rates, and other metrics from CarpetX stdout logs.
"""
module MiscStdout

using DelimitedFiles
using Statistics

#############################
# Basic Loading Functions   #
#############################

"""
    load_data(dirs, parent_dir, option) -> (dats, labs)

Load raw performance data from simulation stdout files.

# Arguments
- `dirs::Vector{Tuple{String,String}}`: List of (subdir_path, label) tuples
- `parent_dir::String`: Parent directory containing the subdirectories
- `option::String`: Metric to extract. Valid options:
  - `"TotalComputeTime"`: Total evolution compute time
  - `"ZcsPerSecond"`: Grid cell updates per second (from stdout)
  - `"ZcsPerSecond2"`: Grid cell updates per second (recalculated)

# Returns
- `dats`: Vector of datasets, each containing [steps, times, cells, custom_metric]
- `labs`: Vector of labels corresponding to each dataset

# Example
```julia
dirs = [
    ("Z4c_L7_G128-N2-MPI16_r0000/stdout.txt", "N2"),
    ("Z4c_L7_G128-N4-MPI32_r0000/stdout.txt", "N4"),
]
dats, labs = load_data(dirs, "/path/to/data", "TotalComputeTime")
```
"""
function load_data(
    dirs::Vector{Tuple{String,String}},
    parent_dir::String,
    option::String,
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Regex patterns for extracting the requested metric from stdout
    patterns = Dict(
        "TotalComputeTime" =>
            r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
        "ZcsPerSecond2" =>  # Recalculated from total evolution compute time
            r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
        "ZcsPerSecond" =>
            r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
    )

    pattern = get(patterns, option) do
        error("Invalid option: $option. Valid options are: $(keys(patterns))")
    end

    # CarpetX stdout patterns for standard metrics
    step_pattern =
        r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    time_pattern =
        r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    cell_pattern = r"\(CarpetX\): Grid cells:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]

    for (subdir, _) in dirs
        file_path = joinpath(parent_dir, subdir)

        steps = Float64[]
        times = Float64[]
        cells = Float64[]
        custom_matches = Float64[]

        lines = try
            readlines(file_path)
        catch e
            println("Error reading file $file_path: $e")
            continue
        end

        # Parse each line, extracting values that match our patterns
        for line in lines
            if (m_step = match(step_pattern, line)) !== nothing
                push!(steps, parse(Float64, m_step.captures[1]))
            end
            if (m_time = match(time_pattern, line)) !== nothing
                push!(times, parse(Float64, m_time.captures[1]))
            end
            if (m_cell = match(cell_pattern, line)) !== nothing
                push!(cells, parse(Float64, m_cell.captures[1]))
            end
            if (m_custom = match(pattern, line)) !== nothing
                push!(custom_matches, parse(Float64, m_custom.captures[1]))
            end
        end

        # Truncate arrays to common length (data points may not be perfectly aligned)
        min_len =
            minimum([length(steps), length(times), length(cells), length(custom_matches)])
        if min_len > 0
            push!(
                dats,
                [
                    steps[1:min_len],
                    times[1:min_len],
                    cells[1:min_len],
                    custom_matches[1:min_len],
                ],
            )
        else
            println("Warning: No valid data found in file $file_path.")
            push!(dats, [Float64[], Float64[], Float64[], Float64[]])
        end
    end

    return (dats, labs)
end

"""
    get_matched_dirs(parent_dir, dir_pattern, fname) -> (x_values, matched_dirs)

Find simulation directories matching a pattern and extract node counts.

Scans `parent_dir` for directories matching `dir_pattern`, extracts the node count
from the "N{number}" portion of the directory name, and returns sorted results.

# Arguments
- `parent_dir::String`: Directory to search
- `dir_pattern::Regex`: Pattern to match directory names (e.g., `r"Z4c_L7_G256-N\\d+-MPI\\d+_r0000"`)
- `fname::String`: Filename to append to matched directories (e.g., "stdout.txt")

# Returns
- `x_values`: Sorted vector of node counts extracted from directory names
- `matched_dirs`: Vector of (path, label) tuples, sorted by node count

# Example
```julia
x_vals, dirs = get_matched_dirs("/data", r"Z4c_L7_G256-N\\d+-MPI\\d+_r0000", "stdout.txt")
# x_vals = [2.0, 4.0, 8.0]
# dirs = [("Z4c_L7_G256-N2-MPI16_r0000/stdout.txt", "N2"), ...]
```
"""
function get_matched_dirs(
    parent_dir::String,
    dir_pattern::Regex,
    fname::String,
)::Tuple{Vector{Float64},Vector{Tuple{String,String}}}
    @assert isdir(parent_dir) "Provided `parent_dir` is not a valid directory."

    matched_dirs = Vector{Tuple{String,String}}()
    x_values = Vector{Float64}()
    n_value_regex = r"N(\d+)"

    for dir in readdir(parent_dir; join = false)
        if (match(dir_pattern, dir)) !== nothing
            n_match = match(n_value_regex, dir)
            @assert n_match !== nothing "Directory name must include an 'N' followed by a number"

            n_value = parse(Float64, n_match.captures[1])
            dir_path = joinpath(dir, fname)
            label = "N$(Int(n_value))"

            push!(matched_dirs, (dir_path, label))
            push!(x_values, n_value)
        end
    end

    sorted_indices = sortperm(x_values)
    return (x_values[sorted_indices], matched_dirs[sorted_indices])
end




############################
# Wrapper Functions        #
############################

"""
    load_values(dir_patterns, parent_dir; option, fname) -> (vals, labs)

Load raw data for multiple directory pattern groups.

Iterates over each pattern in `dir_patterns`, finds matching directories,
and loads raw data using `load_data()`.

# Arguments
- `dir_patterns::Vector{Tuple{Regex,String}}`: List of (pattern, label) tuples
- `parent_dir::String`: Parent directory to search
- `option::String`: Metric to extract (default: "TotalComputeTime")
- `fname::String`: Output filename to look for (default: "stdout.txt")

# Returns
- `vals`: Vector of `load_data()` results, one per pattern group
- `labs`: Vector of labels for each pattern group
"""
function load_values(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    option::String = "TotalComputeTime",
    fname::String = "stdout.txt",
)::Tuple{Vector{Any},Vector{String}}
    @assert isdir(parent_dir) "Provided `parent_dir` is not a valid directory."
    @assert !isempty(dir_patterns) "Provided `dir_patterns` cannot be empty."

    vals = Vector{Any}()
    labs = Vector{String}()

    for (dir_pattern, label) in dir_patterns
        _, matched_dirs = get_matched_dirs(parent_dir, dir_pattern, fname)
        data = load_data(matched_dirs, parent_dir, option)
        push!(vals, data)
        push!(labs, label)
    end

    return (vals, labs)
end

"""
    load_avgs(dir_patterns, parent_dir; range, option, fname) -> (avgs, labs)

Load averaged metrics for multiple directory pattern groups.

This is the primary function for scaling analysis. For each pattern group,
it finds matching directories, loads data, and computes averages.

# Arguments
- `dir_patterns::Vector{Tuple{Regex,String}}`: List of (pattern, label) tuples
- `parent_dir::String`: Parent directory to search
- `range`: Index range for averaging (default: `:` for all data)
- `option::String`: Metric to compute (default: "TotalComputeTime")
- `fname::String`: Output filename to look for (default: "stdout.txt")

# Returns
- `avgs`: Vector of [[node_counts...], [averages...]] for each pattern group
- `labs`: Vector of labels for each pattern group

# Example
```julia
patterns = [
    (r"Z4c_L7_G256-N\\d+-MPI\\d+_r0000", "G256"),
    (r"Z4c_L7_G128-N\\d+-MPI\\d+_r0000", "G128"),
]
avgs, labs = load_avgs(patterns, "/data"; option="ZcsPerSecond")
# avgs[1] = [[2, 4, 8], [1.2e9, 2.3e9, 4.1e9]]  # node counts and averages for G256
```
"""
function load_avgs(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    range = :,
    option::String = "TotalComputeTime",
    fname::String = "stdout.txt",
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    @assert isdir(parent_dir) "Provided `parent_dir` is not a valid directory."
    @assert !isempty(dir_patterns) "Provided `dir_patterns` cannot be empty."

    avgs = Vector{Vector{Vector{Float64}}}()
    labs = Vector{String}()

    for (dir_pattern, label) in dir_patterns
        x_values, matched_dirs = get_matched_dirs(parent_dir, dir_pattern, fname)
        dats, _ = load_data(matched_dirs, parent_dir, option)
        push!(avgs, [x_values, calc_avgs(dats, range, option)])
        push!(labs, label)
    end

    return (avgs, labs)
end


############################
# Internal Helper Functions #
############################

"""
    calc_avgs(dats, range, option) -> avgs

Compute average metrics from raw data based on the specified option.

# Arguments
- `dats`: Vector of datasets from `load_data()`, each containing [steps, times, cells, values]
- `range`: Index range to use for calculations (e.g., `:` for all, `2:end`)
- `option::String`: Calculation method:
  - `"TotalComputeTime"`: Days to simulate 1 time unit = 86400 * (t_end - t_start) / (compute_end - compute_start)
  - `"ZcsPerSecond2"`: Zone-cycles/sec = sum(cells) / total_compute_time
  - `"ZcsPerSecond"`: Mean of reported zone-cycles/sec values

# Returns
Vector of computed averages, one per dataset
"""
function calc_avgs(
    dats::Vector{Vector{Vector{Float64}}},
    range,
    option::String,
)::Vector{Float64}
    SECONDS_PER_DAY = 3600 * 24

    # Calculation formulas for each metric option
    option_calculations = Dict(
        "TotalComputeTime" =>
            (_, t, _, v) -> SECONDS_PER_DAY * ((t[end] - t[1]) / (v[end] - v[1])),
        "ZcsPerSecond2" => (_, _, c, v) -> sum(c[2:end]) / (v[end] - v[1]),
        "ZcsPerSecond" => (_, _, _, v) -> mean(v),
    )

    calc_fn = get(option_calculations, option) do
        error(
            "Invalid option: '$option'. Valid options are: $(join(keys(option_calculations), ", ")).",
        )
    end

    avgs = Vector{Float64}(undef, length(dats))

    for (i, dat) in enumerate(dats)
        @assert length(dat) >= 4 "Dataset at index $i does not contain enough columns (expected 4)."

        steps = dat[1][range]
        times = dat[2][range]
        cells = dat[3][range]
        values = dat[4][range]

        avgs[i] = calc_fn(steps, times, cells, values)
    end

    return avgs
end

end
