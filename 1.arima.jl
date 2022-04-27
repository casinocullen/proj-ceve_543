############################################################
######                                                ######
######                   ARIMA                        ######
######                                                ######
############################################################

# import Pkg
# Pkg.add("StatsPlots")
# Pkg.add("Optim")
# Pkg.add("Turing")
# Pkg.add("DynamicHMC")
# Pkg.add("StateSpaceModels")

# Load packages
using CSV
using DataFrames
using Dates
#using Chain
using Plots
using StatsBase
using StatsPlots
using Turing
using DynamicHMC
using StateSpaceModels
using Optim

# Load O3 data from 0.data_prep.jl
o3_all_years_daily = DataFrame(CSV.File("./output/o3_all_years_daily.csv"))
o3_all_years_monthly = DataFrame(CSV.File("./output/o3_all_years_monthly.csv"))


# Find parameters p,d,q

#Plot ACF and PACF plots
diff_series = diff(o3_all_years_monthly.o3_mean)
total_lags = 20
s1 = scatter(collect(1:total_lags), autocor(diff_series, collect(1:total_lags)), title = "ACF")
s2 = scatter(collect(1:total_lags), pacf(diff_series, collect(1:total_lags)), title = "PACF")
p_acf_pacf = plot(s1, s2, layout = (2, 1))
savefig(p_acf_pacf, "./vis/1.arima_acf_pacf.png")



############################################################
### Build an ARIMA model with order (1, 1, 0)
############################################################

@model ARIMA110(x;N_forecast=20) = begin
    T = length(x)
    μ ~ Uniform(-20, 20)
    ϕ ~ Uniform(-3, 3)
	σ ~ truncated(Normal(0, 1), 0, Inf)
    for t in 3:T
        val = μ +                      # Drift term.
              x[t-1] +                 # ARIMA(0,1,0) portion.
              ϕ * (x[t-1] - x[t-2])    # ARIMA(1,0,0) portion.
        x[t] ~ Normal(val, σ)
    end

	# future
	xnew = []
	tnew = T .+ collect(1:N_forecast)
	
	for i in 1:N_forecast
		xcat = vcat(x, xnew)
		val = μ + xcat[tnew[i]-1] +
              ϕ * (xcat[tnew[i]-1] - xcat[tnew[i]-2]) 
		push!(xnew, rand(Normal(val, σ)))
	end
	return tnew, xnew
end;

# Find the optimized parameters using MLE
optimize(ARIMA110(o3_all_years_monthly.o3_mean), MLE(), NelderMead())

chains = begin
	sampler = DynamicNUTS()
	n_per_chain = 5000
	nchains = 4
	Turing.sample(ARIMA110(o3_all_years_monthly.o3_mean), sampler, MCMCThreads(), n_per_chain, nchains, drop_warmup=true, N_forecast=10)
	#sample(ar_trend_model, sampler, 5_000, drop_warmup=true, N_forecast=N_forecast)
end;
p_chains = plot(chains)

print(summarystats(chains))

savefig(p_chains, "./vis/1.arima_chain_check.png")


xnew = let
	chains_params = Turing.MCMCChains.get_sections(chains, :parameters)
	generated_quantities(ARIMA110(o3_all_years_monthly.o3_mean), chains_params) 
end;
p_chains = plot(chains)
savefig(p_chains, "./vis/1.arima_chain_check.png")

# Make forecast using ARIMA(1,1,0)
p_arima_forecast = scatter(o3_all_years_monthly.date_num, o3_all_years_monthly.o3_mean, label="Obs", 
xlabel="Month", ylabel = "O3 Conc. (ppb)", legend=:topleft)
	
for i in 1:1000
    tt, yy = rand(xnew)
    label = i == 1 ? "Forecast" : ""
    plot!(p_arima_forecast, tt, yy, color=:gray, label=label, linewidth=0.125)
end
plot!(p_arima_forecast, mean(first.(xnew)), mean(last.(xnew)), color=:red, label="Mean", linewidth=1)

savefig(p_arima_forecast, "./vis/1.arima_forecast.png")

############################################################
### SARIMA
############################################################
steps_ahead = 30
model_sarima = SARIMA(o3_all_years_monthly.o3_mean; order = (0, 0, 1), seasonal_order = (2, 1, 0, 12))
StateSpaceModels.fit!(model_sarima)

# Forecast
forec_sarima = forecast(model_sarima, steps_ahead);
forec_vec = []
for i in 1:steps_ahead
    push!(forec_vec, forec_sarima.expected_value[i][1])
end
p_sarima_forecast = plot(model_sarima, forec_sarima; title = "SARIMA Forecast", label = "")
savefig(p_sarima_forecast, "./vis/1.sarima_forecast.png")


# Validate using 2021 true value
all_hou_data_2021 = let 
	fname = "./source/all_hou_cbsa_2021_data.csv"
	df_raw = DataFrame(CSV.File(fname))
    df_raw[!, :o3] = df_raw[!, :daily_8hr_ozone_max] * 1000
    
    df_raw[!, :month] = month.(df_raw[!, :date])
    df_raw[!, :year] = year.(df_raw[!, :date])

    df_raw_grp = combine(groupby(df_raw, [:month, :year]), :o3 => mean)
end;


p_sarima_posterior = plot(all_hou_data_2021.o3_mean, title="SARIMA posterior predictive check", xlabel = "Month (2021)", ylabel = "O3 conc. (ppb)", label="true")
plot!(p_sarima_posterior, forec_vec[1:10], label="pred")

savefig(p_sarima_posterior, "./vis/1.sarima_posterior_check.png")


