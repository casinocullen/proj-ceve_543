############################################################
######                                                ######
######                   Prepare Data                 ######
######                                                ######
############################################################


# import Pkg
# Pkg.add("CSV")
# Pkg.add("DataFrames")
# Pkg.add("Dates")
# Pkg.add("StatsBase")
# Pkg.add("Plots")


# Load packages
using CSV
using DataFrames
using Dates
using StatsBase
using Plots

include("functions/read_o3.jl")


# Read raw O3 daily data
o3_raw_2014 = read_o3("./source/air_pollution/daily_44201_2014.csv")
o3_raw_2015 = read_o3("./source/air_pollution/daily_44201_2015.csv")
o3_raw_2016 = read_o3("./source/air_pollution/daily_44201_2016.csv")
o3_raw_2017 = read_o3("./source/air_pollution/daily_44201_2017.csv")
o3_raw_2018 = read_o3("./source/air_pollution/daily_44201_2018.csv")
o3_raw_2019 = read_o3("./source/air_pollution/daily_44201_2019.csv")
o3_raw_2020 = read_o3("./source/air_pollution/daily_44201_2020.csv")
o3_all_years = vcat(o3_raw_2014, o3_raw_2015, o3_raw_2016, o3_raw_2017, o3_raw_2018, o3_raw_2019, o3_raw_2020)

# Assign year + month
o3_all_years[!, :year] = year.(o3_all_years[!, :date])
o3_all_years[!, :month] = month.(o3_all_years[!, :date])

# Combine to daily average from all sites within Houston
o3_all_years_daily = combine(groupby(o3_all_years, :date), :o3 => mean)
o3_all_years_daily[!, :o3_mean] = o3_all_years_daily[!, :o3_mean] * 1000
o3_all_years_daily[!, :date_num] = collect(1:length(o3_all_years_daily.o3_mean))

# Combine to monthly average from all sites within Houston
o3_all_years_monthly = combine(groupby(o3_all_years, [:year, :month]), :o3 => mean)
o3_all_years_monthly[!, :o3_mean] = o3_all_years_monthly[!, :o3_mean] * 1000
o3_all_years_monthly[!, :date_num] = collect(1:length(o3_all_years_monthly.o3_mean))

# Output
CSV.write("./output/o3_all_years_daily.csv", o3_all_years_daily)
CSV.write("./output/o3_all_years_monthly.csv", o3_all_years_monthly)

# Plot
p_o3_daily = plot(o3_all_years_daily.date, o3_all_years_daily.o3_mean, xlabel = "Date", ylabel = "O3 Conc. (ppb)", label=false)
p_o3_monthly = plot(o3_all_years_monthly.date_num, o3_all_years_monthly.o3_mean, xlabel = "# of Months", ylabel = "O3 Conc. (ppb)", label=false)

savefig(p_o3_daily, "./vis/0.o3_daily.png")
savefig(p_o3_monthly, "./vis/0.o3_monthly.png")
