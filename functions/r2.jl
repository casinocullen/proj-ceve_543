function r_squared_score(y_pred, y_true)

    # Compute sum of explained variance (SST) and sum of squares of residuals
    sst = sum(((y_true .- mean(y_true)) .^ 2))
    ssr = sum(((y_pred .- y_true) .^ 2))
     
    r_square = 1 - (ssr / sst)
     
    return r_square
    end
    