# Explicitly append library paths to handle modular code structure cleanly
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

module VolumetricTrackerTest

using LinearAlgebra
using Printf
using Random

# Import code assets directly from the primary simulation engine
import KineticCollapse: StandardContext, compute_jacobian, compute_volume_determinant

"""
    generate_stressed_context(N::Int, λ::Float64)

Generates a continuous coordinate context vector where operational tension is scaled by λ.
As λ increases, target distinctiveness components and military demand components scale 
along mutually exclusive vector paths, forcing a structural coordinate divergence.
"""
function generate_stressed_context(N::Int, λ::Float64)
    # Baseline neutral background noise mapping
    v_base = zeros(Float64, N)
    
    # Define vector directions for conflicting operational parameters
    # Path A: Principle of Distinction variables (Target Classification Metrics)
    # Path B: Military Necessity variables (Kinetic Requirement Metrics)
    half = div(N, 2)
    
    for i in 1:half
        v_base[i] = λ * 2.5       # Push upper coordinate subspace components outward
        v_base[i + half] = -λ * 2.5 # Pull lower coordinate subspace components downward
    end
    
    return StandardContext{N}(v_base)
end

"""
    execute_volumetric_sweep(N::Int, steps::Int)

Sweeps across increasing operational tension coefficients to trace the structural
degradation timeline of the differential volume form.
"""
function execute_volumetric_sweep(N::Int, steps::Int)
    @printf("========================================================================\n")
    @printf("EXECUTING ARTIFACT 2.1: VOLUMETRIC TRACKER PROBE\n")
    @printf("Target Manifold Dimension: %d | Simulation Steps: %d\n", N, steps)
    @printf("========================================================================\n")
    @printf("%-10s | %-15s | %-15s | %-15s\n", "Stress (λ)", "Volume det(J)", "σ_min", "Status")
    @printf("------------------------------------------------------------------------\n")
    
    # Step across a standardized operational load profile
    for step in 0:(steps - 1)
        λ = (step / (steps - 1)) * 4.0
        
        # Construct the context under localized stress conditions
        context = generate_stressed_context(N, λ)
        
        # Calculate derivative mapping matrices
        J = compute_jacobian(context)
        
        # Trace structural singular states and spatial volumes
        volume, min_s = compute_volume_determinant(J)
        
        status_str = "STABLE"
        if volume < 1e-15 || min_s < 1e-15
            status_str = "COLLAPSED"
        elseif volume < 1e-8
            status_str = "FRAGILE"
        end
        
        @printf("%-10.4f | %-15e | %-15e | %-15s\n", λ, volume, min_s, status_str)
    end
    @printf("========================================================================\n")
end

end # module VolumetricTrackerTest

if abspath(PROGRAM_FILE) == @__FILE__
    # Run the tracking probe on the standard 80-dimensional Riemannian setup
    const MANIFOLD_DIM = 80
    const RUN_STEPS = 10
    
    VolumetricTrackerTest.execute_volumetric_sweep(MANIFOLD_DIM, RUN_STEPS)
end
