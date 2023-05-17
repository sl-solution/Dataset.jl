using .Base: sub_with_overflow, add_with_overflow, mul_with_overflow


"""
    gatherby(ds, cols;
		mapformats::Bool = true,
		stable::Bool = true,
		isgathered::Bool = false,
		eachrow::Bool = false,
		threads = true)

Return a `Gatherby` representing a view of a `gathered` data set which each group of observation are next to each other.

# Arguments
- `ds` : an `AbstractDataset`.
- `cols` : data set columns to gather by. Can be any column selector
  ($COLUMNINDEX_STR; $MULTICOLUMNINDEX_STR). 
- `mapforamts`: Whether the formated values should be used or not.
- `stable`: Whether the stable alogrithm should be used or not. Setting this to `false` may improve the performance for data set with many groups.
- `isgathered`: If `true` the function assumes that the observation are grouped based on some predefined rules and it only find the start and the end of each group.
- `eachrow`: If `true` the function assumes that each row of the input data set is a group. This is very useful for reshaping data. See `transpose`. 
- `threads`: By default multi threaded algorithm will be used to gather observations, however, uses can change this by passing `false` to this keyword. 

# See also

[`groupby!`](@ref), [`groupby`](@ref), [`combine`](@ref), [`modify`](@ref), [`modify!`](@ref), [`eachgroup`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(a=repeat([1, 2, 3, 4], outer=[2]),
                      b=repeat([2, 1], outer=[4]),
                      c=1:8);

julia> gatherby(ds, :a)
8×3 View of GatherBy Dataset, Gathered by: a
 a         b         c        
 identity  identity  identity 
 Int64?    Int64?    Int64?   
──────────────────────────────
        1         2         1
        1         2         5
        2         1         2
        2         1         6
        3         2         3
        3         2         7
        4         1         4
        4         1         8

julia> gatherby(ds, [:b, :c])
8×3 View of GatherBy Dataset, Gathered by: b ,c
 a         b         c        
 identity  identity  identity 
 Int64?    Int64?    Int64?   
──────────────────────────────
        1         2         1
        2         1         2
        3         2         3
        4         1         4
        1         2         5
        2         1         6
        3         2         7
        4         1         8

julia> collect(eachgroup(gatherby(ds, [:b])))
2-element Vector{SubDataset}:
 4×3 SubDataset
 Row │ a         b         c        
     │ identity  identity  identity 
     │ Int64?    Int64?    Int64?   
─────┼──────────────────────────────
   1 │        1         2         1
   2 │        3         2         3
   3 │        1         2         5
   4 │        3         2         7
 4×3 SubDataset
 Row │ a         b         c        
     │ identity  identity  identity 
     │ Int64?    Int64?    Int64?   
─────┼──────────────────────────────
   1 │        2         1         2
   2 │        4         1         4
   3 │        2         1         6
   4 │        4         1         8

```
"""
gatherby

function _findstarts_for_indices(x)
    _tmp = zeros(Bool, length(x))
    _tmp[1] = true
    Threads.@threads for i in 2:length(x)
        !isequal(x[i-1], x[i]) ? _tmp[i]=true : nothing
    end
    findall(_tmp)
end

function compute_indices(groups, ngroups, ::Val{T}; threads = true) where T
	idx = Vector{T}(undef, length(groups))
    _fill_idx_for_sort!(idx)
	if length(groups) == ngroups
		return idx, copy(idx)
	end
	# TODO we have the same ifelse in sort, probably we need to clean up these into a new function
	if threads && Threads.nthreads() > 1 && length(groups) > Threads.nthreads() && ngroups > 100_000 && ngroups*Threads.nthreads() < length(groups)
		starts = _ds_sort_int_missatright_nopermx_threaded!(groups, idx, ngroups, 1, Val(T))
	elseif threads && Threads.nthreads() > 1 && length(groups) > Threads.nthreads() && ngroups > 100_000
		starts = _ds_sort_int_missatright_nopermx_threaded_lm!(groups, idx, ngroups, 1, Val(T))
	else
		starts = _ds_sort_int_missatright_nopermx!(groups, idx, ngroups, 1, Val(T))
	end
	pop!(starts)
	pop!(starts)
	pop!(starts)
	idx, starts
end

# fast combine for gatherby data

mutable struct GatherBy
    parent
    groupcols
    groups
    lastvalid
    mapformats::Bool
    perm
    starts
	created::DateTime
end
function Base.copy(gds::GatherBy)
	ds_cpy = copy(gds.parent)
	GatherBy(copy(gds.parent), copy(gds.groupcols), copy(gds.groups), gds.lastvalid, gds.mapformats, gds.perm === nothing ? nothing : copy(gds.perm), gds.starts === nothing ? nothing : copy(gds.starts), _get_lastmodified(_attributes(ds_cpy)))
end


nrow(ds::GatherBy) = nrow(ds.parent)
ncol(ds::GatherBy) = ncol(ds.parent)
Base.names(ds::GatherBy, kwargs...) = names(ds.parent, kwargs...)
_names(ds::GatherBy) = _names(ds.parent)
_columns(ds::GatherBy) = _columns(ds.parent)
index(ds::GatherBy) = index(ds.parent)
Base.parent(ds::GatherBy) = ds.parent
Base.size(ds::GatherBy) = size(ds.parent)
Base.size(ds::GatherBy, i::Integer) = size(ds.parent, i)
getformat(ds::GatherBy, i) = getformat(ds.parent, i)


Base.summary(gds::GatherBy) =
        @sprintf("%d×%d View of GatherBy Dataset, Gathered by: %s", size(gds.parent)..., join(_names(gds.parent)[gds.groupcols], " ,"))


function Base.show(io::IO, gds::GatherBy;

	kwargs...)
	_check_consistency(gds)
	if length(_get_perms(gds)) > 200
		_show(io, view(gds.parent, [first(gds.perm, 100);last(gds.perm, 100)], :); title = summary(gds), show_omitted_cell_summary=false, show_row_number  = false, kwargs...)
	else
		_show(io, view(gds.parent, gds.perm, :); title = summary(gds), show_omitted_cell_summary=false, show_row_number  = false, kwargs...)
	end
end

Base.show(io::IO, mime::MIME"text/plain", gds::GatherBy;
          kwargs...) =
    show(io, gds; title = summary(gds), kwargs...)


function _group_creator!(groups, starts, ngroups)
	if ngroups == 1
		fill!(groups, 1)
		return
	end
  	for j in 1:ngroups
		lo = starts[j]
		j == ngroups ? hi = length(groups) : hi = starts[j + 1] - 1
		fill!(view(groups, lo:hi), j)
	end
end

# eachrow = true tells gatherby that each row of passed dataset is a new group - this is useful for transpose()
function gatherby(ds::AbstractDataset, cols::MultiColumnIndex; mapformats::Bool = true, stable::Bool = true, isgathered::Bool = false, eachrow::Bool = false, threads = true)
    colsidx = index(ds)[cols]
	if isempty(ds)
		return GatherBy(ds, colsidx, Int[], 0, mapformats, nothing, nothing, _get_lastmodified(_attributes(ds)))
	end

	T = nrow(ds) < typemax(Int32) ? Int32 : Int64
	_check_consistency(ds)
	if isgathered
		if eachrow
			return GatherBy(ds, colsidx, 1:nrow(ds), nrow(ds), mapformats, 1:nrow(ds), 1:nrow(ds), _get_lastmodified(_attributes(ds)))
		else
			colindex, ranges, last_valid_index = _find_starts_of_groups(ds, colsidx, Val(T); mapformats = mapformats, threads = threads)
		 	groups = Vector{T}(undef, nrow(ds))
		 	_group_creator!(groups, ranges, last_valid_index)
		 	return GatherBy(ds, colindex, groups, last_valid_index, mapformats, 1:nrow(ds), ranges, _get_lastmodified(_attributes(ds)))
		end
	else
		if eachrow
			a = _gather_groups(ds, colsidx, Val(T), mapformats = mapformats, stable = stable, threads = threads)
			b = compute_indices(a[1], a[3], nrow(ds) < typemax(Int32) ? Val(Int32) : Val(Int64); threads = threads)
			return GatherBy(ds, colsidx, 1:nrow(ds), nrow(ds), mapformats, b[1], 1:nrow(ds), _get_lastmodified(_attributes(ds)))
		else
			a = _gather_groups(ds, colsidx, Val(T), mapformats = mapformats, stable = stable, threads = threads)
			return GatherBy(ds, colsidx, a[1], a[3], mapformats, nothing, nothing, _get_lastmodified(_attributes(ds)))
		end
	end
end
gatherby(ds::AbstractDataset, col::ColumnIndex; mapformats = true, stable = true, isgathered = false, eachrow = false, threads = true) = gatherby(ds, [col], mapformats = mapformats, stable = stable, isgathered = isgathered, eachrow = eachrow, threads = threads)


__SPFRMT(x) = x & 1023
__SPFRMT(::Missing) = missing # not needed

# currently not been used in gatherby
# use sort and format trick for fast gatherby - hm stands for high memory footprint
function hm_gatherby(ds::AbstractDataset, cols::MultiColumnIndex; mapformats = false, threads = true)
	modify!(ds, cols=>byrow(hash; threads = threads, mapformats = mapformats)=>:___tmp___cols8934, :___tmp___cols8934=>identity=>:___tmp___cols8934_2)
	setformat!(ds, :___tmp___cols8934_2=>__SPFRMT)
	gds = groupby(ds, [:___tmp___cols8934_2, :___tmp___cols8934], stable = false, threads = threads)
	grpcols, ranges, last_valid_index = _find_starts_of_groups(view(ds, gds.perm, cols), cols, nrow(ds) < typemax(Int32) ? Val(Int32) : Val(Int64); mapformats = mapformats, threads = threads)
	select!(ds, Not([:___tmp___cols8934, :___tmp___cols8934_2]))
	GatherBy(ds, grpcols, nothing, last_valid_index, mapformats, gds.perm, ranges, _get_lastmodified(_attributes(ds)))
end

function _fill_mapreduce_col!(x, f, op, y, loc)
    @inbounds for i in 1:length(y)
        x[loc[i]] = op(x[loc[i]], f(y[i]))
    end
end

function _fill_mapreduce_col!(x, f::Vector, op, y, loc)
	@inbounds for i in 1:length(y)
        x[loc[i]] = op(x[loc[i]], f[loc[i]](y[i]))
    end
end


function _fill_mapreduce_col_threaded!(x, f, op, y, loc, nt)
	@sync for thid in 0:nt-1
		Threads.@spawn for i in 1:length(y)
        	@inbounds if loc[i] % nt == thid
				# we need to do more complicated stuff here?
				x[loc[i]] = op(x[loc[i]], f(y[i]))
			end
		end
    end
end

function _fill_mapreduce_col_threaded!(x, f::Vector, op, y, loc, nt)
	@sync for thid in 0:nt-1
		Threads.@spawn for i in 1:length(y)
        	@inbounds if loc[i] % nt == thid
				x[loc[i]] = op(x[loc[i]], f[loc[i]](y[i]))
			end
		end
    end
end




function gatherby_mapreduce(gds::GatherBy, f, op, col::ColumnIndex, nt, init, ::Val{T}; promotetypes = false, threads = true) where T
	CT = T
	if promotetypes
	    T <: Base.SmallSigned ? CT = Int : nothing
		T <: Base.SmallUnsigned ? CT = UInt : nothing
	end
	res = allocatecol(Union{CT, Missing}, gds.lastvalid)
    fill!(res, init)
	if threads && Threads.nthreads() > 1 && gds.lastvalid > 100_000
		_fill_mapreduce_col_threaded!(res, f, op, _columns(gds.parent)[index(gds.parent)[col]], gds.groups, nt)
	else
    	_fill_mapreduce_col!(res, f, op, _columns(gds.parent)[index(gds.parent)[col]], gds.groups)
	end
    res
end

_gatherby_maximum(gds, col; f = identity, nt = Threads.nthreads(), threads = true) = gatherby_mapreduce(gds, f, _stat_max_fun, col, nt, missing, Val(our_nonmissingtype(eltype(gds.parent[!, col]))), threads = threads)
_gatherby_minimum(gds, col; f = identity, nt = Threads.nthreads(), threads = true) = gatherby_mapreduce(gds, f, _stat_min_fun, col, nt, missing, Val(our_nonmissingtype(eltype(gds.parent[!, col]))), threads = threads)
_gatherby_sum(gds, col; f = identity, nt = Threads.nthreads(), threads = true) = gatherby_mapreduce(gds, f, _stat_add_sum, col, nt, missing, Val(typeof(zero(Core.Compiler.return_type(f, Tuple{eltype(gds.parent[!, col])})))), promotetypes = true, threads = threads)
_gatherby_n(gds, col; nt = Threads.nthreads(), threads = true) = _gatherby_sum(gds, col, f = _stat_notmissing, nt = nt, threads = threads)
_gatherby_length(gds, col; nt = Threads.nthreads(), threads = true) = _gatherby_sum(gds, col, f = x->1, nt = nt, threads = threads)
_gatherby_cntnan(gds, col; nt = Threads.nthreads(), threads = true) = _gatherby_sum(gds, col, f = ISNAN, nt = nt, threads = threads)
_gatherby_nmissing(gds, col; nt = Threads.nthreads(), threads = true) = _gatherby_sum(gds, col, f = _stat_ismissing, nt = nt, threads = threads)


function _fill_gatherby_mean_barrier!(res, sval, nval)
	@inbounds for i in 1:length(nval)
		if nval[i] == 0
			res[i] = missing
		else
			res[i] = sval[i]/nval[i]
		end
	end
end


function _gatherby_mean(gds, col; nt = Threads.nthreads(), threads = true)
	if threads
		nt2 = max(div(nt, 2),1)

		t1 = Threads.@spawn _gatherby_sum(gds, col, nt = nt2)
		t2 = Threads.@spawn _gatherby_n(gds, col, nt = nt2)
		sval = fetch(t1)
		nval = fetch(t2)
	else
		t1 = _gatherby_sum(gds, col, threads = threads)
		t2 = _gatherby_n(gds, col, threads = threads)
		sval = t1
		nval = t2
	end

	T = Core.Compiler.return_type(/, Tuple{our_nonmissingtype(eltype(sval)), our_nonmissingtype(eltype(nval))})
	res = _our_vect_alloc(Union{Missing, T}, length(nval))
	_fill_gatherby_mean_barrier!(res, sval, nval)
	res
end

function _fill_gatherby_var_barrier!(res, countnan, meanval, ss, nval, cal_std, dof)

	@inbounds for i in 1:length(nval)
		if cal_std
			if countnan[i] > 0
				res[i] = NaN
			elseif nval[i] == 0
				res[i] = missing
			elseif nval[i] == 1 && dof
				res[i] = missing
			else
				res[i] = sqrt(ss[i]/(nval[i]-Int(dof)))
			end
		else
			if countnan[i] > 0
				res[i] = NaN
			elseif nval[i] == 0
				res[i] = missing
			elseif nval[i] == 1 && dof
				res[i] = missing
			else
				res[i] = ss[i]/(nval[i]-Int(dof))
			end
		end
	end
end

# TODO directly calculating var should be a better approach
function _gatherby_var(gds, col; dof = true, cal_std = false, threads = true)
	if threads
		nt = Threads.nthreads()
		nt2 = max(div(nt,2),1)
		t1 = Threads.@spawn _gatherby_cntnan(gds, col, nt = nt2)
		t2 = Threads.@spawn _gatherby_mean(gds, col, nt = nt2)
		meanval = fetch(t2)
		t3 = Threads.@spawn gatherby_mapreduce(gds, [x->abs2(x - meanval[i]) for i in 1:length(meanval)], _stat_add_sum, col, nt2, missing, Val(Float64))
		t4 = Threads.@spawn _gatherby_n(gds, col, nt = nt2)
		countnan = fetch(t1)
		ss = fetch(t3)
		nval = fetch(t4)
	else
		t1 = _gatherby_cntnan(gds, col, threads = threads)
		t2 = _gatherby_mean(gds, col, threads = threads)
		meanval = t2
		t3 = gatherby_mapreduce(gds, [x->abs2(x - meanval[i]) for i in 1:length(meanval)], _stat_add_sum, col, Threads.nthreads(), missing, Val(Float64), threads = threads)
		t4 = _gatherby_n(gds, col, threads = threads)
		countnan = t1
		ss = t3
		nval = t4
	end
	T = Core.Compiler.return_type(/, Tuple{our_nonmissingtype(eltype(meanval)), our_nonmissingtype(eltype(nval))})
	res = _our_vect_alloc(Union{Missing, T}, length(nval))
	_fill_gatherby_var_barrier!(res, countnan, meanval, ss, nval, cal_std, dof)
	res
end
_gatherby_std(gds, col; dof = true, threads = true) = _gatherby_var(gds, col; dof = dof, cal_std = true, threads = threads)


const FAST_GATHERBY_REDUCTION = [sum, length, minimum, maximum, mean, var, std, n, nmissing]


function _fast_gatherby_reduction(gds, ms)
    !(gds isa GatherBy) && return false
    gds.groups == nothing && return false
    for i in 1:length(ms)
        if (ms[i].second.first isa Expr) && ms[i].second.first.head == :BYROW
        elseif (ms[i].second.first isa Base.Callable)
            flag = ms[i].second.first ∈ FAST_GATHERBY_REDUCTION
            !flag && return false
        end
    end
    return true
end


function _fast_gatherby_groups_to_res!(outres, x, grp)
	# the first element of each group is used for the output data set
    @inbounds for i in length(x):-1:1
        outres[grp[i]] = x[i]
    end
end


function _fast_gatherby_combine_f_barrier(gds, col, newds, mssecond, mslast, newds_lookup, grp, ngrps, threads)

    if !(mssecond isa Expr)
        if mssecond == sum
            newds[!, mslast] =  _gatherby_sum(gds, col, threads = threads)
        elseif mssecond == maximum
            newds[!, mslast] =  _gatherby_maximum(gds, col, threads = threads)
        elseif mssecond == minimum
            newds[!, mslast] =  _gatherby_minimum(gds, col, threads = threads)
        elseif mssecond == mean
            newds[!, mslast] =  _gatherby_mean(gds, col, threads = threads)
        elseif mssecond == mean
            newds[!, mslast] =  _gatherby_mean(gds, col, threads = threads)
        elseif mssecond == var
            newds[!, mslast] =  _gatherby_var(gds, col, dof = true, threads = threads)
        elseif mssecond == std
            newds[!, mslast] =  _gatherby_std(gds, col, dof = true, threads = threads)
        elseif mssecond == length
            newds[!, mslast] =  _gatherby_length(gds, col, threads = threads)
        elseif mssecond == IMD.n
            newds[!, mslast] =  _gatherby_n(gds, col, threads = threads)
        else mssecond == IMD.nmissing
            newds[!, mslast] =  _gatherby_nmissing(gds, col, threads = threads)
        end


    elseif (mssecond isa Expr) && mssecond.head == :BYROW
        newds[!, mslast] = byrow(newds, mssecond.args[1], col; mssecond.args[2]...)
    else
        throw(ArgumentError("`combine` doesn't support $(msfirst=>mssecond=>mslast) combination"))
    end
end

function _combine_fast_gatherby_reduction(gds, ms, newlookup, new_nm; dropgroupcols = false, threads = true)
    groupcols = gds.groupcols
    ngroups = gds.lastvalid
    groups = gds.groups

    all_names = _names(gds.parent)

    newds_idx = Index(Dict{Symbol, Int}(), Symbol[], Dict{Int, Function}(), Int[], Bool[], false, [], Int[], 1, false)

    newds = Dataset([], newds_idx)
    newds_lookup = index(newds).lookup
    var_cnt = 1
	if !dropgroupcols
	    for j in 1:length(groupcols)
	        addmissing = false
	        _tmpres = allocatecol(gds.parent[!, groupcols[j]].val, ngroups, addmissing = addmissing)
	        if DataAPI.refpool(_tmpres) !== nothing
	            _fast_gatherby_groups_to_res!(_tmpres.refs, DataAPI.refarray(_columns(gds.parent)[groupcols[j]]), groups)
	            push!(_columns(newds), _tmpres)
	        else
	            _fast_gatherby_groups_to_res!(_tmpres, _columns(gds.parent)[groupcols[j]], groups)
	            push!(_columns(newds), _tmpres)
	        end
	        push!(index(newds), new_nm[var_cnt])
			setformat!(newds, new_nm[var_cnt] => getformat(parent(gds), groupcols[j]))
	        var_cnt += 1
	    end
	end
	for i in 1:length(ms)
		_fast_gatherby_combine_f_barrier(gds, ms[i].first, newds, ms[i].second.first, ms[i].second.second, newds_lookup, groups, ngroups, threads)
		# if !haskey(index(newds), ms[i].second.second)
			# push!(index(newds), ms[i].second.second)
		# end

	end
	newds
end
