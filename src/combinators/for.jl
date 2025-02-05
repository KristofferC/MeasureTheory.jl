
export For
using Random
import Base


"""
    For(f, base...)

`For` provides a convenient way to construct a `ProductMeasure`. There are
several options for the `base`. With Julia's `do` notation, this can look very
similar to a standard `for` loop, while maintaining semantics structure that's
easier to work with.

------------

# `For(f, base::Int...)`

When one or several `Int` values are passed for `base`, the result is treated as
depending on `CartesianIndices(base)`. 

```
julia> For(3) do λ Exponential(λ) end |> marginals
3-element mappedarray(MeasureTheory.var"#17#18"{var"#15#16"}(var"#15#16"()), ::CartesianIndices{1, Tuple{Base.OneTo{Int64}}}) with eltype Exponential{(:λ,), Tuple{Int64}}:
 Exponential(λ = 1,)
 Exponential(λ = 2,)
 Exponential(λ = 3,)
```

```
julia> For(4,3) do μ,σ Normal(μ,σ) end |> marginals
4×3 mappedarray(MeasureTheory.var"#17#18"{var"#11#12"}(var"#11#12"()), ::CartesianIndices{2, Tuple{Base.OneTo{Int64}, Base.OneTo{Int64}}}) with eltype Normal{(:μ, :σ), Tuple{Int64, Int64}}:
 Normal(μ = 1, σ = 1)  Normal(μ = 1, σ = 2)  Normal(μ = 1, σ = 3)
 Normal(μ = 2, σ = 1)  Normal(μ = 2, σ = 2)  Normal(μ = 2, σ = 3)
 Normal(μ = 3, σ = 1)  Normal(μ = 3, σ = 2)  Normal(μ = 3, σ = 3)
 Normal(μ = 4, σ = 1)  Normal(μ = 4, σ = 2)  Normal(μ = 4, σ = 3)
```

-------

# `For(f, base::AbstractArray...)``

In this case, `base` behaves as if the arrays are `zip`ped together before
applying the map.

```
julia> For(randn(3)) do x Exponential(x) end |> marginals
3-element mappedarray(x->Main.Exponential(x), ::Vector{Float64}) with eltype Exponential{(:λ,), Tuple{Float64}}:
 Exponential(λ = -0.268256,)
 Exponential(λ = 1.53044,)
 Exponential(λ = -1.08839,)
```

```
julia> For(1:3, 1:3) do μ,σ Normal(μ,σ) end |> marginals
3-element mappedarray((:μ, :σ)->Main.Normal(μ, σ), ::UnitRange{Int64}, ::UnitRange{Int64}) with eltype Normal{(:μ, :σ), Tuple{Int64, Int64}}:
 Normal(μ = 1, σ = 1)
 Normal(μ = 2, σ = 2)
 Normal(μ = 3, σ = 3)
```

----

# `For(f, base::Base.Generator)`

For `Generator`s, the function maps over the values of the generator:

```
julia> For(eachrow(rand(4,2))) do x Normal(x[1], x[2]) end |> marginals |> collect
4-element Vector{Normal{(:μ, :σ), Tuple{Float64, Float64}}}:
 Normal(μ = 0.255024, σ = 0.570142)
 Normal(μ = 0.970706, σ = 0.0776745)
 Normal(μ = 0.731491, σ = 0.505837)
 Normal(μ = 0.563112, σ = 0.98307)
```

"""
function For(f, base...) end



# ForArray

ForArray{D,N,T,F} = ProductMeasure{ReadonlyMappedArray{D, N, T, F}} 

function TV.as(d::ForArray)
    d1 = d.data.f(first(d.data.data))
    as(Array, as(d1), size(d.data)...)
end

function Base.show(io::IO, d::ForArray{D,N,T,F}) where {D,N,T,F}
    print(io, "For(")
    print(io, d.data.f, ", ")
    print(io, d.data.data, ")")
end

function Base.show(io::IO, d::ForArray{D,N,T,F}) where {D,N,T <: CartesianIndices,F}
    print(io, "For(")
    print(io, d.data.f, ", ")
    join(io, size(d.data), ", ")
    print(io, ")")
end

For(f, dims::AbstractArray...) = ProductMeasure(mappedarray(f, dims...))

For(f, dims::Int...) = ProductMeasure(mappedarray(i -> f(Tuple(i)...), CartesianIndices(dims))) 

function Base.eltype(::ForArray{D,N,T,F}) where {D,N,T,F}
    return eltype(D)
end

basemeasure(μ::ForArray) = @inbounds basemeasure(μ.data[1])^size(μ.data)

# """
#     indexstyle(a::AbstractArray, b::AbstractArray)

# Find the best IndexStyle that works for both `a` and `b`. This will return
# `IndexLinear` if both `a` and `b` support it; otherwise it will fall back on `IndexCartesian`.
# """
# function indexstyle(::A,::B)
#     if IndexStyle(A) == IndexStyle(B) == IndexLinear()
#         return IndexLinear()
#     end

#     return IndexCartesian()
# end

# function Base.rand(rng::AbstractRNG, μ::ForArray{D,N,T,F}) where {F,T<:AbstractArray,D,X}
#     s = size(μ.θ)
#     x = Array{X,length(s)}(undef, s...)
#     rand!(rng, x, μ)
# end

# function logdensity(μ::ForArray{D,N,T,F}, x)
#     getℓ(θⱼ, xⱼ) = logdensity(μ.f(θⱼ), xⱼ)
#     ℓ = mappedarray(getℓ, μ.θ, x)
#     _logdensity(μ, x, indexstyle(μ.θ, x), result_type)
# end

# function _logdensity(μ::ForArray{D,N,T,F}, x, ::IndexLinear, ::Type{R}) where {R<:AbstractFloat}
#     ℓ = zero(R)
#     μ.f(μ.θ)
# end

# function basemeasure(μ::ForArray{D,N,T,F}) where {F,T<:AbstractArray,D,X}

# ForGenerator

ForGenerator{G} = ProductMeasure{G} where {G <: Base.Generator}

function TV.as(d::ForGenerator)
    d1 = d.data.f(first(d.data.iter))
    as(Array, as(d1), size(d.data)...) 
end


For(f, dims::Base.Generator) = ProductMeasure(Base.Generator(f ∘ dims.f, dims.iter))

sampletype(::ForGenerator) = Base.Generator

function Base.rand(rng::AbstractRNG, T::Type, d::ForGenerator)
    r(x) = rand(rng, T, x)
    Base.Generator(r ∘ d.data.f, d.data.iter)
end

function logdensity(d::ForGenerator, x)
    sum((logdensity(dj, xj) for (dj, xj) in zip(d.data, x)))
end

testvalue(μ::ProductMeasure) = mappedarray(testvalue, μ.data)
