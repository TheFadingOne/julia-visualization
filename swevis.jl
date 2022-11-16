using Makie
using GLMakie

struct Frame
    xs  :: Vector{Float64}
    ys  :: Vector{Float64}
    zs  :: Vector{Float64}
    hs  :: Vector{Float64}
    hus :: Vector{Float64}
    hvs :: Vector{Float64}
    bs  :: Vector{Float64}
end

struct SWEData
    timesteps :: Vector{Float64}
    frames    :: Vector{Frame}
    xlims
    ylims
    zlims
end

function readswedata(filename)
    r1 = r"#.*"
    r2 = r"([\w\._]*),([\w\._]*)"
    r3 = r"((/[\w\.]*)*)(/[\w\.]*)"

    data = SWEData(
                   [],
                   [],
                   [prevfloat(typemax(Float64)), nextfloat(typemin(Float64))],
                   [prevfloat(typemax(Float64)), nextfloat(typemin(Float64))],
                   [prevfloat(typemax(Float64)), nextfloat(typemin(Float64))])

    open(filename, "r") do io
        s = read(io, String)
        lines = split(s, '\n')

        for line = lines
            if line == "" || match(r1, line) !== nothing
                continue
            end

            m = match(r2, line)
            if m === nothing
                data = nothing
                break
            end

            sub = SubstitutionString(string("\\1/", m[2]))
            csvfilename = replace(filename, r3 => sub)

            frame = readframe!(csvfilename, data.xlims, data.ylims, data.zlims)
            if frame === nothing
                data = nothing
                break
            end

            push!(data.timesteps, parse(Float64, m[1]))
            push!(data.frames, frame)
        end
    end

    data
end

function readframe!(filename, xlims, ylims, zlims)
    r1 = r"#.*"
    r2 = r"(-?[\d\.]*),(-?[\d\.]*),(-?[\d\.]*),(-?[\d\.]*),(-?[\d\.]*).(-?[\d\.]*),(-?[\d\.]*)"
    frame = Frame([], [], [], [], [], [], [])

    open(filename, "r") do io
        s = read(io, String)
        lines = split(s, '\n')

        for line = lines
            if line == "" || match(r1, line) !== nothing
                continue
            end

            m = match(r2, line)
            if m === nothing
                frame = nothing
                break
            end

            x = parse(Float64, m[1])
            y = parse(Float64, m[2])
            z = parse(Float64, m[3])
            h = parse(Float64, m[4])
            hu = parse(Float64, m[5])
            hv = parse(Float64, m[6])
            b = parse(Float64, m[7])

            push!(frame.xs, x)
            push!(frame.ys, y)
            push!(frame.zs, z)
            push!(frame.hs, h)
            push!(frame.hus, hu)
            push!(frame.hvs, hv)
            push!(frame.bs, b)

            xlims[1] = min(0, x, xlims[1])
            xlims[2] = max(x, xlims[2])

            ylims[1] = min(0, y, ylims[1])
            ylims[2] = max(y, ylims[2])

            zlims[1] = min(z, h, hu, hv, zlims[1])
            zlims[2] = max(z, h, hu, hv, zlims[2])
        end
    end

    frame
end

# TODO animate data
data = readswedata(ARGS[1])
fig = surface(
              data.frames[1].xs,
              data.frames[1].ys,
              data.frames[1].hs,
              axis=(; type=Axis3,
                    limits = (data.xlims[1], data.xlims[2], data.ylims[1], data.ylims[2], 0, data.zlims[2])))
save(ARGS[2], fig)
