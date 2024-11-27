using Documenter
using InMemoryDatasets

DocMeta.setdocmeta!(InMemoryDatasets, :DocTestSetup, :(using InMemoryDatasets); recursive=true)

# Build documentation.
# ====================

makedocs(
    # options
    # modules = [InMemoryDatasets],
    doctest = false, # this needs more work
    clean = false,
    sitename = "InMemoryDatasets",
    # format = Documenter.HTML(
    #     canonical = "https://sl-solution.github.io/InMemoryDataset.jl/stable/",
    #     edit_link = "main"
    # ),
    pages = Any[
        "Introduction" => "index.md",
        "First Steps" => "man/basics.md",
        "Tutorial" => "man/tutorial.md",
        "User Guide" => Any[
            "Missing Values" => "man/missing.md",
            "Formats" => "man/formats.md",
            "Call functions on each observation" => "man/map.md",
            "Row-wise operations" => "man/byrow.md",
            "Transform columns" => "man/modify.md",
            "Filter observations" => "man/filter.md",
            "Sort" => "man/sorting.md",
            "Group observations" => "man/grouping.md",
            "Aggregation" => "man/aggregation.md",
            "Transpose data" => "man/transpose.md",
            "Joins" => "man/joins.md"
        ],
        "Gallery" => "man/gallery.md",
        "Performance tips" => "man/performance.md",
        "API" => Any[
            "Functions" => "lib/functions.md"
        ]
    ],
    strict = true
)

# Deploy built documentation from Travis.
# =======================================

deploydocs(
    # options
    repo = "github.com/sl-solution/InMemoryDatasets.jl",
    target = "build",
    deps = nothing,
    make = nothing,
    devbranch = "master"
)
