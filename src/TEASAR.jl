__precompile__();
module TEASAR
include("Points.jl")
include("BWDists.jl")
include("Skeleton.jl")
using .Points
using .BWDists
using .Skeleton

export skeletonize

end # end of module
