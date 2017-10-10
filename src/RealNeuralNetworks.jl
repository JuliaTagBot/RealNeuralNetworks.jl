__precompile__();
module RealNeuralNetworks

include("FakeSegmentations.jl")
include("NodeNets.jl"); 
include("SWCs.jl");  
include("Manifests.jl"); 
include("BranchNets.jl")

using .SWCs
using .NodeNets 
using .Manifests
using .BranchNets

end # end of module
