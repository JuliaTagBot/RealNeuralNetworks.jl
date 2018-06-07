using Base.Test
using RealNeuralNetworks.Utils.FakeSegmentations 
using RealNeuralNetworks.Neurons
using RealNeuralNetworks.NodeNets
using RealNeuralNetworks.SWCs
using CSV

const NEURON_ID = 77625
const ASSERT_DIR = joinpath(@__DIR__, "../assert")
const SWC_BIN_PATH = joinpath(ASSERT_DIR, "$(NEURON_ID).swc.bin") 
const ARBOR_DENSITY_MAP_VOXEL_SIZE = (2000,2000,2000)

@testset "test synapse attaching functions" begin
    println("load swc of a real neuron...")
    @time swc = SWCs.load_swc_bin( SWC_BIN_PATH )
    neuron = Neuron( swc )

    println("downsample node number...")
    Neurons.downsample_nodes(neuron)

    println("attaching presynapses...")
    preSynapses = CSV.read( joinpath(ASSERT_DIR, "$(NEURON_ID).pre.synapses.csv") )
    Neurons.attach_pre_synapses!(neuron, preSynapses)
    
    println("attaching postsynapses...")
    postSynapses = CSV.read( joinpath(ASSERT_DIR, "$(NEURON_ID).post.synapses.csv") ) 
    Neurons.attach_post_synapses!(neuron, postSynapses)

    preSynapseToSomaPathLengthList  = Neurons.get_pre_synapse_to_soma_path_length_list( neuron )
    postSynapseToSomaPathLengthList = Neurons.get_post_synapse_to_soma_path_length_list( neuron )
    @test !isempty(preSynapseToSomaPathLengthList)
    @test !isempty(postSynapseToSomaPathLengthList)
end 

@testset "test Neuron IO and resampling " begin 
    println("load swc of a real neuron...")
    @time swc = SWCs.load_swc_bin( SWC_BIN_PATH )
    neuron = Neuron( swc )

    println("downsample node number...")
    Neurons.downsample_nodes(neuron)

    println("compute arbor density map...")
    @time arborDensityMap = Neurons.get_arbor_density_map(neuron, 
                                                ARBOR_DENSITY_MAP_VOXEL_SIZE, 8.0)
    #@test norm(arborDensityMap[:]) ≈ Neurons.get_total_path_length(neuron)
    #@test norm(arborDensityMap[:]) ≈ 1.0
    neuron1 = neuron
    densityMap1 = Neurons.translate_soma_to_coordinate_origin(neuron1, arborDensityMap, 
                                                             ARBOR_DENSITY_MAP_VOXEL_SIZE)
    @show indices(densityMap1)
    println("compute arbor density map distance...")
    @time d = Neurons.get_arbor_density_map_distance(densityMap1, densityMap1)
    @test d == 0.0

    fileName = joinpath(dirname(SWC_BIN_PATH), "$(NEURON_ID).swc.bin")
    neuron2 = Neuron( SWCs.load_swc_bin(fileName) )
    densityMap2 = Neurons.get_arbor_density_map(neuron, ARBOR_DENSITY_MAP_VOXEL_SIZE, 8.0)
    #@test norm(densityMap2[:]) ≈ 1.0                                               
    densityMap2 = Neurons.translate_soma_to_coordinate_origin(neuron2, densityMap2, 
                                                              ARBOR_DENSITY_MAP_VOXEL_SIZE)
    @show indices(densityMap2) 
    println("compute arbor density map distance...")                          
    @time d = Neurons.get_arbor_density_map_distance(densityMap1, densityMap2)
    println("arbor density map distance: $d")
    #@test d > 0.0 && d < 2.0

    Neurons.save(neuron, "/tmp/neuron.swc")
    neuron3 = Neurons.resample(neuron, Float32(40))
    #Neurons.save_swc(neuron2, "/tmp/neuron2.swc")
    rm("/tmp/neuron.swc")
    #rm("/tmp/neuron2.swc")
end 

@testset "test Neurons" begin
    println("load swc of a real neuron...")
    @time swc = SWCs.load_swc_bin( SWC_BIN_PATH )

    neuron = Neuron( swc )
    #neuron = Neurons.resample(neuron, Float32(40))
    println("get node list ...")
    @time nodeList = Neurons.get_node_list(neuron)
    println("get edge list ...")
    @time edgeList = Neurons.get_edge_list(neuron)
    println("get segment order list...")
    @time segmentOrderList = Neurons.get_segment_order_list( neuron )

    println("clean up the neuron ...")
    neuron = Neurons.remove_subtree_in_soma(neuron)
    neuron = Neurons.remove_hair(neuron)
    neuron = Neurons.remove_subtree_in_soma(neuron)
    neuron = Neurons.remove_terminal_blobs(neuron)
    neuron = Neurons.remove_redundent_nodes(neuron)

    #println("get fractal dimension ...")
    #@time fractalDimension, _,_ = Neurons.get_fractal_dimension( neuron )
    #@show fractalDimension 

    println("get surface area which is frustum based")
    @test Neurons.get_surface_area(neuron) > 0
    
    println("get frustum based volume")
    @test Neurons.get_volume(neuron) > 0

    println("get typical radius ...")
    @test Neurons.get_typical_radius( neuron ) > 0

    println("get asymmetry ...")
    @test Neurons.get_asymmetry( neuron ) > 0
 
    println("get mass center ...")
    @show Neurons.get_mass_center( neuron )

    println("get branching angle ...")
    @test Neurons.get_branching_angle( neuron, 5 ) > 0

    println("get path to root length ...")
    @test Neurons.get_path_to_soma_length( neuron, 5; nodeIndex=4 ) > 0

    println("sholl analysis ...")
    @time shollNumList = Neurons.get_sholl_number_list(neuron, 10000 )
    @test !isempty(shollNumList)

    println("get segment path length list ...")
    @time segmentPathLengthList = Neurons.get_segment_path_length_list( neuron )
    @show length( segmentPathLengthList )
    @test length( segmentPathLengthList ) == Neurons.get_num_segments(neuron)

    println("get terminal segment index list...")
    @time terminalSegmentIndexList = Neurons.get_terminal_segment_index_list( neuron )
    @test !isempty( terminalSegmentIndexList )
    println("get terminal node list ...")
    @time terminalNodeList = Neurons.get_terminal_node_list( neuron )
    @test !isempty( terminalNodeList )

    println("test split a tree...")
    @time tree1, tree2 = split(neuron, 4; nodeIndexInSegment = 5)
    @test !isempty(tree1)
    @test !isempty(tree2)
end 

@testset "test fake segmentation skeletonization" begin 
    println("create fake cylinder segmentation...")
    @time seg = FakeSegmentations.broken_cylinder()
    println("skeletonization to build a Neuron ...")
    @time neuron = Neuron(seg)
    @test !isempty(Neurons.get_node_list(neuron))
    
    println("create fake ring segmentation ...")
    seg = FakeSegmentations.broken_ring()
    neuron = Neuron(seg)
    @test !isempty(Neurons.get_node_list(neuron))
    
    println("transform to SWC structure ...")
    @time swc = SWCs.SWC( neuron )
    tempFile = tempname() * ".swc"
    SWCs.save(swc, tempFile)
    rm(tempFile)
end 


