@doc doc"""
apply Hodrick-Prescott filter to `AbstractVector`.

##### Arguments
- `y::AbstractVector` : data to be detrended
- `λ::Real` : penalty on variation in trend

##### Returns
- `y_cyclical::Vector`: cyclical component
- `y_trend::Vector`: trend component
"""
function hp_filter(y::AbstractVector{<:Real}, λ::Real)
    λ = Float64(λ)
    y = Float64.(y)
    N = length(y)
    H = spdiagm(-2 => fill(λ, N-2),
                -1 => vcat(-2λ, fill(-4λ, N - 3), -2λ),
                 0 => vcat(1 + λ, 1 + 5λ, fill(1 + 6λ, N-4),
                           1 + 5λ, 1 + λ),
                 1 => vcat(-2λ, fill(-4λ, N - 3), -2λ),
                 2 => fill(λ, N-2))
    y_trend = H \ y
    y .-= y_trend # cyclical
    return y, y_trend
end

@doc doc"""
This function applies "Hamilton filter" to `AbstractVector`.

http://econweb.ucsd.edu/~jhamilto/hp.pdf

##### Arguments
- `y::AbstractVector` : data to be filtered
- `h::Integer` : Time horizon that we are likely to predict incorrectly.
                 Original paper recommends 2 for annual data, 8 for quarterly data,
                 24 for monthly data.
- `p::Integer` : Number of lags in regression. Must be greater than `h`.
Note: For seasonal data, it's desirable for `p` and `h` to be integer multiples
      of the number of obsevations in a year.
      e.g. For quarterly data, `h = 8` and `p = 4` are recommended.
##### Returns
- `y_cycle::Vector` : cyclical component
- `y_trend::Vector` : trend component
"""
function hamilton_filter(y::AbstractVector{<:Real}, h::Integer, p::Integer)
    T = length(y)
    y_cycle = fill(NaN, T)

    # construct X matrix of lags
    X = Matrix{Float64}(undef, T-p-h+1, p + 1)
    X[:, 1] .= 1
    for j in 1:p
        X[:, j + 1] = view(y, p-j+1:T-h-j+1)
    end

    # do OLS regression
    b = (X' * X) \ (X' * view(y, p+h:T))
    Xb = X * b
    y_cycle[p+h:T] .= view(y, p+h:T) .- Xb
    y_trend = append!(fill(NaN, p+h-1), Xb)
    return y_cycle, y_trend
end

@doc doc"""
This function applies "Hamilton filter" to `<:AbstractVector`
under random walk assumption.

http://econweb.ucsd.edu/~jhamilto/hp.pdf

##### Arguments
- `y::AbstractVector` : data to be filtered
- `h::Integer` : Time horizon that we are likely to predict incorrectly.
                 Original paper recommends 2 for annual data, 8 for quarterly data,
                 24 for monthly data.
Note: For seasonal data, it's desirable for `h` to be an integer multiple
      of the number of obsevations in a year.
      e.g. For quarterly data, `h = 8` is recommended.
##### Returns
- `y_cycle::Vector` : cyclical component
- `y_trend::Vector` : trend component
"""
function hamilton_filter(y::AbstractVector{<:Real}, h::Integer)
    y = Vector{Float64}(y)
    T = length(y)
    y_cycle = fill(NaN, T)
    y_cycle[h+1:T] .= view(y, h+1:T) .- view(y, 1:T-h)
    y .-= y_cycle # trend
    return y_cycle, y
end
