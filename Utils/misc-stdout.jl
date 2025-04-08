module MiscStdout

using DelimitedFiles
using Statistics

##########################
# Basic loading function #
##########################

# Load data from dirs
#   dirs:   [
#             ("Z4c_L7_G128-N2-MPI16_r0000", "N2"),
#             ("Z4c_L7_G128-N4-MPI32_r0000", "N4"),
#           ]
#   return: (
#             [
#               [[x1,x2,x3...], [y1,y2,y3...], [z1,z2,z3,...], ...],
#               [[ ...       ], [ ...       ], [ ...        ], ...],
#             ],
#             [
#               "N2",
#               "N4",
#             ]
#           )
function load_data(
    dirs::Vector{Tuple{String,String}},
    parent_dir::String,
    option::String,
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
    # Define patterns for specific options
    patterns = Dict(
        "TotalComputeTime" =>
            r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
        "ZcsPerSecond2" =>  # we recalculate ZcsPerSecond using total evolution compute time here
            r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
        "ZcsPerSecond" =>
            r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
    )

    # Get the appropriate pattern or throw an error for an invalid option
    pattern = get(patterns, option) do
        error("Invalid option: $option. Valid options are: $(keys(patterns))")
    end

    # Precompile regex patterns for better performance
    step_pattern =
        r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    time_pattern =
        r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    cell_pattern = r"\(CarpetX\): Grid cells:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    # Preallocate the dats container
    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]  # Extract labels

    for (subdir, _) in dirs
        file_path = joinpath(parent_dir, subdir)

        # Initialize containers for matched data
        steps = Float64[]
        times = Float64[]
        cells = Float64[]
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
            # Match and parse total iterations
            if (m_step = match(step_pattern, line)) !== nothing
                push!(steps, parse(Float64, m_step.captures[1]))
            end
            # Match and parse simulation time
            if (m_time = match(time_pattern, line)) !== nothing
                push!(times, parse(Float64, m_time.captures[1]))
            end
            # Match and parse total cells
            if (m_cell = match(cell_pattern, line)) !== nothing
                push!(cells, parse(Float64, m_cell.captures[1]))
            end
            # Match and parse custom pattern
            if (m_custom = match(pattern, line)) !== nothing
                push!(custom_matches, parse(Float64, m_custom.captures[1]))
            end
        end

        # Ensure arrays are synchronized to the minimum length
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

# Return matched directories and extracted values
#   dir_pattern: r"Z4c_L7_G256-N\d+-MPI\d+_r0000"
#   fname:       "stdout.txt"
#   return:      (
#                  [ 2, 4, 8, ...],
#                  [
#                    ("Z4c_L7_G256_N2_MPI16_r0000/stdout.txt", "N2"),
#                    ("Z4c_L7_G256_N4_MPI32_r0000/stdout.txt", "N4"),
#                    ("Z4c_L7_G256_N8_MPI64_r0000/stdout.txt", "N8"),
#                    ...,
#                  ],
#                )
function get_matched_dirs(
    parent_dir::String,
    dir_pattern::Regex,
    fname::String,
)::Tuple{Vector{Float64},Vector{Tuple{String,String}}}
    # Validate input directory
    @assert isdir(parent_dir) "Provided `parent_dir` is not a valid directory."

    # Prepare outputs
    matched_dirs = Vector{Tuple{String,String}}()
    x_values = Vector{Float64}()

    # Predefine regex for extracting "N" value
    n_value_regex = r"N(\d+)"

    # Iterate through directories in the parent directory
    for dir in readdir(parent_dir; join = false)
        if (match(dir_pattern, dir)) !== nothing
            # Extract "N" value
            n_match = match(n_value_regex, dir)
            @assert n_match !== nothing "Directory name must include an 'N' followed by a number"

            # Parse the extracted value
            n_value = parse(Float64, n_match.captures[1])

            # Construct the file path and label
            dir_path = joinpath(dir, fname)
            label = "N$n_value"

            # Store directory and associated label
            push!(matched_dirs, (dir_path, label))
            push!(x_values, n_value)
        end
    end

    # Sort by `x_values` and apply the same order to `matched_dirs`
    sorted_indices = sortperm(x_values)

    return (x_values[sorted_indices], matched_dirs[sorted_indices])
end




######################################
# Wrapper functions for loading data #
######################################

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
        _, matched_dirs = get_matched_dirs(parent_dir, dir_pattern, fname)

        # Load data for matched directories
        data = load_data(matched_dirs, parent_dir, option)

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
        x_values, matched_dirs = get_matched_dirs(parent_dir, dir_pattern, fname)

        # Load data for the matched directories
        dats, _ = load_data(matched_dirs, parent_dir, option)

        # Save the avgs and the label
        push!(avgs, [x_values, calc_avgs(dats, range, option)])
        push!(labs, label)
    end

    return (avgs, labs)
end




##################
# Tool functions #
##################

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
        "ZcsPerSecond2" => (_, _, c, v) -> sum(c[2:end]) / (v[end] - v[1]),
        "ZcsPerSecond" => (_, _, _, v) -> mean(v),
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

end
