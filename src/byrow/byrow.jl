struct _DUMMY_STRUCT
end

# anymissing(::_DUMMY_STRUCT) = false
nunique(::_DUMMY_STRUCT) =  false
stdze!(::_DUMMY_STRUCT) = false
stdze(::_DUMMY_STRUCT) = false
select(::_DUMMY_STRUCT) = false
rescale(::_DUMMY_STRUCT) = false
rescale(::_DUMMY_STRUCT) = false

byrow(ds::AbstractDataset, ::typeof(Base.sum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_sum(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.sum), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, sum, [col]; by = by, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.sum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_sum(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.sum), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, sum, [col]; by = by, threads = threads)


byrow(ds::AbstractDataset, ::typeof(prod), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_prod(ds, by, cols; threads = threads)
byrow(ds::AbstractDataset, ::typeof(prod), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, prod, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(count), cols::MultiColumnIndex = :; by = isequal(true), threads = nrow(ds) > Threads.nthreads()*10) = row_count(ds, by, cols; threads =threads)
byrow(ds::AbstractDataset, ::typeof(count), col::ColumnIndex; by = isequal(true), threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, count, [col], by = by, threads = threads)

# byrow(ds::AbstractDataset, ::typeof(anymissing), cols::MultiColumnIndex = names(ds, Union{Missing, Number})) = row_anymissing(ds, cols)

function expand_Base_Fix(f, f2)
	if f isa Base.Fix2
		return _bool(x->f.f(f2(x), f.x))
	elseif f isa Base.Fix1
		return _bool(x->f.f(f.x, f2(x)))
	else
		return x->f(f2(x))
	end
end

_check_missing(x, missings) = ismissing(x) ? missings : x

function expand_Base_Fix(f, f2, missings)
	if f isa Base.Fix2
		return _bool(x->_check_missing(f.f(f2(x), f.x), missings))
	elseif f isa Base.Fix1
		return _bool(x->_check_missing(f.f(f.x,f2(x)), missings))
	else
		return x->_check_missing(f(f2(x)), missings)
	end
end

function byrow(ds::AbstractDataset, ::typeof(any), cols::MultiColumnIndex = :; missings = missing, by = isequal(true), threads = nrow(ds) > Threads.nthreads()*10, mapformats = false)
	colsidx = multiple_getindex(index(ds), cols)
	if by isa AbstractVector
		if mapformats
			if !ismissing(missings)
				by = map((x,y)->expand_Base_Fix(x, getformat(ds, y), missings), by, colsidx)
			else
				by = map((x,y)->expand_Base_Fix(x, getformat(ds, y)), by, colsidx)
			end
		else
			if !ismissing(missings)
			    by = map(y -> x -> ismissing(x) ? missings : y(x), by)
			end
		end
	else
		if mapformats
			if !ismissing(missings)
				by = map(y->expand_Base_Fix(by, getformat(ds, y), missings), colsidx)
			else
				by = map(y->expand_Base_Fix(by, getformat(ds, y)), colsidx)
			end
		else
			if !ismissing(missings)
				by = first(map(y -> x -> ismissing(x) ? missings : y(x), [by]))
			end
		end
	end
	
	row_any(ds, by, colsidx, threads = threads)

end

byrow(ds::AbstractDataset, ::typeof(any), col::ColumnIndex; missings = missing, by = isequal(true), threads = nrow(ds) > Threads.nthreads()*10, mapformats = false) = byrow(ds, any, [col]; missings = missings, by = by, threads = threads, mapformats = mapformats)

function byrow(ds::AbstractDataset, ::typeof(all), cols::MultiColumnIndex = :; missings = missing, by = isequal(true), threads = nrow(ds) > Threads.nthreads()*10, mapformats = false)
	colsidx =  multiple_getindex(index(ds), cols)
	if by isa AbstractVector
		if mapformats
			if !ismissing(missings)
				by = map((x,y)->expand_Base_Fix(x, getformat(ds, y), missings), by, colsidx)
			else
				by = map((x,y)->expand_Base_Fix(x, getformat(ds, y)), by, colsidx)
			end
		else
			if !ismissing(missings)
				by = map(y -> x -> ismissing(x) ? missings : y(x), by)
			end
		end
	else
		if mapformats
			if !ismissing(missings)
				by = map(y->expand_Base_Fix(by, getformat(ds, y), missings), colsidx)
			else
				by = map(y->expand_Base_Fix(by, getformat(ds, y)), colsidx)
			end
		else
			if !ismissing(missings)
				by = first(map(y -> x -> ismissing(x) ? missings : y(x), [by]))
			end
		end
	end
	row_all(ds, by, colsidx, threads = threads)
end
byrow(ds::AbstractDataset, ::typeof(all), col::ColumnIndex; missings = missing, by = isequal(true), threads = nrow(ds) > Threads.nthreads()*10, mapformats = false) = byrow(ds, all, [col]; missings = missings, by = by, threads = threads, mapformats = mapformats)

byrow(ds::AbstractDataset, ::typeof(isequal), cols::MultiColumnIndex; with = nothing, threads = nrow(ds) > Threads.nthreads()*10) = row_isequal(ds, cols, by = with, threads = threads)
byrow(ds::AbstractDataset, ::typeof(isequal), cols::ColumnIndex; with = nothing, threads = nrow(ds) > Threads.nthreads()*10) = row_isequal(ds, cols, by = with, threads = threads)

if VERSION >= v"1.8"
	byrow(ds::AbstractDataset, ::typeof(allequal), cols::MultiColumnIndex; threads = nrow(ds) > Threads.nthreads()*10) = row_isequal(ds, cols, by = nothing, threads = threads)
	byrow(ds::AbstractDataset, ::typeof(allequal), cols::ColumnIndex;  threads = nrow(ds) > Threads.nthreads()*10) = row_isequal(ds, cols, by = nothing, threads = threads)
end


byrow(ds::AbstractDataset, ::typeof(isless), cols::MultiColumnIndex; with, threads = nrow(ds) > Threads.nthreads()*10, rev::Bool = false, lt = isless) = row_isless(ds, cols, with, threads = threads, rev = rev, lt = lt)
byrow(ds::AbstractDataset, ::typeof(isless), col::ColumnIndex; with, threads = nrow(ds) > Threads.nthreads()*10, rev::Bool = false, lt = isless) = row_isless(ds, [col], with, threads = threads, rev = rev, lt = lt)

byrow(ds::AbstractDataset, ::typeof(in), cols::MultiColumnIndex; item, threads = nrow(ds) > Threads.nthreads()*10, eq = isequal) = row_in(ds, cols, item; threads = threads, eq = eq)

byrow(ds::AbstractDataset, ::typeof(findfirst), cols::MultiColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10, item = nothing, eq = isequal) = row_findfirst(ds, by, cols; threads = threads, item = item, eq = eq)
byrow(ds::AbstractDataset, ::typeof(findlast), cols::MultiColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10, item = nothing, eq = isequal) = row_findlast(ds, by, cols; threads = threads, item = item, eq = eq)

byrow(ds::AbstractDataset, ::typeof(select), cols::MultiColumnIndex; with, threads = nrow(ds) > Threads.nthreads()*10) = row_select(ds, cols, with, threads = threads)

byrow(ds::AbstractDataset, ::typeof(fill!), cols::MultiColumnIndex; with , by = ismissing, threads = nrow(ds) > Threads.nthreads()*10, rolling = false) = row_fill!(ds, cols, with, f = by, threads = threads, rolling = rolling)
byrow(ds::AbstractDataset, ::typeof(fill!), col::ColumnIndex; with , by = ismissing, threads = nrow(ds) > Threads.nthreads()*10, rolling = false) = byrow(ds, fill!, [col], with = with, by = by, threads = threads, rolling = rolling)
byrow(ds::AbstractDataset, ::typeof(fill), cols::MultiColumnIndex; with , by = ismissing, threads = nrow(ds) > Threads.nthreads()*10, rolling = false) = row_fill!(copy(ds), cols, with, f = by, threads = threads, rolling = rolling)
byrow(ds::AbstractDataset, ::typeof(fill), col::ColumnIndex; with , by = ismissing, threads = nrow(ds) > Threads.nthreads()*10, rolling = false) = byrow(copy(ds), fill!, [col], with = with, by = by, threads = threads, rolling = rolling)

byrow(ds::AbstractDataset, ::typeof(coalesce), cols::MultiColumnIndex; threads = nrow(ds) > Threads.nthreads()*10) = row_coalesce(ds, cols; threads = threads)

byrow(ds::AbstractDataset, ::typeof(mean), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_mean(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(mean), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, mean, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.maximum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_maximum(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.maximum), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, maximum, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.minimum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_minimum(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.minimum), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, minimum, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.argmin), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_argmin(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.argmin), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, argmin, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.argmax), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_argmax(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.argmax), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, argmax, [col]; by = by, threads = threads)


byrow(ds::AbstractDataset, ::typeof(IMD.maximum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_maximum(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.maximum), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, maximum, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(IMD.minimum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_minimum(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.minimum), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, minimum, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(IMD.argmin), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_argmin(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.argmin), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, argmin, [col]; by = by, threads = threads)

byrow(ds::AbstractDataset, ::typeof(IMD.argmax), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, threads = nrow(ds) > Threads.nthreads()*10) = row_argmax(ds, by, cols, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.argmax), col::ColumnIndex; by = identity, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, argmax, [col]; by = by, threads = threads)






byrow(ds::AbstractDataset, ::typeof(var), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, dof = true, threads = nrow(ds) > Threads.nthreads()*10) = row_var(ds, by, cols; dof = dof, threads = threads)
byrow(ds::AbstractDataset, ::typeof(var), col::ColumnIndex; by = identity, dof = true, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, var, [col]; by = by, dof = dof, threads = threads)

byrow(ds::AbstractDataset, ::typeof(std), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, dof = true, threads = nrow(ds) > Threads.nthreads()*10) = row_std(ds, by, cols; dof = dof, threads = threads)
byrow(ds::AbstractDataset, ::typeof(std), col::ColumnIndex; by = identity, dof = true, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, std, [col]; by = by, dof = dof, threads = threads)

function byrow(ds::AbstractDataset, ::typeof(nunique), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); by = identity, count_missing = true, threads=nrow(ds)>1000) 
	res = byrow(ds, x->length(Set(Base.Generator(by, x))), cols, threads=threads)
	if count_missing
		return res
	else
		return res .- row_any(ds, ismissing, cols)
	end
end
byrow(ds::AbstractDataset, ::typeof(nunique), col::ColumnIndex; by = identity, count_missing = true) = byrow(ds, nunique, [col]; by = by, count_missing = count_missing)



byrow(ds::AbstractDataset, ::typeof(Base.cumsum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumsum(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.cumsum), col::ColumnIndex; missings = :ignore, threads = nrow(ds)> Threads.nthreads()) = byrow(ds, cumsum, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.cumprod!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumprod!(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.cumprod!), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cumprod!, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.cumprod), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumprod(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.cumprod), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cumprod, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(Base.cumsum!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumsum!(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(Base.cumsum!), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cumsum!, [col], missings = missings, threads = threads)



byrow(ds::AbstractDataset, ::typeof(IMD.cumsum), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumsum(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.cumsum), col::ColumnIndex; missings = :ignore, threads = nrow(ds)> Threads.nthreads()) = byrow(ds, cumsum, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(IMD.cumprod!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumprod!(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.cumprod!), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cumprod!, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(IMD.cumprod), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumprod(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.cumprod), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cumprod, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(IMD.cumsum!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cumsum!(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(IMD.cumsum!), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cumsum!, [col], missings = missings, threads = threads)




byrow(ds::AbstractDataset, ::typeof(cummin!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cummin!(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(cummin!), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cummin!, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(cummin), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cummin(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(cummin), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cummin, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(cummax!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cummax!(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(cummax!), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cummax!, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(cummax), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = row_cummax(ds, cols, missings = missings, threads = threads)
byrow(ds::AbstractDataset, ::typeof(cummax), col::ColumnIndex; missings = :ignore, threads = nrow(ds)>Threads.nthreads()*10) = byrow(ds, cummax, [col], missings = missings, threads = threads)

byrow(ds::AbstractDataset, ::typeof(sort), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); threads = true, kwargs...) = threads ? hp_row_sort(ds, cols; kwargs...) : row_sort(ds, cols; kwargs...)
byrow(ds::AbstractDataset, ::typeof(sort), col::ColumnIndex; threads = true, kwargs...) = byrow(ds, sort, [col]; threads = threads, kwargs...)

byrow(ds::AbstractDataset, ::typeof(sort!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); threads = true, kwargs...) = threads ? hp_row_sort!(ds, cols; kwargs...) : row_sort!(ds, cols; kwargs...)
# byrow(ds::AbstractDataset, ::typeof(sort!), col::ColumnIndex; threads = true, kwargs...) = byrow(ds, sort!, [col]; threads = threads, kwargs...)

byrow(ds::AbstractDataset, ::typeof(issorted), cols::MultiColumnIndex; threads = nrow(ds) > Threads.nthreads()*10, rev = false, lt = isless) = row_issorted(ds, cols; rev = rev, lt = lt, threads = threads)

byrow(ds::AbstractDataset, ::typeof(stdze), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); threads = true) = row_stdze(ds, cols, threads = threads)

byrow(ds::AbstractDataset, ::typeof(stdze!), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); threads = true) = row_stdze!(ds, cols, threads = threads)

byrow(ds::AbstractDataset, ::typeof(rescale), cols::MultiColumnIndex=names(ds, Union{Missing,Number}); range=[0, 1], threads=true) = row_rescale(ds, cols, range=range, threads=threads)

byrow(ds::AbstractDataset, ::typeof(rescale!), cols::MultiColumnIndex=names(ds, Union{Missing,Number}); range=[0, 1], threads=true) = row_rescale!(ds, cols, range=range, threads=threads)

function byrow(ds::AbstractDataset, ::typeof(hash), cols::MultiColumnIndex = :; by = identity, mapformats = false, threads = nrow(ds) > Threads.nthreads()*10)
	colsidx = multiple_getindex(index(ds), cols)
	if mapformats
		by = map(y->expand_Base_Fix(by, getformat(ds, y)), colsidx)
	end
	row_hash(ds, by, cols, threads = threads)
end

byrow(ds::AbstractDataset, ::typeof(hash), col::ColumnIndex; by = identity, mapformats = false, threads = nrow(ds) > Threads.nthreads()*10) = byrow(ds, hash, [col]; by = by, mapformats = mapformats, threads = threads)

byrow(ds::AbstractDataset, ::typeof(join), col::MultiColumnIndex; threads = nrow(ds) > Threads.nthreads()*10, delim = "", last = "") = row_join(ds, col, threads = threads, delim = delim, last = last)

byrow(ds::AbstractDataset, ::typeof(mapreduce), cols::MultiColumnIndex = names(ds, Union{Missing, Number}); op = .+, f = identity,  init = _missings(mapreduce(eltype, promote_type, view(_columns(ds),index(ds)[cols])), nrow(ds)), kwargs...) = mapreduce(f, op, eachcol(ds[!, cols]), init = init; kwargs...)


function byrow(ds::AbstractDataset, f::Function, cols::MultiColumnIndex; threads = nrow(ds)>1000)
	colsidx = multiple_getindex(index(ds), cols)
	length(colsidx) == 1 && return byrow(ds, f, colsidx[1]; threads = threads)
	threads ?  hp_row_generic(ds, f, cols) : row_generic(ds, f, cols)
end

# TODO do we need to make sure that the result is Union of Missing?
function byrow(ds::AbstractDataset, f::Function, cols::NTuple{N, ColumnIndex}) where N
	cols_idx = [index(ds)[cols[i]] for i in 1:length(cols)]
	f.(view(_columns(ds), cols_idx)...)
end

function byrow(ds::AbstractDataset, f::Function, col::ColumnIndex; threads = nrow(ds)>1000, allowmissing::Bool = true)
	if threads
		T = Core.Compiler.return_type(f, Tuple{our_nonmissingtype(eltype(ds[!, col]))})
		if allowmissing
			res = Vector{Union{Missing, T}}(undef, nrow(ds))
		else
			res = Vector{T}(undef, nrow(ds))
		end
		_hp_map_a_function!(res, f, _columns(ds)[index(ds)[col]])
	else
		T = Core.Compiler.return_type(f, Tuple{our_nonmissingtype(eltype(ds[!, col]))})
		if allowmissing
			res = Vector{Union{Missing, T}}(undef, nrow(ds))
		else
			res = Vector{T}(undef, nrow(ds))
		end
		map!(f, res, _columns(ds)[index(ds)[col]])
	end
	res
end


# specific path for converting Any to suitable type
byrow(ds::AbstractDataset, ::typeof(identity), col::ColumnIndex) = identity.(_columns(ds)[index(ds)[col]])

# special case for converting the type of a column conveniently 
byrow(ds::AbstractDataset, f::Type, col::ColumnIndex) = convert(Vector{Union{Missing, f}}, _columns(ds)[index(ds)[col]])
