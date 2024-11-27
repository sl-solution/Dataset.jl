# custom help for byrow()
function Docs.getdoc(x::typeof(byrow), y)
    if y == Union{}
        return _get_doc_byrow("default")
    elseif y == Tuple{typeof(sum)}
        return _get_doc_byrow("sum")
    elseif y == Tuple{typeof(mean)}
        return _get_doc_byrow("mean")
    elseif y == Tuple{typeof(all)}
        return _get_doc_byrow("all")
    elseif y == Tuple{typeof(any)}
        return _get_doc_byrow("any")
    elseif y == Tuple{typeof(count)}
        return _get_doc_byrow("count")
    elseif y == Tuple{typeof(prod)}
        return _get_doc_byrow("prod")
    elseif y == Tuple{typeof(isequal)}
        return _get_doc_byrow("isequal")
    elseif VERSION >= v"1.8" && y == Tuple{typeof(allequal)}
        return _get_doc_byrow("allequal")
    elseif y == Tuple{typeof(isless)}
        return _get_doc_byrow("isless")
    elseif y == Tuple{typeof(in)}
        return _get_doc_byrow("in")
    elseif y == Tuple{typeof(findfirst)}
        return _get_doc_byrow("findfirst")
    elseif y == Tuple{typeof(findlast)}
        return _get_doc_byrow("findlast")
    elseif y == Tuple{typeof(select)}
        return _get_doc_byrow("select")
    elseif y == Tuple{typeof(fill!)}
        return _get_doc_byrow("fill!")
    elseif y == Tuple{typeof(fill)}
        return _get_doc_byrow("fill")
    elseif y == Tuple{typeof(coalesce)}
        return _get_doc_byrow("coalesce")
    elseif y == Tuple{typeof(maximum)}
        return _get_doc_byrow("maximum")
    elseif y == Tuple{typeof(minimum)}
        return _get_doc_byrow("minimum")
    elseif y == Tuple{typeof(argmax)}
        return _get_doc_byrow("argmax")
    elseif y == Tuple{typeof(argmin)}
        return _get_doc_byrow("argmin")
    elseif y == Tuple{typeof(issorted)}
        return _get_doc_byrow("issorted")
    elseif y == Tuple{typeof(join)}
        return _get_doc_byrow("join")
    elseif y == Tuple{typeof(hash)}
        return _get_doc_byrow("hash")
    elseif y == Tuple{typeof(nunique)}
        return _get_doc_byrow("nunique")
    elseif y == Tuple{typeof(mapreduce)}
        return _get_doc_byrow("mapreduce")
    elseif y == Tuple{typeof(var)}
        return _get_doc_byrow("var")
    elseif y == Tuple{typeof(std)}
        return _get_doc_byrow("std")
    elseif y == Tuple{typeof(cumsum!)}
        return _get_doc_byrow("cumsum!")
    elseif y == Tuple{typeof(cumsum)}
        return _get_doc_byrow("cumsum")
    elseif y == Tuple{typeof(cumprod!)}
        return _get_doc_byrow("cumprod!")
    elseif y == Tuple{typeof(cumprod)}
        return _get_doc_byrow("cumprod")
    elseif y == Tuple{typeof(cummax!)}
        return _get_doc_byrow("cummax!")
    elseif y == Tuple{typeof(cummax)}
        return _get_doc_byrow("cummax")
    elseif y == Tuple{typeof(cummin!)}
        return _get_doc_byrow("cummin!")
    elseif y == Tuple{typeof(cummin)}
        return _get_doc_byrow("cummin")
    elseif y == Tuple{typeof(sort!)}
        return _get_doc_byrow("sort!")
    elseif y == Tuple{typeof(sort)}
        return _get_doc_byrow("sort")
    elseif y == Tuple{typeof(stdze!)}
        return _get_doc_byrow("stdze!")
    elseif y == Tuple{typeof(stdze)}
        return _get_doc_byrow("stdze")
    elseif y == Tuple{typeof(rescale!)}
        return _get_doc_byrow("rescale!")
    elseif y == Tuple{typeof(rescale)}
        return _get_doc_byrow("rescale")
    else
        return _get_doc_byrow("generic")
    end
end



function _get_doc_byrow(fun; text = byrow_docs_text)
    split_text = split(text, "@@@@")
    loc = findfirst(==(fun), split_text)
    Markdown.parse(split_text[loc+1])
end

byrow_docs_text = """
@@@@default@@@@
    byrow(ds::AbstractDataset, fun, cols; ...)

Perform a row-wise operation specified by `fun` on selected columns `cols`. Generally,
`fun` can be any function that returns a scalar value for each row.

> User can pass a type as `fun` when `cols` is referring to a single column. In this case, `byrow` simply converts the selected column to vector of type `fun`.

`byrow` is fine tuned for the following operations. To get extra help for each of them search help for `byrow(fun)`, e.g. `?byrow(sum)`;

# Reduction operations

- `all`
- `allequal` (this needs Julia 1.8 or later)
- `any`
- `argmax`
- `argmin`
- `coalesce`
- `count`
- `findfirst`
- `findlast`
- `hash`
- `in`
- `isequal`
- `isless`
- `issorted`
- `join`
- `mapreduce`
- `maximum`
- `mean`
- `minimum`
- `nunique`
- `prod`
- `select`
- `std`
- `sum`
- `var`

# Special operations

- `cummax`
- `cummax!`
- `cummin`
- `cummin!`
- `cumprod`
- `cumprod!`
- `cumsum`
- `cumsum!`
- `fill`
- `fill!`
- `sort`
- `sort!`
- `stdze`
- `stdze!`
- `rescale`
- `rescale!`

@@@@sum@@@@
    byrow(ds::AbstractDataset, sum, cols = names(ds, Number); [by = identity, threads])

Sum results of calling function `by` on each element of each row of `ds`. If `cols` is not specified, `byrow`
computes sum for all numeric columns in `ds`.

Passing `threads = false` disables multithreaded computations.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

## Example

```jldoctest
julia> ds = Dataset(x = [1,2,3], y = [2.0, 1.5, 4.0])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Float64?
─────┼────────────────────
   1 │        1       2.0
   2 │        2       1.5
   3 │        3       4.0

julia> byrow(ds, sum, :)
3-element Vector{Float64}:
 3.0
 3.5
 7.0
```
@@@@mean@@@@
    byrow(ds::AbstractDataset, mean, cols = names(ds, Number); [by = identity, threads])

Compute mean of the results of calling function `by` on each element of each row of `ds`. If `cols` is not specified, `byrow`
computes mean for all numeric columns in `ds`.

Passing `threads = false` disables multithreaded computations.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

## Example

```jldoctest
julia> ds = Dataset(x = [1,2,3], y = [2.0, 1.5, 4.0])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Float64?
─────┼────────────────────
   1 │        1       2.0
   2 │        2       1.5
   3 │        3       4.0

julia> byrow(ds, mean, :)
3-element Vector{Float64}:
 1.5
 1.75
 3.5
```
@@@@all@@@@
    byrow(ds::AbstractDataset, all, cols = :; [by = isequal(true), threads, mapformats = false])

Test whether all elements in each row in selected columns are `true`, when `by` is passed, determine whether predicate `by` returns `true` for all elements in the row.

By default, `byrow` uses the actual values for test the elements, however, passing `mapformats = true`
change this to the formatted values.

Each columns in `cols` may have its own `by`. This may be achieved by passing a vector of predicates to `by`.

Passing `threads = false` disables multithreaded computations.

See [`filter`](@ref), [`filter!`](@ref), [`delete`](@ref), [`delete!`](@ref)

## Example

```jldoctest
julia> ds = Dataset(x = [1,2,3], y = [2.0, 1.5, 4.0])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Float64?
─────┼────────────────────
   1 │        1       2.0
   2 │        2       1.5
   3 │        3       4.0

julia> byrow(ds, all, :, by = [==(2), >(1)])
3-element Vector{Bool}:
 0
 1
 0
```
@@@@any@@@@
    byrow(ds::AbstractDataset, any, cols = :; [by = isequal(true), threads, mapformats = false])

Test whether any elements in each row in selected columns is `true`, when `by` is passed, determine whether predicate `by` returns `true` for any elements in the row.

By default, `byrow` uses the actual values for test the elements, however, passing `mapformats = true`
change this to the formatted values.

Each columns in `cols` may have its own `by`. This may be achieved by passing a vector of predicates to `by`.

Passing `threads = false` disables multithreaded computations.

See [`filter`](@ref), [`filter!`](@ref), [`delete`](@ref), [`delete!`](@ref)

## Example

```jldoctest
julia> ds = Dataset(x = [1,2,3], y = [2.0, 1.5, 4.0])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Float64?
─────┼────────────────────
   1 │        1       2.0
   2 │        2       1.5
   3 │        3       4.0

julia> byrow(ds, any, :, by = [==(2), >(1)])
3-element Vector{Bool}:
 1
 1
 1
```
@@@@count@@@@
    byrow(ds::AbstractDataset, count, cols = :; [by = isequal(true), threads])

Count the number of elements in each row for selected columns which the function `by` returns `true`.

Passing `threads = false` disables multithreaded computations.

## Example

```jldoctest
julia> julia> ds = Dataset(x = [1,2,3], y = [2, 6, 5])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         2
   2 │        2         6
   3 │        3         5

julia> byrow(ds, count, :, by = isodd)
3-element Vector{Int32}:
 1
 0
 2
```
@@@@prod@@@@
    byrow(ds::AbstractDataset, prod, cols = names(ds, Number); [by = identity, threads])

Return the product of the results of calling function `by` on each element of each row of `ds`. If `cols` is not specified, `byrow`
computes product for all numeric columns in `ds`.

Passing `threads = false` disables multithreaded computations.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

## Example

```jldoctest
julia>  ds = Dataset(x = [1,2,3], y = [2.0, 1.5, 4.0])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Float64?
─────┼────────────────────
   1 │        1       2.0
   2 │        2       1.5
   3 │        3       4.0

julia> byrow(ds, prod, :)
3-element Vector{Union{Missing, Float64}}:
  2.0
  3.0
 12.0
```
@@@@isequal@@@@
    byrow(ds::AbstractDataset, isequal, cols; [with = nothing, threads])

Returns a boolean vector which is `true` if all values in the corresponding row are equal (using `isequal`).
 Optionally, a vector of values can be passed view the `with` keyword argument to compare values in selected
 columns with the passed vector.

Passing `threads = false` disables multithreaded computations.

See [`byrow(isless)`](@ref), [`byrow(in)`](@ref), [`byrow(issorted)`](@ref)

## Examples

```jldoctest
julia> ds = Dataset(x1 = [1,2,3,1,2,3], x2 = [1,2,1,2,1,2])
6×2 Dataset
 Row │ x1        x2
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         1
   4 │        1         2
   5 │        2         1
   6 │        3         2

julia> byrow(ds, isequal, [1,2])
6-element Vector{Bool}:
 1
 1
 0
 0
 0
 0

julia> byrow(ds, isequal, [1,2], with = [2,2,2,3,3,3])
6-element Vector{Bool}:
 0
 1
 0
 0
 0
 0
```
@@@@allequal@@@@
    byrow(ds::AbstractDataset, allequal, cols; [threads])

Returns a boolean vector which is `true` if all values in the corresponding row are equal (using `isequal`).

Passing `threads = false` disables multithreaded computations.

See [`byrow(isequal)`](@ref), [`byrow(isless)`](@ref), [`byrow(in)`](@ref), [`byrow(issorted)`](@ref)
@@@@isless@@@@
    byrow(ds::AbstractDataset, isless, cols, [with, threads, rev = false, lt = isless])

Return a boolean vector which is true if all values in corresponding row for selected `cols` are less than value given by the `with` keyword argument. A vector, or a column name can be passed via `with`.

Passing `rev = true` returns true if all values are greater than passed values via `with`.

By default, the comparison is done via `isless` function, however, user may change it by passing a function via the `lt` keyword argument. The function passed to `lt` must accept two arguments where it takes its first argument from `cols` and its second argument from `with`. However, if `rev = true` the function passed as `lt` will take its first argument from `with` and its second argument from `cols`. The function passed as `lt` must return `true` or `false`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(isequal)`](@ref), [`byrow(in)`](@ref), [`byrow(issorted)`](@ref)

## Examples

```jldoctest
julia> ds = Dataset(x1 = [1,2,3,1,2,3], x2 = [1,2,1,2,1,2], x3 = 6:-1:1)
6×3 Dataset
 Row │ x1        x2        x3
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         1         6
   2 │        2         2         5
   3 │        3         1         4
   4 │        1         2         3
   5 │        2         1         2
   6 │        3         2         1

julia> byrow(ds, isless, [1,2], with = :x3)
6-element Vector{Bool}:
 1
 1
 1
 1
 0
 0

julia> byrow(ds, isless, 1:2, with = :x3, lt = (x,y) -> isless(x^2, y))
6-element Vector{Bool}:
 1
 1
 0
 0
 0
 0

julia> ds = Dataset(x1 = [1,2,3,1,2,3], x2 = [1,2,1,2,1,2],
                    x3 = [(1,2), (2,3), (1,2), (4,5), (1,2), (1,2)])
6×3 Dataset
 Row │ x1        x2        x3
     │ identity  identity  identity
     │ Int64?    Int64?    Tuple…?
─────┼──────────────────────────────
   1 │        1         1  (1, 2)
   2 │        2         2  (2, 3)
   3 │        3         1  (1, 2)
   4 │        1         2  (4, 5)
   5 │        2         1  (1, 2)
   6 │        3         2  (1, 2)

julia> byrow(ds, isless, 1:2, with = :x3, lt = in)
6-element Vector{Bool}:
 1
 1
 0
 0
 1
 0
```
@@@@in@@@@
    byrow(ds::AbstractDataset, in, cols; [item, threads, eq = isequal])

Return a boolean vector which its elements are true if in a row the value of `item` is equal to any values from `cols`. The equality is checked via the function passed as `eq`. User can pass a vector of values or a column name to `item`.

The function passed as `eq` must accept two arguments where it takes its first argument from `item` and its second argument from `cols`. The function passed as `eq` must return `true` or `false`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(isequal)`](@ref), [`byrow(isless)`](@ref), [`byrow(issorted)`](@ref)

## Examples

```jldoctest
julia> ds = Dataset(x1 = [1,2,3,1,2,3], x2 = [1,2,1,2,1,2], x3 = 6:-1:1)
6×3 Dataset
 Row │ x1        x2        x3
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         1         6
   2 │        2         2         5
   3 │        3         1         4
   4 │        1         2         3
   5 │        2         1         2
   6 │        3         2         1

julia> byrow(ds, in, r"x", item = [1,2,3,4,5,6])
6-element Vector{Bool}:
 1
 1
 1
 0
 0
 0

julia> byrow(ds, in, [2,3], item = :x1, eq = isless)
6-element Vector{Bool}:
 1
 1
 1
 1
 0
 0
julia> byrow(ds, in, r"x", item = [5,4,5,4,5,4], eq = (x,y) -> x+y == 11)
6-element Vector{Bool}:
 1
 0
 0
 0
 0
 0
```
@@@@findfirst@@@@
    byrow(ds::AbstractDataset, findfirst, cols; [by = identity, item = nothing, eq = isequal, threads])

Return the column name of the first `true` value in `cols` or for which `by` returns `true`. If no such value is found, it returns `missing`. User can pass a vector of values or a column name to `item` to find the column name of the first time that the value of `item` is equal to the value of the column. User may use a customised function for checking the equlity of `item` and `columns` by passing it to the `eq` keyword argument. The function passed as `eq` must be a binary function where its first argument is from `item` and its second argument is from `col`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(findlast)`](@ref), [`byrow(select)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(g = [1, 1, 1, 2, 2],
                               x1_int = [0, 0, 1, missing, 2],
                               x2_int = [3, 2, 1, 3, -2],
                               x1_float = [1.2, missing, -1.0, 2.3, 10],
                               x2_float = [missing, missing, 3.0, missing, missing],
                               x3_float = [missing, missing, -1.4, 3.0, -100.0])
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float   x2_float   x3_float
     │ identity  identity  identity  identity   identity   identity
     │ Int64?    Int64?    Int64?    Float64?   Float64?   Float64?
─────┼───────────────────────────────────────────────────────────────
   1 │        1         0         3        1.2  missing    missing
   2 │        1         0         2  missing    missing    missing
   3 │        1         1         1       -1.0        3.0       -1.4
   4 │        2   missing         3        2.3  missing          3.0
   5 │        2         2        -2       10.0  missing       -100.0

julia> byrow(ds, findfirst, :, by = ismissing)
5-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :x2_float
 :x1_float
 missing
 :x1_int
 :x2_float

julia> byrow(ds, findfirst, 1:3, item = [1,1,1,1,1])
5-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :g
 :g
 :g
 missing
 missing

julia> ds = Dataset(x1 = [1,2,2], x2 = [5,6,7], x3 = [8,9,10])
3×3 Dataset
 Row │ x1        x2        x3
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         5         8
   2 │        2         6         9
   3 │        2         7        10

julia> byrow(ds, select, :, with = byrow(ds, findfirst, :, by = isodd))
3-element Vector{Union{Missing, Int64}}:
 1
 9
 7
```
@@@@findlast@@@@
    byrow(ds::AbstractDataset, findlast, cols; [by = identity, item = nothing, eq = isequal, threads])

Return the column name of the last `true` value in `cols` or for which `by` returns `true`. If no such value is found, it returns `missing`. User can pass a vector of values or a column name to `item` to find the column name of the last time that the value of `item` is equal to the value of the column. User may use a customised function for checking the equlity of `item` and `columns` by passing it to the `eq` keyword argument. The function passed as `eq` must be a binary function where its first argument is from `item` and its second argument is from `col`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(findfirst)`](@ref), [`byrow(select)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(g = [1, 1, 1, 2, 2],
                               x1_int = [0, 0, 1, missing, 2],
                               x2_int = [3, 2, 1, 3, -2],
                               x1_float = [1.2, missing, -1.0, 2.3, 10],
                               x2_float = [missing, missing, 3.0, missing, missing],
                               x3_float = [missing, missing, -1.4, 3.0, -100.0])
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float   x2_float   x3_float
     │ identity  identity  identity  identity   identity   identity
     │ Int64?    Int64?    Int64?    Float64?   Float64?   Float64?
─────┼───────────────────────────────────────────────────────────────
   1 │        1         0         3        1.2  missing    missing
   2 │        1         0         2  missing    missing    missing
   3 │        1         1         1       -1.0        3.0       -1.4
   4 │        2   missing         3        2.3  missing          3.0
   5 │        2         2        -2       10.0  missing       -100.0

julia> byrow(ds, findlast, :, by = ismissing)
5-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :x3_float
 :x3_float
 missing
 :x2_float
 :x2_float

julia> byrow(ds, findlast, 1:3, item = [1,1,1,1,1])
5-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :g
 :g
 :x2_int
 missing
 missing

julia> ds = Dataset(x1 = [1,2,2], x2 = [5,6,7], x3 = [8,9,10])
3×3 Dataset
 Row │ x1        x2        x3
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         5         8
   2 │        2         6         9
   3 │        2         7        10

julia> byrow(ds, select, :, with = byrow(ds, findlast, :, by = isodd))
3-element Vector{Union{Missing, Int64}}:
 5
 9
 7
```
@@@@select@@@@
    byrow(ds::AbstractDataset, select, cols; [with, threads])

Select value of `with` among `cols`. The `with` must be a vector of column names(`Symbol` or `String`) or column index (relative to column position in `cols`) or a column name which contains this information.

For heterogeneous column types, `byrow` use `promote_type` for the output. If the column select doesn't exist among `cols`, `byrow` returns `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(findfirst)`](@ref), [`byrow(findlast)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x1 = [1,2,3,4],
            x2 = [1.5,6.5,3.4,2.4],
            x3 = [true, false, true, false],
            y1 = ["x2", "x1", missing, "x2"],
            y2 = [:x2, :x1, missing, :x2],
            y3 = [3,1,1,2])
4×6 Dataset
 Row │ x1        x2        x3        y1        y2        y3
     │ identity  identity  identity  identity  identity  identity
     │ Int64?    Float64?  Bool?     String?   Symbol?   Int64?
─────┼────────────────────────────────────────────────────────────
   1 │        1       1.5      true  x2        x2               3
   2 │        2       6.5     false  x1        x1               1
   3 │        3       3.4      true  missing   missing          1
   4 │        4       2.4     false  x2        x2               2

julia> byrow(ds, select, 1:2, with = :y1)
4-element Vector{Union{Missing, Float64}}:
 1.5
 2.0
  missing
 2.4

julia> byrow(ds, select, [2,1,3], with = :y3)
4-element Vector{Union{Missing, Float64}}:
 1.0
 6.5
 3.4
 4.0

julia> byrow(ds, select, [2,1,3], with = [3,1,1,2])
4-element Vector{Union{Missing, Float64}}:
 1.0
 6.5
 3.4
 4.0

julia> ds = Dataset(x1 = [1,2,2], x2 = [5,6,7], x3 = [8,9,10])
3×3 Dataset
 Row │ x1        x2        x3
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1         5         8
   2 │        2         6         9
   3 │        2         7        10

julia> byrow(ds, select, :, with = byrow(ds, findfirst, :, by = isodd))
3-element Vector{Union{Missing, Int64}}:
 1
 9
 7
```
@@@@fill!@@@@
    byrow(ds::AbstractDataset, fill!, cols; [with, by = ismissing, rolling = false, threads])

Fill missing (default behaviour) values in `cols` with values from `with`. User can pass a vector of values or a column name to `with`. `byrow` fills the values in-place, so the type of `cols` and `with` must match. By default, `byrow` fills only missing values in `cols`, but, user can pass any function to `by` which `byrow` fills only the values that returns `true` when `by` is called on them.

When `rolling = true`, `byrow` uses `with` to fill the missing values in the first column among `cols` and replace `with` with the updated values in the first column and uses these values to fill the missing values in the second column among `cols` and replace `with` with the updated values in the second column, and continues this process.

Passing `threads = false` disables multithreaded computations.

`fill!` is a special `byrow` operations, because it changes the input data set rather than producing a vector.

See [`byrow(fill)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x = [1,missing,3], y = [missing,2, 3])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1   missing
   2 │  missing         2
   3 │        3         3

julia> byrow(ds, fill!, :, with = 1:3)
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3

julia> ds = Dataset(x = [1,0,3], y = [0,2,3])
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         0
   2 │        0         2
   3 │        3         3

julia> byrow(ds, fill!, :, with = 1:3, by = isequal(0))
3×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?    Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
   3 │        3         3

julia> ds = Dataset(x = [2,0,3], y = [0,2,3], z = [5,0,0])
3×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        2         0         5
   2 │        0         2         0
   3 │        3         3         0

julia> byrow(ds, fill!, :, with = [missing, missing, missing], by = isequal(0), rolling = true)
3×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        2         2         5
   2 │  missing         2         2
   3 │        3         3         3
```
@@@@fill@@@@
    byrow(ds::AbstractDataset, fill, cols; [with, by = ismissing, rolling = false, threads])

Variant of `byrow(fill!)` which passes a copy of `ds` and leaves `ds` unchanged.

See [`byrow(fill!)`](@ref)
@@@@coalesce@@@@
    byrow(ds::AbstractDataset, coalesce, cols; [threads])

Return the first value in each row of `cols` which is not equal to `missing`, if any. Otherwise return `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(select)`](@ref), [`byrow(findfirst)`](@ref), [`byrow(findlast)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x = [1,missing, missing], y = [missing, missing, 3], z = [5, missing, missing])
3×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?    Int64?    Int64?
─────┼──────────────────────────────
   1 │        1   missing         5
   2 │  missing   missing   missing
   3 │  missing         3   missing

julia> byrow(ds, coalesce, :)
3-element Vector{Union{Missing, Int64}}:
 1
  missing
 3

julia> byrow(ds, coalesce, [:z, :y, :x])
3-element Vector{Union{Missing, Int64}}:
 5
  missing
 3
```
@@@@maximum@@@@
    byrow(ds::AbstractDataset, maximum, cols; [by = identity, threads])

Return the largest result of calling function `by` on each values in each row (of selected columns). If `cols` is not specified, `byrow`
returns maximum for all numeric columns in `ds`.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(minimum)`](@ref), [`byrow(argmax)`](@ref), [`byrow(argmin)`](@ref)

# Examples

```jldoctest
julia> ds = Dataset(x=[1,2,3], y=[1.3,-2.4,5.5], z=[missing, 4,1])
3×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?    Float64?  Int64?
─────┼──────────────────────────────
   1 │        1       1.3   missing
   2 │        2      -2.4         4
   3 │        3       5.5         1

julia> byrow(ds, maximum)
3-element Vector{Union{Missing, Float64}}:
 1.3
 4.0
 5.5

julia> byrow(ds, maximum, [1,3])
3-element Vector{Union{Missing, Int64}}:
 1
 4
 3
```
@@@@minimum@@@@
    byrow(ds::AbstractDataset, minimum, cols; [by = identity, threads])

Return the smallest result of calling function `by` on each values in each row (of selected columns). If `cols` is not specified, `byrow`
returns minimum for all numeric columns in `ds`.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(maximum)`](@ref), [`byrow(argmax)`](@ref), [`byrow(argmin)`](@ref)

# Examples

```jldoctest
julia> ds = Dataset(x=[1,2,3], y=[1.3,-2.4,5.5], z=[missing, 4,1])
3×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?    Float64?  Int64?
─────┼──────────────────────────────
   1 │        1       1.3   missing
   2 │        2      -2.4         4
   3 │        3       5.5         1

julia> byrow(ds, minimum)
3-element Vector{Union{Missing, Float64}}:
  1.0
 -2.4
  1.0

julia> byrow(ds, minimum, [1,3])
3-element Vector{Union{Missing, Int64}}:
 1
 2
 1
```
@@@@argmax@@@@
    byrow(ds::AbstractDataset, argmax, cols; [by = identity, threads])

Return the column name of the maximum result of calling function `by` on each values in each row (of selected columns). If `cols` is not specified, `byrow`
passes all numeric columns in `ds`.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(maximum)`](@ref), [`byrow(minimum)`](@ref), [`byrow(argmin)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x=[1,2,missing], y=[1.3,-2.4,missing], z=[missing, 4,missing])
3×3 Dataset
 Row │ x         y          z
     │ identity  identity   identity
     │ Int64?    Float64?   Int64?
─────┼───────────────────────────────
   1 │        1        1.3   missing
   2 │        2       -2.4         4
   3 │  missing  missing     missing

julia> byrow(ds, argmax)
3-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :y
 :z
 missing

julia> byrow(ds, argmax, 1:2, by = abs)
3-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :y
 :y
 missing
```
@@@@argmin@@@@
    byrow(ds::AbstractDataset, argmin, cols; [by = identity, threads])

Return the column name of the minimum result of calling function `by` on each values in each row (of selected columns). If `cols` is not specified, `byrow`
passes all numeric columns in `ds`.

Missing values are removed from the calculation. When all values in a row are missing, it returns `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(maximum)`](@ref), [`byrow(minimum)`](@ref), [`byrow(argmax)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x=[1,2,missing], y=[1.3,-2.4,missing], z=[missing, 4,missing])
3×3 Dataset
 Row │ x         y          z
     │ identity  identity   identity
     │ Int64?    Float64?   Int64?
─────┼───────────────────────────────
   1 │        1        1.3   missing
   2 │        2       -2.4         4
   3 │  missing  missing     missing

julia> byrow(ds, argmin)
3-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :x
 :y
 missing

julia> byrow(ds, argmin, 1:2, by = abs)
3-element PooledArrays.PooledVector{Union{Missing, Symbol}, UInt32, Vector{UInt32}}:
 :x
 :x
 missing
```
@@@@issorted@@@@
    byrow(ds::AbstractDataset, issorted, cols; [rev = false, lt = isless, threads])

Test whether the values in rows (in selected `cols`) are in sorted order. Passing `rev = true` test whether the values in rows are in descending order. By default, the order of values is check by the `isless` function, however, user may pass any function to `lt`. The passed function to `lt` must accept two arguments where `byrow` calls `!lt(x2, x1)` when `rev = false` and `!lt(x1, x2)` when `rev = true` on consecutive column values.

Missing values are larger than any other values. User may pass a customised funtion to `lt` to skip missing values.

Passing `threads = false` disables multithreaded computations.

See [`byrow(isequal)`](@ref), [`byrow(isless)`](@ref), [`byrow(in)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x=[1,2,missing], y=[1.3,-2.4,missing], z=[missing, 4,missing])
3×3 Dataset
 Row │ x         y          z
     │ identity  identity   identity
     │ Int64?    Float64?   Int64?
─────┼───────────────────────────────
   1 │        1        1.3   missing
   2 │        2       -2.4         4
   3 │  missing  missing     missing

julia> byrow(ds, issorted, :)
3-element Vector{Bool}:
 1
 0
 1

julia> byrow(ds, issorted, :, lt = (x,y)->isless(abs(x), abs(y)))
3-element Vector{Bool}:
 1
 1
 1

julia> byrow(ds, issorted, :, lt = isequal) # byrow checks !lt(y, x)
3-element Vector{Bool}:
 1
 1
 0

julia> byrow(ds, issorted, :, lt = !isequal)
3-element Vector{Bool}:
 0
 0
 1
```
@@@@join@@@@
    byrow(ds::AbstractDataset, join, cols; [delim = "", last = "", threads])

For each row and selected columns convert values to string and join them into a single string, inserting the given delimiter (if any) between adjacent strings. If `last` is given, it will be used instead of `delim` between the last two strings. Missing values are converted to empty string and `true` and `false` converted to `1` and `0`, respectively.

Passing `threads = false` disables multithreaded computations.
@@@@hash@@@@
    byrow(ds::AbstractDataset, hash, cols; [by = identity, threads])

Compute an integer hash code of result of calling `by` on each values in each row of selected `cols`. When `cols` is not specified `byrow` compute hash code for all columns in `ds`.

Passing `threads = false` disables multithreaded computations.
@@@@nunique@@@@
    byrow(ds::AbstractDataset, nunique, cols; [by = identity, count_missing = true])

Return the number of unique values of the result of calling `by` on each values in each row of selected `cols`. When `cols` is not specified, `byrow` returns the number of unique values for all numeric columns. `missing` are counted as distinct value, and passing `count_missing = false` drop missings from the final count.
@@@@mapreduce@@@@
    byrow(ds::AbstractDataset, mapreduce, cols; op = .+, f = identity, init, kwargs...)

Map `f` on each values in each row of selected `cols` and reduce the result by using `op`. Keyword arguments `op` and `init` must be passed.
@@@@var@@@@
    byrow(ds::AbstractDataset, var, cols; [dof = true, by = identity, threads])

Compute the variance of result of calling `by` on each value in each row of `ds` for selected `cols`. When `cols` is not specified `byrow` computes the variance for all numeric columns. By default, degree of freedom is used for denominator, and passing `dof = false` change it to number of values.

Missing values are droped from calculations, and when all values in a row are `missing` it returns `missing`.

Passing `threads = false` disables multithreaded computations.

# Examples
```jldoctest
julia> ds = Dataset(x1 = [1.0,missing,missing], x2 = [5,6,missing])
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Int64?
─────┼─────────────────────
   1 │       1.0         5
   2 │ missing           6
   3 │ missing     missing

julia> byrow(ds, var, :)
3-element Vector{Union{Missing, Float64}}:
 8.0
  missing
  missing

julia> byrow(ds, var, :, dof = false)
3-element Vector{Union{Missing, Float64}}:
 4.0
 0.0
  missing
```
@@@@std@@@@
    byrow(ds::AbstractDataset, std, cols; [dof = true, by = identity, threads])

Compute the standard deviation of result of calling `by` on each value in each row of `ds` for selected `cols`. When `cols` is not specified `byrow` computes the standard deviation for all numeric columns. By default, degree of freedom is used for denominator, and passing `dof = false` change it to number of values.

Missing values are droped from calculations, and when all values in a row are `missing` it returns `missing`.

Passing `threads = false` disables multithreaded computations.

# Examples
```jldoctest
julia> ds = Dataset(x1 = [1.0,missing,missing], x2 = [5,6,missing])
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Int64?
─────┼─────────────────────
   1 │       1.0         5
   2 │ missing           6
   3 │ missing     missing

julia> byrow(ds, std, :)
3-element Vector{Union{Missing, Float64}}:
 2.8284271247461903
  missing
  missing

julia> byrow(ds, std, :, dof = false)
3-element Vector{Union{Missing, Float64}}:
 2.0
 0.0
  missing
```
@@@@cumsum!@@@@
    byrow(ds::Dataset, cumsum!, cols; [missings = :ignore, threads])

Replace each value in `cols` by the result of `cumsum` on each row. When `cols` is not specified `byrow` replace every numeric columns. The type of selected column will be promoted to be able to contain the result of computations. By default missing values are filled with the result of preceding calculations, and passing `missings = :skip` leaves `missing` values untouched.

Passing `threads = false` disables multithreaded computations.

See [`byrow(cumsum)`](@ref), [`byrow(cumprod!)`](@ref), [`byrow(cummax!)`](@ref), [`byrow(cummin!)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x1 = [1.0,missing,2.0], x2 = [5,6,missing])
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Int64?
─────┼─────────────────────
   1 │       1.0         5
   2 │ missing           6
   3 │       2.0   missing

julia> byrow(ds, cumsum!)
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Float64?
─────┼─────────────────────
   1 │       1.0       6.0
   2 │ missing         6.0
   3 │       2.0       2.0

julia> ds = Dataset(x1 = [1.0,missing,2.0], x2 = [5,6,missing])
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Int64?
─────┼─────────────────────
   1 │       1.0         5
   2 │ missing           6
   3 │       2.0   missing

julia> byrow(ds, cumsum!, missings = :skip)
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Float64?
─────┼──────────────────────
   1 │       1.0        6.0
   2 │ missing          6.0
   3 │       2.0  missing
```
@@@@cumsum@@@@
    byrow(ds::AbstractDataset, cumsum, cols; [missings = :ignore, threads])

Variant of `byrow(cumsum!)` which pass a copy of `ds` and leave `ds` untouched.
@@@@cumprod!@@@@
    byrow(ds::Dataset, cumprod!, cols; [missings = :ignore, threads])

Replace each value in `cols` by the result of `cumprod` on each row. When `cols` is not specified `byrow` replace every numeric columns. The type of selected column will be promoted to be able to contain the result of computations. By default missing values are filled with the result of preceding calculations, and passing `missings = :skip` leaves `missing` values untouched.

Passing `threads = false` disables multithreaded computations.

See [`byrow(cumprod)`](@ref), [`byrow(cumsum!)`](@ref), [`byrow(cummax!)`](@ref), [`byrow(cummin!)`](@ref)
@@@@cumprod@@@@
    byrow(ds::AbstractDataset, cumprod, cols; [missings = :ignore, threads])

Variant of `byrow(cumprod!)` which pass a copy of `ds` and leave `ds` untouched.
@@@@cummax!@@@@
    byrow(ds::Dataset, cummax!, cols; [missings = :ignore, threads])

Replace each value in `cols` by the result of cumulative maximum on each row. When `cols` is not specified `byrow` replace every numeric columns. The type of selected column will be promoted to be able to contain the result of computations. By default missing values are filled with the result of preceding calculations, and passing `missings = :skip` leaves `missing` values untouched.

Passing `threads = false` disables multithreaded computations.

See [`byrow(cummax)`](@ref), [`byrow(cumsum!)`](@ref), [`byrow(cumprod!)`](@ref), [`byrow(cummin!)`](@ref)
@@@@cummax@@@@
    byrow(ds::AbstractDataset, cummax, cols; [missings = :ignore, threads])

Variant of `byrow(cummax!)` which pass a copy of `ds` and leave `ds` untouched.
@@@@cummin!@@@@
    byrow(ds::Dataset, cummin!, cols; [missings = :ignore, threads])

Replace each value in `cols` by the result of cumulative minimum on each row. When `cols` is not specified `byrow` replaces every numeric columns. The type of selected column will be promoted to be able to contain the result of computations. By default missing values are filled with the result of preceding calculations, and passing `missings = :skip` leaves `missing` values untouched.

Passing `threads = false` disables multithreaded computations.

See [`byrow(cummin)`](@ref), [`byrow(cumsum!)`](@ref), [`byrow(cumprod!)`](@ref), [`byrow(cummax!)`](@ref)
@@@@cummin@@@@
    byrow(ds::AbstractDataset, cummin, cols; [missings = :ignore, threads])

Variant of `byrow(cummin!)` which pass a copy of `ds` and leave `ds` untouched.
@@@@sort!@@@@
    byrow(ds::Dataset, sort!, cols; [threads, kwargs...])

Update `ds` in place with sorted values in each row of selected `cols`. When `cols` is not specified `byrow` uses every numeric columns. User can pass any keyword argument support by Julia `sort` function. Columns in `cols` will be promoted to be able to contain the new sorted values.

Passing `threads = false` disables multithreaded computations.

See [`byrow(sort)`](@ref), [`sort!`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x1 = [1.0,missing,2.0], x2 = [5,6,missing])
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Int64?
─────┼─────────────────────
   1 │       1.0         5
   2 │ missing           6
   3 │       2.0   missing

julia> byrow(ds, sort!, :)
3×2 Dataset
 Row │ x1        x2
     │ identity  identity
     │ Float64?  Float64?
─────┼─────────────────────
   1 │      1.0        5.0
   2 │      6.0  missing
   3 │      2.0  missing

julia> ds = Dataset(x1 = [1.0,missing,2.0], x2 = [5,6,missing])
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Int64?
─────┼─────────────────────
   1 │       1.0         5
   2 │ missing           6
   3 │       2.0   missing

julia> byrow(ds, sort!, :, rev = true)
3×2 Dataset
 Row │ x1         x2
     │ identity   identity
     │ Float64?   Float64?
─────┼─────────────────────
   1 │       5.0       1.0
   2 │ missing         6.0
   3 │ missing         2.0
```
@@@@sort@@@@
    byrow(ds::AbstractDataset, sort, cols; [threads, kwargs...])

Variant of `byrow(sort!)` which pass a copy of `ds` and leave `ds` untouched.
@@@@stdze!@@@@
    byrow(ds::Dataset, stdze!, cols; [threads])

Replace each value in each row of `ds` for selected `cols` by its standardised values. After Standardization, each row have a mean of 0 and a variance of 1.

Missing values are skipped from the calculation. When all values in a row are missing, it returns `missing`.

Passing `threads = false` disables multithreaded computations.

See [`byrow(stdze)`](@ref)

# Examples
```jldoctest
julia> ds = Dataset(x=[1,2,5], y=[3.7,-2.4,5.5], z=[9, 4, 3])
3×3 Dataset
 Row │ x         y         z        
     │ identity  identity  identity 
     │ Int64?    Float64?  Int64?   
─────┼──────────────────────────────
   1 │        1       3.7         9
   2 │        2      -2.4         4
   3 │        5       5.5         3

julia> byrow(ds,stdze!,:)
3×3 Dataset
 Row │ x          y          z         
     │ identity   identity   identity  
     │ Float64    Float64    Float64   
─────┼─────────────────────────────────
   1 │ -0.876372  -0.21295    1.08932
   2 │  0.244339  -1.09952    0.855186
   3 │  0.377964   0.755929  -1.13389

julia> byrow(ds,mean,:)
3-element Vector{Float64}:
  1.4802973661668753e-16
-3.700743415417188e-17
  0.0
  
julia> byrow(ds,var,:)
3-element Vector{Union{Missing, Float64}}:
  1.0000000000000004
  1.0
  0.9999999999999989

julia> ds = Dataset(x=[missing,2,missing], y=[3.7,-2.4,missing], z=[9, 4, missing])
3×3 Dataset
 Row │ x         y          z        
     │ identity  identity   identity 
     │ Int64?    Float64?   Int64?   
─────┼───────────────────────────────
   1 │  missing        3.7         9
   2 │        2       -2.4         4
   3 │  missing  missing     missing 

julia> byrow(ds,stdze!,:)
3×3 Dataset
 Row │ x               y               z              
     │ identity        identity        identity       
     │ Float64?        Float64?        Float64?       
─────┼────────────────────────────────────────────────
   1 │ missing              -0.707107        0.707107
   2 │       0.244339       -1.09952         0.855186
   3 │ missing         missing         missing 
```

@@@@stdze@@@@
    byrow(ds::AbstractDataset, stdze, cols; [threads])

Variant of `byrow(stdze!)` which pass a copy of `ds` and leave `ds` untouched.

@@@@rescale!@@@@
    byrow(ds::Dataset, rescale!, cols; [range = [0, 1], threads])

Replace each value in each row of `ds` for selected `cols` by its rescaled values. 
Also known as min-max scaling or min-max normalization, rescaling is the simplest method and consists in rescaling the range of features to scale the range.
The formula to rescale a range between an arbitrary set of values [a, b] is given as: a + ((x-min(x))(b-a)/(max(x)-min(x)). 

Missing values are skipped from the calculation. When all values in a row are missing, it returns `missing`.
If the maximum value of a row is equal to the minimum value of a row, the result will also be `missing`.


Passing `range = [minval, mxval]` to define the range of rescale result.
Passing `threads = false` disables multithreaded computations.

See [`byrow(rescale)`](@ref)

@@@@rescale@@@@
    byrow(ds::AbstractDataset, rescale, cols; [range = [0, 1], threads])

Variant of `byrow(rescale!)` which pass a copy of `ds` and leave `ds` untouched.

@@@@generic@@@@
    byrow(ds::AbstractDataset, fun, cols; [threads])

Return the result of calling `fun` on each row of `ds` selected by `cols`. The `fun` function must accept one argument which contains the values of each row as a vector of values and return a scalar.

When user passes a "Type" as `fun` and a single column as `cols`,  `byrow` converts the corresponding column to the type specified by `fun` using the `convert` function in Base Julia.

For generic functions there are the below special cases:

* When `cols` is a single column, `byrow(ds, fun, cols)` acts like `fun.(ds[:, cols])`
* When `cols` is referring to exactly two columns and it is possible to pass two vectors as arguments of `fun`, `byrow` returns `fun.(ds[:, col1], ds[:, col2])` when possible.
* When `cols` is a `Tuple` of column indices, `byrow(ds, fun, cols)` returns `fun.(ds[:, cols[1]], ds[:, cols[2]], ...)`, i.e. `fun` is a multivariate function which will be applied on each row of `cols`.
"""
