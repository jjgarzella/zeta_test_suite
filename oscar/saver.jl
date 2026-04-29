"""
saver.jl — Save v3 zeta-function test cases to JSON using Oscar.

Mirrors sage/saver.sage for the model kinds the oscar loader handles:
plane_curve, projective_hypersurface, double_cover_P2. Other kinds error.

Public API:
    make_plane_curve_model(F; pretty=nothing)
    make_projective_hypersurface_model(F; pretty=nothing)
    make_double_cover_P2_model(branch_poly; pretty=nothing)
    make_variety(model, dim; coeff_domain=..., non_middle_factors=..., genus=nothing)
    encode_lpoly(coeffs)
    encode_l_factors(factors)
    encode_result(p, result)
    save_case(variety, result, filename, id; notes="", p=nothing,
              non_middle_factors=nothing)
    save_grouped_case(case, filename)
"""

using Oscar
using JSON

const SCHEMA_VERSION = "3"
const INT64_JSON_BOUND = big(2)^63

const DEFAULT_NON_MIDDLE_FACTORS = Dict(
    "kind" => "projective_lefschetz",
    "middle_factor_content" => "full",
)

# ----------------------------------------------------------------------
# Scalar / poly encoding
# ----------------------------------------------------------------------

_json_integer_like(n::Integer) = abs(BigInt(n)) < INT64_JSON_BOUND ? Int(n) : string(BigInt(n))
_json_integer_like(n::ZZRingElem) = abs(BigInt(n)) < INT64_JSON_BOUND ? Int(n) : string(BigInt(n))

function _nonnegative_int(c, p::Integer)
    lifted = BigInt(lift(ZZ, c))
    return mod(lifted, BigInt(p))
end

function _encode_multivariable_poly(poly; p::Union{Nothing,Integer}=nothing)
    monomials_out = Vector{Vector{Int}}()
    coeffs_out = Any[]
    for (c, e) in coefficients_and_exponents(poly)
        if iszero(c)
            continue
        end
        push!(monomials_out, [Int(ei) for ei in e])
        if p !== nothing
            push!(coeffs_out, _json_integer_like(_nonnegative_int(c, p)))
        else
            push!(coeffs_out, _json_integer_like(BigInt(lift(ZZ, c))))
        end
    end
    return monomials_out, coeffs_out
end

_vars_of_ring(R) = [string(g) for g in gens(R)]

function _ring_characteristic(R)
    p = characteristic(base_ring(R))
    return p == 0 ? nothing : Int(p)
end

# ----------------------------------------------------------------------
# Per-kind model dict builders
# ----------------------------------------------------------------------

function make_plane_curve_model(F; pretty=nothing)
    R = parent(F)
    vars_ = _vars_of_ring(R)
    if length(vars_) != 3
        error("plane_curve requires exactly 3 variables, got $(vars_)")
    end
    p = _ring_characteristic(R)
    monos, coefs = _encode_multivariable_poly(F; p=p)
    return Dict(
        "kind" => "plane_curve",
        "pretty" => pretty === nothing ? "$F = 0" : pretty,
        "vars" => vars_,
        "monomials" => monos,
        "coeffs" => coefs,
    )
end

function make_projective_hypersurface_model(F; pretty=nothing)
    R = parent(F)
    vars_ = _vars_of_ring(R)
    if length(vars_) < 2
        error("projective_hypersurface requires >= 2 variables, got $(vars_)")
    end
    p = _ring_characteristic(R)
    monos, coefs = _encode_multivariable_poly(F; p=p)
    return Dict(
        "kind" => "projective_hypersurface",
        "pretty" => pretty === nothing ? "$F = 0" : pretty,
        "vars" => vars_,
        "monomials" => monos,
        "coeffs" => coefs,
    )
end

function make_double_cover_P2_model(branch_poly; pretty=nothing)
    R = parent(branch_poly)
    vars_ = _vars_of_ring(R)
    if length(vars_) != 3
        error("double_cover_P2 requires a 3-variable branch poly, got $(vars_)")
    end
    p = _ring_characteristic(R)
    monos, coefs = _encode_multivariable_poly(branch_poly; p=p)
    return Dict(
        "kind" => "double_cover_P2",
        "pretty" => pretty === nothing ? "y^2 = $branch_poly" : pretty,
        "branch_vars" => vars_,
        "branch_monomials" => monos,
        "branch_coeffs" => coefs,
    )
end

# ----------------------------------------------------------------------
# Variety / result wrappers
# ----------------------------------------------------------------------

function make_variety(model, dim; coeff_domain=nothing,
                      non_middle_factors=nothing, genus=nothing)
    variety = Dict{String,Any}(
        "coeff_domain" => coeff_domain === nothing ? Dict("kind" => "integer") : coeff_domain,
        "dim" => Int(dim),
        "non_middle_factors" => non_middle_factors === nothing ? copy(DEFAULT_NON_MIDDLE_FACTORS) : non_middle_factors,
        "model" => model,
    )
    if genus !== nothing
        variety["genus"] = Int(genus)
    end
    return variety
end

encode_lpoly(coeffs) = Dict("coeffs_asc" => [_json_integer_like(c) for c in coeffs])

function encode_l_factors(factors)
    return Dict(
        string(k) => Dict("coeffs_asc" => [_json_integer_like(c) for c in v])
        for (k, v) in factors
    )
end

function encode_result(p, result)
    out = Dict{String,Any}("p" => _json_integer_like(p))
    if result isa AbstractDict
        out["l_factors"] = encode_l_factors(result)
    else
        out["Lpoly"] = encode_lpoly(result)
    end
    return out
end

# ----------------------------------------------------------------------
# Public save_case / save_grouped_case
# ----------------------------------------------------------------------

function save_case(variety, result, filename, id; notes="", p=nothing,
                   non_middle_factors=nothing)
    if variety isa AbstractDict
        if p === nothing
            error("save_case: keyword `p` is required when `variety` is a dict")
        end
        variety_dict = variety
        result_p = p
    else
        error("save_case: pass a v3 variety dict; oscar saver does not " *
              "auto-convert CAS-level variety objects (use make_plane_curve_model etc.)")
    end

    case = Dict(
        "id" => id,
        "variety" => variety_dict,
        "results" => [encode_result(result_p, result)],
        "notes" => notes,
    )
    save_grouped_case(case, filename)
end

function save_grouped_case(case::AbstractDict, filename::AbstractString)
    if !endswith(filename, ".json")
        error("filename must end with '.json', got $(repr(filename))")
    end

    if !isfile(filename)
        data = Dict("schema_version" => SCHEMA_VERSION, "cases" => [case])
    else
        data = open(JSON.parse, filename)
        if get(data, "schema_version", nothing) != SCHEMA_VERSION
            error("$filename: existing schema_version " *
                  "$(repr(get(data, "schema_version", nothing))) != $(repr(SCHEMA_VERSION))")
        end
        found = false
        for (i, existing) in enumerate(data["cases"])
            if existing["id"] == case["id"]
                data["cases"][i] = case
                found = true
                break
            end
        end
        if !found
            push!(data["cases"], case)
        end
    end

    open(filename, "w") do fh
        JSON.print(fh, data, 2)
    end
    return nothing
end
