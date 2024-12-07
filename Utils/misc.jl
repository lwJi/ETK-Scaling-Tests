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
)::Vector{Vector{Vector{Float64}}}
    # Precompile regex patterns for better performance
    time_pattern = r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    step_pattern = r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"

    # Preallocate the dats container
    dats = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dirs]      # Extract labels

    for (subdir, _) in dirs
        fname = joinpath(parent_dir, subdir)

        # Initialize containers for matched data
        steps = Float64[]
        times = Float64[]
        custom_matches = Float64[]

        # Process each line in the file
        for line in readlines(fname)
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
        push!(dats, [steps[1:min_len], times[1:min_len], custom_matches[1:min_len]])
    end

    return (dats, labs)
end

end
