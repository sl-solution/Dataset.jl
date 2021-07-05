module InMemoryDatasets



# using TableTraits,IteratorInterfaceExtensions
using Reexport
using Compat
using Printf
using PrettyTables, REPL
using Markdown
using PooledArrays
@reexport using Missings, InvertedIndices
@reexport using Statistics
@reexport using Dates
import DataAPI,
       DataAPI.All,
       DataAPI.Between,
       DataAPI.Cols,
       DataAPI.describe,
       Tables,
       Tables.columnindex

export
      # types
      AbstractDataset,
      DatasetColumns,
      DatasetColumn,
      SubDataset,
      SubDatasetColumn,
      Dataset,
      GatherBy,
      Between,
      # functions
      nrow,
      ncol,
      getformat,
      setformat!,
      removeformat!,
      content,
      mask,
      groupby!,
      groupby,
      gatherby,
      ungroup!,
      modify,
      modify!,
      combine,
      setinfo!,
      # from byrow operations
      byrow,
      nunique,
      # from stat
      stdze,
      lag,
      lead,
      rescale,
      wsum,
      wmean,
      k_largest,
      k_smallest




include("other/index.jl")
include("other/utils.jl")
include("stat/non_hp_stat.jl")
include("stat/hp_stat.jl")
include("stat/stat.jl")
include("abstractdataset/abstractdataset.jl")
# create dataset
include("dataset/constructor.jl")
# get elements
include("dataset/getindex.jl")
# set elements
include("dataset/setindex.jl")
# delete and append observations
include("dataset/del_and_append.jl")
# concatenate
include("dataset/cat.jl")

# byrow operations
include("byrow/row_functions.jl")
include("byrow/hp_row_functions.jl")
include("byrow/byrow.jl")
# other functions
include("dataset/other.jl")
include("subdataset/subdataset.jl")
include("datasetrow/datasetrow.jl")
include("other/broadcasting.jl")

# modifying dataset
include("dataset/modify.jl")
include("dataset/combine.jl")
include("abstractdataset/selection.jl")
# sorting
include("sort/util.jl")
include("sort/qsort.jl")
include("sort/int.jl")
include("sort/pooled.jl")
include("sort/sortperm.jl")
include("sort/sort.jl")
include("sort/groupby.jl")
include("sort/gatherby.jl")

include("abstractdataset/iteration.jl")
include("abstractdataset/prettytables.jl")
include("abstractdataset/show.jl")
include("datasetrow/show.jl")

include("abstractdataset/io.jl")

include("other/tables.jl")


end
