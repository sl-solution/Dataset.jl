_add_sum(x, y) = Base.add_sum(x, y)
_add_sum(x, ::Missing) = x
_add_sum(::Missing, x) = x
_add_sum(::Missing, ::Missing) = missing
_mul_prod(x, y) = Base.mul_prod(x, y)
_mul_prod(x, ::Missing) = x
_mul_prod(::Missing, x) = x
_mul_prod(::Missing, ::Missing) = missing
_min_fun(x, y) = min(x, y)
_min_fun(x, ::Missing) = x
_min_fun(::Missing, y) = y
_min_fun(::Missing, ::Missing) = missing
_max_fun(x, y) = max(x, y)
_max_fun(x, ::Missing) = x
_max_fun(::Missing, y) = y
_max_fun(::Missing, ::Missing) = missing
_bool(f) = x->f(x)::Bool

struct _Prehashed
    hash::UInt64
end
Base.hash(x::_Prehashed) = x.hash


Base.@propagate_inbounds function _op_for_sum!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] = _add_sum(x[i], f(y[i]))
    end
    x
end

function row_sum(ds::AbstractDataset, f::Function,  cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    T = Core.Compiler.return_type(f, Tuple{CT})
	CT = our_nonmissingtype(T)
	CT <: SMALLSIGNED ? CT = Int : nothing
	CT <: SMALLUNSIGNED ? CT = UInt : nothing
	CT <: Bool ? CT = Int : nothing
	T = Union{Missing, CT}
    init0 = _missings(T, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_sum!(x,y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_sum!(x,y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

row_sum(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_sum(ds, identity, cols, threads = threads)



Base.@propagate_inbounds function _op_for_prod!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] = _mul_prod(x[i], f(y[i]))
    end
    x
end

function row_prod(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    T = Core.Compiler.return_type(f, Tuple{CT})
	CT = our_nonmissingtype(T)
	CT <: SMALLSIGNED ? CT = Int : nothing
	CT <: SMALLUNSIGNED ? CT = UInt : nothing
	CT <: Bool ? CT = Int : nothing
	T = Union{Missing, CT}
    init0 = _missings(T, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_prod!(x,y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_prod!(x,y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

row_prod(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_prod(ds, identity, cols; threads = threads)

Base.@propagate_inbounds function _op_for_count!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] += f(y[i])
    end
    x
end


function row_count(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    init0 = zeros(Int32, size(ds,1))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_count!(x, y, _bool(f), lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_count!(x, y, _bool(f), 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

row_count(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_count(ds, x->true, cols; threads = threads)

_op_bool_add(x::Bool,y::Bool) = x | y ? true : false
Base.@propagate_inbounds function op_for_any!(x, y, f, lo, hi)
    @simd for i in lo:hi
        !x[i] ? x[i] = f(y[i]) : nothing
    end
    x
end

function row_any(ds::AbstractDataset, f::Union{AbstractVector{<:Function}, Function}, cols = :; threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    init0 = zeros(Bool, size(ds,1))

    multi_f = false
    if f isa AbstractVector
        @assert length(f) == length(colsidx) "number of provided functions must match the number of selected columns"
        multi_f = true
    end

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if multi_f
                mapreduce_index(f, (x, y, func) -> op_for_any!(x, y, _bool(func), lo, hi), view(_columns(ds),colsidx), init0)
            else
                mapreduce(identity, (x,y) -> op_for_any!(x,y, _bool(f), lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if multi_f
            mapreduce_index(f, (x, y, func) -> op_for_any!(x, y, _bool(func), 1, length(x)), view(_columns(ds),colsidx), init0)
        else
            mapreduce(identity, (x,y) -> op_for_any!(x,y, _bool(f), 1, length(x)), view(_columns(ds),colsidx), init = init0)
        end
    end
    init0
end

row_any(ds::AbstractDataset, cols = :; threads = true) = row_any(ds, isequal(true), cols; threads = threads)

_op_bool_mult(x::Bool,y::Bool) = x & y ? true : false

Base.@propagate_inbounds function op_for_all!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] ? x[i] = f(y[i]) : nothing
    end
    x
end

function row_all(ds::AbstractDataset, f::Union{AbstractVector{<:Function}, Function}, cols = :; threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    init0 = ones(Bool, size(ds,1))

    multi_f = false
    if f isa AbstractVector
        @assert length(f) == length(colsidx) "number of provided functions must match the number of selected columns"
        multi_f = true
    end

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if multi_f
                mapreduce_index(f, (x, y, func) -> op_for_all!(x, y, _bool(func), lo, hi), view(_columns(ds),colsidx), init0)
            else
                mapreduce(identity, (x,y) -> op_for_all!(x,y, _bool(f), lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if multi_f
            mapreduce_index(f, (x, y, func) -> op_for_all!(x, y, _bool(func), 1, length(x)), view(_columns(ds),colsidx), init0)
        else
            mapreduce(identity, (x,y) -> op_for_all!(x,y, _bool(f), 1, length(x)), view(_columns(ds),colsidx), init = init0)
        end
    end
    init0
end
row_all(ds::AbstractDataset, cols = :; threads = true) = row_all(ds, isequal(true), cols; threads = threads)

# this is a general rule for order of arguments in isequal, isless, findfirst, ...
# if the keyword argument is `with` then eq(y, with)
# if the keyword argument is `item` then eq(item, y)

Base.@propagate_inbounds function _op_for_isequal!(x, y, x1, lo, hi)
    @simd for i in lo:hi
        x[i] ? x[i] = isequal(y[i], x1[i]) : nothing
    end
    x
end


function row_isequal(ds::AbstractDataset, cols = :; by::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex, Nothing} = nothing, threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    if !(by isa ColumnIndex) && by !== nothing
        @assert length(by) == nrow(ds) "to compare values of selected columns in each row, the length of the passed vector and the number of rows must match"
    end
    if by isa SubDatasetColumn || by isa DatasetColumn
        x1 = __!(by)
    elseif by isa ColumnIndex
        x1 = _columns(ds)[index(ds)[by]]
    elseif by === nothing
        x1 = _columns(ds)[colsidx[1]]
    else
        x1 = by
    end
    init0 = ones(Bool, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_isequal!(x,y, x1, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_isequal!(x,y, x1, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

Base.@propagate_inbounds function _op_for_isless!(x, y, vals, rev,lt, lo, hi)
    if !rev
        @simd for i in lo:hi
            x[i] ? x[i] = lt(y[i], vals[i]) : nothing
        end
    else
        @simd for i in lo:hi
            x[i] ? x[i] = lt(vals[i], y[i]) : nothing
        end
    end
    x
end


function row_isless(ds::AbstractDataset, cols, colselector::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex}; threads = true, rev = false, lt = isless)
    if !(colselector isa ColumnIndex)
        @assert length(colselector) == nrow(ds) "to compare values of selected columns in each row, the length of the passed vector and the number of rows must match"
    end
    colsidx = multiple_getindex(index(ds), cols)
    if colselector isa SubDatasetColumn || colselector isa DatasetColumn
        colselector = __!(colselector)
    elseif colselector isa ColumnIndex
        colselector = _columns(ds)[index(ds)[colselector]]
    end
    init0 = ones(Bool, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_isless!(x, y, colselector, rev, lt, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_isless!(x, y, colselector, rev, lt, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0

end


# TODO probably we should use this approach instead of mapreduce_indexed
Base.@propagate_inbounds function _op_for_findfirst!(x, y, f, idx, missref, lo, hi)
    idx[] += 1
    @simd for i in lo:hi
        x[i] = ifelse(isequal(missref, x[i]) && isequal(true, f(y[i])), idx[], x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_findfirst!(x, y, item, idx, missref, eq, lo, hi)
    idx[] += 1
    @simd for i in lo:hi
        x[i] = ifelse(isequal(missref, x[i]) && eq(item[i], y[i]), idx[], x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_findlast!(x, y, f, idx, missref, lo, hi)
    idx[] += 1
    @simd for i in lo:hi
        x[i] = ifelse(isequal(true, f(y[i])), idx[], x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_findlast!(x, y, item, idx, missref, eq, lo, hi)
    idx[] += 1
    @simd for i in lo:hi
        x[i] = ifelse(eq(item[i], y[i]), idx[], x[i])
    end
    x
end

function row_findfirst(ds::AbstractDataset, f, cols = names(ds, Union{Missing, Number});item::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex, Nothing} = nothing, threads = true, eq = isequal)
    if !(item isa ColumnIndex) && item !== nothing
        @assert length(item) == nrow(ds) "length of item values must be the same as the number of rows"
    elseif item isa SubDatasetColumn || item isa DatasetColumn
        item = __!(item)
    elseif item isa ColumnIndex
        item = _columns(ds)[index(ds)[item]]
    end
    colsidx = multiple_getindex(index(ds), cols)

    colnames_pa = allowmissing(PooledArray(_names(ds)[colsidx]))
    push!(colnames_pa, missing)
    missref = get(colnames_pa.invpool, missing, 0)
    init0 = fill(missref, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        idx = [Ref{Int}(0) for _ in 1:Threads.nthreads()]
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if item === nothing
                mapreduce(identity, (x,y) -> _op_for_findfirst!(x, y, f, idx[i], missref, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_findfirst!(x, y, item, idx[i], missref, eq, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        idx = Ref{Int64}(0)
        if item === nothing
            mapreduce(identity, (x,y) -> _op_for_findfirst!(x, y, f, idx, missref, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_findfirst!(x, y, item, idx, missref, eq, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        end
    end
    colnames_pa.refs = init0
    colnames_pa
end

function row_findlast(ds::AbstractDataset, f, cols = names(ds, Union{Missing, Number}); item::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex, Nothing} = nothing, threads = true, eq = isequal)
    if !(item isa ColumnIndex) && item !== nothing
        @assert length(item) == nrow(ds) "length of item values must be the same as the number of rows"
    elseif item isa SubDatasetColumn || item isa DatasetColumn
        item = __!(item)
    elseif item isa ColumnIndex
        item = _columns(ds)[index(ds)[item]]
    end
    colsidx = multiple_getindex(index(ds), cols)
    colnames_pa = allowmissing(PooledArray(_names(ds)[colsidx]))
    push!(colnames_pa, missing)
    missref = get(colnames_pa.invpool, missing, 0)
    init0 = fill(missref, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        idx = [Ref{Int}(0) for _ in 1:Threads.nthreads()]
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if item === nothing
                mapreduce(identity, (x,y) -> _op_for_findlast!(x, y, f, idx[i], missref, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_findlast!(x, y, item, idx[i], missref, eq, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        idx = Ref{Int}(0)
        if item === nothing
            mapreduce(identity, (x,y) -> _op_for_findlast!(x, y, f, idx, missref, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_findlast!(x, y, item, idx, missref, eq, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        end
    end
    colnames_pa.refs = init0
    colnames_pa
end

Base.@propagate_inbounds function _op_for_in!(x, y, x1, eq, lo, hi)
    @simd for i in lo:hi
        !x[i] ? x[i] = eq(x1[i], y[i]) : nothing
    end
    x
end

function row_in(ds::AbstractDataset, collections, items::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex}; threads = true, eq = isequal)
    if !(items isa ColumnIndex)
        @assert length(items) == nrow(ds) "length of item values must be the same as the number of rows"
    end
    colsidx = index(ds)[collections]
    if items isa SubDatasetColumn || items isa DatasetColumn
        items = __!(items)
    elseif items isa ColumnIndex
        items = _columns(ds)[index(ds)[items]]
    end
    init0 = zeros(Bool, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_in!(x, y, items, eq, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_in!(x, y, items, eq, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

Base.@propagate_inbounds function _op_for_select!(x, y, colselector, dsnames, idx, lo, hi)
    idx[] += 1
    @simd for i in lo:hi
        if isequal(colselector[i], dsnames[idx[]])
            x[i] = y[i]
        end
    end
    x
end

function row_select(ds::AbstractDataset, cols, colselector::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex}; threads = true)
    if !(colselector isa ColumnIndex)
        @assert length(colselector) == nrow(ds) "to pick values of selected columns in each row, the length of the column names and the number of rows must match, i.e. the length of the vector passed as `by` must be $(nrow(ds))."
    end
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    if colselector isa SubDatasetColumn || colselector isa DatasetColumn
        colselector = __!(colselector)
    end
    if colselector isa ColumnIndex
        colselector = _columns(ds)[index(ds)[colselector]]
    end
    if eltype(colselector) <: Union{Missing, Symbol}
        nnames = Symbol.(names(ds, colsidx))
    elseif eltype(colselector) <: Union{Missing, AbstractString}
        nnames = names(ds, colsidx)
    elseif eltype(colselector) <: Union{Missing, Integer}
        nnames = 1:length(colsidx)
    end
    init0 = _missings(CT, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        idx = [Ref{Int}(0) for _ in 1:Threads.nthreads()]
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_select!(x, y, colselector, nnames, idx[i], lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        idx = Ref{Int}(0)
        mapreduce(identity, (x,y) -> _op_for_select!(x, y, colselector, nnames, idx, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

Base.@propagate_inbounds function _op_for_fill!(x, y, f, lo, hi)
    @simd for i in lo:hi
       y[i] = ifelse(f(y[i]), x[i], y[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_fill_roll!(x, y, f, lo, hi)
    @simd for i in lo:hi
       y[i] = ifelse(f(y[i]), x[i], y[i])
    end
    y
end


# rolling = true, means fill a column an use its value for next filling
function row_fill!(ds::AbstractDataset, cols, val::Union{AbstractVector, DatasetColumn, SubDatasetColumn, ColumnIndex}; f = ismissing, threads = true, rolling = false)
    if !(val isa ColumnIndex)
        @assert length(val) == nrow(ds) "to fill values in each row, the length of passed values and the number of rows must match."
    end
    colsidx = multiple_getindex(index(ds), cols)
    if val isa SubDatasetColumn || val isa DatasetColumn
        val = __!(val)
    end
    if val isa ColumnIndex
        val = _columns(ds)[index(ds)[val]]
    end
    init0 = val

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if rolling
                mapreduce(identity, (x,y) -> _op_for_fill_roll!(x, y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_fill!(x, y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if rolling
            mapreduce(identity, (x,y) -> _op_for_fill_roll!(x, y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_fill!(x, y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        end
    end
    any(index(parent(ds)).sortedcols .∈ Ref(IMD.parentcols.(Ref(IMD.index(ds)), cols))) && _reset_grouping_info!(parent(ds))
    _modified(_attributes(parent(ds)))
    ds
end


Base.@propagate_inbounds function _op_for_coalesce!(x, y, lo, hi)
    if all(!ismissing, view(x, lo:hi))
        x
    else
        @simd for i in lo:hi
            x[i] = ifelse(ismissing(x[i]), y[i], x[i])
        end
    end
    x
end


function row_coalesce(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))

    init0 = _missings(CT, size(ds,1))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_coalesce!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_coalesce!(x, y, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end

function row_mean(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    row_sum(ds, f, cols; threads = threads) ./ row_count(ds, x -> !ismissing(x), cols; threads = threads)
end
row_mean(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_mean(ds, identity, cols; threads = threads)


Base.@propagate_inbounds function _op_for_min!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] = _min_fun(x[i], f(y[i]))
    end
    x
end

Base.@propagate_inbounds function _op_for_max!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] = _max_fun(x[i], f(y[i]))
    end
    x
end

function row_minimum(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    T = Core.Compiler.return_type(f, Tuple{CT})
    init0 = _missings(T, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_min!(x, y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_min!(x, y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end
row_minimum(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_minimum(ds, identity, cols; threads = threads)

function row_maximum(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    T = Core.Compiler.return_type(f, Tuple{CT})
    init0 = _missings(T, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_max!(x, y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        mapreduce(identity, (x,y) -> _op_for_max!(x, y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end
    init0
end
row_maximum(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_maximum(ds, identity, cols; threads = threads)

Base.@propagate_inbounds function _op_for_argminmax!(x, y, f, vals, idx, missref, lo, hi)
    idx[] += 1
    @simd for i in lo:hi
        if !ismissing(vals[i]) && isequal(vals[i], f(y[i])) && isequal(x[i], missref)
            x[i] = idx[]
        end
    end
    x
end

function row_argmin(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    minvals = row_minimum(ds, f, cols; threads = threads)
    colnames_pa = allowmissing(PooledArray(_names(ds)[colsidx]))
    push!(colnames_pa, missing)
    missref = get(colnames_pa.invpool, missing, missing)
    init0 = fill(missref, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        idx = [Ref{Int}(0) for _ in 1:Threads.nthreads()]
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_argminmax!(x, y, f, minvals, idx[i], missref, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        idx = Ref{Int}(0)
        mapreduce(identity, (x,y) -> _op_for_argminmax!(x, y, f, minvals, idx, missref, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end

    colnames_pa.refs = init0
    colnames_pa
end
row_argmin(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_argmin(ds, identity, cols, threads = threads)

function row_argmax(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    maxvals = row_maximum(ds, f, cols; threads = threads)
    colnames_pa = allowmissing(PooledArray(_names(ds)[colsidx]))
    push!(colnames_pa, missing)
    missref = get(colnames_pa.invpool, missing, missing)
    init0 = fill(missref, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        idx = [Ref{Int}(0) for _ in 1:Threads.nthreads()]
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            mapreduce(identity, (x,y) -> _op_for_argminmax!(x, y, f, maxvals, idx[i], missref, lo, hi), view(_columns(ds),colsidx), init = init0)
        end
    else
        idx = Ref{Int}(0)
        mapreduce(identity, (x,y) -> _op_for_argminmax!(x, y, f, maxvals, idx, missref, 1, length(x)), view(_columns(ds),colsidx), init = init0)
    end

    colnames_pa.refs = init0
    colnames_pa
end
row_argmax(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); threads = true) = row_argmax(ds, identity, cols, threads = threads)


# TODO better function for the first component of operator
function _row_wise_var(ss, sval, n, dof, T)
    res = Vector{T}(undef, length(ss))
    for i in 1:length(ss)
        if n[i] == 0
            res[i] = missing
        elseif n[i] == 1
            res[i] = zero(T)
        else
            res[i] = ss[i]/n[i] - (sval[i]/n[i])*(sval[i]/n[i])
            if dof
                res[i] = (n[i] * res[i])/(n[i]-1)
            end
        end
    end
    res
end

# TODO needs type stability
# TODO need abs2 for calculations
function row_var(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); dof = true, threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    CT = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    T = Core.Compiler.return_type(f, Tuple{CT})
    _sq_(x) = x^2
    ss = row_sum(ds, _sq_ ∘ f, cols; threads = threads)
    sval = row_sum(ds, f, cols; threads = threads)
    n = row_count(ds, x -> !ismissing(x), cols; threads = threads)
    T2 = Core.Compiler.return_type(/, Tuple{eltype(ss), eltype(n)})
    res = Vector{Union{Missing, T2}}(undef, length(ss))
    res .= ss ./ n .- (sval ./ n) .^ 2
    if dof
        res .= (n .* res) ./ (n .- 1)
        res .= ifelse.(n .== 1, missing, res)
    end
    res
    # _row_wise_var(ss, sval, n, dof, T)
end
row_var(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); dof = true, threads = true) = row_var(ds, identity, cols, dof = dof, threads = threads)

function row_std(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); dof = true, threads = true)
    sqrt.(row_var(ds, f, cols, dof = dof, threads = threads))
end
row_std(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); dof = true, threads = true) = row_std(ds, identity, cols, dof = dof, threads = threads)

Base.@propagate_inbounds function _op_for_cumsum_skip!(x, y, lo, hi)
    @simd for i in lo:hi
        x[i] = _add_sum(x[i], y[i])
    end
    @simd for i in lo:hi
        y[i] = ifelse(ismissing(y[i]), missing, x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_cumsum_ignore!(x, y, lo, hi)
    @simd for i in lo:hi
        y[i] = _add_sum(x[i], y[i])
    end
    y
end


function row_cumsum!(ds::Dataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    !(missings in (:ignore, :skip)) && throw(ArgumentError("`missings` can be either `:ignore` or `:skip`"))
    colsidx = index(ds)[cols]
    T = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    if T <: Union{Missing, INTEGERS}
        T <: Union{Missing, SMALLSIGNED}
        T = T <: Union{Missing, SMALLSIGNED, Bool} ? Union{Int, Missing} : T
        T = T <: Union{Missing, SMALLUNSIGNED} ?  Union{Missing, UInt} : T
    end
    for i in colsidx
        if eltype(ds[!, i]) >: Missing
            _columns(ds)[i] = convert(Vector{Union{Missing, T}}, _columns(ds)[i])
        else
            _columns(ds)[i] = convert(Vector{T}, _columns(ds)[i])
        end
    end
    init0 = _missings(T, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if missings == :ignore
                mapreduce(identity, (x,y) -> _op_for_cumsum_ignore!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_cumsum_skip!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if missings == :ignore
            mapreduce(identity, (x,y) -> _op_for_cumsum_ignore!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_cumsum_skip!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        end
    end

    removeformat!(ds, cols)
    any(index(ds).sortedcols .∈ Ref(colsidx)) && _reset_grouping_info!(ds)
    _modified(_attributes(ds))
    ds
end

function row_cumsum(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    dscopy = copy(ds)
    row_cumsum!(dscopy, cols, missings = missings, threads = threads)
    dscopy
end

Base.@propagate_inbounds function _op_for_cumprod_skip!(x, y, lo, hi)
    @simd for i in lo:hi
        x[i] = _mul_prod(x[i], y[i])
    end
    @simd for i in lo:hi
        y[i] = ifelse(ismissing(y[i]), missing, x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_cumprod_ignore!(x, y, lo, hi)
    @simd for i in lo:hi
        y[i] = _mul_prod(x[i], y[i])
    end
    y
end

function row_cumprod!(ds::Dataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    !(missings in (:ignore, :skip)) && throw(ArgumentError("`missings` can be either `:ignore` or `:skip`"))
    colsidx = index(ds)[cols]
    T = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    for i in colsidx
        if eltype(ds[!, i]) >: Missing
            _columns(ds)[i] = convert(Vector{Union{Missing, T}}, _columns(ds)[i])
        else
            _columns(ds)[i] = convert(Vector{T}, _columns(ds)[i])
        end
    end
    init0 = _missings(T, nrow(ds))


    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if missings == :ignore
                mapreduce(identity, (x,y) -> _op_for_cumprod_ignore!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_cumprod_skip!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if missings == :ignore
            mapreduce(identity, (x,y) -> _op_for_cumprod_ignore!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_cumprod_skip!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        end
    end

    removeformat!(ds, cols)
    any(index(ds).sortedcols .∈ Ref(colsidx)) && _reset_grouping_info!(ds)
    _modified(_attributes(ds))
    ds
end

function row_cumprod(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    dscopy = copy(ds)
    row_cumprod!(dscopy, cols; missings = missings, threads = threads)
    dscopy
end


Base.@propagate_inbounds function _op_for_cummin_skip!(x, y, lo, hi)
    @simd for i in lo:hi
        x[i] = _min_fun(x[i], y[i])
    end
    @simd for i in lo:hi
        y[i] = ifelse(ismissing(y[i]), missing, x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_cummin_ignore!(x, y, lo, hi)
    @simd for i in lo:hi
        y[i] = _min_fun(x[i], y[i])
    end
    y
end

function row_cummin!(ds::Dataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    !(missings in (:ignore, :skip)) && throw(ArgumentError("`missings` can be either `:ignore` or `:skip`"))
    colsidx = index(ds)[cols]
    T = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    for i in colsidx
        if eltype(ds[!, i]) >: Missing
            _columns(ds)[i] = convert(Vector{Union{Missing, T}}, _columns(ds)[i])
        else
            _columns(ds)[i] = convert(Vector{T}, _columns(ds)[i])
        end
    end
    init0 = _missings(T, nrow(ds))


    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if missings == :ignore
                mapreduce(identity, (x,y) -> _op_for_cummin_ignore!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_cummin_skip!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if missings == :ignore
            mapreduce(identity, (x,y) -> _op_for_cummin_ignore!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_cummin_skip!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        end
    end

    removeformat!(ds, cols)
    any(index(ds).sortedcols .∈ Ref(colsidx)) && _reset_grouping_info!(ds)
    _modified(_attributes(ds))
    ds
end
# row_cumsum!(ds::AbstractDataset, cols = names(ds, Union{Missing, Number})) = row_cumsum!(identity, ds, cols)

function row_cummin(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    dscopy = copy(ds)
    row_cummin!(dscopy, cols, missings = missings, threads = threads)
    dscopy
end


Base.@propagate_inbounds function _op_for_cummax_skip!(x, y, lo, hi)
    @simd for i in lo:hi
        x[i] = _max_fun(x[i], y[i])
    end
    @simd for i in lo:hi
        y[i] = ifelse(ismissing(y[i]), missing, x[i])
    end
    x
end

Base.@propagate_inbounds function _op_for_cummax_ignore!(x, y, lo, hi)
    @simd for i in lo:hi
        y[i] = _max_fun(x[i], y[i])
    end
    y
end

function row_cummax!(ds::Dataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    !(missings in (:ignore, :skip)) && throw(ArgumentError("`missings` can be either `:ignore` or `:skip`"))
    colsidx = index(ds)[cols]
    T = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    for i in colsidx
        if eltype(ds[!, i]) >: Missing
            _columns(ds)[i] = convert(Vector{Union{Missing, T}}, _columns(ds)[i])
        else
            _columns(ds)[i] = convert(Vector{T}, _columns(ds)[i])
        end
    end
    init0 = _missings(T, nrow(ds))


    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if missings == :ignore
                mapreduce(identity, (x,y) -> _op_for_cummax_ignore!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            else
                mapreduce(identity, (x,y) -> _op_for_cummax_skip!(x, y, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if missings == :ignore
            mapreduce(identity, (x,y) -> _op_for_cummax_ignore!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        else
            mapreduce(identity, (x,y) -> _op_for_cummax_skip!(x, y, 1, length(init0)), view(_columns(ds),colsidx), init = init0)
        end
    end

    removeformat!(ds, cols)
    any(index(ds).sortedcols .∈ Ref(colsidx)) && _reset_grouping_info!(ds)
    _modified(_attributes(ds))
    ds
end
# row_cumsum!(ds::AbstractDataset, cols = names(ds, Union{Missing, Number})) = row_cumsum!(identity, ds, cols)

function row_cummax(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); missings = :ignore, threads = true)
    dscopy = copy(ds)
    row_cummax!(dscopy, cols, missings = missings, threads = threads)
    dscopy
end


function row_stdze!(ds::Dataset , cols = names(ds, Union{Missing, Number}); threads = true)
    colsidx = index(ds)[cols]

    meandata = row_mean(ds, colsidx; threads = threads)
    stddata = row_std(ds, colsidx; threads = threads)
    _stdze_fun(x) = ifelse.(isequal.(stddata, 0), missing, (x .- meandata) ./ stddata)

    for i in 1:length(colsidx)
        _columns(ds)[colsidx[i]] = _stdze_fun(_columns(ds)[colsidx[i]])
    end
    removeformat!(ds, colsidx)
    any(index(ds).sortedcols .∈ Ref(colsidx)) && _reset_grouping_info!(ds)
    _modified(_attributes(ds))
    ds
end


function row_stdze(ds::AbstractDataset , cols = names(ds, Union{Missing, Number}); threads = true)
    dscopy = copy(ds)
    row_stdze!(dscopy, cols; threads = threads)
    dscopy
end

function row_rescale!(ds::Dataset, cols=names(ds, Union{Missing,Number}); range, threads=true)
  colsidx = IMD.index(ds)[cols]

  mindata = IMD.row_minimum(ds, colsidx; threads=threads)
  maxdata = IMD.row_maximum(ds, colsidx; threads=threads)
  max_min = maxdata .- mindata

  _rescale_fun(x) = ifelse.(isequal.(max_min, 0), missing, range[1] .+ (((x .- mindata) .* (range[2] - range[1])) ./ max_min))

  for i in 1:length(colsidx)
    IMD._columns(ds)[colsidx[i]] = _rescale_fun(IMD._columns(ds)[colsidx[i]])
  end
  removeformat!(ds, colsidx)
  any(IMD.index(ds).sortedcols .∈ Ref(colsidx)) && IMD._reset_grouping_info!(ds)
  IMD._modified(IMD._attributes(ds))
  ds
end

function row_rescale(ds::AbstractDataset, cols=names(ds, Union{Missing,Number}); range, threads=true)
  dscopy = copy(ds)
  row_rescale!(dscopy, cols; range=range, threads=threads)
  dscopy
end


function row_sort!(ds::Dataset, cols = names(ds, Union{Missing, Number}); kwargs...)
    colsidx = index(ds)[cols]
    T = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    m = Matrix{T}(ds[!, colsidx])
    sort!(m; dims = 2, kwargs...)
    for i in 1:length(colsidx)
        _columns(ds)[colsidx[i]] = m[:, i]
    end
    removeformat!(ds, cols)
    any(index(ds).sortedcols .∈ Ref(colsidx)) && _reset_grouping_info!(ds)
    _modified(_attributes(ds))
    ds
end

function row_sort(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); kwargs...)
    dscopy = copy(ds)
    row_sort!(dscopy, cols; kwargs...)
    dscopy
end

Base.@propagate_inbounds function _op_for_issorted!(x, y, res, lt, lo, hi)
    @simd for i in lo:hi
        res[i] ? res[i] = !lt(y[i], x[i]) : nothing
    end
    y
end
Base.@propagate_inbounds function _op_for_issorted_rev!(x, y, res, lt, lo, hi)
    @simd for i in lo:hi
        res[i] ? res[i] = !lt(x[i], y[i]) : nothing
    end
    y
end

function row_issorted(ds::AbstractDataset, cols; rev = false, lt = isless, threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    init0 = ones(Bool, nrow(ds))

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if rev
                mapreduce(identity, (x,y) -> _op_for_issorted_rev!(x, y, init0, lt, lo, hi), view(_columns(ds),colsidx))
            else
                mapreduce(identity, (x,y) -> _op_for_issorted!(x, y, init0, lt, lo, hi), view(_columns(ds),colsidx))
            end
        end
    else
        if rev
            mapreduce(identity, (x,y) -> _op_for_issorted_rev!(x, y, init0, lt, 1, length(init0)), view(_columns(ds),colsidx))
        else
            mapreduce(identity, (x,y) -> _op_for_issorted!(x, y, init0, lt, 1, length(init0)), view(_columns(ds),colsidx))
        end
    end
    init0
end

# TODO is it possible to have a faster row_count_unique??
function _fill_prehashed!(prehashed, y, f, n, j)
    @views copy!(prehashed[:, j] , _Prehashed.(hash.(f.(y))))
end

function _fill_dict_and_add!(init0, dict, prehashed, n, p)
    for i in 1:n
        for j in 1:p
            if !haskey(dict, prehashed[i, j])
                get!(dict, prehashed[i, j], nothing)
                init0[i] += 1
            end
        end
        empty!(dict)
    end
end

# This is not working - because we only the hash values and in many cases like 2.1 and 4611911198408756429 the hash is the same
# function row_nunique(ds::AbstractDataset, f::Function, cols = names(ds, Union{Missing, Number}); count_missing = true)
#     colsidx = multiple_getindex(index(ds), cols)
#     prehashed = Matrix{_Prehashed}(undef, size(ds,1), length(colsidx))
#     allcols = view(_columns(ds),colsidx)

#     for j in 1:size(prehashed,2)
#         _fill_prehashed!(prehashed, allcols[j], f, size(ds,1), j)
#     end

#     init0 = zeros(Int32, size(ds,1))
#     dict = Dict{_Prehashed, Nothing}()
#     _fill_dict_and_add!(init0, dict, prehashed, size(ds,1), length(colsidx))
#     if count_missing
#         return init0
#     else
#         return init0 .- row_any(ds, ismissing, cols)
#     end
# end
# row_nunique(ds::AbstractDataset, cols = names(ds, Union{Missing, Number}); count_missing = true) = row_nunique(ds, identity, cols; count_missing = count_missing)

Base.@propagate_inbounds function _op_for_hash!(x, y, f, lo, hi)
    @simd for i in lo:hi
        x[i] = hash(f(y[i]), x[i])
    end
    x
end

function row_hash(ds::AbstractDataset, f::Union{AbstractVector{<:Function}, Function}, cols = :; threads = true)
    colsidx = multiple_getindex(index(ds), cols)
    init0 = zeros(UInt64, nrow(ds))

    multi_f = false
    if f isa AbstractVector
        @assert length(f) == length(colsidx) "number of provided functions must match the number of selected columns"
        multi_f = true
    end

    if threads
        cz = div(length(init0), Threads.nthreads())
        Threads.@threads for i in 1:Threads.nthreads()
            lo = (i-1)*cz+1
            i == Threads.nthreads() ? hi = length(init0) : hi = i*cz
            if multi_f
                mapreduce_index(f, (x, y, func) -> _op_for_hash!(x, y, func, lo, hi), view(_columns(ds),colsidx), init0)
            else
                mapreduce(identity, (x,y) -> _op_for_hash!(x, y, f, lo, hi), view(_columns(ds),colsidx), init = init0)
            end
        end
    else
        if multi_f
            mapreduce_index(f, (x, y, func) -> _op_for_hash!(x, y, func, 1, length(x)), view(_columns(ds),colsidx), init0)
        else
            mapreduce(identity, (x,y) -> _op_for_hash!(x, y, f, 1, length(x)), view(_columns(ds),colsidx), init = init0)
        end
    end
    init0
end
row_hash(ds::AbstractDataset, cols = :; threads = true) = row_hash(ds, identity, cols; threads = threads)

function _convert_uint8_to_string!(res, init0, curr_pos, ds, threads)
    if threads
        Threads.@threads for i in 1:nrow(ds)
            res[i] = String(view(init0, 1:curr_pos[i]-2, i))
        end
    else
        for i in 1:nrow(ds)
            res[i] = String(view(init0, 1:curr_pos[i]-2, i))
        end
    end
end
function _add_last_for_join!(init0, curr_pos, ds, last_uint, last_len, threads)
    if threads
        Threads.@threads for i in 1:nrow(ds)
            init0[curr_pos[i]-1:curr_pos[i]+last_len-2, i] = last_uint
            curr_pos[i] += last_len-1
        end
    else
        for i in 1:nrow(ds)
            init0[curr_pos[i]-1:curr_pos[i]+last_len-2, i] = last_uint
            curr_pos[i] += last_len-1
        end
    end
end

function row_join(ds::AbstractDataset, cols = :; threads = true, delim::AbstractString = ",", last::AbstractString = "")
    colsidx = multiple_getindex(index(ds), cols)

    max_line_size = maximum(byrow(ds, sum, colsidx, by = y->ncodeunits(__STRING(y)), threads = threads))
    max_line_size += ncodeunits(delim)*(length(colsidx)) + ncodeunits(last)+1
    init0 = Matrix{UInt8}(undef, max_line_size, nrow(ds))
    curr_pos = ones(Int, nrow(ds))

    delimiter = Base.CodeUnits(delim)
    row_join!(init0, curr_pos, ds, repeat([identity], length(colsidx)-1), view(colsidx, 1:length(colsidx)-1); delim = delimiter, quotechar = nothing, threads = threads)
    if length(last)>0
        delimiter = Base.CodeUnits(last)
    end
    if length(colsidx) > 1
        _add_last_for_join!(init0, curr_pos, ds, delimiter, length(delimiter), threads)
    end
    row_join!(init0, curr_pos, ds, [identity], colsidx[length(colsidx)]; delim = delimiter, quotechar = nothing, threads = threads)

    res = Vector{Union{String, Missing}}(undef, nrow(ds))
    _convert_uint8_to_string!(res, init0, curr_pos, ds, threads)
    res

end


function _fill_col!(inmat, column, rows, j)
    for i in 1:length(rows)
        inmat[j, i] = column[rows[i]]
    end
end
function _fill_matrix!(inmat, all_data, rows, cols)
    for j in 1:length(cols)
        _fill_col!(inmat, all_data[j], rows, j)
    end
end

function row_generic(ds::AbstractDataset, f::Function, cols::MultiColumnIndex)
    colsidx = multiple_getindex(index(ds), cols)
    if length(colsidx) == 2
        try
            allowmissing(f.(_columns(ds)[colsidx[1]], _columns(ds)[colsidx[2]]))
        catch e
            if e isa MethodError
                _row_generic(ds, f, colsidx)
            else
                rethrow(e)
            end
        end
    else
        _row_generic(ds, f, colsidx)
    end
end
function _row_generic(ds::AbstractDataset, f::Function, colsidx)
    T = mapreduce(eltype, promote_type, view(_columns(ds),colsidx))
    inmat = Matrix{T}(undef, length(colsidx), min(1000, nrow(ds)))

    all_data = view(_columns(ds), colsidx)
    _fill_matrix!(inmat, all_data, 1:min(1000, nrow(ds)), colsidx)
    res_temp = allowmissing(f.(eachcol(inmat)))
    if !(typeof(res_temp) <:  AbstractVector)
        throw(ArgumentError("output of `f` must be a vector"))
    end

    # if length(res_temp[1]) > 1
    #     throw(ArgumentError("The matrix output is not supported"))
    #     res = similar(res_temp, nrow(ds), size(res_temp,2))
    # elseif length(res_temp[1]) == 1
    res = similar(res_temp, nrow(ds))
    # else
        # throw(ArgumentError("the result cannot be with zero dimension"))

    if nrow(ds)>1000
        if size(res, 2) == 1
            view(res, 1:1000) .= res_temp
            _row_generic_vec!(res, ds, f, colsidx, Val(T))
        else
            view(res, 1:1000, :) .= res_temp
            _row_generic_mat!(res, ds, f, colsidx)
        end
    else
        return res_temp
    end
    return res
end

function _row_generic_vec!_barrier(res, f, inmat, all_data, chunck, colsidx)

    for i in 1:chunck
        t_st = i*1000 + 1
        i == chunck ? t_en = length(res) : t_en = (i+1)*1000
        _fill_matrix!(inmat, all_data, t_st:t_en, colsidx)
        for k in t_st:t_en
            res[k] = f(view(inmat, :, k - t_st + 1))
        end
    end
end

function _row_generic_vec!(res, ds, f, colsidx, ::Val{T}) where T
    all_data = view(_columns(ds), colsidx)
    chunck = div(length(res) - 1000, 1000)
    max_cz = length(res) - 1000 - (chunck - 1)* 1000
    inmat = Matrix{T}(undef, length(colsidx), max_cz)
    # make sure that the variable inside the loop are not the same as the out of scope one
    # for i in 1:chunck
    #     t_st = i*1000 + 1
    #     i == chunck ? t_en = length(res) : t_en = (i+1)*1000
    #     _fill_matrix!(inmat, all_data, t_st:t_en, colsidx)
    #     for k in t_st:t_en
    #         res[k] = f(view(inmat, k - t_st + 1, :))
    #     end
    # end
    _row_generic_vec!_barrier(res, f, inmat, all_data, chunck, colsidx)
end
