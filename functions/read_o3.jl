
function read_o3(fname)
	df_raw = DataFrame(CSV.File(fname))
	df = dropmissing(df_raw, :"CBSA Name")
	df[(df[:, "CBSA Name"] .== "Houston-The Woodlands-Sugar Land, TX"), :]
	o3_value = df[!, :"1st Max Value"]
	date = df[!, :"Date Local"]
	df_out = DataFrame(:date => date, :o3 => o3_value)
	sort!(df_out, [:date])
	
	return df_out
end;