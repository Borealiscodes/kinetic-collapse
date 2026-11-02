module KineticCollapse

using LinearAlgebra

export StandardContext, compute_softmax, compute_jacobian, verify_kernel, compute_volume_determinant

"""
    StandardContext

A structurally bound container representing an N-dimensional continuous 
Riemannian latent state vector.
"""
struct StandardContext{N}
    v::Vector{Float64}
    
    function StandardContext{N}(v::Vector{Float64}) where N
        if length(v) != N
            throw(DimensionMismatch("Context vector length must exactly match the manifold dimension N = $N"))
        end
        new{N}(v)
    end
end

"""
    compute_softmax(context::StandardContext{N}) where N

Maps the continuous coordinate vector onto a bounded probability simplex Δ^(N-1).
Evaluates component-wise exponential transformations and handles potential numerical scaling.
"""
function compute_softmax(context::StandardContext{N}) where N
    v = context.v
    max_v = maximum(v) # Defensive stabilization against overflow
    exp_v = exp.(v .- max_v)
    sum_exp = sum(exp_v)
    return exp_v ./ sum_exp
end

"""
    compute_jacobian(context::StandardContext{N}) where N

Computes the exact N x N Jacobian matrix J of the soft-argmax operator.
Applies J_ij = σ(v_i)δ_ij - σ(v_i)σ(v_j) without approximation.
"""
function compute_jacobian(context::StandardContext{N}) where N
    σ = compute_softmax(context)
    J = Matrix{Float64}(undef, N, N)
    
    for j in 1:N
        for i in 1:N
            δ_ij = (i == j) ? 1.0 : 0.0
            J[i, j] = σ[i] * δ_ij - σ[i] * σ[j]
        end
    end
    return J
end

"""
    verify_kernel(J::Matrix{Float64})

Evaluates the action of the Jacobian matrix on the all-ones vector 1.
Returns the structural residual norm. Theorem 1 dictates this must approach 0.
"""
function verify_kernel(J::Matrix{Float64})
    N = size(J, 1)
    ones_vector = ones(Float64, N)
    kernel_projection = J * ones_vector
    residual_norm = norm(kernel_projection)
    return residual_norm, kernel_projection
end

"""
    compute_volume_determinant(J::Matrix{Float64})

Computes the determinant of the Jacobian matrix via Singular Value Decomposition (SVD).
The product of singular values determines the absolute transformation factor of the volume form.
"""
function compute_volume_determinant(J::Matrix{Float64})
    # SVD is utilized to prevent structural numerical instability near singularity boundaries
    s = svdvals(J)
    
    # Calculate log-determinant to safely handle absolute underflow before exponentiation
    log_det = sum(log.(s))
    det_val = exp(log_det)
    
    # Check minimum singular value to verify strict rank deficiency
    min_singular_value = minimum(s)
    
    return det_val, min_singular_value
end

end # module KineticCollapse

# Comprehensive self-contained runtime verification block
if abspath(PROGRAM_FILE) == @__FILE__
    using .KineticCollapse
    using Random
    using Printf

    # Strict adherence to the 80-Dimensional context space definition
    const MANIFOLD_DIMENSION = 80
    Random.seed!(20261102) # Temporal anchor alignment

    @printf("========================================================================\n")
    @printf("INITIALIZING ARTIFACT 1.1 RUNTIME VERIFICATION SUITE\n")
    @printf("Manifold Dimension (N): %d\n", MANIFOLD_DIMENSION)
    @printf("========================================================================\n\n")

    # Generate a random dense coordinate vector within the continuous manifold
    raw_coordinates = randn(MANIFOLD_DIMENSION) .* 5.0
    context_manifold = StandardContext{MANIFOLD_DIMENSION}(raw_coordinates)

    @printf("[STEP 1] Projecting continuous context space onto probability simplex...\n")
    probabilities = compute_softmax(context_manifold)
    @printf("-> Max probability component: %6.4f\n", maximum(probabilities))
    @printf("-> Min probability component: %6.4f\n", minimum(probabilities))
    @printf("-> Normalization check (∑σ):   %6.4f\n\n", sum(probabilities))

    @printf("[STEP 2] Computing full derivative maps (Jacobian Tensor Field)...\n")
    J = compute_jacobian(context_manifold)
    @printf("-> Jacobian dimension: %d x %d\n\n", size(J, 1), size(J, 2))

    @printf("[STEP 3] Evaluating Theorem 1: Kernel Projection Analysis (1 ∈ ker(J))...\n")
    residual_norm, raw_projection = verify_kernel(J)
    @printf("-> Residual L2 Norm of J·1:  %e\n", residual_norm)
    if residual_norm < 1e-12
        @printf("-> VERIFICATION: SUCCESS. The all-ones vector resides cleanly in the kernel.\n\n")
    else
        @printf("-> VERIFICATION: FAILED. Significant divergence detected.\n\n")
    end

    @printf("[STEP 4] Evaluating Wedge Product Proof: Volumetric Disintegration...\n")
    volume_factor, min_s_val = compute_volume_determinant(J)
    @printf("-> Minimum Singular Value (σ_min): %e\n", min_s_val)
    @printf("-> Computed Volume Factor (det(J)): %e\n", volume_factor)
    
    if min_s_val < 1e-12 || volume_factor < 1e-12
        @printf("-> VERIFICATION: SUCCESS. The volume form vanishes absolutely (ω_σ = 0).\n")
    else
        @printf("-> VERIFICATION: FAILED. Volumetric retention detected.\n")
    end
    @printf("========================================================================\n")
end
