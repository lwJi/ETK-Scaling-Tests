module Misc

using DelimitedFiles
using Statistics
using Plots

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
            r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
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

# Return matched directories and extracted values
function get_matched_dirs(
    parent_dir::String,
    dir_pattern::Regex,
    fname::String,
)::Tuple{Vector{Float64},Vector{Tuple{String,String}}}
    matched_dirs = Vector{Tuple{String,String}}()
    x_values = Vector{Float64}()
    for dir in readdir(parent_dir; join = false)
        if (m = match(dir_pattern, dir)) !== nothing
            # Extract "N" value
            n_match = match(r"N(\d+)", dir)
            @assert n_match !== nothing "Directory name must include an 'N' followed by a number"
            n_value = parse(Float64, n_match.captures[1])

            # Store directory and associated label
            push!(matched_dirs, (joinpath(dir, fname), "N$n_value"))
            push!(x_values, n_value)
        end
    end
    return (x_values, matched_dirs)
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
        x_values, matched_dirs = get_matched_dirs(parent_dir, dir_pattern, fname)

        # Load data and compute averages if directories are found
        dats, _ = load_data(matched_dirs, parent_dir, option)
        avgs_tmp = [x_values, calc_avgs(dats, range, option)]

        # Sort by x_values and store the sorted averages
        sorted_indices = sortperm(avgs_tmp[1])
        sorted_avgs = [d[sorted_indices] for d in avgs_tmp]

        # Save the avgs and the label
        push!(avgs, sorted_avgs)
        push!(labs, label)
    end

    return (avgs, labs)
end

# Function to load averages based on options
function load_values(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    range = :,
    option::String = "TotalComputeTime",
    fname::String = "stdout.txt",
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Preallocate the dats container
    vals = Vector{Vector{Vector{Float64}}}()
    labs = Vector{String}()

    # Process each directory pattern
    for (dir_pattern, label) in dir_patterns
        # Containers for matched directories and extracted values
        x_values, matched_dirs = get_matched_dirs(parent_dir, dir_pattern, fname)

        # Load data and compute averages if directories are found
        dats, _ = load_data(matched_dirs, parent_dir, option)
        vals_tmp = [x_values, dats]

        # Sort by x_values and store the sorted averages
        sorted_indices = sortperm(vals_tmp[1])
        sorted_vals = [d[sorted_indices] for d in vals_tmp]

        # Save the vals and the label
        push!(vals, sorted_vals)
        push!(labs, label)
    end

    return (vals, labs)
end

# Plot scaling result
function plot_scaling(
    plt::Plots.Plot,
    patt_dirss::Vector{Tuple{Vector{Tuple{Regex,String}},String,Symbol}};
    option::String = "TotalComputeTime",
    is_print_value::Bool = true,
    is_plot_ideal::Bool = false,
)
    # Process datasets
    for (patterns, parent_dir, mark) in patt_dirss
        # Load averages for the given patterns and directory
        (dats, labs) = load_avgs(patterns, parent_dir; option = option)

        # Iterate through the loaded datasets
        for (i, dat) in enumerate(dats)
            plot!(plt, dat[1], dat[2], label = labs[i], marker = mark)
            if is_print_value
                println("$(labs[i]): ", dat[2])
            end
        end

        ## Add the "ideal" reference plot
        if (is_plot_ideal)
            x_ref, y_ref = dats[end]  # choose the last dataset as the reference
            ideal_y = y_ref[1] .* (x_ref ./ x_ref[1])  # compute the ideal scaling line
            plot!(plt, x_ref, ideal_y; label = "ideal", linestyle = :dash, color = :red)
        end
    end
end

end
