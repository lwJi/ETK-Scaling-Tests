"""
    PltTools

Plotting utilities for Einstein Toolkit scaling analysis.

Provides functions to visualize scaling performance and parallel efficiency
of ETK simulations across different node configurations.
"""
module PltTools

include("load_data.jl")

using DelimitedFiles
using Plots
using Printf

######################
# Plotting Functions #
######################

"""
    plot_scaling(plt, patt_dirss; option, is_print_value, is_plot_ideal)

Plot scaling curves showing performance vs node count.

Adds scaling curves to an existing plot for each pattern group. Y-axis values
depend on the `option` parameter (e.g., zone-cycles/sec, compute time).

# Arguments
- `plt::Plots.Plot`: Existing plot object to add curves to
- `patt_dirss::Vector{Tuple{...}}`: Vector of (patterns, parent_dir, marker) tuples
  - `patterns`: Vector of (regex, label) for directory matching
  - `parent_dir`: Directory containing simulation outputs
  - `marker`: Plot marker symbol (e.g., `:circle`, `:square`)
- `option::String`: Metric to plot (default: "TotalComputeTime")
- `is_print_value::Bool`: Print values to stdout (default: false)
- `is_plot_ideal::Bool`: Add ideal linear scaling reference line (default: false)

# Example
```julia
plt = plot(xlabel="Nodes", ylabel="Zcs/sec", xscale=:log2, yscale=:log10)
patt_dirss = [
    ([(r"Z4c_.*-N\\d+.*", "Z4c")], "/data/runs", :circle),
]
plot_scaling(plt, patt_dirss; option="ZcsPerSecond", is_plot_ideal=true)
```
"""
function plot_scaling(
    plt::Plots.Plot,
    patt_dirss::Vector{Tuple{Vector{Tuple{Regex,String}},String,Symbol}};
    option::String = "TotalComputeTime",
    is_print_value::Bool = false,
    is_plot_ideal::Bool = false,
)::Nothing
    @assert !isempty(patt_dirss) "The `patt_dirss` input cannot be empty."

    for (patterns, parent_dir, mark) in patt_dirss
        @assert isdir(parent_dir) "Invalid directory: $parent_dir"

        dats, labs = LoadData.load_avgs(patterns, parent_dir; option = option)
        @assert !isempty(dats) "No data found for directory: $parent_dir"

        for (i, dat) in enumerate(dats)
            plot!(plt, dat[1], dat[2], label = labs[i], marker = mark)
            if is_print_value
                @printf("  %8s: [", labs[i])
                println(join([@sprintf(" %8.2e", d) for d in dat[2]], ","), "]")
            end
        end

        if is_plot_ideal
            x_ref, y_ref = dats[end]
            ideal_y = y_ref[1] .* (x_ref ./ x_ref[1])  # Linear scaling: y ∝ x
            plot!(plt, x_ref, ideal_y; label = "Ideal", linestyle = :dash, color = :red)
        end
    end
end

"""
    plot_efficiency(plt, patt_dirss; option, is_print_value, is_plot_ideal)

Plot parallel efficiency (normalized performance per node) vs node count.

Efficiency is computed as (Zcs/sec/node) normalized to the smallest node count,
so ideal scaling yields efficiency = 1.0 at all node counts.

# Arguments
- `plt::Plots.Plot`: Existing plot object to add curves to
- `patt_dirss::Vector{Tuple{...}}`: Vector of (patterns, parent_dir, marker) tuples
- `option::String`: Metric to use (default: "ZcsPerSecond")
- `is_print_value::Bool`: Print efficiency values to stdout (default: false)
- `is_plot_ideal::Bool`: Add ideal efficiency=1.0 reference line (default: false)

# Example
```julia
plt = plot(xlabel="Nodes", ylabel="Efficiency", xscale=:log2)
plot_efficiency(plt, patt_dirss; is_plot_ideal=true)
```
"""
function plot_efficiency(
    plt::Plots.Plot,
    patt_dirss::Vector{Tuple{Vector{Tuple{Regex,String}},String,Symbol}};
    option::String = "ZcsPerSecond",
    is_print_value::Bool = false,
    is_plot_ideal::Bool = false,
)::Nothing
    @assert !isempty(patt_dirss) "The `patt_dirss` input cannot be empty."

    for (patterns, parent_dir, mark) in patt_dirss
        @assert isdir(parent_dir) "Invalid directory: $parent_dir"

        dats, labs = LoadData.load_avgs(patterns, parent_dir; option = option)
        @assert !isempty(dats) "No data found for directory: $parent_dir"

        for (i, dat) in enumerate(dats)
            value_per_node = dat[2] ./ dat[1]
            efficiency = value_per_node ./ first(value_per_node)  # Normalize to first point
            plot!(plt, dat[1], efficiency, label = labs[i], marker = mark)
            if is_print_value
                @printf("  %8s: [", labs[i])
                println(join([@sprintf(" %8.2e", eff) for eff in efficiency], ","), "]")
            end
        end

        if is_plot_ideal
            x_ref, _ = dats[end]
            ideal_y = fill(1.0, length(x_ref))  # Perfect efficiency = 1.0
            plot!(plt, x_ref, ideal_y; label = "Ideal", linestyle = :dash, color = :red)
        end
    end
end

end
