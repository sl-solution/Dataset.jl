"""
    groupby(ds, cols;
		alg = HeapSortAlg(),
		rev = false,
		mapformats::Bool = true,
		stable = true,
		threads = true)

Return a `GroupBy` representing a view of a `sorted` data set which each group of observation are next to each other.

# Arguments
- `ds` : an `AbstractDataset` or the output of `groupby`.
- `cols` : data set columns to group by. Can be any column selector
  ($COLUMNINDEX_STR; $MULTICOLUMNINDEX_STR). 
- `alg` : The sorting algorithm for creating `grouped` data set. By default Heap algorithm is used, however, user can pass `QuickSort` too.
- `rev` : A `Bool` value or a Vector of `Bool` which indicate which column should be sorted in descending order.
- `mapforamts`: Whether the formated values should be used or not.
- `stable`: Whether the sorting alogrithm should be stable or not. Setting this to `false` often improve the performance.
- `threads`: By default multi threaded algorithm will be used to group observations, however, user can change this by passing `false` to this keyword. 

# See also

[`groupby!`](@ref), [`gatherby`](@ref), [`combine`](@ref), [`modify`](@ref), [`modify!`](@ref), [`eachgroup`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(a=repeat([1, 2, 3, 4], outer=[2]),
                      b=repeat([2, 1], outer=[4]),
                      c=1:8);

julia> groupby(ds, :a)
8×3 View of Grouped Dataset, Grouped by: a
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

julia> groupby(ds, [:a, :c], rev=[true, false])
8×3 View of Grouped Dataset, Grouped by: a ,c
 a         b         c        
 identity  identity  identity 
 Int64?    Int64?    Int64?   
──────────────────────────────
        4         1         4
        4         1         8
        3         2         3
        3         2         7
        2         1         2
        2         1         6
        1         2         1
        1         2         5

julia> collect(eachgroup(groupby(ds, [:b])))
2-element Vector{SubDataset}:
 4×3 SubDataset
 Row │ a         b         c        
     │ identity  identity  identity 
     │ Int64?    Int64?    Int64?   
─────┼──────────────────────────────
   1 │        2         1         2
   2 │        4         1         4
   3 │        2         1         6
   4 │        4         1         8
 4×3 SubDataset
 Row │ a         b         c        
     │ identity  identity  identity 
     │ Int64?    Int64?    Int64?   
─────┼──────────────────────────────
   1 │        1         2         1
   2 │        3         2         3
   3 │        1         2         5
   4 │        3         2         7
		
```
"""
groupby

"""
    groupby!(ds, cols;
		alg = HeapSortAlg(),
		rev = false,
		mapformats::Bool = true,
		stable = true,
		threads = true)

Repace a data set by its sorted version and tag the data set as a grouped data set, i.e. when the data set is used as the argument for other functions it will be seen as a grouped data set.

# Arguments
- `ds` : a `Dataset`.
- `cols` : data set columns to group by. Can be any column selector
  ($COLUMNINDEX_STR; $MULTICOLUMNINDEX_STR). 
- `alg` : The sorting algorithm for creating `grouped` data set. By default Heap algorithm is used, however, user can pass `QuickSort` too.
- `rev` : A `Bool` value or a Vector of `Bool` which indicate which column should be sorted in descending order.
- `mapforamts`: Whether the formated values should be used or not.
- `stable`: Whether the sorting alogrithm should be stable or not. Setting this to `false` often improve the performance.
- `threads`: By default multi threaded algorithm will be used to group observations, however, user can change this by passing `false` to this keyword. 

# See also

[`ungroup!`](@ref), [`groupby`](@ref), [`gatherby`](@ref), [`combine`](@ref), [`modify`](@ref), [`modify!`](@ref), [`eachgroup`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(a=repeat([1, 2, 3, 4], outer=[2]),
                      b=repeat([2, 1], outer=[4]),
                      c=1:8);

julia> groupby!(ds, :a)
8×3 Grouped Dataset with 4 groups
Grouped by: a
 Row │ a         b         c        
     │ identity  identity  identity 
     │ Int64?    Int64?    Int64?   
─────┼──────────────────────────────
   1 │        1         2         1
   2 │        1         2         5
   3 │        2         1         2
   4 │        2         1         6
   5 │        3         2         3
   6 │        3         2         7
   7 │        4         1         4
   8 │        4         1         8

julia>groupby!(ds, [:a, :c], rev=[true, false])
8×3 Grouped Dataset with 8 groups
Grouped by: a, c
 Row │ a         b         c        
     │ identity  identity  identity 
     │ Int64?    Int64?    Int64?   
─────┼──────────────────────────────
   1 │        4         1         4
   2 │        4         1         8
   3 │        3         2         3
   4 │        3         2         7
   5 │        2         1         2
   6 │        2         1         6
   7 │        1         2         1
   8 │        1         2         5

```
"""
function groupby!(ds::Dataset, cols::MultiColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true)
	sort!(ds, cols, alg = alg, rev = rev,  mapformats = mapformats, stable = stable, threads = threads)
	index(ds).grouped[] = true
	if isempty(ds)
		index(ds).ngroups[] = 0
	end
	_modified(_attributes(ds))
	ds
end

groupby!(ds::Dataset, col::ColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true) = groupby!(ds, [col]; alg = alg, rev = rev, mapformats = mapformats, stable = stable, threads = threads)

mutable struct GroupBy
	parent
	groupcols
	rev
	perm
	starts
	lastvalid
	mapformats::Bool
	created::DateTime
end

function Base.copy(gds::GroupBy)
	ds_cp = copy(gds.parent)
	GroupBy(ds_cp, copy(gds.groupcols), copy(gds.rev), copy(gds.perm), copy(gds.starts), gds.lastvalid, gds.mapformats, _get_lastmodified(_attributes(ds_cp)))
end

nrow(ds::GroupBy) = nrow(ds.parent)
ncol(ds::GroupBy) = ncol(ds.parent)
Base.names(ds::GroupBy, kwargs...) = names(ds.parent, kwargs...)
_names(ds::GroupBy) = _names(ds.parent)
_columns(ds::GroupBy) = _columns(ds.parent)
index(ds::GroupBy) = index(ds.parent)
Base.parent(ds::GroupBy) = ds.parent
Base.size(ds::GroupBy) = size(ds.parent)
Base.size(ds::GroupBy, i::Integer) = size(ds.parent, i)

function groupby(ds::Dataset, cols::MultiColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true)
	_check_consistency(ds)
	colsidx = index(ds)[cols]
	if isempty(ds)
		return GroupBy(parent(ds), colsidx, rev, Int[], Int[], 0, mapformats, _get_lastmodified(_attributes(ds)))
	end
	a = _sortperm(ds, cols, rev, a = alg, mapformats = mapformats, stable = stable, threads = threads)
	GroupBy(parent(ds),colsidx, rev, a[2], a[1], a[3], mapformats, _get_lastmodified(_attributes(ds)))
end

groupby(ds::Dataset, col::ColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true) = groupby(ds, [col], alg = alg, rev = rev, mapformats = mapformats, stable = stable, threads = threads)

function groupby!(ds::GroupBy, cols::MultiColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true)
	colsidx = index(ds)[cols]
	grng = GIVENRANGE(_get_perms(ds),_group_starts(ds), nothing, _ngroups(ds))
	a = _sortperm(ds, cols, rev, a = alg, mapformats = mapformats, stable = stable, givenrange = grng, skipcol = -1, threads = threads)
	ds.groupcols = colsidx
	ds.rev = rev
	ds.lastvalid = a[3]
	ds.mapformats = mapformats
	ds
end
groupby!(ds::GroupBy, col::ColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true) = groupby!(ds, [col], alg = alg, rev = rev, mapformats = mapformats, stable = stable, threads =threads)

function groupby(ds::GroupBy, cols::MultiColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true)
	colsidx = index(ds)[cols]
	grng = GIVENRANGE(copy(_get_perms(ds)),copy(_group_starts(ds)), nothing, _ngroups(ds))
	a = _sortperm(ds, cols, rev, a = alg, mapformats = mapformats, stable = stable, givenrange = grng, skipcol = -1, threads = threads)
	GroupBy(parent(ds),colsidx, rev, a[2], a[1], a[3], mapformats, _get_lastmodified(_attributes(parent(ds))))
end
groupby(ds::GroupBy, col::ColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true) = groupby(ds, [col], alg = alg, rev = rev, mapformats = mapformats, stable = stable, threads = threads)



function _threaded_permute_for_groupby(x, perm; threads = true)
	if DataAPI.refpool(x) !== nothing
		pa = x
		if pa isa PooledArray
			# we could use copy but it will be inefficient for small selected_rows
			res = PooledArray(PooledArrays.RefArray(_threaded_permute(pa.refs, perm)), DataAPI.invrefpool(pa), DataAPI.refpool(pa), PooledArrays.refcount(pa))
		else
			# for other pooled data(like Categorical arrays) we don't have optimised path
			res = pa[perm]
		end
	else
		res = _threaded_permute(x, perm; threads = threads)
	end
	res
end

modify(origninal_gds::Union{GroupBy, GatherBy}, @nospecialize(args...); threads::Bool = true) = modify!(copy(origninal_gds), args..., threads = threads)
function modify!(gds::Union{GroupBy, GatherBy}, @nospecialize(args...); threads::Bool = true)
	_check_consistency(gds)
	if parent(gds) isa SubDataset
		idx_cpy = copy(index(parent(gds)))
	else
		idx_cpy = Index(copy(index(parent(gds)).lookup), copy(index(parent(gds)).names), copy(index(parent(gds)).format))
	end
	norm_var = normalize_modify_multiple!(idx_cpy, index(parent(gds)), args...)
	allnewvars = map(x -> x.second.second, norm_var)
	all_new_var = Symbol[]
	for i in 1:length(allnewvars)
		if typeof(allnewvars[i]) <: MultiCol
			for j in 1:length(allnewvars[i].x)
				push!(all_new_var, allnewvars[i].x[j])
			end
		else
			push!(all_new_var, allnewvars[i])
		end
	end
	var_index = idx_cpy[unique(all_new_var)]
	# TODO what we should do when a groupcol is modified??
	# any(index(parent(gds)).sortedcols .∈ Ref(var_index)) && throw(ArgumentError("the grouping variables cannot be modified, first use `ungroup!(ds)` to ungroup the data set"))
	_modify_grouped(gds, norm_var, threads)
end


function _modify_grouped_f_barrier(gds::Union{GroupBy, GatherBy}, msfirst, mssecond, mslast, threads)
	perm = _get_perms(gds; threads = threads)
	starts = _group_starts(gds; threads = threads)
	ngroups = gds.lastvalid
	iperm = invperm(perm)
	if (mssecond isa Base.Callable) && !(mslast isa MultiCol)
		if parent(gds) isa SubDataset
			T = _check_the_output_type(parent(parent(gds)), msfirst=>mssecond=>mslast)
		else
			T = _check_the_output_type(parent(gds), msfirst=>mssecond=>mslast)
		end
		_res = allocatecol(T, nrow(parent(gds)))

		if msfirst isa Tuple
			_modify_grouped_fill_one_col_tuple!(_res, ntuple(i->_threaded_permute_for_groupby(_columns(parent(gds))[msfirst[i]], perm), length(msfirst)), mssecond, starts, ngroups, nrow(parent(gds)), threads)
		else
			_modify_grouped_fill_one_col!(_res, _threaded_permute_for_groupby(_columns(parent(gds))[msfirst], perm), mssecond, starts, ngroups, nrow(parent(gds)), threads)
		end
		# temporary work around for Subdataset, it is EXPERIMENTAL
		if parent(gds) isa SubDataset
			if haskey(index(parent(gds)), mslast)
				parent(gds)[:, mslast] = _threaded_permute_for_groupby(_res, iperm)
			elseif !haskey(index(parent(parent(gds))), mslast)
				parent(parent(gds))[!, mslast] = _missings(T, nrow(parent(parent(gds))))
				_update_subindex!(index(parent(gds)), index(parent(parent(gds))), mslast)
				parent(gds)[:, mslast] = _threaded_permute_for_groupby(_res, iperm)
			else
				throw(ArgumentError("modifing a parent's column which doesn't appear in SubDataset is not allowed"))
			end
		else
			parent(gds)[!, mslast] = _threaded_permute_for_groupby(_res, iperm; threads = threads)
		end
	elseif (mssecond isa Expr)  && mssecond.head == :BYROW
		if parent(gds) isa SubDataset
			_res = byrow(parent(gds), mssecond.args[1], msfirst; mssecond.args[2]...)
			if haskey(index(parent(gds)), mslast)
				parent(gds)[:, mslast] = _res
			elseif !haskey(index(parent(parent(gds))), mslast)
				parent(parent(gds))[!, mslast] = _missings(eltype(_res), nrow(parent(parent(gds))))
				_update_subindex!(index(parent(gds)), index(parent(parent(gds))), mslast)
				parent(gds)[:, mslast] = _res
			else
				throw(ArgumentError("modifing a parent's column which doesn't appear in SubDataset is not allowed"))
			end
		else
			parent(gds)[!, mslast] = byrow(parent(gds), mssecond.args[1], msfirst; mssecond.args[2]...)
		end
	elseif (mssecond isa Base.Callable) && (mslast isa MultiCol) && (mssecond isa typeof(splitter))
		_modify_multiple_out!(parent(gds), _columns(parent(gds))[msfirst], mslast.x)
	else
		# if something ends here, we should implement new functionality for it
		@error "not yet know how to handle the situation $(msfirst => mssecond => mslast)"
	end
end



function combine(gds::Union{GroupBy, GatherBy}, @nospecialize(args...); dropgroupcols = false, threads = true)
	_check_consistency(gds)
	idx_cpy::Index = Index(Dict{Symbol, Int}(), Symbol[], Dict{Int, Function}())
	if !dropgroupcols
        for i in gds.groupcols
            push!(idx_cpy, Symbol(names(gds)[i]))
        end
    end

	ms = normalize_combine_multiple!(idx_cpy, index(gds.parent), args...)
	# the rule is that in combine, byrow must only be used for already aggregated columns
	# so, we should check every thing pass to byrow has been assigned in args before it
	# if this is not the case, throw ArgumentError and ask user to use modify instead
	newlookup, new_nm = _create_index_for_newds(gds.parent, ms, gds.groupcols)
	!(_is_byrow_valid(Index(newlookup, new_nm, Dict{Int, Function}()), ms)) && throw(ArgumentError("`byrow` must be used for aggregated columns, use `modify` otherwise"))
	if _fast_gatherby_reduction(gds, ms)
		return _combine_fast_gatherby_reduction(gds, ms, newlookup, new_nm; dropgroupcols = dropgroupcols, threads = threads)
	end
	# _check_mutliple_rows_for_each_group return the first transformation which causes multiple
	# rows or 0 if all transformations return scalar for each group
	# the transformation returning multiple rows must not be based on the previous columns in combine
	# result (which seems reasonable ??)
	_first_vector_res = _check_mutliple_rows_for_each_group(gds.parent, ms)
	_is_groupingcols_modifed(gds, ms) && throw(ArgumentError("`combine` cannot modify the grouping or sorting columns, use a different name for the computed column"))

	groupcols = gds.groupcols
	a = (_get_perms(gds; threads = threads), _group_starts(gds; threads = threads), gds.lastvalid)
	starts = a[2]
	ngroups = gds.lastvalid

	# we will use new_lengths later for assigning the grouping info of the new ds
	if _first_vector_res == 0
		new_lengths = ones(Int, ngroups)
		our_cumsum!(new_lengths)
		total_lengths = ngroups
	else
		if ms[_first_vector_res].first isa Tuple
			CT = return_type(ms[_first_vector_res].second.first,
			ntuple(i->gds.parent[!, ms[_first_vector_res].first[i]].val, length(ms[_first_vector_res].first)))
		else
			CT = return_type(ms[_first_vector_res].second.first,
			gds.parent[!, ms[_first_vector_res].first].val)
		end
		special_res = _our_vect_alloc(CT, ngroups)
		new_lengths = _our_vect_alloc(Int, ngroups)
		# _columns(ds)[ms[_first_vector_res].first]
		if ms[_first_vector_res].first isa Tuple
			_compute_the_mutli_row_trans_tuple!(special_res, new_lengths, ntuple(i->_threaded_permute_for_groupby(_columns(gds.parent)[index(gds.parent)[ms[_first_vector_res].first[i]]], a[1], threads = threads), length(ms[_first_vector_res].first)), nrow(gds.parent), ms[_first_vector_res].second.first, _first_vector_res, starts, ngroups, threads)
		else
			_compute_the_mutli_row_trans!(special_res, new_lengths, _threaded_permute_for_groupby(_columns(gds.parent)[index(gds.parent)[ms[_first_vector_res].first]], a[1], threads = threads), nrow(gds.parent), ms[_first_vector_res].second.first, _first_vector_res, starts, ngroups, threads)
		end
		# special_res, new_lengths = _compute_the_mutli_row_trans(ds, ms, _first_vector_res, starts, ngroups)
		our_cumsum!(new_lengths)
		total_lengths = new_lengths[end]
	end
	all_names = _names(gds.parent)

	newds_idx = Index(Dict{Symbol, Int}(), Symbol[], Dict{Int, Function}(), Int[], Bool[], false, [], Int[], 1, false)

	newds = Dataset([], newds_idx)
	newds_lookup = index(newds).lookup
	var_cnt = 1
	if !dropgroupcols
		for j in 1:length(groupcols)
			addmissing = false
			_tmpres = allocatecol(gds.parent[!, groupcols[j]].val, total_lengths, addmissing = addmissing)
			if DataAPI.refpool(_tmpres) !== nothing
				_push_groups_to_res_pa!(_columns(newds), _tmpres, view(_columns(gds.parent)[groupcols[j]], a[1]), starts, new_lengths, total_lengths, j, groupcols, ngroups, threads)
			else
				_push_groups_to_res!(_columns(newds), _tmpres, view(_columns(gds.parent)[groupcols[j]], a[1]), starts, new_lengths, total_lengths, j, groupcols, ngroups, threads)
			end
			push!(index(newds), new_nm[var_cnt])
			setformat!(newds, new_nm[var_cnt] => getformat(parent(gds), groupcols[j]))
			var_cnt += 1
		end
	end
	old_x = ms[1].first
	curr_x = _columns(gds.parent)[1]
	for i in 1:length(ms)
		# TODO this needs a little work, we should permute a column once and reuse it as many times as possible
		# this can be done by sorting the first argument of col=>fun=>dst between each byrow
		if i == 1
			if !(ms[i].first isa Tuple)
				curr_x = _threaded_permute_for_groupby(_columns(gds.parent)[index(gds.parent)[ms[i].first]], a[1], threads = threads)
			end
		else
			if !(ms[i].first isa Tuple)
				if old_x !== ms[i].first
					if !(ms[i].second.first isa Expr) && haskey(index(gds.parent), ms[i].first)
						curr_x = _threaded_permute_for_groupby(_columns(gds.parent)[index(gds.parent)[ms[i].first]], a[1], threads = threads)
						old_x = ms[i].first
					else
						curr_x = view(_columns(gds.parent)[1], a[1])
					end
				end
			end

		end

		if i == _first_vector_res
			if ms[i].first isa Tuple && !(ms[i].second.first isa Expr)
				_combine_f_barrier_special_tuple(special_res, ntuple(j-> view(_columns(gds.parent)[index(gds.parent)[ms[i].first[j]]], a[1]), length(ms[i].first)), newds, ms[i].first, ms[i].second.first, ms[i].second.second, newds_lookup, _first_vector_res,ngroups, new_lengths, total_lengths, threads)
			else
				_combine_f_barrier_special(special_res, view(_columns(gds.parent)[index(gds.parent)[ms[i].first]], a[1]), newds, ms[i].first, ms[i].second.first, ms[i].second.second, newds_lookup, _first_vector_res,ngroups, new_lengths, total_lengths, threads)
			end
		else
			if ms[i].first isa Tuple && !(ms[i].second.first isa Expr)
				_combine_f_barrier_tuple(ntuple(j-> _threaded_permute_for_groupby(_columns(gds.parent)[index(gds.parent)[ms[i].first[j]]], a[1], threads = threads), length(ms[i].first)), newds, ms[i].first, ms[i].second.first, ms[i].second.second, newds_lookup, starts, ngroups, new_lengths, total_lengths, threads)
			else
				_combine_f_barrier(!(ms[i].second.first isa Expr) && haskey(index(gds.parent), ms[i].first) ? curr_x : view(_columns(gds.parent)[1], a[1]), newds, ms[i].first, ms[i].second.first, ms[i].second.second, newds_lookup, starts, ngroups, new_lengths, total_lengths, threads)
			end
		end
		if !haskey(index(newds), ms[i].second.second)
			push!(index(newds), ms[i].second.second)
		end

	end
	newds
end


Base.summary(gds::GroupBy) =
@sprintf("%d×%d View of Grouped Dataset, Grouped by: %s", size(gds.parent)..., join(_names(gds.parent)[gds.groupcols], " ,"))


function Base.show(io::IO, gds::GroupBy;

	kwargs...)
	_check_consistency(gds)
	#TODO pretty_table is very slow for large views, temporary workaround, later we should fix this
	if length(gds.perm) > 200
		_show(io, view(gds.parent, [first(gds.perm, 100);last(gds.perm, 100)], :); title = summary(gds), show_omitted_cell_summary=false, show_row_number  = false, kwargs...)
	else
		_show(io, view(gds.parent, gds.perm, :); title = summary(gds), show_omitted_cell_summary=false, show_row_number  = false, kwargs...)
	end
end

Base.show(io::IO, mime::MIME"text/plain", gds::GroupBy;
kwargs...) =
show(io, gds; title = summary(gds), kwargs...)

"""
	ungroup!(ds)

Remove the grouping information of a grouped data set created by `groupby!`, however, the function leaves the data sorted.
"""
function ungroup!(ds::Dataset)
	if index(ds).grouped[]
		index(ds).grouped[] = false
		_modified(_attributes(ds))
	end
	ds
end

isgrouped(ds::Dataset)::Bool = index(ds).grouped[]
isgrouped(ds::SubDataset)::Bool = false

function group_starts(ds::Dataset)
	index(ds).starts[1:index(ds).ngroups[]]
end
function getindex_group(ds::Dataset, i::Integer)
	if !(1 <= i <= index(ds).ngroups[])
		throw(BoundsError(ds, i))
	end
	lo = index(ds).starts[i]
	i == index(ds).ngroups[] ? hi = nrow(ds) : hi = index(ds).starts[i+1] - 1
	lo:hi
end
function getindex_group(ds::Union{GatherBy, GroupBy}, i::Integer)
	if !(1 <= i <= ds.lastvalid)
		throw(BoundsError(ds, i))
	end
	lo = _group_starts(ds)[i]
	i == ds.lastvalid ? hi = nrow(ds) : hi = _group_starts(ds)[i+1] - 1
	lo:hi
end

function _ngroups(ds::GroupBy)
	ds.lastvalid
end
function _ngroups(ds::Dataset)
	index(ds).ngroups[]
end

function _ngroups(ds::GatherBy)
	ds.lastvalid
end

function _groupcols(ds::GroupBy)
	ds.groupcols
end
function _groupcols(ds::Dataset)
	if isgrouped(ds)
		index(ds).sortedcols
	else
		Int[]
	end
end

_sortedcols(ds::Dataset) = index(ds).sortedcols
_sortedcols(ds::GroupBy) = _groupcols(ds)

function _groupcols(ds::GatherBy)
	ds.groupcols
end

function _group_starts(ds::GroupBy; threads = true)
	ds.starts
end
function _group_starts(ds::Dataset; threads = true)
	index(ds).starts
end

function _group_starts(ds::GatherBy; threads = true)
	if ds.starts === nothing
		a = compute_indices(ds.groups, ds.lastvalid, nrow(ds.parent) < typemax(Int32) ? Val(Int32) : Val(Int64), threads = threads)
		ds.starts = a[2]
		ds.perm = a[1]
		ds.starts
	else
		ds.starts
	end
end


function _get_perms(ds::Dataset; threads = true)
	1:nrow(ds)
end
_get_perms(ds::SubDataset; threads = true) = 1:nrow(ds)
function _get_perms(ds::GroupBy; threads = true)
	ds.perm
end
function _get_perms(ds::GatherBy; threads = true)
	if ds.perm === nothing
		a = compute_indices(ds.groups, ds.lastvalid, nrow(ds.parent) < typemax(Int32) ? Val(Int32) : Val(Int64); threads = threads)
		ds.starts = a[2]
		ds.perm = a[1]
		ds.perm
	else
		ds.perm
	end
end


_get_sort_perms(ds::Dataset) = index(ds).perm
_get_sort_perms(ds::GroupBy) = _get_perms(ds)


function _get_rev(ds::Dataset)
	index(ds).rev
end
function _get_rev(ds::GroupBy)
	ds.rev
end

function _get_fmt(ds::Dataset)
	index(ds).fmt[]
end
function _get_fmt(ds::GroupBy)
	ds.mapformats
end
function _get_fmt(ds::GatherBy)
	ds.mapformats
end

getformat(ds::GroupBy, i) = getformat(parent(ds), i)


### EXPERIMENTAL FOR SubDataset ####
_sortedcols(::SubDataset) = []
_get_fmt(::SubDataset) = false
_get_rev(::SubDataset) = []

function groupby(ds::SubDataset, cols::MultiColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true)
	_check_consistency(ds)
	colsidx = index(ds)[cols]
	a = _sortperm_v(ds, cols, rev, a = alg, mapformats = mapformats, stable = stable, threads = threads)
	GroupBy(ds, colsidx, rev, a[2], a[1], a[3], mapformats, _get_lastmodified(_attributes(ds)))
end
groupby(ds::SubDataset, col::ColumnIndex; alg = HeapSortAlg(), rev = false, mapformats::Bool = true, stable = true, threads = true) = groupby(ds, [col], alg = alg, rev = rev, mapformats = mapformats, stable = stable, threads = threads)


### check consistency of grouped data - GroupBy, GatherBy

function _check_consistency(ds::Union{GroupBy, GatherBy})
    lmd=ds.created
    lmp=_get_lastmodified(_attributes(parent(ds)))
    @assert lmd == lmp "The parent data set which the grouped data set is based on has been modified. To fix the issue regroup data."
end