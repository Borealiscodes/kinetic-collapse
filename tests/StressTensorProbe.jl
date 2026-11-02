# Explicitly append library paths to handle modular code structure cleanly
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

module StressTensorProbeTest

using LinearAlgebra
using Printf
using Random

# Import code assets directly from the primary simulation engine
import KineticCollapse: StandardContext, compute_softmax

"""
    inject_directional_stress(N::Int, target_idx::Int, α::Float64)

Constructs an 80-dimensional context vector where a specific target coordinate is forced 
by a scaling stress coefficient α. The surrounding coordinate paths are held constant 
to establish a controlled directional axis.
"""
function inject_directional_stress(N::Int, target_idx::Int, α::Float64)
    # Background baseline context vectors initialized with uniform random entries
    v_raw = randn(N) .* 0.1
    
    # Inject directional stress tensor magnitude along the target channel index
    v_raw[target_idx] = α
    
    return StandardContext{N}(v_raw)
end

"""
    execute_snapping_probe(N::Int, target_idx::Int, points::Int)

Tracks the displacement velocity profile of the probability vector output as directional 
stress forces the context vector outward along a specific axis.
"""
function execute_snapping_probe(N::Int, target_idx::Int, points::Int)
    @printf("========================================================================\n")
    @printf("EXECUTING ARTIFACT 2.2: DIRECTIONAL STRESS TENSOR PROBE\n")
    @printf("Manifold Dimension: %d | Target Channel Index: %d\n", N, target_idx)
    @printf("========================================================================\n")
    @printf("%-10s | %-18s | %-18s | %-12s\n", "Stress (α)", "Target Component", "L2 Dist to e_k", "Velocity (Δ)")
    @printf("------------------------------------------------------------------------\n")
    
    prev_dist = 0.0
    
    for p in 0:(points - 1)
        # Exponential growth curve for stress injection to trace asymptotic mechanics
        α = p == 0 ? 0.0 : 2.0^p
        
        # Generate the stressed latent manifold configuration
        context = inject_directional_stress(N, target_idx, α)
        
        # Project through the soft-argmax map
        σ = compute_softmax(context)
        
        # Calculate distance to pure basis vertex e_k
        e_k = zeros(Float64, N)
        e_k[target_idx] = 1.0
        current_dist = norm(σ - e_k)
        
        # Calculate displacement metric delta tracking kinematic acceleration
        velocity_delta = (p == 0) ? 0.0 : abs(current_dist - prev_dist)
        
        @printf("%-10.2f | %-18.10f | %-18.10e | %-12.4e\n", α, σ[target_idx], current_dist, velocity_delta)
        
        prev_dist = current_dist
    end
    @printf("========================================================================\n")
end

end # module StressTensorProbeTest

if abspath(PROGRAM_FILE) == @__FILE__
    # Execute snapping acceleration validation over standard 80-dimensional substrate
    const MANIFOLD_DIM = 80
    const TARGET_INDEX = 42 # Arbitrary target index channel selection
    const TEST_POINTS = 8
    
    # Initialize global seed for deterministic tracking
    Random.seed!(20261102)
    
    StressTensorProbeTest.execute_snapping_probe(MANIFOLD_DIM, TARGET_INDEX, TEST_POINTS)
end
