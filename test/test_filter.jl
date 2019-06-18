@testset "Testing filter.jl" begin
    mat = readdlm("test_filter.txt")
    data = Dict("year" => mat[:, 1],
                "empl" => Int.(mat[:, 2]),
                "ham_c_mat" => mat[:, 3],
                "ham_rw_c_mat" => mat[:, 4],
                "hp_c_mat" => mat[:, 5])
    data["data"] = 100*log.(data["empl"])

    @testset "test hp filter" begin
        data["hp_c"], data["hp_t"] = hp_filter(data["data"], 1600)
        @test isapprox(data["hp_c"], data["hp_c_mat"])
    end

    @testset "test hamilton filter" begin
        data["ham_c"], data["ham_t"] = hamilton_filter(data["data"], 8, 4)
        data["ham_rw_c"], data["hp_rw_t"] = hamilton_filter(data["data"], 8)
        @test isapprox(data["ham_c"], data["ham_c_mat"], nans=true, rtol=1e-7, atol=1e-7)
        @test isapprox(data["ham_rw_c"], data["ham_rw_c_mat"], nans=true)
    end
end
