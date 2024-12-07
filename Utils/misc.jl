module Misc

using DelimitedFiles
using Plots

#############
# load data #
#############

function load_data(
    dirs::Vector{Tuple{String,String}},
    parent_dir::String,
    pattern::Regex,
)::Tuple{Vector{Vector{Vector{Float64}}},Vector{String}}
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

end
