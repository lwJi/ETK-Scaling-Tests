module PltTools

include("load_data.jl")

using DelimitedFiles
using Statistics
using Plots
using Printf

###################################
# Tool functions for loading data #
###################################

# Function to load values based on options
#   dir_patterns: [
#                   (r"Z4c_L7_G256-N\d+-MPI\d+_r0000", "G256"),
#                   (r"Z4c_L7_G128-N\d+-MPI\d+_r0000", "G128"),
#                   ...,
#                 ]
#   fname:        "stdout.txt"
#   return:       (
#                   [
#                     (                                                        --
#                       [                                                        |
#                         [[x1,x2,x3...], [y1,y2,y3...], [z1,z2,z3,...], ...],   |
#                         [[ ...       ], [ ...       ], [ ...        ], ...],   |
#                       ],                                                       |--> returned by load_data()
#                       [                                                        |
#                         "N2",                                                  |
#                         "N4",                                                  |
#                       ]                                                        |
#                     ),                                                       --
#                     (),
#                     ...,
#                   ],
#                   [
#                     "G256",
#                     "G128",
#                     ...,
#                   ]
#                 )
function load_values(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    option::String = "TotalComputeTime",
    fname::String = "stdout.txt",
)::Tuple{Vector{Any},Vector{String}}
    # Validate inputs
    @assert isdir(parent_dir) "Provided `parent_dir` is not a valid directory."
    @assert !isempty(dir_patterns) "Provided `dir_patterns` cannot be empty."

    # Preallocate the dats container
    vals = Vector{Any}()
    labs = Vector{String}()

    # Process each directory pattern
    for (dir_pattern, label) in dir_patterns
        # Extract matched directories
        _, matched_dirs = LoadData.get_matched_dirs(parent_dir, dir_pattern, fname)

        # Load data for matched directories
        data = LoadData.load_data(matched_dirs, parent_dir, option)

        # Save the vals and the label
        push!(vals, data)
        push!(labs, label)
    end

    return (vals, labs)
end

# Function to load averages based on options
#   dir_patterns: [
#                   (r"Z4c_L7_G256-N\d+-MPI\d+_r0000", "G256"),
#                   (r"Z4c_L7_G128-N\d+-MPI\d+_r0000", "G128"),
#                   ...,
#                 ]
#   fname:        "stdout.txt"
#   return:       (
#                   [
#                     [ [2, 4, 8, ...], [avg2, avg4, avg8, ...] ],
#                     [ [ ...        ], [ ...                 ] ],
#                     ...,
#                   ],
#                   ,
#                   [
#                     "G256",
#                     "G128",
#                     ...,
#                   ]
#                 )
function load_avgs(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    range = :,
    option::String = "TotalComputeTime",
    fname::String = "stdout.txt",
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Validate inputs
    @assert isdir(parent_dir) "Provided `parent_dir` is not a valid directory."
    @assert !isempty(dir_patterns) "Provided `dir_patterns` cannot be empty."

    # Preallocate the dats container
    avgs = Vector{Vector{Vector{Float64}}}()
    labs = Vector{String}()

    # Process each directory pattern
    for (dir_pattern, label) in dir_patterns
        # Extract matched directories and their associated x_values
        x_values, matched_dirs = LoadData.get_matched_dirs(parent_dir, dir_pattern, fname)

        # Load data for the matched directories
        dats, _ = LoadData.load_data(matched_dirs, parent_dir, option)

        # Save the avgs and the label
        push!(avgs, [x_values, calc_avgs(dats, range, option)])
        push!(labs, label)
    end

    return (avgs, labs)
end

# Function to calculate averages for a given dataset
#   dats:   [                                                      --
#             [[x1,x2,x3...], [y1,y2,y3...], [z1,z2,z3,...], ...],   |
#             [[ ...       ], [ ...       ], [ ...        ], ...],   |--> first slot of load_data()'s return
#             ...,                                                   |
#           ],                                                     --
#   return: [
#             avg1,
#             avg2,
#             ...,
#           ]
function calc_avgs(
    dats::Vector{Vector{Vector{Float64}}},
    range,
    option::String,
)::Vector{Float64}
    # Constants for conversions
    seconds_per_day = 3600 * 24

    # Define calculations for each option using a dictionary
    option_calculations = Dict(
        "TotalComputeTime" =>
            (_, t, _, v) -> seconds_per_day * ((t[end] - t[1]) / (v[end] - v[1])),
        "ZcsPerSecond" => (_, _, _, v) -> mean(v),
        "ZcsPerSecond2" => (_, t, c, _) -> sum(c[2:end]) / (t[end] - t[1]),
    )

    # Validate the option and retrieve the corresponding calculation function
    calc_fn = get(option_calculations, option) do
        error(
            "Invalid option: '$option'. Valid options are: $(join(keys(option_calculations), ", ")).",
        )
    end

    # Preallocate results
    avgs = Vector{Float64}(undef, length(dats))

    # Process each dataset
    for (i, dat) in enumerate(dats)
        # Ensure the dataset has enough data
        @assert length(dat) >= 3 "Dataset at index $i does not contain enough data (expected at least 3 entries)."

        # Extract time and value data for the given range
        steps = dat[1][range]
        times = dat[2][range]
        cells = dat[3][range]
        values = dat[4][range]

        # Perform the calculation and store the result
        avgs[i] = calc_fn(steps, times, cells, values)
    end

    return avgs
end

##################
# Plot functions #
##################

# Plot scaling result
function plot_scaling(
    plt::Plots.Plot,
    patt_dirss::Vector{Tuple{Vector{Tuple{Regex,String}},String,Symbol}};
    option::String = "TotalComputeTime",
    is_print_value::Bool = false,
    is_plot_ideal::Bool = false,
)::Nothing
    @assert !isempty(patt_dirss) "The `patt_dirss` input cannot be empty."

    # Process datasets
    for (patterns, parent_dir, mark) in patt_dirss
        @assert isdir(parent_dir) "Invalid directory: $parent_dir"

        # Load averages for the given patterns and directory
        dats, labs = load_avgs(patterns, parent_dir; option = option)
        @assert !isempty(dats) "No data found for directory: $parent_dir"

        # Iterate through the loaded datasets
        for (i, dat) in enumerate(dats)
            plot!(plt, dat[1], dat[2], label = labs[i], marker = mark)
            if is_print_value
                @printf("  %8s: [", labs[i])
                println(join([@sprintf(" %8.2e", d) for d in dat[2]], ","), "]")
            end
        end

        ## Add the "ideal" reference plot
        if (is_plot_ideal)
            x_ref, y_ref = dats[end]  # choose the last dataset as the reference
            ideal_y = y_ref[1] .* (x_ref ./ x_ref[1])  # compute the ideal scaling line
            plot!(plt, x_ref, ideal_y; label = "Ideal", linestyle = :dash, color = :red)
        end
    end
end

# Plot efficiency
function plot_efficiency(
    plt::Plots.Plot,
    patt_dirss::Vector{Tuple{Vector{Tuple{Regex,String}},String,Symbol}};
    option::String = "ZcsPerSecond",
    is_print_value::Bool = false,
    is_plot_ideal::Bool = false,
)::Nothing
    @assert !isempty(patt_dirss) "The `patt_dirss` input cannot be empty."

    # Process datasets
    for (patterns, parent_dir, mark) in patt_dirss
        @assert isdir(parent_dir) "Invalid directory: $parent_dir"

        # Load averages for the given patterns and directory
        dats, labs = load_avgs(patterns, parent_dir; option = option)
        @assert !isempty(dats) "No data found for directory: $parent_dir"

        # Iterate through the loaded datasets
        for (i, dat) in enumerate(dats)
            value_per_node = dat[2] ./ dat[1]  # Zcs/sec/node
            efficiency = value_per_node ./ first(value_per_node)
            plot!(plt, dat[1], efficiency, label = labs[i], marker = mark)
            if is_print_value
                @printf("  %8s: [", labs[i])
                println(join([@sprintf(" %8.2e", eff) for eff in efficiency], ","), "]")
            end
        end

        ## Add the "ideal" reference plot
        if (is_plot_ideal)
            x_ref, y_ref = dats[end]  # choose the last dataset as the reference
            ideal_y = fill(1.0, length(x_ref))
            plot!(plt, x_ref, ideal_y; label = "Ideal", linestyle = :dash, color = :red)
        end
    end
end

end
