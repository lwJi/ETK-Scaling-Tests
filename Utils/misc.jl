module Misc

using DelimitedFiles
using Plots

# load
function load_data(fnames, dir, pattern)
    dats = []
    for fname in fnames
        data = readlines(joinpath(dir, fname))
        matches_step = []
        matches_time = []
        matches_patt = []
        for row in data
            m_time = match(r"\(CarpetX\): Simulation time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)", row)
            m_step = match(r"\(CarpetX\):   total iterations:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)", row)
            m_patt = match(pattern, row)
            if m_time !== nothing
                push!(matches_time, parse(Float64, m_time.captures[1]))
            end
            if m_step !== nothing
                push!(matches_step, parse(Int64, m_step.captures[1]))
            end
            if m_patt !== nothing
                push!(matches_patt, parse(Float64, m_patt.captures[1]))
            end
        end
        len = minimum([length(matches_step), length(matches_time), length(matches_patt)])
        push!(dats, [matches_step[1:len], matches_time[1:len], matches_patt[1:len]])
    end
    return dats
end

function load_data_manual(fnames, dir)
    dats = []
    for fname in fnames
        data = readdlm(joinpath(dir, fname), Float64, comments=true)
        nodes = data[:, 1]
        cycle = data[:, 2]
        speed = data[:, 3]
        push!(dats, [nodes, cycle, speed])
    end
    return dats
end

# plot
function plot_speed(plt, nodes, dir; prefix="N", range=:,
    pattern=r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)")
    #pattern=r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    files = [prefix * string(i) * "/stdout.txt" for i in nodes]
    datas = load_data(files, dir, pattern)
    for i in 1:length(datas)
        label_i = prefix * string(nodes[i])
        x = datas[i][1][range]  # steps
        y = datas[i][3][range]  # value
        plt = plot!(x, y, seriestype=:line, marker=:circle, label=label_i)
    end
end

function calc_avgs(datas, range)
    avgs = []
    for i in 1:length(datas)
        x = datas[i][2][range]  # time
        y = datas[i][3][range]  # value
        push!(avgs, (3600 * 24) * ((x[end] - x[1]) / (y[end] - y[1])))  # M/day
        #push!(avgs, mean(y))  # ZCs/sec
    end
    return avgs
end

function plot_scaling(plt, nodes, dirss; prefix="N", range=:, with_ideal=false, verbose=false,
    pattern=r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)")
    #pattern=r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    files = [prefix * string(i) * "/stdout.txt" for i in nodes]
    for dirs in dirss
        dir, lab = dirs
        datas = load_data(files, dir, pattern)
        avgs = calc_avgs(datas, range)
        if verbose
            println(avgs)
        end
        plt = plot!(nodes, avgs, seriestype=:line, marker=:circle, label=lab)
        if with_ideal
            avgsI = [avgs[1] / nodes[1] * n for n in nodes]
            plt = plot!(nodes, avgsI, seriestype=:line, marker=:circle, label="")
        end
    end
end

function plot_efficiency(plt, nodes, dirss; prefix="N", range=:, with_ideal=false,
    pattern=r"total evolution compute time:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)")
    #pattern=r"Grid cell updates per second:\s+([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)"
    files = [prefix * string(i) * "/stdout.txt" for i in nodes]
    for dirs in dirss
        dir, lab = dirs
        datas = load_data(files, dir, pattern)
        avgs = calc_avgs(datas, range)
        avgsI = [avgs[1] / nodes[1] * n for n in nodes]
        avgsE = [avgs[i] / avgsI[i] for i in 1:length(nodes)]
        plt = plot!(nodes, avgsE, seriestype=:line, marker=:circle, label=lab)
        if with_ideal
            plt = plot!(nodes, [1.0 for n in nodes], seriestype=:line, marker=:circle, label="")
        end
    end
end

end