# Dimensionality Checks

@testset "check_dims(X; dims)" begin
    n = 20
    p = 5
    for T in (Float32, Float64)
        @test_throws ArgumentError DA.check_dims(zeros(T, p, p), dims=0)
        @test_throws ArgumentError DA.check_dims(zeros(T, p, p), dims=3)

        @test (n, p) == DA.check_dims(zeros(T, n, p), dims=1)
        @test (n, p) == DA.check_dims(zeros(T, p, n), dims=2)
        @test (n, p) == DA.check_dims(transpose(zeros(T, n, p)), dims=2)
    end
end

@testset "check_data_dims(X, y; dims)" begin
    n = 10
    p = 5
    for T in (Float32, Float64)
        X = zeros(T, n, p)
        y = zeros(Int, n)

        @test_throws ArgumentError DA.check_data_dims(X, y, dims=0)
        @test_throws ArgumentError DA.check_data_dims(X, y, dims=3)

        # check parameter dimensionality for row-based data

        @test_throws DimensionMismatch DA.check_data_dims(zeros(T, n+1, p), y, dims=1)
        @test_throws DimensionMismatch DA.check_data_dims(zeros(T, n-1, p), y, dims=1)

        @test_throws DimensionMismatch DA.check_data_dims(X, zeros(Int, n+1), dims=1)
        @test_throws DimensionMismatch DA.check_data_dims(X, zeros(Int, n-1), dims=1)

        @test (n, p) == DA.check_data_dims(X, y, dims=1)

        # check parameter dimensionality for column-based data

        Xt = transpose(X)

        @test_throws DimensionMismatch DA.check_data_dims(zeros(T, p, n+1), y, dims=2)
        @test_throws DimensionMismatch DA.check_data_dims(zeros(T, p, n-1), y, dims=2)

        @test_throws DimensionMismatch DA.check_data_dims(Xt, zeros(Int, n+1), dims=2)
        @test_throws DimensionMismatch DA.check_data_dims(Xt, zeros(Int, n-1), dims=2)

        @test (n, p) == DA.check_data_dims(Xt, y, dims=2)
    end
end

@testset "check_centroid_dims(M, X; dims)" begin
    n = 20
    p = 5
    k = 3
    for T in (Float32, Float64)
        X = zeros(T, n, p)
        M = zeros(T, k, p)

        @test_throws ArgumentError DA.check_centroid_dims(M, X, dims=0)
        @test_throws ArgumentError DA.check_centroid_dims(M, X, dims=3)

        # check parameter dimensionality for row-based data

        @test_throws DimensionMismatch DA.check_centroid_dims(zeros(T, k, p+1), X, dims=1)
        @test_throws DimensionMismatch DA.check_centroid_dims(zeros(T, k, p-1), X, dims=1)

        @test_throws DimensionMismatch DA.check_centroid_dims(M, zeros(T, n, p+1), dims=1)
        @test_throws DimensionMismatch DA.check_centroid_dims(M, zeros(T, n, p-1), dims=1)

        @test (n, p, k) == DA.check_centroid_dims(M, X, dims=1)

        # check parameter dimensionality for column-based data

        Xt = transpose(X)
        Mt = transpose(M)

        @test_throws DimensionMismatch DA.check_centroid_dims(zeros(T, p+1, k), Xt, dims=2)
        @test_throws DimensionMismatch DA.check_centroid_dims(zeros(T, p-1, k), Xt, dims=2)

        @test_throws DimensionMismatch DA.check_centroid_dims(Mt, zeros(T, p+1, n), dims=2)
        @test_throws DimensionMismatch DA.check_centroid_dims(Mt, zeros(T, p-1, n), dims=2)

        @test (n, p, k) == DA.check_centroid_dims(Mt, Xt, dims=2)
    end
end

# Data Validation

@testset "validate_priors(π)" begin
    k = 10
    for T in (Float32, Float64)
        # Check probability domain
        @test_throws DomainError DA.validate_priors(T[0.5; 0.5; 0.0])
        @test_throws DomainError DA.validate_priors(T[1.0; 0.0; 0.0])

        # Check totals
        @test_throws ArgumentError DA.validate_priors(T[0.3; 0.3; 0.3])
        @test_throws ArgumentError DA.validate_priors(T[0.4; 0.4; 0.4])

        # Test valid π
        π = rand(T, k)
        π ./= sum(π)
        #broadcast!(/, π, π, sum(π))

        @test k == DA.validate_priors(π)
    end
end

# Class operations

@testset "class_counts(nₘ, y)" begin
    m = 3
    nₖ = 300

    y = repeat(vec(1:m), outer=nₖ)

    # Test bounds
    y_tst = copy(y)

    y_tst[1] = 0
    @test_throws BoundsError DA.class_counts!(Vector{Int}(undef, m), y_tst)

    y_tst[1] = m + 1
    @test_throws BoundsError DA.class_counts!(Vector{Int}(undef, m), y_tst)

    # Test computation
    @test DA.class_counts!(Vector{Int}(undef, m), y) == [nₖ for i = 1:m]
end

@testset "_class_centroids!(M, X, y)" begin
    nₖ = [45, 55]
    n = sum(nₖ)
    p = 3

    for T in (Float32, Float64)
        X, y, M = random_data(T, nₖ, p)
        Xt = transpose(copy(transpose(X)))
        Mt = transpose(copy(transpose(M)))
        
        # test predictor dimensionality
        @test_throws DimensionMismatch DA._class_centroids!(zeros(T,2,p+1), X,  y)
        @test_throws DimensionMismatch DA._class_centroids!(zeros(T,2,p-1), X,  y)
        @test_throws DimensionMismatch DA._class_centroids!(zeros(T,2,p+1), Xt, y)
        @test_throws DimensionMismatch DA._class_centroids!(zeros(T,2,p-1), Xt, y)

        # test observation dimensionality
        @test_throws DimensionMismatch DA._class_centroids!(similar(M),  X,  zeros(Int,n+1))
        @test_throws DimensionMismatch DA._class_centroids!(similar(M),  X,  zeros(Int,n-1))
        @test_throws DimensionMismatch DA._class_centroids!(similar(Mt), Xt, zeros(Int,n+1))
        @test_throws DimensionMismatch DA._class_centroids!(similar(Mt), Xt, zeros(Int,n-1))

        # test indexing of class_centroids
        y_test = copy(y)

        y_test[p] = 3
        @test_throws BoundsError DA._class_centroids!(similar(M),  X,  y_test)
        @test_throws BoundsError DA._class_centroids!(similar(Mt), Xt, y_test)

        y_test[p] = 0
        @test_throws BoundsError DA._class_centroids!(similar(M),  X,  y_test)
        @test_throws BoundsError DA._class_centroids!(similar(Mt), Xt, y_test)

        # test observation count
        y_test = copy(y)
        y_test .= 2

        @test_throws ErrorException DA._class_centroids!(similar(M),  X,  y_test)
        @test_throws ErrorException DA._class_centroids!(similar(Mt), Xt, y_test)

        # test mean computation
        M_test = similar(M)
        M_res = DA._class_centroids!(M_test, X, y)
        @test M_res === M_test
        @test isapprox(M, M_test)

        Mt_test = transpose(similar(transpose(M)))
        Mt_res = DA._class_centroids!(Mt_test, Xt, y)
        @test Mt_res === Mt_test
        @test isapprox(Mt, Mt_test)
    end
end

@testset "class_centroids!(M, X, y; dims)" begin
    nₖ = [45, 55]
    n = sum(nₖ)
    p = 3

    for T in (Float32, Float64)
        X, y, M = random_data(T, nₖ, p)
        Xt = copy(transpose(X))
        Mt = copy(transpose(M))

        # Check dims argument
        @test_throws ArgumentError DA.class_centroids!(similar(M), X, y, dims=0)
        @test_throws ArgumentError DA.class_centroids!(similar(M), X, y, dims=3)

        # Test predictor dimensionality
        @test_throws DimensionMismatch DA.class_centroids!(similar(M), X,  zeros(Int,n+1))
        @test_throws DimensionMismatch DA.class_centroids!(similar(M), X,  zeros(Int,n-1))

        @test_throws DimensionMismatch DA.class_centroids!(similar(Mt), Xt, zeros(Int,n+1), dims=2)
        @test_throws DimensionMismatch DA.class_centroids!(similar(Mt), Xt, zeros(Int,n-1), dims=2)

        # test indexing of class_centroids - careful of k argument
        y_test = copy(y)

        y_test[p] = 3
        @test_throws BoundsError DA.class_centroids!(similar(M), X, y_test, dims=1)
        @test_throws BoundsError DA.class_centroids!(similar(Mt), Xt, y_test, dims=2)

        y_test[p] = 0
        @test_throws BoundsError DA.class_centroids!(similar(M), X, y_test, dims=1)
        @test_throws BoundsError DA.class_centroids!(similar(Mt), Xt, y_test, dims=2)

        # test observation count
        y_test = copy(y)
        y_test .= 2

        @test_throws ErrorException DA.class_centroids!(similar(M), X,  y_test, dims=1)
        @test_throws ErrorException DA.class_centroids!(similar(Mt), Xt, y_test, dims=2)

        # test mean computation
        M_test = similar(M)
        M_res = DA.class_centroids!(M_test, X, y, dims=1)
        @test M_res === M_test
        @test isapprox(M_test, M)

        Mt_test = similar(Mt)
        Mt_res = DA.class_centroids!(Mt_test, Xt, y, dims=2)
        @test Mt_res === Mt_test
        @test isapprox(Mt_test, Mt)
    end
end

@testset "_center_classes!(X, M, y)" begin
    nₖ = [45, 55]
    n = sum(nₖ)
    p = 3

    for T in (Float32, Float64)
        X, y, M = random_data(T, nₖ, p)
        Xtt = transpose(copy(transpose(X)))
        Mtt = transpose(copy(transpose(M)))

        # test predictor dimensionality
        @test_throws DimensionMismatch DA._center_classes!(X,  zeros(T,2,p+1), y)
        @test_throws DimensionMismatch DA._center_classes!(X,  zeros(T,2,p-1), y)
        @test_throws DimensionMismatch DA._center_classes!(Xtt, zeros(T,2,p+1), y)
        @test_throws DimensionMismatch DA._center_classes!(Xtt, zeros(T,2,p-1), y)

        # test observation dimensionality
        @test_throws DimensionMismatch DA._center_classes!(X, similar(M), zeros(Int,n+1))
        @test_throws DimensionMismatch DA._center_classes!(X, similar(M), zeros(Int,n-1))
        @test_throws DimensionMismatch DA._center_classes!(Xtt, similar(Mtt), zeros(Int,n+1))
        @test_throws DimensionMismatch DA._center_classes!(Xtt, similar(Mtt), zeros(Int,n-1))

        # test indexing of class_centroids - careful of k argument
        y_test = copy(y)

        y_test[p] = 3
        @test_throws BoundsError DA._center_classes!(copy(X), M, y_test)
        @test_throws BoundsError DA._center_classes!(copy(Xtt), Mtt, y_test)

        y_test[p] = 0
        @test_throws BoundsError DA._center_classes!(copy(X), M, y_test)
        @test_throws BoundsError DA._center_classes!(copy(Xtt), Mtt, y_test)

        # test centering
        X_center = X .- M[y, :]

        X_test = DA._center_classes!(X, M, y)
        @test X === X_test
        @test isapprox(X_center, X)

        Xtt_test = DA._center_classes!(Xtt, Mtt, y)
        @test Xtt === Xtt_test
        @test isapprox(X_center, Xtt)
    end
end

@testset "center_classes!(X, M, y; dims)" begin
    nₖ = [45, 55]
    n = sum(nₖ)
    p = 3

    for T in (Float32, Float64)
        X, y, M = random_data(T, nₖ, p)
        Xt = copy(transpose(X))
        Mt = copy(transpose(M))

        # check dims argument
        @test_throws ArgumentError DA.center_classes!(X, M, y, dims=0)
        @test_throws ArgumentError DA.center_classes!(X, M, y, dims=3)

        # test predictor dimensionality
        @test_throws DimensionMismatch DA.center_classes!(X, zeros(T,2,p+1), y, dims=1)
        @test_throws DimensionMismatch DA.center_classes!(X, zeros(T,2,p-1), y, dims=1)

        @test_throws DimensionMismatch DA.center_classes!(Xt, zeros(T,p+1,2), y, dims=2)
        @test_throws DimensionMismatch DA.center_classes!(Xt, zeros(T,p-1,2), y, dims=2)

        # test observation dimensionality
        @test_throws DimensionMismatch DA.center_classes!(X, M, zeros(Int,n+1), dims=1)
        @test_throws DimensionMismatch DA.center_classes!(X, M, zeros(Int,n-1), dims=1)

        @test_throws DimensionMismatch DA.center_classes!(Xt, Mt, zeros(Int,n+1), dims=2)
        @test_throws DimensionMismatch DA.center_classes!(Xt, Mt, zeros(Int,n-1), dims=2)

        # test indexing of class_centroids - careful of k argument
        y_test = copy(y)

        y_test[p] = 3
        @test_throws BoundsError DA.center_classes!(copy(X),  M, y_test, dims=1)
        @test_throws BoundsError DA.center_classes!(copy(Xt), Mt, y_test, dims=2)

        y_test[p] = 0
        @test_throws BoundsError DA.center_classes!(copy(X), M, y_test, dims=1)
        @test_throws BoundsError DA.center_classes!(copy(Xt), Mt, y_test, dims=2)

        # test centering
        X_center = X .- M[y, :]

        X_test = DA.center_classes!(X, M, y, dims=1)
        @test X === X_test
        @test isapprox(X_center, X)

        Xt_test = DA.center_classes!(Xt, Mt, y, dims=2)
        @test Xt === Xt_test
        @test isapprox(transpose(X_center), Xt)
    end
end


@testset "regularize!(Σ₁, Σ₂, λ)" begin
    for T in (Float32, Float64)
        S = zeros(T, 3, 3)
        @test_throws DimensionMismatch DA.regularize!(zeros(T, 2, 3), S, T(0))
        @test_throws DimensionMismatch DA.regularize!(S, zeros(T, 2, 3), T(0))
        @test_throws DimensionMismatch DA.regularize!(S, zeros(T, 2, 2), T(0))
        
        @test_throws DomainError DA.regularize!(S, S, T(0) - eps(T(0)))
        @test_throws DomainError DA.regularize!(S, S, T(1) + eps(T(1)))
        
        S1 = cov(rand(T, 10, 3))
        S2 = cov(rand(T, 10, 3))
        for λ in (T(0), T(0.25), T(0.5), T(0.75), T(1))
            S1_test = copy(S1)
            S2_test = copy(S2)

            DA.regularize!(S1_test, S2_test, λ)

            @test isapprox(S1_test, (1-λ)S1 + λ*S2)
            @test S2_test == S2
        end
    end
end

@testset "regularize!(Σ, γ)" begin
    n = 10
    p = 3
    for T in (Float32, Float64)
        @test_throws DimensionMismatch DA.regularize!(zeros(T, 2, 3), T(0))
        @test_throws DimensionMismatch DA.regularize!(zeros(T, 3, 2), T(0))
        
        S = zeros(T, p, p)
        @test_throws DomainError DA.regularize!(S, T(0) - eps(T(0)))
        @test_throws DomainError DA.regularize!(S, T(1) + eps(T(1)))

        S = cov(rand(T, n, p))
        for γ in (T(0), T(0.25), T(0.5), T(0.75), T(1))
            S_test = copy(S)

            DA.regularize!(S_test, γ)

            @test isapprox(S_test, (1-γ)S + γ*(tr(S)/p)I)
        end
    end
end

@testset "whiten_data!(X; dims, df)" begin
    n = 10
    p = 3
    for T in (Float32, Float64)
        # test matrix with too few rows
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,p), dims=1)
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,p), dims=2)
        
        # test singular matrix
        @test_throws ErrorException DA.whiten_data!(zeros(T,n,p), dims=1)
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,n), dims=2)
        
        # test whitening 
        X = T[diagm(0 => ones(T, p));
              rand(n-p, p) .- 0.5]
        X .= X .- mean(X, dims=1)  # Data must be centered
        Xt = copy(transpose(X))

        ### rows
        X_test = copy(X)
        W, detΣ = DA.whiten_data!(X_test, dims=1)
        @test isapprox(cov(X*W, dims=1), diagm(0 => ones(T, p)))
        @test isapprox(det(cov(X, dims=1)), detΣ)

        ### cols
        Xt_test = copy(Xt)
        W, detΣ = DA.whiten_data!(Xt_test, dims=2)
        @test isapprox(cov(W*Xt, dims=2), diagm(0 => ones(T, p)))
        @test isapprox(det(cov(Xt, dims=2)), detΣ)
    end
end

@testset "whiten_data!(X, γ; dims, df)" begin
    n = 10
    p = 3
    for T in (Float32, Float64)
        # test limits for γ
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,p), T(0) - eps(T(0)), dims=1)
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,p), T(1) - eps(T(1)), dims=1)

        # test matrix with too few rows
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,p), T(0), dims=1)
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,p), T(0), dims=2)
        
        # test singular matrix
        @test_throws ErrorException DA.whiten_data!(zeros(T,n,p), T(0), dims=1)
        @test_throws ErrorException DA.whiten_data!(zeros(T,p,n), T(0), dims=2)
        
        # test whitening 
        Iₚ = diagm(0 => ones(T, p))

        X = T[Iₚ; rand(n-p, p) .- 0.5]
        X .= X .- mean(X, dims=1)  # Data must be centered
        Xt = copy(transpose(X))

        S = X'X
        Σ = S/(n-1)

        for γ in range(zero(T), step=convert(T, 0.25), stop=one(T))
            S_γ = (one(T) - γ)*S + γ*(tr(S)/p)*I
            Σ_γ = (one(T) - γ)*Σ + γ*(tr(Σ)/p)*I

            ### rows
            W_test, detΣ_test = DA.whiten_data!(copy(X), γ, dims=1)

            @test isapprox(det(Σ_γ), detΣ_test)
            @test isapprox(transpose(W_test)*Σ_γ*W_test, Iₚ)
            if γ == zero(T)
                @test isapprox(cov(X*W_test, dims=1), Iₚ)
            end

            W_test, detS_test = DA.whiten_data!(copy(X), γ, dims=1, df=1)
            @test isapprox(det(S_γ), detS_test)
            @test isapprox(transpose(W_test)*S_γ*W_test, Iₚ)

            ### cols
            W_test, detΣ_test = DA.whiten_data!(copy(Xt), γ, dims=2)

            @test isapprox(det(Σ_γ), detΣ_test)
            @test isapprox(W_test*Σ_γ*transpose(W_test), Iₚ)
            if γ == zero(T)
                @test isapprox(cov(W_test*Xt, dims=2), Iₚ)
            end

            W_test, detS_test = DA.whiten_data!(copy(Xt), γ, dims=2, df=1)
            @test isapprox(det(S_γ), detS_test)
            @test isapprox(W_test*S_γ*transpose(W_test), Iₚ)
        end
    end
end