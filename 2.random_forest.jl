############################################################
######                                                ######
######                Random Forest                   ######
######                                                ######
############################################################

# import Pkg
# Pkg.add("Lathe")
# Pkg.add("ScikitLearn")
# Pkg.add("Random")
# Pkg.add("Statistics")
# Pkg.add("DecisionTree")

# Load packages
using CSV
using DataFrames
using Lathe.preprocess: TrainTestSplit
using ScikitLearn, Random
using Statistics
using DecisionTree

include("functions/r2.jl")

# Load all variables pre-processed 
all_hou_data = let 
	fname = "./source/all_hou_cbsa_2020_data.csv"
	df_raw = DataFrame(CSV.File(fname))
    df_raw[!, :daily_8hr_ozone_max] = df_raw[!, :daily_8hr_ozone_max] * 1000
    df_raw
end;

# Define features to use in the model
feature_names = ["AWND", "PRCP", "TAVG", "TMAX", "TMIN", 
"temp_max", "temp_avg", "temp_min", "dew_point_max", "dew_point_avg", "dew_point_min", 
"rh_max", "rh_avg", "rh_min", "ws_max", "ws_avg", "ws_min", "pres_max", "pres_avg", "pres_min", 
"rain_total", "sunlight_hrs", 
"so2_mass_lbs_hou_coal", "nox_mass_lbs_hou_coal", "co2_mass_tons_hou_coal",
"so2_mass_lbs_hou_ng", "nox_mass_lbs_hou_ng", "co2_mass_tons_hou_ng", 
"so2_mass_lbs_hou_all", "nox_mass_lbs_hou_all", "co2_mass_tons_hou_all"];

# Split data to train and test
train, test = TrainTestSplit(all_hou_data)
	
trainX = train[!, feature_names] |> Matrix
trainy = train[!, "daily_8hr_ozone_max"]
testX = test[!, feature_names] |> Matrix
testy = test[!, "daily_8hr_ozone_max"]

regr = RandomForestRegressor(n_trees=20)
ScikitLearn.fit!(regr, trainX, trainy)
y_pred = ScikitLearn.predict(regr, hcat(testX))

# Validate
r_squared_score(y_pred, testy)

# Plot time series plot for test set
p_random_forest_test = plot(testy, title="Random Forest Posterior Check (Test)", xlabel = "Test Index", ylabel = "O3 conc. (ppb)", label="true")
plot!(p_random_forest_test, y_pred, label="pred")
savefig(p_random_forest_test, "./vis/2.random_forest_validation_test.png")

# Predict 2021
all_hou_data_2021 = let 
	fname = "./source/all_hou_cbsa_2021_data.csv"
	df_raw = DataFrame(CSV.File(fname))
    df_raw[!, :daily_8hr_ozone_max] = df_raw[!, :daily_8hr_ozone_max] * 1000
    df_raw
end;

test_2021 = all_hou_data_2021[!, feature_names] |> Matrix
y_2021 = all_hou_data_2021[!, "daily_8hr_ozone_max"]
y_pred_2021 = ScikitLearn.predict(regr, hcat(test_2021))


# Plot time series plot for 2021 validation
p_random_forest_2021 = plot(y_2021, title="Random Forest Posterior Check (2021)", xlabel = "2021 Date", ylabel = "O3 conc. (ppb)", label="true")
p_random_forest_2021 = plot!(p_random_forest_2021, y_pred_2021, label="pred")
savefig(p_random_forest_2021, "./vis/2.random_forest_validation_2021.png")


# Validation
r_squared_score(y_pred_2021, y_2021)


