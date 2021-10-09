# Datasets

`InMemoryDatasets.jl` is a `Julia` package for working with tabular data sets.

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://sl-solution.github.io/InMemoryDatasets.jl/stable)

# Examples

```julia
> using InMemoryDatasets
> a = Dataset(x = [1,2], y = [1,2])
2×2 Dataset
 Row │ x         y
     │ identity  identity
     │ Int64?     Int64?
─────┼────────────────────
   1 │        1         1
   2 │        2         2
```

# Formats

For each data set, one can assign a named function to a column as its format. The column formatted values will be used for displaying, sorting, grouping and joining, however, for any other operation the actual values will be used. The format function doesn't modify the actual values of a column.

`setformat!` assigns a format to a column, and `removeformat!` removes a column format.

## Examples

```julia
julia> ds = Dataset(randn(10,2), :auto)
10×2 Dataset
 Row │ x1          x2        
     │ identity    identity  
     │ Float64?     Float64?   
─────┼───────────────────────
   1 │  0.108189   -2.71151
   2 │ -0.520872   -1.00426
   3 │  0.667433   -0.357071
   4 │ -0.317271   -0.457264
   5 │  0.404249    0.405335
   6 │ -1.0304      0.292216
   7 │  0.874799   -0.169534
   8 │  0.0723834   1.47378
   9 │  0.338568    1.08032
  10 │ -1.07939     1.24903

julia> myformat(x) = round(Int, x)
myformat (generic function with 1 method)

julia>  setformat!(ds, 1 => myformat)
10×2 Dataset
 Row │ x1        x2        
     │ myformat  identity  
     │ Float64?   Float64?   
─────┼─────────────────────
   1 │        0  -2.71151
   2 │       -1  -1.00426
   3 │        1  -0.357071
   4 │        0  -0.457264
   5 │        0   0.405335
   6 │       -1   0.292216
   7 │        1  -0.169534
   8 │        0   1.47378
   9 │        0   1.08032
  10 │       -1   1.24903

julia> getformat(ds, :x1)
myformat (generic function with 1 method)

julia> removeformat!(ds, :x1)
10×2 Dataset
 Row │ x1          x2        
     │ identity    identity  
     │ Float64?     Float64?   
─────┼───────────────────────
   1 │  0.108189   -2.71151
   2 │ -0.520872   -1.00426
   3 │  0.667433   -0.357071
   4 │ -0.317271   -0.457264
   5 │  0.404249    0.405335
   6 │ -1.0304      0.292216
   7 │  0.874799   -0.169534
   8 │  0.0723834   1.47378
   9 │  0.338568    1.08032
  10 │ -1.07939     1.24903
```

# Calling a function on each observation

The `map(ds, fun, cols)` function can be used to call `fun`  on each observation in `cols` (actual values). When different functions needed to be applied to each column, a vector of functions can be supplied. The `map!(ds, fun, cols)` function can be used when the operations needed to be done in-place. `map!`  requires the operation be done in-place, if this is not possible, the function skip the operation.

## Examples

```julia
julia> ds = Dataset(g = [1, 1, 1, 2, 2],
                   x1_int = [0, 0, 1, missing, 2],
                   x2_int = [3, 2, 1, 3, -2],
                   x1_float = [1.2, missing, -1.0, 2.3, 10],
                   x2_float = [missing, missing, 3.0, missing, missing],
                   x3_float = [missing, missing, -1.4, 3.0, -100.0])
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float   x2_float   x3_float
     │ identity  identity  identity  identity   identity   identity
     │ Int64?     Int64?    Int64?     Float64?   Float64?   Float64?
─────┼───────────────────────────────────────────────────────────────
   1 │        1         0         3        1.2  missing    missing
   2 │        1         0         2  missing    missing    missing
   3 │        1         1         1       -1.0        3.0       -1.4
   4 │        2   missing         3        2.3  missing          3.0
   5 │        2         2        -2       10.0  missing       -100.0

julia> map(ds, x->x^2, :x2_int)
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float    x2_float   x3_float
     │ identity  identity  identity  identity    identity   identity
     │ Int64?     Int64?    Int64?     Float64?    Float64?   Float64?
─────┼─────────────────────────────────────────────────────────────────
   1 │        1         0         9        1.44  missing    missing
   2 │        1         0         4  missing     missing    missing
   3 │        1         1         1        1.0         9.0        1.96
   4 │        4   missing         9        5.29  missing          9.0
   5 │        4         4         4      100.0   missing      10000.0

julia> map(ds, [sqrt, x->x^2], 2:3)
5×6 Dataset
 Row │ g         x1_int         x2_int    x1_float   x2_float   x3_float
     │ identity  identity       identity  identity   identity   identity
     │ Int64?     Float64?       Int64?    Float64?   Float64?   Float64?
─────┼────────────────────────────────────────────────────────────────────
   1 │        1        0.0             9        1.2  missing    missing
   2 │        1        0.0             4  missing    missing    missing
   3 │        1        1.0             1       -1.0        3.0       -1.4
   4 │        2  missing               9        2.3  missing          3.0
   5 │        2        1.41421         4       10.0  missing       -100.0

julia> map!(ds, x -> ismissing(x) ? 0 : x, r"x")
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float  x2_float  x3_float
     │ identity  identity  identity  identity  identity  identity
     │ Int64?     Int64?    Int64?    Float64?  Float64?  Float64?
─────┼────────────────────────────────────────────────────────────
   1 │        1         0         3       1.2       0.0       0.0
   2 │        1         0         2       0.0       0.0       0.0
   3 │        1         1         1      -1.0       3.0      -1.4
   4 │        2         0         3       2.3       0.0       3.0
   5 │        2         2        -2      10.0       0.0    -100.0

julia> map!(ds, [sqrt, x->x^2], 2:3)
┌ Warning: cannot map `f` on ds[!, :x1_int] in-place, the selected column is Union{Missing, Int64} and the result of calculation is Union{Missing, Float64}
└ @ InMemoryDatasets ~/.julia/dev/InMemoryDatasets/src/dataset/other.jl:482
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float  x2_float  x3_float
     │ identity  identity  identity  identity  identity  identity
     │ Int64?     Int64?    Int64?    Float64?  Float64?  Float64?
─────┼────────────────────────────────────────────────────────────
   1 │        1         0         9       1.2       0.0       0.0
   2 │        1         0         4       0.0       0.0       0.0
   3 │        1         1         1      -1.0       3.0      -1.4
   4 │        2         0         9       2.3       0.0       3.0
   5 │        2         2         4      10.0       0.0    -100.0
```

# Masking observations

The `mask(ds, fun, cols)` function can be used to return a Bool `Dataset` which the observation in row `i` and column `j` is true if `fun(ds[i, j])` is true. The `fun` is called on actual values by default, however, using the option `mapformats = true` causes `fun` to be called on the formatted values.

## Examples

```julia
julia> ds = Dataset(x = 1:10, y = repeat(1:5, inner = 2), z = repeat(1:2, 5))
10×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?     Int64?     Int64?
─────┼──────────────────────────────
   1 │        1         1         1
   2 │        2         1         2
   3 │        3         2         1
   4 │        4         2         2
   5 │        5         3         1
   6 │        6         3         2
   7 │        7         4         1
   8 │        8         4         2
   9 │        9         5         1
  10 │       10         5         2

julia> function gender(x)
          x == 1 ? "Male" : x == 2 ? "Female" : missing
       end
julia> setformat!(ds, 2 => sqrt, 3 => gender)
10×3 Dataset
 Row │ x         y        z
     │ identity  sqrt     gender
     │ Int64?    Int64?    Int64?
─────┼───────────────────────────
   1 │        1  1.0        Male
   2 │        2  1.0      Female
   3 │        3  1.41421    Male
   4 │        4  1.41421  Female
   5 │        5  1.73205    Male
   6 │        6  1.73205  Female
   7 │        7  2.0        Male
   8 │        8  2.0      Female
   9 │        9  2.23607    Male
  10 │       10  2.23607  Female

julia> mask(ds, [iseven, isequal("Male")], 2:3, mapformats = false)
10×2 Dataset
 Row │ y         z
     │ identity  identity
     │ Bool?      Bool?
─────┼────────────────────
   1 │    false     false
   2 │    false     false
   3 │     true     false
   4 │     true     false
   5 │    false     false
   6 │    false     false
   7 │     true     false
   8 │     true     false
   9 │    false     false
  10 │    false     false

julia> mask(ds, [val -> rem(val, 2) == 0, isequal("Male")], 2:3, mapformats = true)
10×2 Dataset
 Row │ y         z
     │ identity  identity
     │ Bool?      Bool?
─────┼────────────────────
   1 │    false      true
   2 │    false     false
   3 │    false      true
   4 │    false     false
   5 │    false      true
   6 │    false     false
   7 │     true      true
   8 │     true     false
   9 │    false      true
  10 │    false     false
```

# Modifying a Dataset

The `modify()` function can be used to modify columns or add a transformation of columns to a data set. The syntax of `modify` is 

```julia
modify(ds, op...)
```

where `op` can be of the form `col => fun`, `cols=>fun`, `col=>fun=>:new_name`, `cols=>fun=>:new_names`. Here `fun` is a function which can be applied to one column, i.e. `fun` accepts one column of `ds` and return values by calling `fun` on the selected `col`. When no new names is given the `col` is replaced by the new values. The  feature of `modify` is that from left to right when ever a column is updated or created, the next operation has access to its value (either new or updated values). 

When a row operation is needed to be done, `byrow` can be used instead of `fun`, i.e. `cols => byrow(f, kwargs...)` or `cols => byrow(f, kwargs...)=>:new_name`. In this case `f` is applied to each row of `cols`.

`modify!` modifies a data set in place.

## Examples

```julia
julia> ds = Dataset(x = 1:10, y = repeat(1:5, inner = 2), z = repeat(1:2, 5))
10×3 Dataset
 Row │ x         y         z
     │ identity  identity  identity
     │ Int64?     Int64?     Int64?
─────┼──────────────────────────────
   1 │        1         1         1
   2 │        2         1         2
   3 │        3         2         1
   4 │        4         2         2
   5 │        5         3         1
   6 │        6         3         2
   7 │        7         4         1
   8 │        8         4         2
   9 │        9         5         1
  10 │       10         5         2

julia> modify(ds, 
                 1 => x -> x .^ 2,
                 2:3 => byrow(sqrt) => [:sq_y, :sq_z],
                 [:x, :sq_y] => byrow(-)
              )
10×6 Dataset
 Row │ x         y         z         sq_y      sq_z      row_-
     │ identity  identity  identity  identity  identity  identity
     │ Int64?     Int64?    Int64?  Float64?   Float64?   Float64?
─────┼────────────────────────────────────────────────────────────
   1 │        1         1         1   1.0       1.0       0.0
   2 │        4         1         2   1.0       1.41421   3.0
   3 │        9         2         1   1.41421   1.0       7.58579
   4 │       16         2         2   1.41421   1.41421  14.5858
   5 │       25         3         1   1.73205   1.0      23.2679
   6 │       36         3         2   1.73205   1.41421  34.2679
   7 │       49         4         1   2.0       1.0      47.0
   8 │       64         4         2   2.0       1.41421  62.0
   9 │       81         5         1   2.23607   1.0      78.7639
  10 │      100         5         2   2.23607   1.41421  97.7639
```

In the example above, the value of the first column has been updated and been used in the last operation which itself is based on the calculation from previous operations.

# Grouping Datasets

The function `groupby!(ds, cols; rev = false, issorted = false)` groups a data set (sort `ds` based on `cols`). The sorting and grouping is done based on the formatted values of `cols` by default. However, using the option `mapformats = false`  changes this behaviour. `combine(ds, args...)` can be used to aggregate the result for each group. The syntax for `args...` is similar to `modify`, with the exception that in `combine` all `cols`  in  `cols=>fun` always refers to the original data set, and `cols`  in `cols=>byrow(fun...)`  always refers to variables in the output data set. When `new_name` is not provided, `combine`  attaches the name of the transformation at the end of the aggregated variable and creates a new name for the output column.

```julia
julia> ds = Dataset(g = [1, 1, 1, 2, 2],
                   x1_int = [0, 0, 1, missing, 2],
                   x2_int = [3, 2, 1, 3, -2],
                   x1_float = [1.2, missing, -1.0, 2.3, 10],
                   x2_float = [missing, missing, 3.0, missing, missing],
                   x3_float = [missing, missing, -1.4, 3.0, -100.0])
5×6 Dataset
 Row │ g         x1_int    x2_int    x1_float   x2_float   x3_float
     │ identity  identity  identity  identity   identity   identity
     │ Int64?     Int64?    Int64?     Float64?   Float64?   Float64?
─────┼───────────────────────────────────────────────────────────────
   1 │        1         0         3        1.2  missing    missing
   2 │        1         0         2  missing    missing    missing
   3 │        1         1         1       -1.0        3.0       -1.4
   4 │        2   missing         3        2.3  missing          3.0
   5 │        2         2        -2       10.0  missing       -100.0

julia> groupby!(ds, 1)
5×6 Grouped Dataset with 2 groups
Grouped by: g
 Row │ g         x1_int    x2_int    x1_float   x2_float   x3_float
     │ identity  identity  identity  identity   identity   identity
     │ Int64?     Int64?    Int64?     Float64?   Float64?   Float64?
─────┼───────────────────────────────────────────────────────────────
   1 │        1         0         3        1.2  missing    missing
   2 │        1         0         2  missing    missing    missing
   3 │        1         1         1       -1.0        3.0       -1.4
   4 │        2   missing         3        2.3  missing          3.0
   5 │        2         2        -2       10.0  missing       -100.0

julia> combine(ds, :x1_float => sum)
2×2 Dataset
 Row │ g         x1_float_sum
     │ identity  identity
     │ Int64?    Float64?
─────┼────────────────────────
   1 │        1           0.2
   2 │        2          12.3
```

# Joins

`leftjoin`, `innerjoin` , `outerjoin`, `antijoin`, `semijoin`, and  `closejoin`  are the main functions for joining two data sets. `closejoin` joins two data sets based on exact match on the key variable or the closest match when the exact match doesn't exist.

`closejoin!` does the joining in-place. The in-place operation also can be done for `antijoin`, `semijoin`, and `leftjoin` where in the latter case there must not be more than one match from the right data set.

> The joining functions use the formatted value for finding the match.
> 
> The joining functions always sort the second data set.

## Examples

```julia
julia> name = Dataset(ID = [1, 2, 3], Name = ["John Doe", "Jane Doe", "Joe Blogs"])
3×2 Dataset
 Row │ ID        Name
     │ identity  identity
     │ Int64?    String?
─────┼──────────────────────
   1 │        1  John Doe
   2 │        2  Jane Doe
   3 │        3  Joe Blogs

julia> job = Dataset(ID = [1, 2, 4], Job = ["Lawyer", "Doctor", "Farmer"])
3×2 Dataset
 Row │ ID        Job
     │ identity  identity
     │ Int64?   String?
─────┼──────────────────────
   1 │        1  Lawyer
   2 │        2  Doctor
   3 │        4  Farmer

julia> leftjoin(name, job, on = :ID)
3×3 Dataset
 Row │ ID        Name        Job
     │ identity  identity    identity
     │ Int64?    String?     String?
─────┼──────────────────────────────────
   1 │        1  John Doe    Lawyer
   2 │        2  Jane Doe    Doctor
   3 │        3  Joe Blogs   missing

julia> innerjoin(name, job, on = :ID)
2×3 Dataset
 Row │ ID        Name        Job
     │ identity  identity    identity
     │ Int64?    String?     String?
─────┼──────────────────────────────────
   1 │        1  John Doe    Lawyer
   2 │        2  Jane Doe    Doctor

julia> outerjoin(name, job, on = :ID)
4×3 Dataset
 Row │ ID        Name        Job
     │ identity  identity    identity
     │ Int64?    String?     String?
─────┼──────────────────────────────────
   1 │        1  John Doe    Lawyer
   2 │        2  Jane Doe    Doctor
   3 │        3  Joe Blogs   missing
   4 │        4  missing     Farmer

julia> classA = Dataset(id = ["id1", "id2", "id3", "id4", "id5"],
                        mark = [50, 69.5, 45.5, 88.0, 98.5])
5×2 Dataset
 Row │ id          mark
     │ identity    identity
     │ String?     Float64?
─────┼──────────────────────
   1 │ id1             50.0
   2 │ id2             69.5
   3 │ id3             45.5
   4 │ id4             88.0
   5 │ id5             98.5
julia> grades = Dataset(mark = [0, 49.5, 59.5, 69.5, 79.5, 89.5, 95.5], 
                        grade = ["F", "P", "C", "B", "A-", "A", "A+"])
7×2 Dataset
 Row │ mark      grade
     │ identity  identity
     │ Float64?  String?
─────┼──────────────────────
   1 │      0.0  F
   2 │     49.5  P
   3 │     59.5  C
   4 │     69.5  B
   5 │     79.5  A-
   6 │     89.5  A
   7 │     95.5  A+

julia> closejoin(classA, grades, on = :mark)
5×3 Dataset
 Row │ id          mark      grade
     │ identity    identity  identity
     │ String?     Float64?  String?
─────┼──────────────────────────────────
   1 │ id1             50.0  P
   2 │ id2             69.5  B
   3 │ id3             45.5  F
   4 │ id4             88.0  A-
   5 │ id5             98.5  A+
```

Examples of using `closejoin` for financial data.

```julia
julia> trades = Dataset(
                [["20160525 13:30:00.023",
                  "20160525 13:30:00.038",
                  "20160525 13:30:00.048",
                  "20160525 13:30:00.048",
                  "20160525 13:30:00.048"],
                ["MSFT", "MSFT",
                 "GOOG", "GOOG", "AAPL"],
                [51.95, 51.95,
                 720.77, 720.92, 98.00],
                [75, 155,
                 100, 100, 100]],
               ["time", "ticker", "price", "quantity"]);

julia> modify!(trades, 1 => byrow(x -> DateTime(x, dateformat"yyyymmdd HH:MM:SS.s")))
5×4 Dataset
 Row │ time                     ticker      price     quantity
     │ identity                 identity    identity  identity
     │ DateTime?                String?      Float64?  Int64?
─────┼─────────────────────────────────────────────────────────
   1 │ 2016-05-25T13:30:00.023  MSFT           51.95        75
   2 │ 2016-05-25T13:30:00.038  MSFT           51.95       155
   3 │ 2016-05-25T13:30:00.048  GOOG          720.77       100
   4 │ 2016-05-25T13:30:00.048  GOOG          720.92       100
   5 │ 2016-05-25T13:30:00.048  AAPL           98.0        100

julia> quotes = Dataset(
              [["20160525 13:30:00.023",
                "20160525 13:30:00.023",
                "20160525 13:30:00.030",
                "20160525 13:30:00.041",
                "20160525 13:30:00.048",
                "20160525 13:30:00.049",
                "20160525 13:30:00.072",
                "20160525 13:30:00.075"],
              ["GOOG", "MSFT", "MSFT", "MSFT",
               "GOOG", "AAPL", "GOOG", "MSFT"],
              [720.50, 51.95, 51.97, 51.99,
               720.50, 97.99, 720.50, 52.01],
              [720.93, 51.96, 51.98, 52.00,
               720.93, 98.01, 720.88, 52.03]],
             ["time", "ticker", "bid", "ask"]);

julia> modify!(quotes, 1 => byrow(x -> DateTime(x, dateformat"yyyymmdd HH:MM:SS.s")))
8×4 Dataset
 Row │ time                     ticker      bid       ask
     │ identity                 identity    identity  identity
     │ DateTime?                String?     Float64?  Float64?
─────┼─────────────────────────────────────────────────────────
   1 │ 2016-05-25T13:30:00.023  GOOG          720.5     720.93
   2 │ 2016-05-25T13:30:00.023  MSFT           51.95     51.96
   3 │ 2016-05-25T13:30:00.030  MSFT           51.97     51.98
   4 │ 2016-05-25T13:30:00.041  MSFT           51.99     52.0
   5 │ 2016-05-25T13:30:00.048  GOOG          720.5     720.93
   6 │ 2016-05-25T13:30:00.049  AAPL           97.99     98.01
   7 │ 2016-05-25T13:30:00.072  GOOG          720.5     720.88
   8 │ 2016-05-25T13:30:00.075  MSFT           52.01     52.03

julia> closejoin(trades, quotes, on = :time, makeunique = true)
5×7 Dataset
 Row │ time                     ticker      price     quantity  ticker_1    bid       ask
     │ identity                 identity    identity  identity  identity    identity  identity
     │ DateTime?                String?     Float64?  Int64?    String?     Float64?  Float64?
─────┼─────────────────────────────────────────────────────────────────────────────────────────
   1 │ 2016-05-25T13:30:00.023  MSFT           51.95        75  MSFT           51.95     51.96
   2 │ 2016-05-25T13:30:00.038  MSFT           51.95       155  MSFT           51.97     51.98
   3 │ 2016-05-25T13:30:00.048  GOOG          720.77       100  GOOG          720.5     720.93
   4 │ 2016-05-25T13:30:00.048  GOOG          720.92       100  GOOG          720.5     720.93
   5 │ 2016-05-25T13:30:00.048  AAPL           98.0        100  GOOG          720.5     720.93
```

In the above example the close join for each `ticker` can be done by supplying `ticker` as the first variable of `on` keyword, i.e. when more than one variable is used for `on` the last one will be used for close match and the rest are used for exact match.

```julia
julia> closejoin(trades, quotes, on = [:ticker, :time], border = :nearest)
5×6 Dataset
 Row │ time                     ticker      price       quantity  bid       ask
     │ identity                 identity    identity    identity  identity  identity
     │ DateTime?                String?     Float64?    Int64?    Float64?  Float64?
─────┼─────────────────────────────────────────────────────────────────────────────
   1 │ 2016-05-25T13:30:00.023  MSFT           51.95        75     51.95     51.96
   2 │ 2016-05-25T13:30:00.038  MSFT           51.95       155     51.97     51.98
   3 │ 2016-05-25T13:30:00.048  GOOG          720.77       100    720.5     720.93
   4 │ 2016-05-25T13:30:00.048  GOOG          720.92       100    720.5     720.93
   5 │ 2016-05-25T13:30:00.048  AAPL           98.0        100     97.99     98.01
```

 When `border` is set to `:missing` for the `:backward` direction the value below the smallest value will be set to `missing`, and for the `:forward` direction the value above the largest value will be set to `missing`.

```julia
julia> closejoin(trades, quotes, on = [:ticker, :time], border = :missing)
5×6 Dataset
 Row │ time                     ticker       price     quantity  bid         ask
     │ identity                 identity     identity  identity  identity    identity
     │ DateTime?                String?      Float64?  Int64?    Float64?    Float64?
─────┼─────────────────────────────────────────────────────────────────────────────────
   1 │ 2016-05-25T13:30:00.023  MSFT           51.95        75       51.95       51.96
   2 │ 2016-05-25T13:30:00.038  MSFT           51.95       155       51.97       51.98
   3 │ 2016-05-25T13:30:00.048  GOOG          720.77       100      720.5       720.93
   4 │ 2016-05-25T13:30:00.048  GOOG          720.92       100      720.5       720.93
   5 │ 2016-05-25T13:30:00.048  AAPL           98.0        100  missing     missing
```

# Update a data set by values from another data set

`update!` updates a data set with a given data set. The function uses the given keys (`on = ...`) to match the rows which need updating. By default the missing values in transaction data set wouldn't replace the values in the main data set, however, using `allowmissing = true`  changes this behaviour. If there are multiple rows in the main data set which match the key using `mode = :all` causes all of them to be updated, and `mode = :missing` updates only the ones which are missing in the main data set. If there are multiple rows in the transaction data set which match the key only the last one will be used to update the main data set.

## Examples

```julia
julia> main = Dataset(group = ["G1", "G1", "G1", "G1", "G2", "G2", "G2"],
                      id    = [ 1  ,  1  ,  2  ,  2  ,  1  ,  1  ,  2  ],
                      x1    = [1.2, 2.3,missing,  2.3, 1.3, 2.1  , 0.0 ],
                      x2    = [ 5  ,  4  ,  4  ,  2  , 1  ,missing, 2  ])
7×4 Dataset
 Row │ group         id        x1         x2
     │ identity     identity  identity   identity
     │ String?      Int64?   Float64?    Int64?
─────┼───────────────────────────────────────────
   1 │ G1                 1        1.2         5
   2 │ G1                 1        2.3         4
   3 │ G1                 2  missing           4
   4 │ G1                 2        2.3         2
   5 │ G2                 1        1.3         1
   6 │ G2                 1        2.1   missing
   7 │ G2                 2        0.0         2


julia> transaction = Dataset(group = ["G1", "G2"], id = [2, 1], 
                        x1 = [2.5, missing], x2 = [missing, 3])
2×4 Dataset
 Row │ group       id        x1         x2
     │ identity    identity  identity   identity
     │ String?       Int64?    Float64?   Int64?
─────┼───────────────────────────────────────────
   1 │ G1                 2        2.5   missing
   2 │ G2                 1  missing           3


julia> update(main, transaction, on = [:group, :id], 
               allowmissing = false, mode = :missing)
7×4 Dataset
 Row │ group        id        x1        x2
     │ identity     identity  identity  identity
     │ String?       Int64?    Float64?  Int64?
─────┼──────────────────────────────────────────
   1 │ G1                 1       1.2         5
   2 │ G1                 1       2.3         4
   3 │ G1                 2       2.5         4
   4 │ G1                 2       2.3         2
   5 │ G2                 1       1.3         1
   6 │ G2                 1       2.1         3
   7 │ G2                 2       0.0         2


julia> update(main, transaction, on = [:group, :id],
               allowmissing = false, mode = :all)
7×4 Dataset
 Row │ group       id        x1        x2
     │ identity    identity  identity  identity
     │ String?       Int64?    Float64?  Int64?
─────┼──────────────────────────────────────────
   1 │ G1                 1       1.2         5
   2 │ G1                 1       2.3         4
   3 │ G1                 2       2.5         4
   4 │ G1                 2       2.5         2
   5 │ G2                 1       1.3         3
   6 │ G2                 1       2.1         3
   7 │ G2                 2       0.0         2
```
