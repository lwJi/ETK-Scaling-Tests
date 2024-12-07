module Misc

using DelimitedFiles

#############
# load data #
#############

function load_data(
    dirs::Vector{Tuple{String,String}},
    parent_dir::String;
    pattern::Regex = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
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

function calc_avgs(dats, range)
    avgs = []
    for i in 1:length(dats)
        x = dats[i][2][range]  # time
        y = dats[i][3][range]  # value
        push!(avgs, (3600 * 24) * ((x[end] - x[1]) / (y[end] - y[1])))  # M/day
        #push!(avgs, mean(y))  # ZCs/sec
    end
    return avgs
end

function load_speed_avgs(
    dir_patterns::Vector{Tuple{Regex,String}},
    parent_dir::String;
    range=:,
    fname::String = "stdout.txt",
)
    # Preallocate the dats container
    avgs = Vector{Vector{Vector{Float64}}}()
    labs = [label for (_, label) in dir_patterns]      # Extract labels

    for (dir_pattern, _) in dir_patterns
        # Find matching directories using the regex pattern
        dirs = Vector{Tuple{String,String}}()
        xaxi = Vector{Float64}()
        for dir in readdir(parent_dir; join=false)
            if (m = match(dir_pattern, dir)) !== nothing
                label = match(r"N(\d+)", dir).captures[1]  # Extract label from the dirname
                push!(dirs, (joinpath(dir, fname), "N$label"))
                push!(xaxi, parse(Float64, label))
            end
        end

        (dats_tmp, labs_tmp) = load_data(dirs, parent_dir)

        push!(avgs, [xaxi, calc_avgs(dats_tmp, range)])
    end
    
    return (avgs, labs)
end

end
