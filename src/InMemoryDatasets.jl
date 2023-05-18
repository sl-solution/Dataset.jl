module InMemoryDatasets



using TableTraits,IteratorInterfaceExtensions
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
       DataAPI.innerjoin,
       DataAPI.outerjoin,
       DataAPI.rightjoin,
       DataAPI.leftjoin,
       DataAPI.semijoin,
       DataAPI.antijoin,
       DataAPI.nrow,
       DataAPI.ncol,
       # DataAPI.crossjoin,
       Tables,
       Tables.columnindex

const IMD = InMemoryDatasets
export
      # types
      IMD,
      @c_str,
      Characters,
      AbstractDataset,
      DatasetColumns,
      DatasetColumn,
      SubDataset,
      SubDatasetColumn,
      Dataset,
      GatherBy,
      GroupBy,
      Between,
      splitter,
      # functions
      nrow,
      ncol,
      rename!,
      rename,
      duplicates,
      getformat,
      setformat!,
      removeformat!,
      content,
      completecases,
      dropmissing,
      dropmissing!,
      flatten,
      flatten!,
      repeat!,
      select,
      select!,
      delete,
      mapcols,
      insertcols!,
      mask,
      compare,
      groupby!,
      groupby,
      gatherby,
      describe,
      issorted!,
      unsort!,
      ungroup!,
      modify,
      modify!,
      combine,
      setinfo!,
      getinfo,
      eachgroup,
      # allowmissing!,
      # from byrow operations
      byrow,
      nunique,
      # from stat
      lag,
      lag!,
      lead,
      lead!,
      stdze,
      stdze!,
      rescale,
      topk,
      topkperm,
      cummax,
      cummax!,
      cummin,
      cummin!,
      ffill!,
      ffill,
      bfill!,
      bfill,
      # from join
      innerjoin,
      outerjoin,
      leftjoin,
      leftjoin!,
      # rightjoin,
      antijoin,
      semijoin,
      antijoin!,
      semijoin!,
      closejoin,
      closejoin!,
      update,
      update!





include("other/index.jl")
include("characters/characters.jl")
include("other/utils.jl")
include("stat/non_hp_stat.jl")
include("stat/hp_stat.jl")
include("stat/stat.jl")
include("abstractdataset/abstractdataset.jl")
include("abstractdataset/dscol.jl")
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
include("byrow/util.jl")
include("byrow/row_functions.jl")
include("byrow/hp_row_functions.jl")
include("byrow/byrow.jl")
include("byrow/doc.jl")

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
include("sort/int_any.jl")
include("sort/sortperm.jl")
include("sort/sort.jl")
include("sort/gatherby.jl")
include("sort/groupby.jl")


# transpose
include("dataset/transpose.jl")

# joins
include("join/join.jl")
include("join/join_dict.jl")
include("join/closejoin.jl")
include("join/update.jl")
include("join/compare.jl")
include("join/main.jl")

include("abstractdataset/iteration.jl")
include("abstractdataset/prettytables.jl")
include("abstractdataset/show.jl")
include("datasetrow/show.jl")

include("abstractdataset/io.jl")

include("other/tables.jl")

# taking care of missings in other packages
include("missings/missings.jl")
# ds stat
include("stat/ds_stat.jl")
# precompile
include("precompile/precompile.jl")
include("precompile/warmup.jl")
include("precompile/create_sysimage.jl")
# FIXME currently v1.9.0 precompilation and loading cause an enormous amount of allocation - v1.10 seems ok
VERSION != v"1.9.0" &&  _precompile()

function __init__()
   if Threads.nthreads() == 1
         if get(ENV, "IMD_WARN_THREADS", "1") == "1"
               @warn "Julia started with single thread, to enable multithreaded functionalities in InMemoryDatasets.jl start Julia with multiple threads."
         end
   end
end
end
