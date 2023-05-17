Base.summary(ds::Dataset) =
    if !isempty(index(ds).sortedcols) && index(ds).grouped[]
        @sprintf("%d×%d Grouped Dataset with %d groups\nGrouped by: %s", size(ds)..., index(ds).ngroups[],join(_names(ds)[index(ds).sortedcols],", "))
    elseif !isempty(index(ds).sortedcols)
        @sprintf("%d×%d Sorted Dataset\n Sorted by: %s", size(ds)...,join(_names(ds)[index(ds).sortedcols],", "))
    else
        @sprintf("%d×%d Dataset", size(ds)...)
    end
Base.summary(io::IO, ds::AbstractDataset) = print(io, summary(ds))
Base.summary(ds::SubDataset) =
    @sprintf("%d×%d SubDataset", size(ds)...)


"""
    IMD.ourstrwidth(io::IO, x::Any, buffer::IOBuffer, truncstring::Int)

Determine the number of characters that would be used to print a value.
"""
function ourstrwidth(io::IO, x::Any, buffer::IOBuffer, truncstring::Int)
    truncate(buffer, 0)
    ourshow(IOContext(buffer, :compact=>get(io, :compact, true)), x, truncstring)
    return textwidth(String(take!(buffer)))
end

function truncatestring(s::AbstractString, truncstring::Int)
    truncstring <= 0 && return s
    totalwidth = 0
    for (i, c) in enumerate(s)
        totalwidth += textwidth(c)
        if totalwidth > truncstring
            return first(s, i-1) * '…'
        end
    end
    return s
end

"""
    IMD.ourshow(io::IO, x::Any, truncstring::Int)

Render a value to an `IO` object compactly using print.
`truncstring` indicates the approximate number of text characters width to truncate
the output (if it is a non-positive value then no truncation is applied).
"""
function ourshow(io::IO, x::Any, truncstring::Int; styled::Bool=false)
    io_ctx = IOContext(io, :compact=>get(io, :compact, true), :typeinfo=>typeof(x))
    sx = sprint(print, x, context=io_ctx)
    sx = escape_string(sx, ()) # do not escape "
    sx = truncatestring(sx, truncstring)
    styled ? printstyled(io_ctx, sx, color=:light_black) : print(io_ctx, sx)
end

const SHOW_TABULAR_TYPES = Union{AbstractDataset}

# workaround Julia 1.0 for Char
ourshow(io::IO, x::Char, truncstring::Int; styled::Bool=false) =
    ourshow(io, string(x), styled=styled, truncstring)

ourshow(io::IO, x::Nothing, truncstring::Int; styled::Bool=false) =
    ourshow(io, "", styled=styled, truncstring)
ourshow(io::IO, x::SHOW_TABULAR_TYPES, truncstring::Int; styled::Bool=false) =
    ourshow(io, summary(x), truncstring, styled=styled)

function ourshow(io::IO, x::Markdown.MD, truncstring::Int)
    r = repr(x)
    truncstring <= 0 && return chomp(truncstring)
    len = min(length(r, 1, something(findfirst(==('\n'), r), lastindex(r)+1)-1), truncstring)
    return print(io, len < length(r) - 1 ? first(r, len)*'…' : first(r, len))
end

# AbstractChar: https://github.com/JuliaLang/julia/pull/34730 (1.5.0-DEV.261)
# Irrational: https://github.com/JuliaLang/julia/pull/34741 (1.5.0-DEV.266)
if VERSION < v"1.5.0-DEV.261" || VERSION < v"1.5.0-DEV.266"
    function ourshow(io::IO, x::T, truncstring::Int) where T <: Union{AbstractChar, Irrational}
        io = IOContext(io, :compact=>get(io, :compact, true), :typeinfo=>typeof(x))
        show(io, x)
    end
end

# For most data frames, especially wide, columns having the same element type
# occur multiple times. batch_compacttype ensures that we compute string
# representation of a specific column element type only once and then reuse it.

function batch_compacttype(types::Vector{Any}, maxwidths::Vector{Int})
    @assert length(types) == length(maxwidths)
    cache = Dict{Any, String}()
    return map(types, maxwidths) do T, maxwidth
        get!(cache, T) do
            compacttype(T, maxwidth)
        end
    end
end

function batch_compacttype(types::Vector{Any}, maxwidth::Int=8)
    cache = Dict{Type, String}()
    return map(types) do T
        get!(cache, T) do
            compacttype(T, maxwidth)
        end
    end
end

"""
    compacttype(T::Type, maxwidth::Int=8, initial::Bool=true)

Return compact string representation of type `T`.

For displaying data frame we do not want string representation of type to be
longer than `maxwidth`. This function implements rules how type names are
cropped if they are longer than `maxwidth`.
"""
function compacttype(T::Type, maxwidth::Int=8)
    maxwidth = max(8, maxwidth)

    T === Any && return "Any"
    T === Missing && return "Missing"

    sT = string(T)
    textwidth(sT) ≤ maxwidth && return sT

    if T >: Missing
        T = our_nonmissingtype(T)
        sT = string(T)
        suffix = "?"
        textwidth(sT) ≤ maxwidth && return sT * suffix
    else
        suffix = ""
    end

    maxwidth -= 1 # we will add "…" at the end

    # This is only type display shortening so we
    # are OK with any T whose name starts with CategoricalValue here
    if startswith(sT, "CategoricalValue") || startswith(sT, "CategoricalArrays.CategoricalValue")
        sT = string(nameof(T))
        if textwidth(sT) ≤ maxwidth
            return sT * "…" * suffix
        else
            return (maxwidth ≥ 11 ? "Categorical…" : "Cat…") * suffix
        end
    elseif T isa Union
        return "Union…" * suffix
    else
        sT = string(nameof(T))
    end

    cumwidth = 0
    stop = 0
    for (i, c) in enumerate(sT)
        cumwidth += textwidth(c)
        if cumwidth ≤ maxwidth
            stop = i
        else
            break
        end
    end
    return first(sT, stop) * "…" * suffix
end

function _show(io::IO,
               ds::AbstractDataset;
               allrows::Bool = !get(io, :limit, false),
               allcols::Bool = !get(io, :limit, false),
               rowlabel::Symbol = :Row,
               summary::Bool = true,
               eltypes::Bool = true,
               rowid = nothing,
               truncate::Int = 32,
               kwargs...)

    _check_consistency(ds)

    names_str = names(ds)
    if typeof(ds) <: SubDataset
        column_formats = _getformats_for_show(ds)
    else
        column_formats = _getformats(ds)
    end
    names_format = fill("identity", length(names_str))
    _pt_formmatters_ = Function[]
    # push!(_pt_formmatters_, _pretty_tables_general_formatter)
    for (k,v) in column_formats
        names_format[k] = string(v)
        push!(_pt_formmatters_, (vv, i, j) -> j == k ? v(vv) : vv)
    end
    push!(_pt_formmatters_, _pretty_tables_general_formatter)

    pt_formatter = ntuple(i->_pt_formmatters_[i], length(_pt_formmatters_))
    names_len = Int[textwidth(n) for n in names_str]
    maxwidth = Int[max(9, nl) for nl in names_len]
    types = Any[eltype(c) for c in eachcol(ds)]
    types_str = batch_compacttype(types, maxwidth)

    if allcols && allrows
        crop = :none
    elseif allcols
        crop = :vertical
    elseif allrows
        crop = :horizontal
    else
        crop = :both
    end

    # For consistency, if `kwargs` has `compact_printng`, we must use it.
    compact_printing::Bool = get(kwargs, :compact_printing, get(io, :compact, true))

    num_rows, num_cols = size(ds)

    # By default, we align the columns to the left unless they are numbers,
    # which is checked in the following.
    alignment = fill(:l, num_cols)

    # Create the dictionary with the anchor regex that is used to align the
    # floating points.
    alignment_anchor_regex = Dict{Int, Vector{Regex}}()

    # Regex to align real numbers.
    alignment_regex_real = [r"\."]

    # Regex for columns with complex numbers.
    #
    # Here we are matching `+` or `-` unless it is not at the beginning of the
    # string or an `e` precedes it.
    alignment_regex_complex = [r"(?<!^)(?<!e)[+-]"]

    for i = 1:num_cols
        type_i = our_nonmissingtype(types[i])

        if type_i <: Complex
            alignment_anchor_regex[i] = alignment_regex_complex
            alignment[i] = :r
        elseif type_i <: Real
            alignment_anchor_regex[i] = alignment_regex_real
            alignment[i] = :r
        elseif type_i <: Number
            alignment[i] = :r
        end
    end

    # Make sure that `truncate` does not hide the type and the column name.
    maximum_columns_width = Int[truncate == 0 ? 0 : max(truncate + 1, l, textwidth(t))
                                for (l, t) in zip(names_len, types_str)]

    # Check if the user wants to display a summary about the DataFrame that is
    # being printed. This will be shown using the `title` option of
    # `pretty_table`.
    title = summary ? Base.summary(ds) : ""

    # If `rowid` is not `nothing`, then we are printing a data row. In this
    # case, we will add this information using the row name column of
    # PrettyTables.jl. Otherwise, we can just use the row number column.
    if (rowid === nothing) || (ncol(ds) == 0)
        show_row_number::Bool = get(kwargs, :show_row_number, true)
        row_names = nothing

        # If the columns with row numbers is not shown, then we should not
        # display a vertical line after the first column.
        vlines = fill(1, show_row_number)
    else
        nrow(ds) != 1 &&
            throw(ArgumentError("rowid may be passed only with a single row data frame"))

        # In this case, if the user does not want to show the row number, then
        # we must hide the row name column, which is used to display the
        # `rowid`.
        if !get(kwargs, :show_row_number, true)
            row_names = nothing
            vlines = Int[]
        else
            row_names = [string(rowid)]
            vlines = Int[1]
        end

        show_row_number = false
    end
    # if isgrouped(ds)
    #     extrahlines = view(index(ds).starts,1:index(ds).ngroups[]) .- 1
    # else
        extrahlines = [0]
    # end
    # Print the table with the selected options.
    # currently pretty_table is very slow for large tables, the workaround is to use only few rows
    if nrow(ds) > 10^7*5
        vcm = :bottom
    else
        vcm = :middle
    end
    pretty_table(io, ds;
                 alignment                   = alignment,
                 alignment_anchor_fallback   = :r,
                 alignment_anchor_regex      = alignment_anchor_regex,
                 body_hlines                 = extrahlines,
                 compact_printing            = compact_printing,
                 crop                        = crop,
                 crop_num_lines_at_beginning = 2,
                 ellipsis_line_skip          = 3,
                 formatters                  = pt_formatter,
                 header                      = (names_str, names_format, types_str),
                 header_alignment            = :l,
                 hlines                      = [:header],
                 highlighters                = (_PRETTY_TABLES_HIGHLIGHTER,),
                 maximum_columns_width       = maximum_columns_width,
                 newline_at_end              = false,
                 show_subheader              = eltypes,
                 row_label_alignment          = :r,
                 row_label_crayon             = Crayon(),
                 row_label_column_title       = string(rowlabel),
                 row_labels                   = row_names,
                 row_number_alignment        = :r,
                 row_number_column_title     = string(rowlabel),
                 show_row_number             = show_row_number,
                 title                       = title,
                 vcrop_mode                  = vcm,
                 vlines                      = vlines,
                 kwargs...)

    return nothing
end

"""
    show([io::IO, ]ds::AbstractDataset;
         allrows::Bool = !get(io, :limit, false),
         allcols::Bool = !get(io, :limit, false),
         allgroups::Bool = !get(io, :limit, false),
         rowlabel::Symbol = :Row,
         summary::Bool = true,
         eltypes::Bool = true,
         truncate::Int = 32,
         kwargs...)

Render a data frame to an I/O stream. The specific visual
representation chosen depends on the width of the display.

If `io` is omitted, the result is printed to `stdout`,
and `allrows`, `allcols` and `allgroups` default to `false`.

# Arguments
- `io::IO`: The I/O stream to which `ds` will be printed.
- `ds::AbstractDataset`: The data frame to print.
- `allrows::Bool `: Whether to print all rows, rather than
  a subset that fits the device height. By default this is the case only if
  `io` does not have the `IOContext` property `limit` set.
- `allcols::Bool`: Whether to print all columns, rather than
  a subset that fits the device width. By default this is the case only if
  `io` does not have the `IOContext` property `limit` set.
- `allgroups::Bool`: Whether to print all groups rather than
  the first and last, when `ds` is a `GroupedDataFrame`.
  By default this is the case only if `io` does not have the `IOContext` property
  `limit` set.
- `rowlabel::Symbol = :Row`: The label to use for the column containing row numbers.
- `summary::Bool = true`: Whether to print a brief string summary of the data frame.
- `eltypes::Bool = true`: Whether to print the column types and formats under column names.
- `truncate::Int = 32`: the maximal display width the output can use before
  being truncated (in the `textwidth` sense, excluding `…`).
  If `truncate` is 0 or less, no truncation is applied.
- `kwargs...`: Any keyword argument supported by the function `pretty_table` of
  PrettyTables.jl can be passed here to customize the output.
"""
function Base.show(io::IO,
          ds::AbstractDataset;
          allrows::Bool = !get(io, :limit, false),
          allcols::Bool = !get(io, :limit, false),
          rowlabel::Symbol = :Row,
          summary::Bool = true,
          eltypes::Bool = true,
          truncate::Int = 32,
          kwargs...)
    _show(io, ds; allrows=allrows, allcols=allcols, rowlabel=rowlabel,
          summary=summary, eltypes=eltypes, truncate=truncate, kwargs...)
end

function Base.show(ds::AbstractDataset;
          allrows::Bool = !get(stdout, :limit, true),
          allcols::Bool = !get(stdout, :limit, true),
          rowlabel::Symbol = :Row,
          summary::Bool = true,
          eltypes::Bool = true,
          truncate::Int = 32,
          kwargs...)
    show(stdout, ds;
         allrows=allrows, allcols=allcols, rowlabel=rowlabel, summary=summary,
         eltypes=eltypes, truncate=truncate, kwargs...)
end
