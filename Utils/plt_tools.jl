module PltTools

include("load_data.jl")

using DelimitedFiles
using Plots
using Printf

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
        dats, labs = LoadData.load_avgs(patterns, parent_dir; option = option)
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
        dats, labs = LoadData.load_avgs(patterns, parent_dir; option = option)
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
