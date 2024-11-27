```@meta
CurrentModule = InMemoryDatasets
```

# Functions

```@index
Pages = ["functions.md"]
```

## Constructing data set
```@docs
copy
repeat!
similar
```

## Formats
```@docs
removeformat!
setformat!
```

## Summary information
```@docs
content
getinfo
ncol
ndims
nrow
setinfo!
size
```

## Working with column names
```@docs
names
propertynames
rename
rename!
```

## Modifying data sets
```@docs
append!
flatten
flatten!
insertcols!
map
map!
mapcols
push!
repeat
repeat!
update
update!
```

## Transposing and reshaping data sets
```@docs
flatten
flatten!
transpose
```

## Joining
```@docs
antijoin
antijoin!
closejoin
closejoin!
innerjoin
leftjoin
leftjoin!
outerjoin
semijoin
semijoin!
update
update!
```

## Filtering rows
```@docs
compare
contains
deleteat!
duplicates
first
filter
filter!
last
mask
unique
unique!
```

## Working with missing values
```@docs
completecases
dropmissing
dropmissing!
map
map!
```

## Statistics
```@docs
lag
lag!
lead
lead!
rescale
stdze
topk
```
