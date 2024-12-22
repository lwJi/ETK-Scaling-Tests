module LoadData

using DelimitedFiles

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
    cell_pattern =
        r"\(CarpetX\): Grid cells:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    # Preallocate the dats container
    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]  # Extract labels

    for (subdir, _) in dirs
        file_path = joinpath(parent_dir, subdir)

        # Initialize containers for matched data
        steps = Float64[]
        times = Float64[]
        custom_matches = Float64[]
        cells = Float64[]

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
            # Match and parse total cells
            if (m_cell = match(cell_pattern, line)) !== nothing
                push!(cells, parse(Float64, m_cell.captures[1]))
            end
        end

        # Ensure arrays are synchronized to the minimum length
        min_len = minimum([length(steps), length(times), length(custom_matches), length(cells)])
        if min_len > 0
            push!(dats, [steps[1:min_len], times[1:min_len], custom_matches[1:min_len], cells[1:min_len]])
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

end
