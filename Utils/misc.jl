module Misc

using DelimitedFiles
using Plots

#############
# load data #
#############

function load_data(
    fnames::Vector{String},
    dir::String,
    pattern::Regex,
)::Vector{Vector{Vector{Float64}}}
    # Precompile regex patterns for better performance
    time_pattern = r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    step_pattern = r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    # Preallocate the results container
    results = Vector{Vector{Vector{Float64}}}(undef, length(fnames))

    for (i, fname) in enumerate(fnames)
        file_path = joinpath(dir, fname)

        # Attempt to read the file
        lines = try
            readlines(file_path)
        catch e
            println("Error reading file $file_path: $e")
            continue
        end

        # Initialize containers for matched data
        steps = Float64[]
        times = Float64[]
        custom_matches = Float64[]

        # Process each line in the file
        for line in lines
            # Match and parse simulation time
            if m_time = match(time_pattern, line)
                push!(times, parse(Float64, m_time.captures[1]))
            end
            # Match and parse total iterations
            if m_step = match(step_pattern, line)
                push!(steps, parse(Float64, m_step.captures[1]))
            end
            # Match and parse custom pattern
            if m_custom = match(pattern, line)
                push!(custom_matches, parse(Float64, m_custom.captures[1]))
            end
        end

        # Ensure arrays are synchronized to the minimum length
        min_len = minimum([length(steps), length(times), length(custom_matches)])
        if min_len > 0
            results[i] = [steps[1:min_len], times[1:min_len], custom_matches[1:min_len]]
        else
            println("Warning: No valid data found in file $fname.")
            results[i] = [Float64[], Float64[], Float64[]]
        end
    end

    # Filter out empty entries and return the results
    return filter!(!isempty, results)
end

end
