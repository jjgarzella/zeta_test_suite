using DeRham, Oscar
using Random
using Printf
using Primes

include("/Users/jjgarzella/Developer/ai/zeta_test_suite/oscar/saver.jl")

const ZTS_ROOT = "/Users/jjgarzella/Developer/ai/zeta_test_suite"

# -----------------------------------------------------------------------------
# Polynomial constructors over GF(p)
# -----------------------------------------------------------------------------

function varnames(nvars::Int)
    nvars == 3 ? ["x", "y", "z"] : ["x", "y", "z", "w"]
end

function make_ring(p::Integer, nvars::Int)
    F = GF(Int(p))
    R, _ = polynomial_ring(F, varnames(nvars))
    return R
end

function _build_from_monos(R, exp_vecs, coeffs)
    F = base_ring(R)
    C = MPolyBuildCtx(R)
    for (ev, c) in zip(exp_vecs, coeffs)
        c == 0 && continue
        push_term!(C, F(Int(c)), ev)
    end
    finish(C)
end

"Random dense homogeneous polynomial of degree d in R (all monomials nonzero)."
function rand_dense(R, d::Int; rng=Random.default_rng())
    p = Int(characteristic(base_ring(R)))
    nvars = length(gens(R))
    evs = DeRham.gen_exp_vec(nvars, d)
    coeffs = [rand(rng, 1:p-1) for _ in evs]
    _build_from_monos(R, evs, coeffs)
end

"Random Fermat-kernel + perturbation: x0^d + x1^d + ... + xn^d + small random extras."
function rand_sparse_fk(R, d::Int; num_extra::Int=3, rng=Random.default_rng())
    p = Int(characteristic(base_ring(R)))
    nvars = length(gens(R))
    gens_R = gens(R)
    # Fermat skeleton
    f = sum(gens_R[i]^d for i in 1:nvars)
    # random extra monomials (avoid the Fermat ones)
    evs = DeRham.gen_exp_vec(nvars, d)
    fermat_set = Set{Vector{Int}}()
    for i in 1:nvars
        ev = zeros(Int, nvars)
        ev[i] = d
        push!(fermat_set, ev)
    end
    non_fermat = [ev for ev in evs if !(ev in fermat_set)]
    k = min(num_extra, length(non_fermat))
    chosen_idx = randperm(rng, length(non_fermat))[1:k]
    for idx in chosen_idx
        ev = non_fermat[idx]
        c = rand(rng, 1:p-1)
        term = base_ring(R)(c)
        monterm = one(R)
        for (j, e) in enumerate(ev)
            monterm *= gens_R[j]^Int(e)
        end
        f += base_ring(R)(c) * monterm
    end
    f
end

"Random asymmetric sparse: a handful of random-weight monomials (no obvious symmetry)."
function rand_sparse_as(R, d::Int; num_terms::Int=6, rng=Random.default_rng())
    p = Int(characteristic(base_ring(R)))
    nvars = length(gens(R))
    evs = DeRham.gen_exp_vec(nvars, d)
    k = min(num_terms, length(evs))
    chosen = randperm(rng, length(evs))[1:k]
    coeffs = zeros(Int, length(evs))
    for idx in chosen
        coeffs[idx] = rand(rng, 1:p-1)
    end
    _build_from_monos(R, evs, coeffs)
end

# -----------------------------------------------------------------------------
# Lifting GF(p) polynomial to a ZZ-coefficient polynomial dict (for save)
# -----------------------------------------------------------------------------

"Return (monomials, coeffs) with coefficients lifted to Int in [0, p-1]."
function poly_to_monos_coeffs(f)
    monos = Vector{Vector{Int}}()
    coefs = Int[]
    for (c, ev) in coefficients_and_exponents(f)
        iszero(c) && continue
        push!(monos, [Int(e) for e in ev])
        push!(coefs, Int(lift(ZZ, c)))
    end
    monos, coefs
end

# -----------------------------------------------------------------------------
# DeRham output to Lpoly asc conversion
# -----------------------------------------------------------------------------

"Reverse DeRham's ascending char poly to produce the L-poly ASC coefficients."
function derham_to_lpoly_asc(zc)
    [BigInt(c) for c in reverse(zc)]
end

# -----------------------------------------------------------------------------
# Per-kind zeta computation wrappers
# -----------------------------------------------------------------------------

"Compute Lpoly (asc) for plane curve F of degree d over F_p; returns nothing if non-smooth."
function lpoly_plane_curve(F)
    DeRham.is_Ssmooth(F, [0,1,2]) || return nothing
    zc = DeRham.zeta_coefficients(F)
    zc === false && return nothing
    derham_to_lpoly_asc(zc)
end

"Compute Lpoly (primitive, asc) for K3 quartic F over F_p; returns nothing if non-smooth."
function lpoly_k3(F)
    DeRham.is_Ssmooth(F, [0,1,2,3]) || return nothing
    zc = DeRham.zeta_coefficients(F)
    zc === false && return nothing
    derham_to_lpoly_asc(zc)
end

"Compute Lpoly (primitive, asc) for cubic surface F over F_p; returns nothing if non-smooth."
function lpoly_cubic_surf(F)
    # cubic surface in P^3 requires |S|<=3
    DeRham.is_Ssmooth(F, [0,1,2]) || return nothing
    zc = DeRham.zeta_coefficients(F, S=[0,1,2])
    zc === false && return nothing
    derham_to_lpoly_asc(zc)
end

# -----------------------------------------------------------------------------
# Variety dict builders (for our v3 schema)
# -----------------------------------------------------------------------------

function variety_plane_curve(F; genus)
    monos, coefs = poly_to_monos_coeffs(F)
    vars_ = _vars_of_ring(parent(F))
    Dict{String,Any}(
        "coeff_domain" => Dict("kind" => "integer"),
        "dim" => 1,
        "genus" => Int(genus),
        "non_middle_factors" => Dict(
            "kind" => "projective_lefschetz",
            "middle_factor_content" => "full",
        ),
        "model" => Dict{String,Any}(
            "kind" => "plane_curve",
            "pretty" => "$F = 0",
            "vars" => vars_,
            "monomials" => monos,
            "coeffs" => coefs,
        ),
    )
end

function variety_proj_hypersurface(F; dim, middle_content="primitive")
    monos, coefs = poly_to_monos_coeffs(F)
    vars_ = _vars_of_ring(parent(F))
    Dict{String,Any}(
        "coeff_domain" => Dict("kind" => "integer"),
        "dim" => Int(dim),
        "non_middle_factors" => Dict(
            "kind" => "projective_lefschetz",
            "middle_factor_content" => middle_content,
        ),
        "model" => Dict{String,Any}(
            "kind" => "projective_hypersurface",
            "pretty" => "$F = 0",
            "vars" => vars_,
            "monomials" => monos,
            "coeffs" => coefs,
        ),
    )
end

# -----------------------------------------------------------------------------
# Save a grouped case (one variety + one result)
# -----------------------------------------------------------------------------

function save_one(filename, id, variety_dict, p, lpoly_asc, notes::String)
    case = Dict{String,Any}(
        "id" => id,
        "variety" => variety_dict,
        "results" => [encode_result(BigInt(p), lpoly_asc)],
        "notes" => notes,
    )
    save_grouped_case(case, filename)
    return nothing
end

# -----------------------------------------------------------------------------
# Prime sampling
# -----------------------------------------------------------------------------

"Primes in [lo, hi] skipping any prime dividing d."
function primes_range(lo::Int, hi::Int; skip_d::Int=1)
    [p for p in Primes.primes(lo, hi) if skip_d % p != 0]
end

# Fixed medium prime sample used across all kinds.
const MEDIUM_PRIMES = [101, 131, 167, 211, 251, 307, 401, 503, 601, 701, 811, 953]

# -----------------------------------------------------------------------------
# Drivers
# -----------------------------------------------------------------------------

"""
Generate plane-curve cases of given degree d. One variety per attempt, retried
until smooth. Writes to `filename` via save_grouped_case (upsert by id).
- `kind_tag`: identifier used in IDs, e.g. "plane_q5", "plane_q4".
- `flavor`: :dense, :sparse. For :sparse, alternates fk/as by index.
- `num_per_prime`: cases per prime.
- `primes`: iterable of primes.
- `seed`: RNG seed.
"""
function gen_plane_curve_file(filename, d::Int, genus::Int;
                              kind_tag::String="plane_q$d",
                              flavor::Symbol=:dense,
                              num_per_prime::Int=3,
                              primes::AbstractVector{Int}=primes_range(7, 100; skip_d=d),
                              seed::Int=2001,
                              max_attempts::Int=50,
                              notes_prefix::String="")
    rng = Random.MersenneTwister(seed)
    for p in primes
        R = make_ring(p, 3)
        for i in 1:num_per_prime
            sub = flavor == :dense ? "dense" : (isodd(i) ? "sparse_fk" : "sparse_as")
            id = @sprintf("p%d_%s_%s_%03d", p, kind_tag, sub, i)
            lpoly = nothing
            F = nothing
            for _ in 1:max_attempts
                F = if flavor == :dense
                    rand_dense(R, d; rng=rng)
                elseif isodd(i)
                    rand_sparse_fk(R, d; rng=rng)
                else
                    rand_sparse_as(R, d; rng=rng)
                end
                lpoly = lpoly_plane_curve(F)
                lpoly !== nothing && break
            end
            if lpoly === nothing
                @warn "gen_plane_curve_file: gave up on smooth curve" p=p id=id
                continue
            end
            notes = isempty(notes_prefix) ? "generated via DeRham.jl" : notes_prefix
            save_one(filename, id, variety_plane_curve(F; genus=genus), p, lpoly, notes)
            println("saved $id")
        end
    end
end

"""
Generate projective-hypersurface cases of given degree d in nvars variables.
Retries for smoothness; uses lpoly_cubic_surf when d<nvars (needs S truncation),
otherwise lpoly_k3-style (full S).
"""
function gen_proj_hypersurface_file(filename, d::Int, nvars::Int;
                                    kind_tag::String,
                                    flavor::Symbol=:dense,
                                    num_per_prime::Int=1,
                                    primes::AbstractVector{Int}=primes_range(5, 100; skip_d=d),
                                    seed::Int=1001,
                                    max_attempts::Int=50,
                                    middle_content::String="primitive",
                                    notes_prefix::String="")
    dim = nvars - 2  # hypersurface in P^{nvars-1} has dimension nvars-2
    rng = Random.MersenneTwister(seed)
    S_full = collect(0:nvars-2)      # full S = 0..dim
    truncate_S = d < nvars           # e.g. cubic surface d=3, nvars=4 -> need S=[0,1,2]
    for p in primes
        R = make_ring(p, nvars)
        for i in 1:num_per_prime
            sub = flavor == :dense ? "dense" : (isodd(i) ? "sparse_fk" : "sparse_as")
            id = @sprintf("p%d_%s_%s_%03d", p, kind_tag, sub, i)
            lpoly = nothing
            F = nothing
            for _ in 1:max_attempts
                F = if flavor == :dense
                    rand_dense(R, d; rng=rng)
                elseif isodd(i)
                    rand_sparse_fk(R, d; rng=rng)
                else
                    rand_sparse_as(R, d; rng=rng)
                end
                if !DeRham.is_Ssmooth(F, S_full)
                    continue
                end
                zc = truncate_S ? DeRham.zeta_coefficients(F, S=S_full) : DeRham.zeta_coefficients(F)
                if zc === false
                    continue
                end
                lpoly = derham_to_lpoly_asc(zc)
                break
            end
            if lpoly === nothing
                @warn "gen_proj_hypersurface_file: gave up on smooth hypersurface" p=p id=id
                continue
            end
            notes = isempty(notes_prefix) ? "generated via DeRham.jl" : notes_prefix
            save_one(filename, id,
                     variety_proj_hypersurface(F; dim=dim, middle_content=middle_content),
                     p, lpoly, notes)
            println("saved $id")
        end
    end
end

println("gen.jl loaded")
