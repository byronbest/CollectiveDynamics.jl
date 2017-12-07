### ============== ### ============== ### ============== ###
## Compute particles MSD
## with respect to center of mass
## Martin Zumaya Hernandez
## 11 / 07 / 2017
### ============== ### ============== ### ============== ###

using PyPlot, Polynomials, LaTeXStrings

### ================================== ###

function get_times(Ti, Tf)

    times = [convert(Int, exp10(i)) for i in Ti:Tf]
    tau = Int64[]

    push!(tau, 1)

    for i in 1:(length(times) - 1)

        for t in (times[i]+1):times[i+1]

            if t % times[i] == 0 || t % div(times[i], exp10(1)) == 0
                push!(tau, t)
                # println("//////// ", t)
            end
        end

    end

    return tau
end

### ================================== ###

N = 4096
N = 1024
N = 512
N = 256
N = 128
N = 100
N = 64

times = get_times(0,6)[2:end]
x_vals = broadcast(x -> log10(x), times)

#tflock
dt = 0.08
v0 = 0.1
x_vals = broadcast(x -> log10(x), dt .* times)

### ================================== ###

folder = "NLOC_DATA"
folder = "NLOC_DATA_3D"

folder = "NLOC_MET_3D"
folder = "NLOC_MET_2D"

folder = "new/NLOC_MET_3D_EXT"
folder = "NLOC_MET_2D"

folder = "NLOC_TOP_3D_EXT"
folder = "NLOC_TOP_3D"
folder = "NLOC_TOP_2D"
folder = "NLOC_TOP_3D_MEAN"

folder = "TFLOCK_NLOC_DATA"
folder = "TFLOCK_DATA"

folder = "SVM_GRID_FN_3D"

folder_path = "$(homedir())/art_DATA/$(folder)/EXP_N/exp_data_N_$(N)"
folder_path = "$(homedir())/art_DATA/$(folder)/EXP/exp_data_N_$(N)"
folder_path = "$(homedir())/art_DATA/$(folder)/EXP/exp_data_N_$(N)/eta_1.5"

folder_path = "$(homedir())/art_DATA/$(folder)/DATA/data_N_$(N)"

# eta_folders = readdir(folder_path)

### ================================== ###

order_files = filter( x -> ismatch(r"^order.", x), readdir(folder_path))
exp_files = filter( x -> ismatch(r"^exp.", x), readdir(folder_path))
nn_files = filter( x -> ismatch(r"^nn_mean.", x), readdir(folder_path))

means = zeros(length(times), length(order_files))
orders = zeros(length(times), length(order_files))
nn_means = zeros(length(times), length(order_files))

std_means = zeros(length(times), length(order_files))

### ================================== ###
# para VSK
capt = [match(r"_(\d+\.\d+)\.\w+$|_(\d+\.\d+e-5)\.\w+$", f).captures for f in order_files]
vals = [parse(Float64, vcat(capt...)[i]) for i in find(x -> x != nothing, vcat(capt...))]

# para NLOC
vals = [ parse(Float64, match(r"^\w+_(\d+\.\d+)", x).captures[1]) for x in order_files ]

# para TFLOCK
vals = [ parse(Float64, match(r"(\d\.\d+)\.\w+$", x).captures[1]) for x in order_files ]

### ================================== ###
# i = 3
for i in sortperm(vals)

    println(i)

    raw_data = reinterpret(Float64, read(folder_path * "/" * exp_files[i]))
    exp_data = reshape(raw_data, length(times), div(length(raw_data), length(times)))

    raw_data = reinterpret(Float64, read(folder_path * "/" * order_files[i]))
    order_data = reshape(raw_data, length(times), div(length(raw_data), length(times)))

    raw_data = reinterpret(Float64, read(folder_path * "/" * nn_files[i]))
    nn_data = reshape(raw_data, length(times), div(length(raw_data), length(times)))

    means[:, i] = mean(exp_data, 2)
    std_means[:, i] = std(exp_data, 2)
    orders[:, i] = mean(order_data, 2)
    nn_means[:, i] = mean(nn_data, 2)

end

### ================================== ###

d_means = zeros(length(times), length(order_files))
d_nn_means = zeros(length(times), length(order_files))

# # Tflock
# for i in sortperm(vals)
#     x0 = means[1, i] / (v0*dt)
#     d_means[:,i] = broadcast(x -> ((x / (v0*dt)) - x0)^2, means[:, i])
# end
#
# for i in sortperm(vals)
#     x0 = nn_means[1, i]
#     d_nn_means[:,i] = broadcast(x -> ((x / (v0 * dt)) - x0)^2, nn_means[:, i])
# end

# otros
for i in sortperm(vals)
    x0 = means[1, i]
    d_means[:,i] = broadcast(x -> (x - x0)^2, means[:, i])
end

for i in sortperm(vals)
    x0 = nn_means[1, i]
    d_nn_means[:,i] = broadcast(x -> (x - x0)^2, nn_means[:, i])
end

r_vals = broadcast(x -> log10(x), d_means)
r_nn_vals = broadcast(x -> log10(x), d_nn_means)

r_vals = broadcast(x -> log10(x), means)
r_nn_vals = broadcast(x -> log10(x), nn_means)

x_l = 320
x_l = 330
x_l = 455

# tflock
r_fit_vals = [polyfit(dt .* x_vals[x_l:end], r_vals[x_l:end, i], 1) for i in sortperm(vals)]
r_nn_fit_vals = [polyfit(dt .* x_vals[x_l:end], r_nn_vals[x_l:end, i], 1) for i in sortperm(vals)]

r_fit_vals = [polyfit(x_vals[x_l:end], r_vals[x_l:end, i], 1) for i in sortperm(vals)]
r_nn_fit_vals = [polyfit(x_vals[x_l:end], r_nn_vals[x_l:end, i], 1) for i in sortperm(vals)]

### ================================== ###
# kappa , d_rij(kappa), alpha_rij(kappa),d_rnn(kappa), alpha_rnn(kappa)
writecsv("top_diff_vals.csv", [["kappa" "diff_coef_rij" "diff_exp_rij" "diff_coef_rnn" "diff_exp_rnn"] ; hcat([vals[i] for i in sortperm(vals)], [exp10(r_fit_vals[i][0]) for i in 1:length(r_fit_vals)], [r_fit_vals[i][1] for i in 1:length(r_fit_vals)], [exp10(r_nn_fit_vals[i][0]) for i in 1:length(r_nn_fit_vals)], [r_nn_fit_vals[i][1] for i in 1:length(r_nn_fit_vals)]) ])

writecsv("met_diff_vals.csv", [["kappa" "diff_coef_rij" "diff_exp_rij" "diff_coef_rnn" "diff_exp_rnn"] ; hcat([vals[i] for i in sortperm(vals)], [exp10(r_fit_vals[i][0]) for i in 1:length(r_fit_vals)], [r_fit_vals[i][1] for i in 1:length(r_fit_vals)], [exp10(r_nn_fit_vals[i][0]) for i in 1:length(r_nn_fit_vals)], [r_nn_fit_vals[i][1] for i in 1:length(r_nn_fit_vals)]) ])

### ================================== ###
# kappa , d_rij(kappa), alpha_rij(kappa),d_rnn(kappa), alpha_rnn(kappa)
writecsv("2D_top_diff_vals.csv", [["kappa" "diff_coef_rij" "diff_exp_rij" "diff_coef_rnn" "diff_exp_rnn"] ; hcat([vals[i] for i in sortperm(vals)], [exp10(r_fit_vals[i][0]) for i in 1:length(r_fit_vals)], [r_fit_vals[i][1] for i in 1:length(r_fit_vals)], [exp10(r_nn_fit_vals[i][0]) for i in 1:length(r_nn_fit_vals)], [r_nn_fit_vals[i][1] for i in 1:length(r_nn_fit_vals)]) ])

writecsv("2D_met_diff_vals.csv", [["kappa" "diff_coef_rij" "diff_exp_rij" "diff_coef_rnn" "diff_exp_rnn"] ; hcat([vals[i] for i in sortperm(vals)], [exp10(r_fit_vals[i][0]) for i in 1:length(r_fit_vals)], [r_fit_vals[i][1] for i in 1:length(r_fit_vals)], [exp10(r_nn_fit_vals[i][0]) for i in 1:length(r_nn_fit_vals)], [r_nn_fit_vals[i][1] for i in 1:length(r_nn_fit_vals)]) ])
### ================================== ###
# draft pplots

m_plot = plot(times, means[:, sortperm(vals)], leg = false, xscale = :log10, yscale = :log10, lw = 1.4, xlabel = "t", ylabel = "r_ij(t)")

nn_plot = plot(times, nn_means[:, sortperm(vals)], leg = false, xscale = :log10, yscale = :log10, lw = 1.4, xlabel = "t", ylabel = "r_ij(t)")


dm_plot = scatter(times[x_l:end], d_means[x_l:end, :], xscale = :log10, yscale = :log10, lw = 1.5, leg = false, marker = :o, alpha = 0.5)

dnn_plot = scatter(times[x_l:end], d_nn_means[x_l:end, :], xscale = :log10, yscale = :log10, lw = 1.5, leg = false, marker = :o, alpha = 0.5)

plot(dm_plot, dnn_plot, layout = 2)

plot(m_plot, dm_plot, layout = 2)
plot(nn_plot, dnn_plot, layout = 2)


dif_c = plot(vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], marker = :o, xscale = :log10, xlabel = "k", ylabel = "D", title = "Diffusion Coeffcient", titlefont = font(10), yscale = :log10)

plot!(dif_c, vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], marker = :rect)

dif_e = plot(vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], marker = :o, xscale = :log10, xlabel = "k", ylabel = "alpha", title = "Diffusion Exponent", titlefont = font(10))

plot!(dif_e, vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], marker = :rect)

### ================================== ###
# print plots

plt[:rc]("text", usetex=true)
plt[:rc]("font", family="serif")
plt[:rc]("font", serif="New Century Schoolbook")

fs = 10
ls = 10

plt[:clf]()

### ================================== ###

fig = plt[:figure](num = 1, dpi = 300, facecolor="w", edgecolor="k")
fig[:set_size_inches](2.4, 1.92, forward = true)

### ================================== ###
## d_rij met

ax = fig[:add_subplot](111)

# tflock
ax[:plot](dt .* times, d_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)
ax[:plot](dt .* times, means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

ax[:plot](times, d_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)
ax[:plot](times, means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 300

# ax[:plot](times[x_f:end], broadcast(x-> 0.02exp10(-2)x , times[x_f:end]), "r--", lw = 0.8) # 3D met
# ax[:plot](times[x_f:end], broadcast(x-> 0.05exp10(-2)x , times[x_f:end]), "r--", lw = 0.8) # 2D met

# ax[:plot](times[x_f:end], broadcast(x-> 35*sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D met
ax[:plot](times[x_f:end], broadcast(x-> 0.2*sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D met
ax[:plot](times[x_f:end], broadcast(x-> 0.05*sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D met

# ax[:plot](times[x_f:end], broadcast(x-> 0.05exp10(-2)x , times[x_f:end]), "r--", lw = 0.8) # 2D met
ax[:plot](times[x_f:end], broadcast(x-> 0.2*sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 2D met

plt[:xscale]("log")
plt[:yscale]("log")

# tflock
plt[:xlim](2, exp10(6))
# plt[:xlim](2, 1.5exp10(6))

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 2)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

# tflock
plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4)])

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:xticks]([exp10(2), exp10(4), exp10(6)])

plt[:yticks]([exp10(0), exp10(3), exp10(6), exp10(8)])
plt[:yticks]([exp10(1), exp10(2), exp10(3), exp10(4)])
plt[:yticks]([exp10(1), exp10(2), exp10(3)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

# ax[:text](exp10(6), 0.5exp10(-2), L"t", ha="center", va="center", size=fs) # 3D met
# ax[:text](exp10(6), 0.8exp10(-3), L"t", ha="center", va="center", size=fs) # 2D met

ax[:text](2exp10(1), 1.3exp10(4), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)  # 3D top 4k
ax[:text](0.7exp10(6), 3.5exp10(1), L"t", ha="center", va="center", size=fs) # 3D met 4k

### ================================== ###
# 3D top 4k
ax[:text](0.7exp10(6), 3.5exp10(0), L"t", ha="center", va="center", size=fs)
ax[:text](exp10(1), 3exp10(3), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)
ax[:annotate](L"\kappa", xy = (2exp10(4), 7exp10(0)), xycoords = "data", xytext = (1.2exp10(3), 0.2exp10(3)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )
### ================================== ###
# 3D met 4k
ax[:text](0.7exp10(6), 3.5exp10(0), L"t", ha="center", va="center", size=fs)
ax[:text](1.3exp10(1), exp10(3), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)
ax[:annotate](L"\kappa", xy = (2exp10(4), 6exp10(0)), xycoords = "data", xytext = (1.2exp10(3), 1.2exp10(2)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )
### ================================== ###

ax[:text](exp10(6), 1.8exp10(1), L"t", ha="center", va="center", size=fs) # 3D met
ax[:text](exp10(6), 5exp10(1), L"t", ha="center", va="center", size=fs) # 2D met
ax[:text](0.8exp10(5), 8, L"t", ha="center", va="center", size=fs) # tflock

# ax[:text](4exp10(1), exp10(8), L"\langle \Delta^2 r_{ij} \rangle_{\kappa}", ha="center", va="center", size=fs)  # 3D
# ax[:text](3.5exp10(1), exp10(7), L"\langle \Delta^2 r_{ij} \rangle_{\kappa}", ha="center", va="center", size=fs)  # 2D


ax[:text](exp10(1), 1.5exp10(4), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)  # 3D
ax[:text](1.5exp10(1), 0.75exp10(4), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)  # 2D
ax[:text](3.5exp10(1), 2.5exp10(3), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)  # tflock

ax[:annotate](L"\kappa", xy = (2exp10(3), 2exp10(1)), xycoords = "data", xytext = (1.2exp10(3), 0.2exp10(3)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) ) # tflock

ax[:annotate](L"\kappa", xy = (2exp10(4), 5exp10(1)), xycoords = "data", xytext = (1.5exp10(3), 2.5exp10(3)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) ) # 3D met


plt[:tight_layout]()

fig[:savefig]("tflock_delta_r.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1) # 3D met
fig[:savefig]("tflock_delta_r.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1) # 3D met

fig[:savefig]("delta_rij_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1) # 3D met
fig[:savefig]("delta_rij_met.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1) # 3D met

fig[:savefig]("delta_r_met_4k.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1) # 3D met
fig[:savefig]("delta_r_met_4k.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1) # 3D met

fig[:savefig]("delta_r_top_4k.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1) # 3D met
fig[:savefig]("delta_r_top_4k.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1) # 3D met

fig[:savefig]("2D_delta_r_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1) # 2D met
fig[:savefig]("2D_delta_r_met.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1) # 2D met

plt[:clf]()

### ================================== ###
## d_rnn met

ax = fig[:add_subplot](111)

# tflock
ax[:plot](dt * times, d_nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)
ax[:plot](dt * times, nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

ax[:plot](times, d_nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)
ax[:plot](times, nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 300

ax[:plot](times[x_f:end], broadcast(x-> 2exp10(-2)sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D met
ax[:plot](times[x_f:end], broadcast(x-> 0.05exp10(-2)sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D top 4k

ax[:plot](times[x_f:end], broadcast(x-> exp10(-2)sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 2D met

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](exp10(1), exp10(5)) # tflock
plt[:ylim](exp10(-10), exp10(0)) # tflock

plt[:xlim](2, exp10(6))
plt[:ylim](exp10(-3), exp10(7)) # 3D
plt[:ylim](exp10(-7), exp10(6)) # 2D

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 2)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4)])

plt[:yticks]([exp10(-3), exp10(0), exp10(3), exp10(6)])
plt[:yticks]([exp10(-4), exp10(-1), exp10(2), exp10(5)]) # 2d met
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

### ================================== ###
# 3D top 4k
ax[:text](0.7exp10(6), 0.65exp10(-1), L"t", ha="center", va="center", size=fs)
ax[:text](1.4exp10(1), 0.8exp10(1), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)
ax[:annotate](L"\kappa", xy = (1.5exp10(4), exp10(-1)), xycoords = "data", xytext = (1.2exp10(3), 0.6exp10(0)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )
### ================================== ###

# 3D top 4k
ax[:text](0.7exp10(6), 0.65exp10(-1), L"t", ha="center", va="center", size=fs)
ax[:text](1.4exp10(1), 0.4exp10(2), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)
ax[:annotate](L"\kappa", xy = (1.5exp10(4), exp10(-1)), xycoords = "data", xytext = (exp10(3), 0.3exp10(1)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )
### ================================== ###


ax[:text](0.7exp10(5), 1.64, L"t", ha="center", va="center", size=fs) # tflock
ax[:text](5exp10(1), 2.28, L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs) # tflock

# ax[:text](exp10(6), 7exp10(-3), L"t", ha="center", va="center", size=fs) # 3D met
ax[:text](exp10(6), 2, L"t", ha="center", va="center", size=fs) # 3D met
ax[:text](exp10(6), 2.1exp10(0), L"t", ha="center", va="center", size=fs) # 2D met


ax[:text](7exp10(1), 2exp10(3), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs) # 3D met
ax[:text](4exp10(1), 4exp10(2), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs) # 2D met

# ax[:text](1.5exp10(3), 1.8exp10(5), L"\kappa", ha="center", va="center", size=0.8fs)

# ax[:annotate](L"\kappa", xy = (1.5exp10(4), 0.4exp10(1)), xycoords = "data", xytext = (1.5exp10(3), 0.6exp10(5)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) ) # 3D met
ax[:annotate](L"\kappa", xy = (2exp10(4), 0.4exp10(1)), xycoords = "data", xytext = (1.5exp10(3), 0.3exp10(3)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) ) # 3D met

ax[:annotate](L"\kappa", xy = (2exp10(4), 0.3exp10(1)), xycoords = "data", xytext = (1.5exp10(3), 0.7exp10(2)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) ) # 2D met

ax[:annotate](L"\kappa", xy = (exp10(3), 1.71), xycoords = "data", xytext = (exp10(3), 1.95), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) ) # tflock

plt[:tight_layout]()

fig[:savefig]("tflock_delta_rnn.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("tflock_delta_rnn.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("delta_rnn_met_4k.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("delta_rnn_met_4k.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("delta_rnn_top_4k.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("delta_rnn_top_4k.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("2D_delta_rnn_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("2D_delta_rnn_met.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## diffsion coefficients met

ax = fig[:add_subplot](111)

# ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5, label = L"\langle \Delta^2 r_{ij} \rangle_{\kappa}"  )
# ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5, label = L"\langle \Delta^2 r_{\mathrm{nn}} \rangle_{\kappa}")

ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5, label = L"\langle \Delta r \rangle_{\kappa}"  )
ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5, label = L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}")

ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-<", color = "#000000", ms = 3, lw = 0.5, label = L"\langle \Delta r \rangle_{\kappa}"  )
ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#BB0407", ms = 3, lw = 0.5, label = L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}")

ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-o", color = "#000000", ms = 3, lw = 0.5, label = L"\langle \Delta r \rangle_{\kappa}"  )
ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#BB0407", ms = 3, lw = 0.5, label = L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}")

plt[:xscale]("log")
plt[:yscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 2)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xlim](0.5exp10(-2), exp10(1))
plt[:ylim](exp10(-3), exp10(3))

plt[:yticks]([exp10(-3), exp10(-2), exp10(-1), exp10(0), exp10(1), exp10(2)])
plt[:yticks]([exp10(-1), exp10(0)])
plt[:xticks]([exp10(-2), exp10(-1), exp10(0), exp10(1)])

plt[:yticks]([exp10(-3), exp10(-2), exp10(-1)])
plt[:xticks]([exp10(-2), exp10(-1), exp10(0)])

# ax[:text](2exp10(-3), 4.5exp10(2), L"D(\kappa)", ha="center", va="center", size=fs) # 3D
# ax[:text](25, 0.8exp10(-3), L"\kappa", ha="center", va="center", size=fs) # 3D

### ================================== ###
# 3D met 4k
ax[:text](3.8exp10(-3), 0.9exp10(0), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](9, 0.4exp10(-3), L"\kappa", ha="center", va="center", size=fs)
### ================================== ###
# 3D top 4k
ax[:text](4.5exp10(-4), 0.4exp10(1), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](3, 0.25exp10(-3), L"\kappa", ha="center", va="center", size=fs)
### ================================== ###

ax[:text](2.5exp10(-3), 0.8exp10(1), L"D(\kappa)", ha="center", va="center", size=fs) # 2D
ax[:text](7.5, 0.5exp10(-1), L"\kappa", ha="center", va="center", size=fs) # 2D

ax[:text](2.3exp10(-5), 0.3exp10(2), L"D(\kappa)", ha="center", va="center", size=fs) # 2D top
ax[:text](1.2, 0.25exp10(-1), L"\kappa", ha="center", va="center", size=fs) # 2D top

# plt[:legend](fontsize = "x-small")

plt[:legend](bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
           ncol=2, mode="expand", borderaxespad=0., fontsize = 8.5)

plt[:tight_layout]()

fig[:savefig]("coef_diff_met_4k.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("coef_diff_met_4k.png", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("coef_diff_top_4k.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("coef_diff_top_4k.png", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("2D_coef_diff_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("2D_coef_diff_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("2D_coef_diff_met.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## diffsion coefficients top

vals_m = readcsv("3D_met_diff_vals.csv")
vals_t = readcsv("3D_top_diff_vals.csv")

ax = fig[:add_subplot](111)

# ax[:plot](vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5)
# ax[:plot](vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5)

ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-o", color = "#552299", ms = 3, lw = 0.5, label = L"\langle \Delta r \rangle_{\kappa}"  )
ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#d24760", ms = 3, lw = 0.5, label = L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}")


ax[:plot](vals_t[2:end, 1], vals_t[2:end, 2], "-o", color = "#552299", ms = 3, lw = 0.5, label = L"\langle \Delta r \rangle")
ax[:plot](vals_t[2:end, 1], vals_t[2:end, 4], "-x", color = "#d24760", ms = 3, lw = 0.5, label = L"\langle \Delta r_{\mathrm{nn}} \rangle")

ax[:plot](vals_t[2:end, 1], vals_t[2:end, 2], "-o", color = "#000000", ms = 3, lw = 0.5, label = L"\langle \Delta r \rangle")
ax[:plot](vals_t[2:end, 1], vals_t[2:end, 4], "-x", color = "#BB0407", ms = 3, lw = 0.5, label = L"\langle \Delta r_{\mathrm{nn}} \rangle")

plt[:xscale]("log")
plt[:yscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 3)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xlim](0.6exp10(-3), 1.5exp10(0))

plt[:yticks]([exp10(-2), exp10(0), exp10(2)])
plt[:yticks]([exp10(-1), exp10(0), exp10(1)])

# 3D met
ax[:text](3.2exp10(-3), 5.5exp10(2), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](20, 6exp10(-4), L"\kappa", ha="center", va="center", size=fs)

# 3D top
# ax[:text](3.2exp10(-4), 3exp10(3), L"D(\kappa)", ha="center", va="center", size=fs)
# ax[:text](2, 2exp10(-4), L"\kappa", ha="center", va="center", size=fs)

ax[:text](3.5exp10(-4), 5exp10(1), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](2, 2.5exp10(-2), L"\kappa", ha="center", va="center", size=fs)

# 2D top
ax[:text](0.25exp10(-4), 3exp10(1), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](1, 2.2exp10(-2), L"\kappa", ha="center", va="center", size=fs)

plt[:legend](bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
           ncol=2, mode="expand", borderaxespad=0., fontsize = 8.5)

plt[:tight_layout]()

fig[:savefig]("coef_diff_met.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("coef_diff_met.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("coef_diff_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("coef_diff_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## diffsion exponents top

vals = readcsv("top_diff_vals.csv")

ax = fig[:add_subplot](111)

ax[:plot](vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5)
ax[:plot](vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5)

ax[:plot](vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5)
ax[:plot](vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5)

ax[:plot](vals[2:end, 1], vals[2:end, 3], "-<", color = "#00ae88", ms = 3, lw = 0.5)
ax[:plot](vals[2:end, 1], vals[2:end, 5], "-x", color = "#ffa500", ms = 3, lw = 0.5)

plt[:xscale]("log")
# plt[:yscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xlim](0.6exp10(-3), 1.5exp10(0))

# plt[:yticks]([exp10(-2), exp10(0), exp10(2)])

ax[:text](2exp10(-3), 1.15, L"\alpha(\kappa)", ha="center", va="center", size=fs)
ax[:text](1, 0.98, L"\kappa", ha="center", va="center", size=fs)

fig[:savefig]("exp_diff_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## diffsion exponents BOTH

vals_t = readcsv("top_diff_vals.csv")
vals_m = readcsv("3D_met_diff_vals.csv")

ax = fig[:add_subplot](111)

# ax[:plot](vals[sortperm(vals)][2:end], [r_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-<", color = "#00ae88", ms = 3, lw = 0.5)
# ax[:plot](vals[sortperm(vals)][2:end], [r_nn_fit_vals[i][1] for i in 2:length(r_fit_vals)], "-x", color = "#ffa500", ms = 3, lw = 0.5)

ax[:plot](vals_t[2:end, 1], vals_t[2:end, 2], "-<", color = "#00ae88", ms = 3, lw = 0.5)
ax[:plot](vals_t[2:end, 1], vals_t[2:end, 4], "-s", color = "#ffa500", ms = 3, lw = 0.5)

ax[:plot](vals_m[2:end, 1], vals_m[2:end, 2], "-o", color = "#552299", ms = 3, lw = 0.5)
ax[:plot](vals_m[2:end, 1], vals_m[2:end, 4], "-x", color = "#d24760", ms = 3, lw = 0.5)

ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-o", color = "#552299", ms = 3, lw = 0.5, label = L"\langle \Delta^2 r_{ij} \rangle_{\kappa}"  )
ax[:plot](vals[sortperm(vals)][2:end], [exp10(r_nn_fit_vals[i][0]) for i in 2:length(r_fit_vals)], "-x", color = "#d24760", ms = 3, lw = 0.5, label = L"\langle \Delta^2 r_{\mathrm{nn}} \rangle_{\kappa}")

plt[:xscale]("log")
plt[:yscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 4)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

# plt[:xlim](0.6exp10(-3), 1.5exp10(0))

plt[:xticks]([exp10(-3), exp10(-2), exp10(-1), exp10(0), exp10(1)])
plt[:yticks]([exp10(-2), exp10(0), exp10(2), exp10(3)])

#3D
ax[:text](2.3exp10(-4), 7exp10(3), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](25, 3exp10(-4), L"\kappa", ha="center", va="center", size=fs)

#2D
ax[:text](2.5exp10(-5), exp10(3), L"D(\kappa)", ha="center", va="center", size=fs)
ax[:text](1.4, exp10(-4), L"\kappa", ha="center", va="center", size=fs)

plt[:legend](fontsize = "x-small", loc = 4)

plt[:legend](bbox_to_anchor=(0., 1.02, 1., .102), loc=3,
           ncol=2, mode="expand", borderaxespad=0., fontsize = 8.5)


plt[:tight_layout]()

fig[:savefig]("coeff_diff_both.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("2D_coeff_diff_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("2D_coeff_diff_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## d_rij top

ax = fig[:add_subplot](111)
# ax[:plot](times, d_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)
ax[:plot](times, means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 300

ax[:plot](times[x_f:end], broadcast(x-> 0.2*sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D met
# ax[:plot](times[x_f:end], broadcast(x-> 0.02exp10(-2)x , times[x_f:end]), "r--", lw = 0.8)

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](2, 1.5exp10(6))

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 2)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:yticks]([exp10(0), exp10(3), exp10(6), exp10(9)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

# 3D
# ax[:text](exp10(6), 0.5exp10(-1), L"t", ha="center", va="center", size=fs)
# ax[:text](3exp10(1), 0.8exp10(9), L"\langle \Delta^2 r_{ij} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:text](exp10(6), 2exp10(1), L"t", ha="center", va="center", size=fs)
ax[:text](exp10(1), 3exp10(4), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)

# ax[:annotate](L"\kappa", xy = (2exp10(4), 0.7exp10(3)), xycoords = "data", xytext = (1.5exp10(3), 0.2exp10(8)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

ax[:annotate](L"\kappa", xy = (2exp10(4), 0.5exp10(2)), xycoords = "data", xytext = (1.2exp10(3), 0.5exp10(4)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

# 2D
ax[:text](exp10(6), 5exp10(1), L"t", ha="center", va="center", size=fs)
ax[:text](exp10(1), 2exp10(4), L"\langle \Delta r \rangle_{\kappa}", ha="center", va="center", size=fs)
# ax[:text](1.5exp10(3), exp10(8), L"\kappa", ha="center", va="center", size=0.8fs)

ax[:annotate](L"\kappa", xy = (2exp10(4), 0.6exp10(2)), xycoords = "data", xytext = (1.2exp10(3), 0.3exp10(4)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

plt[:tight_layout]()

# fig[:savefig]("delta_rij_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
# fig[:savefig]("delta_rij_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("delta_r_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("delta_r_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("2D_delta_r_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("2D_delta_r_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

plt[:clf]()

### ================================== ###
## d_rnn met

ax = fig[:add_subplot](111)
# ax[:plot](times, d_nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)
ax[:plot](times, nn_means[:, sortperm(vals)], "-", ms = 2, lw = 0.5)

x_f = 300

# ax[:plot](times[x_f:end], broadcast(x-> 0.02exp10(-4)x , times[x_f:end]), "r--", lw = 0.8)
ax[:plot](times[x_f:end], broadcast(x-> 0.015*sqrt(x) , times[x_f:end]), "r--", lw = 0.8) # 3D met

plt[:xscale]("log")
plt[:yscale]("log")

plt[:xlim](2, 1.5exp10(6)) # 3D
plt[:xlim](10, 1.5exp10(6)) # 2D

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 2)
ax[:tick_params](axis="x",which="minor",bottom="off")
ax[:tick_params](axis="y",which="minor",left="off")

plt[:xticks]([exp10(1), exp10(2), exp10(3), exp10(4), exp10(5), exp10(6)])
plt[:yticks]([exp10(-4), exp10(-1), exp10(2), exp10(5)])
# plt[:yticklabels](["10", "10^{2}", "10^{5}", "10^{8}"])

# 3D
# ax[:text](exp10(6), 3exp10(-6), L"t", ha="center", va="center", size=fs)
# ax[:text](3exp10(1), exp10(4), L"\langle \Delta^2 r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:text](exp10(6), 2exp10(0), L"t", ha="center", va="center", size=fs)
ax[:text](2exp10(1), 1.5exp10(2), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:annotate](L"\kappa", xy = (2exp10(4), 6), xycoords = "data", xytext = (2exp10(3), 2exp10(1)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

# 2D met
ax[:text](exp10(6), 3exp10(-8), L"t", ha="center", va="center", size=fs)
ax[:text](7.5exp10(1), 4exp10(3), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:annotate](L"\kappa", xy = (0.5exp10(4), 2exp10(0)), xycoords = "data", xytext = (1.5exp10(3), 5exp10(2)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

# 2D top
ax[:text](exp10(6), 2exp10(0), L"t", ha="center", va="center", size=fs)
ax[:text](2.5exp10(1), exp10(2), L"\langle \Delta r_{\mathrm{nn}} \rangle_{\kappa}", ha="center", va="center", size=fs)

ax[:annotate](L"\kappa", xy = (2.5exp10(4), 5), xycoords = "data", xytext = (2exp10(3), 2exp10(1)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )

plt[:tight_layout]()

# ax2 = plt[:axes]([0.55, 0.28, 0.3, 0.3])
#
# ax2[:plot](times[x_f:end], d_nn_means[x_f:end, sortperm(vals)], "-", lw = 0.5)
# ax2[:plot](times[x_f:end], broadcast(x-> 5exp10(-4)x , times[x_f:end]), "r--", lw = 0.6)
#
# plt[:xscale]("log")
# plt[:yscale]("log")
#
# plt[:tick_params](which = "both", labelsize = 0.5ls, direction = "in", pad = 4)
#
# ax2[:annotate](L"\kappa", xy = (0.7exp10(4), 2exp10(0)), xycoords = "data", xytext = (1.5exp10(3), 5exp10(2)), arrowprops = Dict(:facecolor => "#423b3b", :edgecolor => "#423b3b", :width => 0.1, :headwidth => 2, :headlength => 3) )


fig[:savefig]("delta_rnn_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("delta_rnn_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

fig[:savefig]("2D_delta_rnn_top.eps", dpi = 300, format = "eps", bbox_inches = "tight" , pad_inches = 0.1)
fig[:savefig]("2D_delta_rnn_top.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

### ================================== ###

ax = fig[:add_subplot](111)

ax[:plot](times, orders[:,1], "-s", color = "#ffa500", ms = 0.1, lw = 0.5)
plt[:xscale]("log")

plt[:tick_params](which = "both", labelsize = ls, direction = "in", pad = 1.5)

ax[:set_xlabel](L"t", labelpad =0)
ax[:set_ylabel](L"\Psi(t)", labelpad =0)

plt[:tight_layout]()

fig[:savefig]("psi_vicsek_3D.png", dpi = 300, format = "png", bbox_inches = "tight" , pad_inches = 0.1)

### ================================== ###

plt[:clf]()
