"""
    AbstractDataset

An abstract type for which all concrete types expose an interface
for working with tabular data.

# Common methods

An `AbstractDataset` is a two-dimensional table with `Symbol`s or strings
for column names. It is the supertype of `Dataset` and `SubDataset` (view of a `Dataset`).

The following are normally implemented for AbstractDatasets:

* [`describe`](@ref) : summarize columns
* `summary` : show number of rows and columns
* `hcat` : horizontal concatenation
* `vcat` : vertical concatenation
* [`repeat`](@ref) : repeat rows
* `names` : columns names
* [`rename!`](@ref) : rename columns names based on keyword arguments
* `length` : number of columns
* `size` : (nrows, ncols)
* [`first`](@ref) : first `n` rows
* [`last`](@ref) : last `n` rows
* `convert` : convert to an array
* [`completecases`](@ref) : boolean vector of complete cases (rows with no missings)
* [`dropmissing`](@ref) : remove rows with missing values
* [`dropmissing!`](@ref) : remove rows with missing values in-place
* [`duplicates`](@ref) : indexes of duplicate rows
* [`unique`](@ref) : remove duplicate rows
* [`unique!`](@ref) : remove duplicate rows in-place

# Indexing and broadcasting

`AbstractDataset` can be indexed by passing two indices specifying
row and column selectors. The allowed indices are a superset of indices
that can be used for standard arrays. You can also access a single column
of an `AbstractDataset` using `getproperty` and `setproperty!` functions.
Columns can be selected using integers, `Symbol`s, or strings.
In broadcasting `AbstractDataset` behavior is similar to a `Matrix`.

"""
abstract type AbstractDataset end

abstract type AbstractDatasetColumn end

# DatasetColumn is a representation of a column of data set
# it is wrapped into a new type to make sure that when ever a column is
# selected, the data set is attached to it
struct DatasetColumn{T <: AbstractDataset, E} <: AbstractDatasetColumn
    col::Int
    ds::T
    val::E
end

struct SubDatasetColumn{T <: AbstractDataset, E} <: AbstractDatasetColumn
    col::Int
    ds::T
    val::E
    selected_index
end
_columns(ds::AbstractDataset) = getfield(ds, :columns)
Base.show(io::IO, ::MIME"text/plain", col::DatasetColumn) = show(IOContext(io, :limit => true), "text/plain", col.val)
Base.show(io::IO, ::MIME"text/plain", col::SubDatasetColumn) = show(IOContext(io, :limit => true), "text/plain", view(col.val, col.selected_index))

_getnames(x::NamedTuple) = propertynames(x)
_getnames(x::AbstractDataset) = _names(x)

# Base.Generator(f, col::SubOrDSCol) = Base.Generator(f, __!(col))

##############################################################################
##
## Basic properties of a Dataset
##
##############################################################################

"""
    names(df::AbstractDataset)
    names(df::AbstractDataset, cols)

Return a freshly allocated `Vector{String}` of names of columns contained in `df`.

If `cols` is passed then restrict returned column names to those matching the
selector (this is useful in particular with regular expressions, `Cols`, `Not`, and `Between`).
`cols` can be:
* any column selector ($COLUMNINDEX_STR; $MULTICOLUMNINDEX_STR)
* a `Type`, in which case names of columns whose `eltype` is a subtype of `T`
  are returned
* a `Function` predicate taking the column name as a string and returning `true`
  for columns that should be kept

See also [`propertynames`](@ref) which returns a `Vector{Symbol}`.
"""
Base.names(ds::AbstractDataset, cols::Colon=:) = names(index(ds))

function Base.names(ds::AbstractDataset, cols)
    nms = _names(index(ds))
    idx = index(ds)[cols]
    idxs = idx isa Int ? (idx:idx) : idx
    return [String(nms[i]) for i in idxs]
end

Base.names(ds::AbstractDataset, T::Type) =
    [String(n) for (n, c) in pairs(eachcol(ds)) if eltype(c) <: Union{Missing, T}]
Base.names(ds::AbstractDataset, fun::Function) = filter!(fun, names(ds))

# _names returns Vector{Symbol} without copying
_names(ds::AbstractDataset) = _names(index(ds))

_getformats(ds::AbstractDataset) = index(ds).format

rows(ds::AbstractDataset) = 1:nrow(ds)

# separate methods are needed due to dispatch ambiguity
Compat.hasproperty(df::AbstractDataset, s::Symbol) = haskey(index(df), s)
Compat.hasproperty(df::AbstractDataset, s::AbstractString) = haskey(index(df), s)


##############################################################################
##
## getting, setting and removing formats
##
##############################################################################
function getformat(ds::AbstractDataset, idx::Integer)
    getformat(index(ds), idx)
end
function getformat(ds::AbstractDataset, y::Symbol)
    getformat(index(ds), y)
end
function getformat(ds::AbstractDataset, y::String)
    getformat(index(ds), y)
end
# function getformat(ds, cols::MultiColumnIndex = :)
#     colsidx = index(ds)[cols]
#     f_v = Dict{Symbol, Function}()
#     vnm = _names(ds)
#     for j in 1:length(colsidx)
#         current_format = getformat(ds, colsidx[j])
#         if current_format != identity
#             push!(f_v, vnm[colsidx[j]]=> current_format)
#         end
#     end
#     f_v
# end
# using Core.Compiler.return_type to check if f make sense for selected column
# this cannot take care of situations like setting sqrt for negative numbers
function _check_format_validity(ds, col, f::Function)
    flag = false
    string(nameof(f))[1] == '#' && return flag
    Core.Compiler.return_type(f, Tuple{eltype(ds[!, col].val)}) == Union{} && return flag
    flag = true
end
_check_format_validity(ds, col, f) = throw(ArgumentError("Only functions can be set as columns' format"))
#Modify Dataset
"""
    setformat!(ds::Dataset, col, f)
    setformat!(ds::Dataset, col => f)
    setformat!(ds::Dataset, col1 => f1, col2 => f2, ...)
    setformat!(ds::Dataset, cols => f)

sets specified formats for the selected `columns` of `ds`.
"""
function setformat!(ds::AbstractDataset, idx::Integer, f::Function)
    !_check_format_validity(ds, idx, f) && return ds
    setformat!(index(ds), idx, f)
    _modified(_attributes(ds))
    ds
end
function setformat!(ds::AbstractDataset, idx::Symbol, f::Function)
    !_check_format_validity(ds, idx, f) && return ds
    setformat!(index(ds), idx, f)
    _modified(_attributes(ds))
    ds
end
function setformat!(ds::AbstractDataset, idx::T, f::Function) where T <: AbstractString
    !_check_format_validity(ds, idx, f) && return ds
    setformat!(index(ds), idx, f)
    _modified(_attributes(ds))
    ds
end
function setformat!(ds::AbstractDataset, p::Pair{Int64, T}) where T <: Function
    !_check_format_validity(ds, p.first, p.second) && return ds
    setformat!(index(ds), p)
   _modified(_attributes(ds))
   ds
end
function setformat!(ds::AbstractDataset, p::Pair{Symbol, T}) where T <: Function
    !_check_format_validity(ds, p.first, p.second) && return ds
    setformat!(index(ds), p)
    _modified(_attributes(ds))
    ds
end
function setformat!(ds::AbstractDataset, p::Pair{S, T}) where S <: AbstractString where T <: Function
    !_check_format_validity(ds, p.first, p.second) && return ds
    setformat!(index(ds), p)
    _modified(_attributes(ds))
    ds
end
function setformat!(ds::AbstractDataset, p::Pair{MC, T}) where T <: Function where MC <: MultiColumnIndex
    idx = index(ds)[p.first]
    for i in 1:length(idx)
        !_check_format_validity(ds, idx[i], p.second) && continue
        setformat!(index(ds), idx[i], p.second)
        # if for any reason one of the formatting is not working, we make sure the modified is correct
        _modified(_attributes(ds))
    end
    ds
end
function setformat!(ds::AbstractDataset, dict::Dict)
    for (k, v) in dict
        !_check_format_validity(ds, k, v) && continue
        setformat!(ds, k, v)
    end
    ds
end
# TODO should we allow arbitarary combination of Pair
function setformat!(ds::AbstractDataset, pv::Vector)
    for p in pv
        !_check_format_validity(ds, p.first, p.second) && continue
        setformat!(index(ds), p)
        # if for any reason one of the formatting is not working, we make sure the modified is correct
        _modified(_attributes(ds))
    end
    ds
end
function setformat!(ds::AbstractDataset, @nospecialize(args...))
    for i in 1:length(args)
        !_check_format_validity(ds, args[i].first, args[i].second) && continue
        setformat!(ds, args[i])
    end
    ds
end
setformat!(ds::AbstractDataset) = throw(ArgumentError("the columns and the format must be specified"))
# removing formats
"""
    removeformat!(ds::Dataset, cols)

removes format from selected `cols` in `ds`.
"""
function removeformat!(ds::AbstractDataset, idx::Integer)
    removeformat!(index(ds), idx)
    _modified(_attributes(ds))
    ds
end
function removeformat!(ds::AbstractDataset, y::Symbol)
    removeformat!(index(ds), y)
    _modified(_attributes(ds))
    ds
end
function removeformat!(ds::AbstractDataset, y::String)
    removeformat!(index(ds), y)
    _modified(_attributes(ds))
    ds
end
function removeformat!(ds::AbstractDataset, y::UnitRange)
    removeformat!(index(ds), y)
    _modified(_attributes(ds))
    ds
end
function removeformat!(ds::AbstractDataset, cols::MultiColumnIndex)
    idx = index(ds)[cols]
    for i in 1:length(idx)
        removeformat!(ds, idx[i])
        _modified(_attributes(ds))
    end
    ds
end
removeformat!(ds::AbstractDataset) = throw(ArgumentError("the `cols` argument must be specified"))
function removeformat!(ds::AbstractDataset, @nospecialize(args...))
    for i in 1:length(args)
        removeformat!(ds, args[i])
    end
    ds
end

# set info
"""
    setinfo!(ds::AbstractDataset, s::String)

Set `s` as the value for the `info` meta data of `ds`.

See [`getinfo`](@ref)
"""
function setinfo!(ds::AbstractDataset, s::String)
    _attributes(ds).meta.info[] = s
    _modified(_attributes(ds))
    s
end
"""
    getinfo(ds::AbstractDataset)

Get information set by `setinfo!`.

See [`setinfo!`](@ref)
"""
function getinfo(ds::AbstractDataset)
    _attributes(ds).meta.info[]
end

# TODO needs better printing
"""
    content(ds::AbstractDataset; output = false)

prints the meta information about `ds` and its columns. Setting `output = true` return a vector of data sets which contains the printed information as data sets.
"""
function content(ds::AbstractDataset; output = false)
    if !output
        println(summary(ds))
        if typeof(ds) <: SubDataset
            println("-----------------------------------")
            println("The parent's Meta information")
        end
        println("   Created: ", _attributes(ds).meta.created)
        println("  Modified: ", _attributes(ds).meta.modified[])
        println("      Info: ", _attributes(ds).meta.info[])
    end
    f_v = [String[], Function[], Type[]]
    all_names = names(ds)
    for i in 1:ncol(ds)
        push!(f_v[1], all_names[i])
        push!(f_v[2], getformat(ds, i))
        push!(f_v[3], our_nonmissingtype(eltype(ds[!, i])))
    end
    format_ds = Dataset(f_v, [:column, :format, :eltype], copycols = false)
    if !output
        println("-----------------------------------")
        println("Columns information ")
        pretty_table(format_ds, header = (["col", "format", "eltype"]), alignment =:l, show_row_number = true)

    else
        [Dataset(meta = ["created", "modified", "info"], value = [_attributes(ds).meta.created, _attributes(ds).meta.modified[], _attributes(ds).meta.info[]]), format_ds]
    end
end

"""
    rename!(ds::Dataset, vals::AbstractVector{Symbol};
            makeunique::Bool=false)
    rename!(ds::Dataset, vals::AbstractVector{<:AbstractString};
            makeunique::Bool=false)
    rename!(ds::Dataset, (from => to)::Pair...)
    rename!(ds::Dataset, d::AbstractDict)
    rename!(ds::Dataset, d::AbstractVector{<:Pair})
    rename!(f::Function, ds::Dataset)

Rename columns of `ds` in-place.
Each name is changed at most once. Permutation of names is allowed.

# Arguments
- `ds` : the `Dataset`
- `d` : an `AbstractDict` or an `AbstractVector` of `Pair`s that maps
  the original names or column numbers to new names
- `f` : a function which for each column takes the old name as a `String`
  and returns the new name that gets converted to a `Symbol`
- `vals` : new column names as a vector of `Symbol`s or `AbstractString`s
  of the same length as the number of columns in `ds`
- `makeunique` : if `false` (the default), an error will be raised
  if duplicate names are found; if `true`, duplicate names will be suffixed
  with `_i` (`i` starting at 1 for the first duplicate).

If pairs are passed to `rename!` (as positional arguments or in a dictionary or
a vector) then:
* `from` value can be a `Symbol`, an `AbstractString` or an `Integer`;
* `to` value can be a `Symbol` or an `AbstractString`.

Mixing symbols and strings in `to` and `from` is not allowed.

See also: [`rename`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(i = 1, x = 2, y = 3)
1×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename!(ds, Dict(:i => "A", :x => "X"))
1×3 Dataset
 Row │ A         X         y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename!(ds, [:a, :b, :c])
1×3 Dataset
 Row │ a         b         c
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename!(ds, [:a, :b, :a])
ERROR: ArgumentError: Duplicate variable names: :a. Pass makeunique=true to make them unique using a suffix automatically.

julia> rename!(ds, [:a, :b, :a], makeunique=true)
1×3 Dataset
 Row │ a         b         a_1
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename!(uppercase, ds)
1×3 Dataset
 Row │ A         B         A_1
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3
```
"""
function rename!(ds::AbstractDataset, vals::AbstractVector{Symbol};
                 makeunique::Bool=false)
    # Modify Dataset
    rename!(index(ds), vals, makeunique=makeunique)
    _modified(_attributes(ds))
    return ds
end

function rename!(ds::AbstractDataset, vals::AbstractVector{<:AbstractString};
                 makeunique::Bool=false)
    rename!(index(ds), Symbol.(vals), makeunique=makeunique)
    _modified(_attributes(ds))
    return ds
end

function rename!(ds::AbstractDataset, args::AbstractVector{Pair{Symbol, Symbol}})
    rename!(index(ds), args)
    _modified(_attributes(ds))
    return ds
end

function rename!(ds::AbstractDataset,
                 args::Union{AbstractVector{<:Pair{Symbol, <:AbstractString}},
                             AbstractVector{<:Pair{<:AbstractString, Symbol}},
                             AbstractVector{<:Pair{<:AbstractString, <:AbstractString}},
                             AbstractDict{Symbol, Symbol},
                             AbstractDict{Symbol, <:AbstractString},
                             AbstractDict{<:AbstractString, Symbol},
                             AbstractDict{<:AbstractString, <:AbstractString}})
    rename!(index(ds), [Symbol(from) => Symbol(to) for (from, to) in args])
    _modified(_attributes(ds))
    return ds
end

function rename!(ds::AbstractDataset,
                 args::Union{AbstractVector{<:Pair{<:Integer, <:AbstractString}},
                             AbstractVector{<:Pair{<:Integer, Symbol}},
                             AbstractDict{<:Integer, <:AbstractString},
                             AbstractDict{<:Integer, Symbol}})
    rename!(index(ds), [_names(ds)[from] => Symbol(to) for (from, to) in args])
    _modified(_attributes(ds))
    return ds
end

function rename!(ds::AbstractDataset, args::Pair...)
    rename!(ds, collect(args))
    _modified(_attributes(ds))
    ds
end


function rename!(f::Function, ds::AbstractDataset)
    rename!(f, index(ds))
    _modified(_attributes(ds))
    return ds
end

"""
    rename(ds::AbstractDataset, vals::AbstractVector{Symbol};
           makeunique::Bool=false)
    rename(ds::AbstractDataset, vals::AbstractVector{<:AbstractString};
           makeunique::Bool=false)
    rename(ds::AbstractDataset, (from => to)::Pair...)
    rename(ds::AbstractDataset, d::AbstractDict)
    rename(ds::AbstractDataset, d::AbstractVector{<:Pair})
    rename(f::Function, ds::AbstractDataset)

Create a new data set that is a copy of `ds` with changed column names.
Each name is changed at most once. Permutation of names is allowed.

# Arguments
- `ds` : the `AbstractDataset`; if it is a `SubDataset` then renaming is
  only allowed if it was created using `:` as a column selector.
- `d` : an `AbstractDict` or an `AbstractVector` of `Pair`s that maps
  the original names or column numbers to new names
- `f` : a function which for each column takes the old name as a `String`
  and returns the new name that gets converted to a `Symbol`
- `vals` : new column names as a vector of `Symbol`s or `AbstractString`s
  of the same length as the number of columns in `ds`
- `makeunique` : if `false` (the default), an error will be raised
  if duplicate names are found; if `true`, duplicate names will be suffixed
  with `_i` (`i` starting at 1 for the first duplicate).

If pairs are passed to `rename` (as positional arguments or in a dictionary or
a vector) then:
* `from` value can be a `Symbol`, an `AbstractString` or an `Integer`;
* `to` value can be a `Symbol` or an `AbstractString`.

Mixing symbols and strings in `to` and `from` is not allowed.

See also: [`rename!`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(i = 1, x = 2, y = 3)
1×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename(ds, :i => :A, :x => :X)
1×3 Dataset
 Row │ A         X         y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename(ds, :x => :y, :y => :x)
1×3 Dataset
 Row │ i         y         x
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename(ds, [1 => :A, 2 => :X])
1×3 Dataset
 Row │ A         X         y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename(ds, Dict("i" => "A", "x" => "X"))
1×3 Dataset
 Row │ A         X         y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3

julia> rename(uppercase, ds)
1×3 Dataset
 Row │ I         X         Y
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         2         3
```
"""
rename(ds::AbstractDataset, vals::AbstractVector{Symbol};
       makeunique::Bool=false) = rename!(copy(ds), vals, makeunique=makeunique)
rename(ds::AbstractDataset, vals::AbstractVector{<:AbstractString};
       makeunique::Bool=false) = rename!(copy(ds), vals, makeunique=makeunique)
rename(ds::AbstractDataset, args...) = rename!(copy(ds), args...)
rename(f::Function, ds::AbstractDataset) = rename!(f, copy(ds))

"""
    size(ds::AbstractDataset[, dim])

Return a tuple containing the number of rows and columns of `ds`.
Optionally a dimension `dim` can be specified, where `1` corresponds to rows
and `2` corresponds to columns.

See also: [`nrow`](@ref), [`ncol`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(a=1:3, b='a':'c');

julia> size(ds)
(3, 2)

julia> size(ds, 1)
3
```
"""
Base.size(ds::AbstractDataset) = (nrow(ds), ncol(ds))
function Base.size(ds::AbstractDataset, i::Integer)
    if i == 1
        nrow(ds)
    elseif i == 2
        ncol(ds)
    else
        throw(ArgumentError("Datasets only have two dimensions"))
    end
end

Base.isempty(ds::AbstractDataset) = size(ds, 1) == 0 || size(ds, 2) == 0

if VERSION < v"1.6"
    Base.firstindex(ds::AbstractDataset, i::Integer) = first(axes(ds, i))
    Base.lastindex(ds::AbstractDataset, i::Integer) = last(axes(ds, i))
end
Base.axes(ds::AbstractDataset, i::Integer) = Base.OneTo(size(ds, i))

"""
    ndims(::AbstractDataset)
    ndims(::Type{<:AbstractDataset})

Return the number of dimensions of a data set, which is always `2`.
"""
Base.ndims(::AbstractDataset) = 2
Base.ndims(::Type{<:AbstractDataset}) = 2

# separate methods are needed due to dispatch ambiguity
Base.getproperty(ds::AbstractDataset, col_ind::Symbol) = ds[!, col_ind]

Base.getproperty(ds::AbstractDataset, col_ind::AbstractString) = ds[!, col_ind]

# Private fields are never exposed since they can conflict with column names
"""
    propertynames(ds::AbstractDataset)

Return a freshly allocated `Vector{Symbol}` of names of columns contained in `ds`.
"""
Base.propertynames(ds::AbstractDataset, private::Bool=false) = copy(_names(ds))

##############################################################################
##
## Similar
##
##############################################################################

"""
    similar(ds::AbstractDataset, rows::Integer=nrow(ds))

Create a new `Dataset` with the same column names and column element types
as `ds`. An optional second argument can be provided to request a number of rows
that is different than the number of rows present in `ds`.
"""
function Base.similar(ds::AbstractDataset, rows::Integer = size(ds, 1))
    rows < 0 && throw(ArgumentError("the number of rows must be non-negative"))
    # Create Dataset
    newds = Dataset(AbstractVector[similar(x, rows) for x in eachcol(ds)], copy(index(ds)),
              copycols=false)
    setinfo!(newds, _attributes(ds).meta.info[])
    newds
end

"""
    empty(ds::AbstractDataset)

Create a new `Dataset` with the same column names and column element types
as `ds` but with zero rows.
"""
Base.empty(ds::AbstractDataset) = similar(ds, 0)

##############################################################################
##
## Equality
##
##############################################################################
Base.:(==)(ds1::AbstractDataset, ds2::AbstractDataset) = isequal(ds1, ds2)

function Base.isequal(ds1::AbstractDataset, ds2::AbstractDataset)
    size(ds1, 2) == size(ds2, 2) || return false
    isequal(index(ds1), index(ds2)) || return false
    for idx in 1:size(ds1, 2)
        isequal(ds1[!, idx], ds2[!, idx]) || return false
    end
    return true
end

"""
    isapprox(ds1::AbstractDataset, ds2::AbstractDataset;
             rtol::Real=atol>0 ? 0 : √eps, atol::Real=0,
             nans::Bool=false, norm::Function=norm)

Inexact equality comparison. `ds1` and `ds2` must have the same size and column names.
Return  `true` if `isapprox` with given keyword arguments
applied to all pairs of columns stored in `ds1` and `ds2` returns `true`.
"""
function Base.isapprox(ds1::AbstractDataset, ds2::AbstractDataset;
                       atol::Real=0, rtol::Real=atol>0 ? 0 : √eps(),
                       nans::Bool=false, norm::Function=norm)
    if size(ds1) != size(ds2)
        throw(DimensionMismatch("dimensions must match: a has dims " *
                                "$(size(ds1)), b has dims $(size(ds2))"))
    end
    if !isequal(index(ds1), index(ds2))
        throw(ArgumentError("column names of passed data sets do not match"))
    end
    return all(isapprox.(eachcol(ds1), eachcol(ds2), atol=atol, rtol=rtol, nans=nans, norm=norm))
end
##############################################################################
##
## Description
##
##############################################################################

"""
    only(ds::AbstractDataset)

If `ds` has a single row return it as a `DatasetRow`; otherwise throw `ArgumentError`.
"""
function only(ds::AbstractDataset)
    nrow(ds) != 1 && throw(ArgumentError("data set must contain exactly 1 row"))
    return ds[1, :]
end

"""
    first(ds::AbstractDataset)

Get the first row of `ds` as a `DatasetRow`.
"""
Base.first(ds::AbstractDataset) = ds[1, :]

"""
    first(ds::AbstractDataset, n::Integer)

Get a data set with the `n` first rows of `ds`.
"""
Base.first(ds::AbstractDataset, n::Integer) = ds[1:min(n, nrow(ds)), :]

"""
    last(ds::AbstractDataset)

Get the last row of `ds` as a `DatasetRow`.
"""
Base.last(ds::AbstractDataset) = ds[nrow(ds), :]

"""
    last(ds::AbstractDataset, n::Integer)

Get a data set with the `n` last rows of `ds`.
"""
Base.last(ds::AbstractDataset, n::Integer) = ds[max(1, nrow(ds)-n+1):nrow(ds), :]


##############################################################################
##
## Miscellaneous
##
##############################################################################

"""
    completecases(ds::AbstractDataset, cols=:; mapformats = false, threads)

Return a Boolean vector with `true` entries indicating rows without missing values
(complete cases) in data set `ds`.

If `cols` is provided, only missing values in the corresponding columns are considered.
`cols` can be any column selector ($COLUMNINDEX_STR; $MULTICOLUMNINDEX_STR).

See also: [`dropmissing`](@ref), [`byrow`](@ref), [`filter`](@ref), [`filter!`](@ref).

Use `findall(completecases(ds))` to get the indices of the rows.

# Examples

```jldoctest
julia> ds = Dataset(i = 1:5,
                       x = [missing, 4, missing, 2, 1],
                       y = [missing, missing, "c", "d", "e"])
5×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    String?
─────┼──────────────────────────────
   1 │        1   missing  missing
   2 │        2         4  missing
   3 │        3   missing  c
   4 │        4         2  d
   5 │        5         1  e

julia> completecases(ds)
5-element Vector{Bool}:
 0
 0
 0
 1
 1

julia> completecases(ds, :x)
5-element Vector{Bool}:
 0
 1
 0
 1
 1

julia> completecases(ds, [:x, :y])
5-element Vector{Bool}:
 0
 0
 0
 1
 1
```
"""
function completecases(ds::AbstractDataset, cols::MultiColumnIndex = :; mapformats = false, threads = nrow(ds)>Threads.nthreads()*10)
    if mapformats
        colsidx = index(ds)[cols]
        by = Function[]
        for j in 1:length(colsidx)
            push!(by, !ismissing∘getformat(ds, colsidx[j]))
        end
        byrow(ds, all, cols, by = by, threads = threads)
    else
        byrow(ds, all, cols, by = !ismissing, threads = threads)
    end
end
completecases(ds::AbstractDataset, col::ColumnIndex; mapformats = false, threads = nrow(ds)>Threads.nthreads()*10) = completecases(ds, [col]; mapformats = mapformats, threads = threads)

"""
    dropmissing(ds::AbstractDataset, cols=:; view::Bool=false, mapformats = false, threads)

Return a data set excluding rows with missing values in `ds`.

If `cols` is provided, only missing values in the corresponding columns are considered.
`cols` can be any column selector ($COLUMNINDEX_STR; $MULTICOLUMNINDEX_STR).

If `view=false` a freshly allocated `Dataset` is returned.
If `view=true` then a `SubDataset` view into `ds` is returned.

See also: [`dropmissing!`](@ref), [`completecases`](@ref), [`byrow`](@ref), [`filter`](@ref), [`filter!`](@ref).

# Examples

```jldoctest
julia> ds = Dataset(i = 1:5,
                x = [missing, 4, missing, 2, 1],
                y = [missing, missing, "c", "d", "e"])
5×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    String?
─────┼──────────────────────────────
   1 │        1   missing  missing
   2 │        2         4  missing
   3 │        3   missing  c
   4 │        4         2  d
   5 │        5         1  e

julia> dropmissing(ds)
2×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    String?
─────┼──────────────────────────────
   1 │        4         2  d
   2 │        5         1  e

julia> dropmissing(ds, :x)
3×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    String?
─────┼──────────────────────────────
   1 │        2         4  missing
   2 │        4         2  d
   3 │        5         1  e

julia> dropmissing(ds, [:x, :y])
2×3 Dataset
 Row │ i         x         y
     │ identity  identity  identity
     │ Int64?    Int64?    String?
─────┼──────────────────────────────
   1 │        4         2  d
   2 │        5         1  e
```
"""
@inline function dropmissing(ds::AbstractDataset,
                             cols::Union{ColumnIndex, MultiColumnIndex}=:;
                             view::Bool=false, mapformats = false, threads = nrow(ds)>Threads.nthreads()*10)
    rowidxs = completecases(ds, cols; mapformats = mapformats, threads = threads)
    if view
        return Base.view(ds, rowidxs, :)
    else
        newds = ds[rowidxs, :]
        return newds
    end
end


function Base.Matrix(ds::AbstractDataset)
    T = mapreduce(eltype, promote_type, _columns(ds))
    return Matrix{T}(ds)
end

function Base.Matrix{T}(ds::AbstractDataset) where T
    n, p = size(ds)
    res = Matrix{T}(undef, n, p)
    idx = 1
    for (name, col) in pairs(eachcol(ds))
        try
            copyto!(res, idx, col)
        catch err
            if err isa MethodError && err.f == convert &&
               !(T >: Missing) && any(ismissing, col)
                throw(ArgumentError("cannot convert a Dataset containing missing " *
                                    "values to Matrix{$T} (found for column $name)"))
            else
                rethrow(err)
            end
        end
        idx += n
    end
    return res
end

Base.Array(ds::AbstractDataset) = Matrix(ds)
Base.Array{T}(ds::AbstractDataset) where {T} = Matrix{T}(ds)

"""
    duplicates(ds::AbstractDataset; [mapformats = false, leave = :first, threads])
    duplicates(ds::AbstractDataset, cols; [mapformats = false, leave = :first, threads])

Return a `Vector{Bool}` in which `true` entries indicate duplicate rows.
A row is a duplicate if there exists a prior row (default behaviour, see the `leave` keyword argument for other options) with all columns containing
equal values (according to `isequal`).

If `mapformats = true` the values are checked based on their formatted values.

The `leave` keyword argument determines which occurrence of duplicated rows should be indicated as non-duplicate rows.

* `leave = :first` means that every occurrence after the first one be marked as duplicate rows,
* `leave = :last` means that every occurrence before the last one be marked as duplicate rows,
* `leave = :none` means that non-duplicates rows be marked true (duplicates row be left out),
* `leave = :random` means that a random occurrence of duplicate rows left out and the rest be marked as duplicate rows.

See also [`unique`](@ref) and [`unique!`](@ref).

# Arguments
- `ds` : `AbstractDataset`
- `cols` : a selector specifying the column(s)

# Examples
```jldoctest
julia> ds = Dataset(i = 1:4, x = [1, 2, 1, 2])
4×2 Dataset
 Row │ i         x
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         1
   4 │        4         2

julia> ds = vcat(ds, ds)
8×2 Dataset
 Row │ i         x
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         1
   4 │        4         2
   5 │        1         1
   6 │        2         2
   7 │        3         1
   8 │        4         2

julia> duplicates(ds)
8-element Vector{Bool}:
 0
 0
 0
 0
 1
 1
 1
 1

julia> duplicates(ds, 2)
8-element Vector{Bool}:
 0
 0
 1
 1
 1
 1
 1
 1
```
"""
duplicates

function duplicates(ds::AbstractDataset, cols::MultiColumnIndex = :; mapformats = false, leave = :first, threads = true)
    # :xor, :nor, :and, :or are undocumented
    !(leave in (:first, :last, :none, :random, :xor, :nand, :nor, :and, :or)) && throw(ArgumentError("`leave` must be either `:first`, `:last`, `:none`, or `random`"))
    if ncol(ds) == 0
        throw(ArgumentError("finding duplicate rows in data set with no " *
                            "columns is not allowed"))
    end

    groups, gslots, ngroups = _gather_groups(ds, cols, nrow(ds) < typemax(Int32) ? Val(Int32) : Val(Int64), mapformats = mapformats, stable = false, threads = threads)
    if leave === :random
        return _nonunique_random_leave(groups, ngroups, nrow(ds))
    end
    res = trues(nrow(ds))
    seen_groups = falses(ngroups)
    if leave === :first
        _nonunique_barrier!(res, groups, seen_groups; first = true)
        return res
    elseif leave === :last
        _nonunique_barrier!(res, groups, seen_groups; first = false)
        return res
    else
        _nonunique_barrier!(res, groups, seen_groups; first = true)
        r1 = res
        res = trues(nrow(ds))
        seen_groups = falses(ngroups)
        _nonunique_barrier!(res, groups, seen_groups; first = false)
        if leave == :none
            .!(r1 .| res)
        elseif leave == :xor
            xor.(r1, res)
        elseif leave == :and
            r1 .& res
        elseif leave == :or
            r1 .| res
        elseif leave == :nand
            .!(r1 .& res)
        elseif leave == :nor
            .!(r1 .| res)
        end

    end

end
duplicates(ds::AbstractDataset, col::ColumnIndex; mapformats = false, leave = :first, threads = true) = duplicates(ds, [col]; mapformats = mapformats, leave = leave, threads = threads)

nonunique(ds::AbstractDataset, cols::MultiColumnIndex = :; mapformats = false, leave = :first, threads = true) = duplicates(ds, cols, mapformats = mapformats, leave = leave, threads = threads)
nonunique(ds::AbstractDataset, col::ColumnIndex; mapformats = false, leave = :first, threads = true) = duplicates(ds, [col], mapformats = mapformats, leave = leave, threads = threads)

function _nonunique_barrier!(res, groups, seen_groups; first = true)
    if first
        @inbounds for i in 1:length(res)
            seen_groups[groups[i]] ? nothing : (seen_groups[groups[i]] = true; res[i] = false)
        end
    else
        @inbounds for i in length(res):-1:1
            seen_groups[groups[i]] ? nothing : (seen_groups[groups[i]] = true; res[i] = false)
        end
    end
    nothing
end

function _RAND_NONUNIQUE(x)
    if x == 1
        1
    else
        rand(1:x)
    end
end

function _nonunique_random_leave_barrier!(counts, groups)
    for i in 1:length(groups)
        counts[groups[i]] += 1
    end
    map!(_RAND_NONUNIQUE, counts, counts)
end

function _fill_nonunique_randomleave!(res, counts, groups)
    for i in 1:length(res)
        res[i] = counts[groups[i]] == 1
        counts[groups[i]] -= 1
    end
end

function _nonunique_random_leave(groups, ngroups, nrows)
    counts = Vector{nrows < typemax(Int32) ? Int32 : Int64}(undef, ngroups)
    fill!(counts, 0)
    _nonunique_random_leave_barrier!(counts, groups)
    res = falses(nrows)
    _fill_nonunique_randomleave!(res, counts, groups)
    .!res
end

"""
    vcat(dss::AbstractDataset...;
         cols::Union{Symbol, AbstractVector{Symbol},
                     AbstractVector{<:AbstractString}}=:setequal,
         source::Union{Nothing, Symbol, AbstractString,
                       Pair{<:Union{Symbol, AbstractString}, <:AbstractVector}}=nothing)

Vertically concatenate `AbstractDataset`s.

The `cols` keyword argument determines the columns of the returned data set:

* `:setequal`: require all data sets to have the same column names disregarding
  order. If they appear in different orders, the order of the first provided data
  set is used.
* `:orderequal`: require all data sets to have the same column names and in the
  same order.
* `:intersect`: only the columns present in *all* provided data sets are kept.
  If the intersection is empty, an empty data set is returned.
* `:union`: columns present in *at least one* of the provided data sets are kept.
  Columns not present in some data sets are filled with `missing` where necessary.
* A vector of `Symbol`s or strings: only listed columns are kept.
  Columns not present in some data sets are filled with `missing` where necessary.

The `source` keyword argument, if not `nothing` (the default), specifies the
additional column to be added in the last position in the resulting data set
that will identify the source data set. It can be a `Symbol` or an
`AbstractString`, in which case the identifier will be the number of the passed
source data set, or a `Pair` consisting of a `Symbol` or an `AbstractString`
and of a vector specifying the data set identifiers (which do not have to be
unique). The name of the source column is not allowed to be present in any
source data set.

The order of columns is determined by the order they appear in the included data
sets, searching through the header of the first data set, then the second,
etc.

The element types of columns are determined using `promote_type`,
as with `vcat` for `AbstractVector`s.

`vcat` ignores empty data sets, making it possible to initialize an empty
data set at the beginning of a loop and `vcat` onto it.

# Example
```jldoctest
julia> ds1 = Dataset(A=1:3, B=1:3)
3×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3

julia> ds2 = Dataset(A=4:6, B=4:6)
3×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        4         4
   2 │        5         5
   3 │        6         6

julia> ds3 = Dataset(A=7:9, C=7:9)
3×2 Dataset
 Row │ A         C
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        7         7
   2 │        8         8
   3 │        9         9

julia> ds4 = Dataset()
0×0 Dataset

julia> vcat(ds1, ds2)
6×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3
   4 │        4         4
   5 │        5         5
   6 │        6         6

julia> vcat(ds1, ds3, cols=:union)
6×3 Dataset
 Row │ A         B         C
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         1   missing
   2 │        2         2   missing
   3 │        3         3   missing
   4 │        7   missing         7
   5 │        8   missing         8
   6 │        9   missing         9

julia> vcat(ds1, ds3, cols=:intersect)
6×1 Dataset
 Row │ A
     │ identity
     │ Int64?
─────┼──────────
   1 │        1
   2 │        2
   3 │        3
   4 │        7
   5 │        8
   6 │        9

julia> vcat(ds4, ds1)
3×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3

julia> vcat(ds1, ds2, ds3, ds4, cols=:union, source="source")
9×4 Dataset
 Row │ A         B         C         source
     │ identity  identity  identity  identity
     │ Int64?    Int64?    Int64?    Int64?
─────┼────────────────────────────────────────
   1 │        1         1   missing         1
   2 │        2         2   missing         1
   3 │        3         3   missing         1
   4 │        4         4   missing         2
   5 │        5         5   missing         2
   6 │        6         6   missing         2
   7 │        7   missing         7         3
   8 │        8   missing         8         3
   9 │        9   missing         9         3

julia> vcat(ds1, ds2, ds4, ds3, cols=:union, source=:source => 'a':'d')
9×4 Dataset
 Row │ A         B         C         source
     │ identity  identity  identity  identity
     │ Int64?    Int64?    Int64?    Char?
─────┼────────────────────────────────────────
   1 │        1         1   missing  a
   2 │        2         2   missing  a
   3 │        3         3   missing  a
   4 │        4         4   missing  b
   5 │        5         5   missing  b
   6 │        6         6   missing  b
   7 │        7   missing         7  d
   8 │        8   missing         8  d
   9 │        9   missing         9  d
```
"""
Base.vcat(dss::AbstractDataset...;
          cols::Union{Symbol, AbstractVector{Symbol},
                      AbstractVector{<:AbstractString}}=:setequal,
          source::Union{Nothing, SymbolOrString,
                           Pair{<:SymbolOrString, <:AbstractVector}}=nothing) =
    reduce(vcat, dss; cols=cols, source=source)

"""
    reduce(::typeof(vcat),
           dss::Union{AbstractVector{<:AbstractDataset},
                      Tuple{AbstractDataset, Vararg{AbstractDataset}}};
           cols::Union{Symbol, AbstractVector{Symbol},
                       AbstractVector{<:AbstractString}}=:setequal,
           source::Union{Nothing, Symbol, AbstractString,
                         Pair{<:Union{Symbol, AbstractString}, <:AbstractVector}}=nothing)

Efficiently reduce the given vector or tuple of `AbstractDataset`s with `vcat`.

The column order, names, and types of the resulting `Dataset`, and
the behavior of `cols` and `source` keyword arguments follow the rules specified
for [`vcat`](@ref) of `AbstractDataset`s.

# Example
```jldoctest
julia> ds1 = Dataset(A=1:3, B=1:3)
3×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3

julia> ds2 = Dataset(A=4:6, B=4:6)
3×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        4         4
   2 │        5         5
   3 │        6         6

julia> ds3 = Dataset(A=7:9, C=7:9)
3×2 Dataset
 Row │ A         C
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        7         7
   2 │        8         8
   3 │        9         9

julia> reduce(vcat, (ds1, ds2))
6×2 Dataset
 Row │ A         B
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3
   4 │        4         4
   5 │        5         5
   6 │        6         6

julia> reduce(vcat, [ds1, ds2, ds3], cols=:union, source=:source)
9×4 Dataset
 Row │ A         B         C         source
     │ identity  identity  identity  identity
     │ Int64?    Int64?    Int64?    Int64?
─────┼────────────────────────────────────────
   1 │        1         1   missing         1
   2 │        2         2   missing         1
   3 │        3         3   missing         1
   4 │        4         4   missing         2
   5 │        5         5   missing         2
   6 │        6         6   missing         2
   7 │        7   missing         7         3
   8 │        8   missing         8         3
   9 │        9   missing         9         3
```
"""
function Base.reduce(::typeof(vcat),
                     dss::Union{AbstractVector{<:AbstractDataset},
                                Tuple{AbstractDataset, Vararg{AbstractDataset}}};
                     cols::Union{Symbol, AbstractVector{Symbol},
                                 AbstractVector{<:AbstractString}}=:setequal,
                     source::Union{Nothing, SymbolOrString,
                                   Pair{<:SymbolOrString, <:AbstractVector}}=nothing)
    # Create Dataset
    res = _vcat(AbstractDataset[ds for ds in dss if ncol(ds) != 0]; cols=cols)
    if source !== nothing
        len = length(dss)
        if source isa SymbolOrString
            col, vals = source, 1:len
        else
            @assert source isa Pair{<:SymbolOrString, <:AbstractVector}
            col, vals = source
        end

        if columnindex(res, col) > 0
            idx = findfirst(ds -> columnindex(ds, col) > 0, dss)
            @assert idx !== nothing
            throw(ArgumentError("source column name :$col already exists in data set " *
                                " passed in position $idx"))
        end

        if len != length(vals)
            throw(ArgumentError("number of passed source identifiers ($(length(vals)))" *
                                "does not match the number of data sets ($len)"))
        end

        source_vec = allocatecol(eltype(vals), nrow(res))
        @assert firstindex(source_vec) == 1 && lastindex(source_vec) == nrow(res)
        start = 1
        for (v, ds) in zip(vals, dss)
            stop = start + nrow(ds) - 1
            source_vec[start:stop] .= Ref(v)
            start = stop + 1
        end

        @assert start == nrow(res) + 1
        insertcols!(res, col => source_vec)
    end

    return res
end

# Create Dataset
# TODO how formats are going to be transferred???
function _vcat(dss::AbstractVector{AbstractDataset};
               cols::Union{Symbol, AbstractVector{Symbol},
                           AbstractVector{<:AbstractString}}=:setequal)

    isempty(dss) && return Dataset()
    # Array of all headers
    allheaders = map(names, dss)
    # Array of unique headers across all data sets
    uniqueheaders = unique(allheaders)
    # All symbols present across all headers
    unionunique = union(uniqueheaders...)
    # List of symbols present in all datasets
    intersectunique = intersect(uniqueheaders...)

    if cols === :orderequal
        header = unionunique
        if length(uniqueheaders) > 1
            throw(ArgumentError("when `cols=:orderequal` all data sets need to " *
                                "have the same column names and be in the same order"))
        end
    elseif cols === :setequal || cols === :equal
        # an explicit error is thrown as :equal was supported in the past
        if cols === :equal
            throw(ArgumentError("`cols=:equal` is not supported. " *
                                "Use `:setequal` instead."))
        end

        header = unionunique
        coldiff = setdiff(unionunique, intersectunique)

        if !isempty(coldiff)
            # if any Datasets are a full superset of names, skip them
            let header=header     # julia #15276
                filter!(u -> !issetequal(u, header), uniqueheaders)
            end
            estrings = map(enumerate(uniqueheaders)) do (i, head)
                matching = findall(h -> head == h, allheaders)
                headerdiff = setdiff(coldiff, head)
                badcols = join(headerdiff, ", ", " and ")
                args = join(matching, ", ", " and ")
                return "column(s) $badcols are missing from argument(s) $args"
            end
            throw(ArgumentError(join(estrings, ", ", ", and ")))
        end
    elseif cols === :intersect
        header = intersectunique
    elseif cols === :union
        header = unionunique
    elseif cols isa Symbol
        throw(ArgumentError("Invalid `cols` value :$cols. " *
                            "Only `:orderequal`, `:setequal`, `:intersect`, " *
                            "`:union`, or a vector of column names is allowed."))
    elseif cols isa AbstractVector{Symbol}
        header = cols
    else
        @assert cols isa AbstractVector{<:AbstractString}
        header = Symbol.(cols)
    end

    length(header) == 0 && return Dataset()
    all_cols = Vector{AbstractVector}(undef, length(header))
    for (i, name) in enumerate(header)
        newcols = map(dss) do ds
            if hasproperty(ds, name)
                return ds[!, name]
            else
                Iterators.repeated(missing, nrow(ds))
            end
        end

        lens = map(length, newcols)
        T = mapreduce(eltype, promote_type, newcols)
        all_cols[i] = allocatecol(T, sum(lens))
        offset = 1
        for j in 1:length(newcols)
            copyto!(all_cols[i], offset, newcols[j])
            offset += lens[j]
        end
    end
    return Dataset(all_cols, header, copycols=false)
end

##############################################################################
##
## Hashing
##
##############################################################################

const hashds_seed = UInt == UInt32 ? 0xfd8bb02e : 0x6215bada8c8c46de

function Base.hash(ds::AbstractDataset, h::UInt)
    h += hashds_seed
    h += hash(size(ds))
    for i in 1:size(ds, 2)
        h = hash(_columns(ds)[i], h)
    end
    return h
end

Base.parent(ads::AbstractDataset) = ads
Base.parentindices(ads::AbstractDataset) = axes(ads)

## Documentation for methods defined elsewhere

function nrow end
function ncol end

"""
    nrow(ds::AbstractDataset)
    ncol(ds::AbstractDataset)

Return the number of rows or columns in an `AbstractDataset` `ds`.

See also [`size`](@ref).

**Examples**

```jldoctest
julia> ds = Dataset(i = 1:10, x = rand(10), y = rand(["a", "b", "c"], 10));

julia> size(ds)
(10, 3)

julia> nrow(ds)
10

julia> ncol(ds)
3
```

"""
(nrow, ncol)

function repeat_lengths_v2!(longnew::AbstractVector, shortold::AbstractVector,
                         lengths)
    counter = 1
    @inbounds for i in eachindex(shortold)
        l = lengths[i]
        # longnew[counter:(counter + l - 1)] .= Ref(shortold[i])
        fill!(view(longnew, counter:(counter + l - 1)),  shortold[i])
        counter += l
    end
    longnew
end

function repeat_lengths!(longnew::AbstractVector, shortold::AbstractVector,
                         lengths::AbstractVector{Int})
    counter = 1
    @inbounds for i in eachindex(shortold)
        l = lengths[i]
        longnew[counter:(counter + l - 1)] .= Ref(shortold[i])
        counter += l
    end
end


# Disallowed operations that are a common mistake

Base.getindex(::AbstractDataset, ::Union{Symbol, AbstractString}) =
        throw(ArgumentError("syntax ds[column] is not supported use ds[!, column] instead"))

Base.setindex!(::AbstractDataset, ::Any, ::Union{Symbol, Integer, AbstractString}) =
    throw(ArgumentError("syntax ds[column] is not supported use ds[!, column] instead"))
