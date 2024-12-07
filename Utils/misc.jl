module Misc

using DelimitedFiles
using Statistics

#############
# load data #
#############

function load_data(
    dirs::Vector{Tuple{String,String}},
    parent_dir::String,
    option::String,
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Define patterns for specific options
    patterns = Dict(
        "TotalComputeTime" =>
            r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
        "ZcsPerSecond" =>
            r"average cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
    )

    # Get the appropriate pattern or throw an error for an invalid option
    pattern = get(patterns, option) do
        error("Invalid option: $option. Valid options are: $(keys(patterns))")
    end

    # Precompile regex patterns for better performance
    time_pattern =
        r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    step_pattern =
        r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    # Preallocate the dats container
    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]      # Extract labels

    for (subdir, _) in dirs
        file_path = joinpath(parent_dir, subdir)

        # Initialize containers for matched data
        steps = Float64[]
        times = Float64[]
        custom_matches = Float64[]

        # Attempt to read the file
        lines = try
            readlines(file_path)
        catch e
            println("Error reading file $file_path: $e")
            continue
        end

        # Process each line in the file
        for line in lines
            # Match and parse simulation time
            if (m_time = match(time_pattern, line)) !== nothing
                push!(times, parse(Float64, m_time.captures[1]))
            end
            # Match and parse total iterations
            if (m_step = match(step_pattern, line)) !== nothing
                push!(steps, parse(Float64, m_step.captures[1]))
            end
            # Match and parse custom pattern
            if (m_custom = match(pattern, line)) !== nothing
                push!(custom_matches, parse(Float64, m_custom.captures[1]))
            end
        end

        # Ensure arrays are synchronized to the minimum length
        min_len = minimum([length(steps), length(times), length(custom_matches)])
        if min_len > 0
            push!(dats, [steps[1:min_len], times[1:min_len], custom_matches[1:min_len]])
        else
            println("Warning: No valid data found in file $file_path.")
            push!(dats, [Float64[], Float64[], Float64[]])
        end
    end

    return (dats, labs)
end

# Function to calculate averages for a given dataset
function calc_avgs(
    dats::Vector{Vector{Vector{Float64}}},
    range,
    option::String,
)::Vector{Float64}
    # Define constants for conversions
    secs_per_day = 3600 * 24

    # Define calculations for each option using a dictionary
    option_calculations = Dict(
        "TotalComputeTime" =>
            (x, y) -> secs_per_day * ((x[end] - x[1]) / (y[end] - y[1])),
        "ZcsPerSecond" => (_, y) -> mean(y),
    )

    # Check for valid option
    calc_fn = get(option_calculations, option) do
        error("Invalid option: $option. Valid options are: $(keys(option_calculations)).")
    end

    # Preallocate results
    avgs = Vector{Float64}(undef, length(dats))

    # Process each dataset
    for (i, dat) in enumerate(dats)
        # Extract time and value data for the given range
        x = dat[2][range]
        y = dat[3][range]

        # Perform the calculation
        avgs[i] = calc_fn(x, y)
    end

    return avgs
end

# Function to load averages based on options
function load_avgs(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    range = :,
    option::String = "TotalComputeTime",
    fname::String = "stdout.txt",
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Preallocate the dats container
    avgs = Vector{Vector{Vector{Float64}}}()
    labs = Vector{String}()

    # Process each directory pattern
    for (dir_pattern, label) in dir_patterns
        # Containers for matched directories and extracted values
        dirs = Vector{Tuple{String,String}}()
        xs = Vector{Float64}()

        for dir in readdir(parent_dir; join = false)
            if (m = match(dir_pattern, dir)) !== nothing
                label_value = parse(Float64, match(r"N(\d+)", dir).captures[1])
                push!(dirs, (joinpath(dir, fname), "N$label_value"))
                push!(xs, label_value)
            end
        end

        # Load data and compute averages if directories are found
        (dats, _) = load_data(dirs, parent_dir, option)
        push!(avgs, [xs, calc_avgs(dats, range, option)])
        push!(labs, label)
    end

    return (avgs, labs)
end

end
