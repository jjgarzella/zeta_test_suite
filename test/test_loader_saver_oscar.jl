using Test
using Oscar
using JSON

include(joinpath(@__DIR__, "..", "oscar", "loader.jl"))
include(joinpath(@__DIR__, "..", "oscar", "saver.jl"))

const FIXTURES = joinpath(@__DIR__, "fixtures")

# ----------------------------------------------------------------------
# TestLoaderPerKind: fixture-backed load for each supported model kind
# ----------------------------------------------------------------------

@testset "TestLoaderPerKind" begin
    @testset "plane_curve" begin
        cases = load_expanded_cases(joinpath(FIXTURES, "plane_curve.json"))
        @test length(cases) == 1
        c = cases[1]
        @test c.variety.kind == "plane_curve"
        @test c.variety.dim == 1
        @test c.variety.genus == 1
        @test haskey(c.variety.polys, "F")
        @test Set(keys(c.expected_l_factors)) == Set(0:2)
    end

    @testset "projective_hypersurface (explicit)" begin
        cases = load_expanded_cases(joinpath(FIXTURES, "projective_hypersurface.json"))
        @test length(cases) == 1
        c = cases[1]
        @test c.variety.kind == "projective_hypersurface"
        @test c.variety.dim == 2
        @test Set(keys(c.expected_l_factors)) == Set(0:4)
    end

    @testset "double_cover_P2 (primitive)" begin
        cases = load_expanded_cases(joinpath(FIXTURES, "double_cover_P2.json"))
        @test length(cases) == 1
        c = cases[1]
        @test c.variety.kind == "double_cover_P2"
        @test c.variety.dim == 2
        @test c.variety.polys["m"] == 2
        @test Set(keys(c.expected_l_factors)) == Set(0:4)
    end
end

# ----------------------------------------------------------------------
# TestLoaderShorthandExpansion: primitive middle factor, Lefschetz pieces
# ----------------------------------------------------------------------

@testset "TestLoaderShorthandExpansion" begin
    @testset "double_cover_P2 primitive middle" begin
        cases = load_expanded_cases(joinpath(FIXTURES, "double_cover_P2.json"))
        c = cases[1]
        p = c.p
        lf = c.expected_l_factors
        # non-middle Lefschetz factors
        @test lf[0] == [ZZ(1), ZZ(-1)]
        @test lf[1] == [ZZ(1)]
        @test lf[3] == [ZZ(1)]
        @test lf[4] == [ZZ(1), -p^2]
        # middle is (1-pT) times the primitive coeffs (degree 21 -> degree 22)
        @test length(lf[2]) == 23
        @test lf[2][1] == ZZ(1)
    end
end

# ----------------------------------------------------------------------
# TestLoaderRejections: unsupported kinds/modes must error
# ----------------------------------------------------------------------

@testset "TestLoaderRejections" begin
    @testset "hyperelliptic kind not supported" begin
        @test_throws ErrorException load_expanded_cases(joinpath(FIXTURES, "hyperelliptic.json"))
    end
    @testset "superelliptic kind not supported" begin
        @test_throws ErrorException load_expanded_cases(joinpath(FIXTURES, "superelliptic.json"))
    end
    @testset "cyclic_cover kind not supported" begin
        @test_throws ErrorException load_expanded_cases(joinpath(FIXTURES, "cyclic_cover.json"))
    end
    @testset "wrong schema version" begin
        mktempdir() do d
            path = joinpath(d, "bad.json")
            open(path, "w") do fh
                JSON.print(fh, Dict("schema_version" => "2", "cases" => []))
            end
            @test_throws ErrorException load_cases(path)
        end
    end
end

# ----------------------------------------------------------------------
# TestSaverRoundTrip: save -> reload matches original
# ----------------------------------------------------------------------

function _roundtrip(fixture_name)
    cases = load_cases(joinpath(FIXTURES, fixture_name))
    @test length(cases) == 1
    original = cases[1]
    mktempdir() do d
        out_path = joinpath(d, "out.json")
        case_dict = Dict(
            "id" => original.id,
            "variety" => original.variety,
            "results" => original.results,
            "notes" => original.notes,
        )
        save_grouped_case(case_dict, out_path)
        reloaded = load_cases(out_path)
        @test length(reloaded) == 1
        r = reloaded[1]
        @test r.id == original.id
        @test r.variety == original.variety
        @test length(r.results) == length(original.results)
        @test r.notes == original.notes
    end
end

@testset "TestSaverRoundTrip" begin
    _roundtrip("plane_curve.json")
    _roundtrip("projective_hypersurface.json")
    _roundtrip("double_cover_P2.json")
end

# ----------------------------------------------------------------------
# TestSaverFromBuilders: build model dicts from Oscar polynomials
# ----------------------------------------------------------------------

@testset "TestSaverFromBuilders" begin
    @testset "plane_curve model builder" begin
        F = GF(7)
        R, (x, y, z) = polynomial_ring(F, [:x, :y, :z])
        poly = x^3 + y^3 + z^3
        model = make_plane_curve_model(poly)
        @test model["kind"] == "plane_curve"
        @test model["vars"] == ["x", "y", "z"]
        @test length(model["monomials"]) == 3
        @test length(model["coeffs"]) == 3
    end

    @testset "projective_hypersurface model builder" begin
        F = GF(7)
        R, vs = polynomial_ring(F, [:x, :y, :z, :w])
        poly = sum(v^4 for v in vs)
        model = make_projective_hypersurface_model(poly)
        @test model["kind"] == "projective_hypersurface"
        @test length(model["vars"]) == 4
        @test length(model["monomials"]) == 4
    end

    @testset "double_cover_P2 model builder" begin
        F = GF(7)
        R, (x, y, z) = polynomial_ring(F, [:x, :y, :z])
        branch = x^6 + y^6 + z^6
        model = make_double_cover_P2_model(branch)
        @test model["kind"] == "double_cover_P2"
        @test model["branch_vars"] == ["x", "y", "z"]
        @test length(model["branch_monomials"]) == 3
    end
end

# ----------------------------------------------------------------------
# TestSaverUpsert: save_grouped_case replaces by id
# ----------------------------------------------------------------------

@testset "TestSaverUpsert" begin
    mktempdir() do d
        out_path = joinpath(d, "out.json")
        F = GF(7)
        R, (x, y, z) = polynomial_ring(F, [:x, :y, :z])

        model1 = make_plane_curve_model(x^3 + y^3 + z^3)
        v1 = make_variety(model1, 1; genus=1)
        save_case(v1, [1, -4, 7], out_path, "case_a"; p=7, notes="first")

        cases = load_cases(out_path)
        @test length(cases) == 1
        @test cases[1].id == "case_a"

        # Upsert: replace case_a
        model1b = make_plane_curve_model(x^3 + y^3 + z^3 + x*y*z)
        v1b = make_variety(model1b, 1; genus=1)
        save_case(v1b, [1, -2, 7], out_path, "case_a"; p=7, notes="updated")

        cases = load_cases(out_path)
        @test length(cases) == 1
        @test cases[1].notes == "updated"

        # New id appends
        save_case(v1, [1, 0, 7], out_path, "case_b"; p=7)
        cases = load_cases(out_path)
        @test length(cases) == 2
        @test Set(c.id for c in cases) == Set(["case_a", "case_b"])
    end
end
