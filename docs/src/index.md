# InMemoryDatasets.jl

Welcome to the InMemoryDatasets.jl documentation!

This resource aims to teach you everything you need to know to get up and
running with the InMemoryDatasets.jl package.

InMemoryDatasets is a collection of tools for working (manipulating, wrangling, cleaning, summarising,...) with tabular data in Julia.

If you are new to InMemoryDatasets.jl, probably **[First steps with Datasets](https://sl-solution.github.io/InMemoryDatasets.jl/stable/man/basics/)** or **[Tutorial](https://sl-solution.github.io/InMemoryDatasets.jl/stable/man/tutorial/)** in manual should be good starting points.

## Package manual

```@contents
Pages = ["man/basics.md",
         "man/tutorial.md",
         "man/missing.md",
         "man/formats.md",
         "man/map.md",
         "man/byrow.md",
         "man/modify.md",
         "man/filter.md",
         "man/sorting.md",
         "man/grouping.md",
         "man/aggregation.md",
         "man/transpose.md",
         "man/joins.md",
         "man/gallery.md",
         "man/performance.md"]
Depth = 2
```

## API

Only exported (i.e. available for use without `InMemoryDatasets.` qualifier after
loading the InMemoryDatasets.jl package with `using InMemoryDatasets`) types and functions
are considered a part of the public API of the InMemoryDatasets.jl package. In general
all such objects are documented in this manual (in case some documentation is
missing please kindly report an issue
[here](https://github.com/sl-solution/InMemoryDatasets.jl/issues/new)).

Please be warned that while Julia allows you to access internal functions or
types of InMemoryDatasets.jl these can change without warning between versions of
InMemoryDatasets.jl. In particular it is not safe to directly access fields of types
that are a part of public API of the InMemoryDatasets.jl package using e.g. the
`getfield` function. Whenever some operation on fields of defined types is
considered allowed an appropriate exported function should be used instead.

```@contents
Pages = ["lib/functions.md"]
Depth = 2
```

## Index

```@index
Pages = ["lib/functions.md"]
```
