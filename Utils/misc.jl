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

    # Preallocate results container
    dats = Vector{Vector{Vector{Float64}}}(undef, length(fnames))

    for (i, fname) in enumerate(fnames)
        file_path = joinpath(dir, fname)
        
        # Read the file
        data = try
            readlines(file_path)
        catch e
            println("Error reading file $file_path: $e")
            continue
        end
        
        # Initialize match containers
        matches_step, matches_time, matches_patt = Float64[], Float64[], Float64[]
        
        # Process each line in the file
        for row in data
            if m_time = match(time_pattern, row)
                push!(matches_time, parse(Float64, m_time.captures[1]))
            end
            if m_step = match(step_pattern, row)
                push!(matches_step, parse(Float64, m_step.captures[1]))
            end
            if m_patt = match(pattern, row)
                push!(matches_patt, parse(Float64, m_patt.captures[1]))
            end
        end
        
        # Synchronize lengths to the minimum of all matched arrays
        len = minimum([length(matches_step), length(matches_time), length(matches_patt)])
        
        if len > 0
            dats[i] = [matches_step[1:len], matches_time[1:len], matches_patt[1:len]]
        else
            println("Warning: No matching data found in file $fname.")
            dats[i] = [Float64[], Float64[], Float64[]]
        end
    end

    # Remove any unprocessed or empty entries
    return filter!(!isempty, dats)
end

function load_data_manually(
    fnames::Vector{String},
    dir::String,
)::Vector{Dict{String,Vector{Float64}}}
    dats = Vector{Dict{String,Vector{Float64}}}(undef, length(fnames))

    for (i, fname) in enumerate(fnames)
        file_path = joinpath(dir, fname)

        # Safely read data and handle errors
        try
            data = readdlm(file_path, Float64, comments = true)

            if size(data, 2) < 3
                throw(
                    ArgumentError(
                        "File $fname does not have the required number of columns.",
                    ),
                )
            end

            nodes = data[:, 1]
            cycle = data[:, 2]
            speed = data[:, 3]

            dats[i] = Dict("nodes" => nodes, "cycle" => cycle, "speed" => speed)
        catch e
            println("Error reading file $file_path: $e")
            dats[i] = Dict("nodes" => Float64[], "cycle" => Float64[], "speed" => Float64[])
        end
    end

    return dats
end

########
# plot #
########

function plot_speed(
    plt::Plots.Plot,
    nodes::Vector{Int},
    dir::String;
    prefix::String = "N",
    range::Union{Symbol, UnitRange{Int}} = :,
    pattern::Regex = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
    #pattern::Regex=r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
)::Plots.Plot
    # Generate file paths based on nodes and prefix
    files = [joinpath(prefix * string(node), "stdout.txt") for node in nodes]

    # Load data using the provided pattern
    datas = load_data(files, dir, pattern)

    # Check if datas is non-empty and iterate
    for (i, data) in enumerate(datas)
        if length(data) < 3 || isempty(data[1]) || isempty(data[3])
            println("Skipping node $nodes[i]: Data is incomplete.")
            continue
        end
        
        # Extract steps and values, applying the specified range
        steps = data[1][range]
        values = data[3][range]
        
        # Generate label for the current node
        label = prefix * string(nodes[i])
        
        # Plot the data
        plt = plot!(steps, values, seriestype=:line, marker=:circle, label=label)
    end

    return plt
end

function calc_avgs(datas, range)
    avgs = []
    for i = 1:length(datas)
        x = datas[i][2][range]  # time
        y = datas[i][3][range]  # value
        push!(avgs, (3600 * 24) * ((x[end] - x[1]) / (y[end] - y[1])))  # M/day
        #push!(avgs, mean(y))  # ZCs/sec
    end
    return avgs
end

function plot_scaling(
    plt,
    nodes,
    dirss;
    prefix = "N",
    range = :,
    with_ideal = false,
    verbose = false,
    pattern = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
)
    #pattern=r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    files = [prefix * string(i) * "/stdout.txt" for i in nodes]
    for dirs in dirss
        dir, lab = dirs
        datas = load_data(files, dir, pattern)
        avgs = calc_avgs(datas, range)
        if verbose
            println(avgs)
        end
        plt = plot!(nodes, avgs, seriestype = :line, marker = :circle, label = lab)
        if with_ideal
            avgsI = [avgs[1] / nodes[1] * n for n in nodes]
            plt = plot!(nodes, avgsI, seriestype = :line, marker = :circle, label = "")
        end
    end
end

function plot_efficiency(
    plt,
    nodes,
    dirss;
    prefix = "N",
    range = :,
    with_ideal = false,
    pattern = r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)",
)
    #pattern=r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    files = [prefix * string(i) * "/stdout.txt" for i in nodes]
    for dirs in dirss
        dir, lab = dirs
        datas = load_data(files, dir, pattern)
        avgs = calc_avgs(datas, range)
        avgsI = [avgs[1] / nodes[1] * n for n in nodes]
        avgsE = [avgs[i] / avgsI[i] for i = 1:length(nodes)]
        plt = plot!(nodes, avgsE, seriestype = :line, marker = :circle, label = lab)
        if with_ideal
            plt = plot!(
                nodes,
                [1.0 for n in nodes],
                seriestype = :line,
                marker = :circle,
                label = "",
            )
        end
    end
end

end
