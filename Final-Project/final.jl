using JuMP
using GLPK
using GLPKMathProgInterface

struct Node
	Cores::Int64
	Func::Int64
end

struct Link
	Source::Int64
	Destination::Int64
	Wight::Int64
end

struct SFCRequest
	Nodes::Array{Node}
	Links::Array{Link}
end

struct Path
	Links::Array{Tuple{Int64,Int64}}
	Source::Int64
	Destination::Int64
end

# Parameters
## SFC Requests

SFCs = [
	SFCRequest([Node(1, 1), Node(1, 2)],
		   [Link(1, 2, 1)]),
	SFCRequest([Node(1, 3), Node(1, 5)],
		   [Link(1, 2, 1)])
       ]

# T Service Function Chain (SFC) requests known in advance
T = size(SFCs)[1]

# We assume that F types of VNFs can be provisioned as
# firewall, IDS, proxy, load balancers, and so on.
t_proc = [1, 1, 1, 1, 1]
F = size(t_proc)[1]

# Physical Network cores
PN_nodes = [Node(2, 0), Node(2, 0)]

# W Number of physical nodes
W = size(PN_nodes)[1]

# VNFs
V = sum(size(r.Nodes)[1] for r in SFCs)

# Paths
Paths = [Path([
	       (1, 2),
	      ], 1, 2),
	 Path([], 1, 1),
	 Path([], 2, 2)
	 ]
P = size(Paths)[1]

# Links
E = [Link(1, 2, 10)]

# Virtual links
D = sum(size(r.Links)[1] for r in SFCs)

# Mathmatical model
m = Model(solver=GLPKSolverMIP())

# assuming the value 1 if the VNF v needs the
# application of the VNF k; otherwise its value is 0
function beta(v::Int64, k::Int64)
	vs = 0
	for r in SFCs
		if vs + size(r.Nodes)[1] >= v
			if r.Nodes[v - vs].Func == k
				return true
			else
				return false
			end
		end
		vs += size(r.Nodes)[1]
	end
end

# the processing capacity requested by the
# VNF node v
function B(v::Int64)
	vs = 0
	for r in SFCs
		if vs + size(r.Nodes)[1] >= v
			return r.Nodes[v - vs].Cores
		end
		vs += size(r.Nodes)[1]
	end
end

# the binary function assuming value 1 or 0 if the
# network link 𝑑 belongs or does not to the path 𝑝
# respectively
function delta(d::Link, p::Path)
	for l in p.Links
		if l[1] == d.Source && l[2] == d.Destination
			return true
		end
	end
	return false
end

function node_range(h::Int64)
	start = 0
	if h > 1
		start = sum(size(SFCs[i].Nodes)[1] for i=1:h-1)
	end
	finish = start + size(SFCs[h].Nodes)[1]

	return start + 1 : finish
end

function link_range(h::Int64)
	start = 0
	if h > 1
		start = sum(size(SFCs[i].Links)[1] for i=1:h-1)
	end
	finish = start + size(SFCs[h].Links)[1]

	return start + 1 : finish
end

function vlink_source(d::Int64)
	ds = 0
	vs = 0
	for r in SFCs
		if ds + size(r.Links)[1] >= d
			return r.Links[d - ds].Source + vs
		end
		ds += size(r.Links)[1]
		vs += size(r.Nodes)[1]
	end
end

function vlink_destination(d::Int64)
	ds = 0
	vs = 0
	for r in SFCs
		if ds + size(r.Links)[1] >= d
			return r.Links[d - ds].Destination + vs
		end
		ds += size(r.Links)[1]
		vs += size(r.Nodes)[1]
	end
end

function index_to_link(d::Int64)
	ds = 0
	for r in SFCs
		if ds + size(r.Links)[1] >= d
			return r.Links[d - ds]
		end
		ds += size(r.Links)[1]
	end
end


# x_h: binary variable assuming the value 1 if the hth SFC
# request is accepted; otherwise its value is zero
@variable(m, x[1:T] >= 0, Bin)

# y_kw: integer variable characterizing the number of
# Vcores allocated to the VNF instance of type k in the
# server w
@variable(m, y[1:F,1:W] >= 0, Int)

# z_vw^k: binary variable assuming the value 1 if the VNF
# node v is served by the VNF instance of type k in the server w
@variable(m, z[1:V,1:W,1:F] >= 0, Bin)

# u_dp: binary variable assuming the value 1 if the virtual
# link e is embedded in the physical
# network path p; otherwise its value is zero.
@variable(m, u[1:D,1:P] >= 0, Bin)

# establishes the fact that at most a number
# of Vcores equal to the available ones are used for each server node w
@constraint(m, [w=1:W], sum(y[k,w] for k=1:F) <= PN_nodes[w].Cores)

# expresses the condition that a VNF can
# be served by one only VNF instance
@constraint(m, [v=1:V], sum(sum(z[v,w,k] for w=1:W) for k=1:F) <= 1)

# To guarantee that a node v needing the application
# of a VNF type is mapped to a correct VNF instance
# we introduce this constraint
@constraint(m, [v=1:V,k=1:F,w=1:W], z[v,w,k] <= beta(v,k))

# limits the number of VNF nodes assigned to one VNF instance
# by taking into account both the number of Vcores assigned to the VNF
# instance and the required VNF node processing capacities
@constraint(m, [k=1:F,w=1:W], sum(z[v,w,k] * B(v) * t_proc[k] for v=1:V) <= y[k,w])

# establish the fact that an SFC request can be accepted when the nodes
# of the SFC graph are assigned to VNF instances
@constraint(m, [h=1:T, v=node_range(h)], x[h] <= sum(sum(z[v,w,k] for w=1:W) for k=1:F))

# establish the fact that when the virtual link d is supported by the physical network path p then
# p.source and p.destination must be the physical network nodes that the nodes d.source
# d.destination of the virtual graph are assigned to.

@constraint(m, [k=1:F,d=1:D,p=1:P], u[d, p] <= z[vlink_source(d), Paths[p].Source, k])
@constraint(m, [k=1:F,d=1:D,p=1:P], u[d, p] <= z[vlink_destination(d), Paths[p].Destination, k])

# the choice of mapping of any virtual link on
# a single physical network path is represented by
# following constraint
@constraint(m, [d=1:D], sum(u[d,p] for p=1:P) <= 1)

# avoids any overloading on any physical network link
@constraint(m, [e in E], sum(index_to_link(d).Wight * sum(delta(e, Paths[p]) * u[d, p] for p=1:P) for d=1:D) <= e.Wight)

# establish the fact that an SFC request can be accepted when the links
# of the SFC graph are assigned to physical network paths
@constraint(m, [h=1:T, d=link_range(h)], x[h] <= sum(u[d,p] for p=1:P))

@objective(m, Max, sum(x[h] for h=1:T))

println(m)

status = @time solve(m)

println()

println("Objective value: ", getobjectivevalue(m))

X = getvalue(x)
Y = getvalue(y)
Z = getvalue(z)
U = getvalue(u)

println()

for h = 1:T
	println("Request ", h, " is ", X[h] == 1 ? "accepted" : "rejected")
end

println()

for w = 1:W, k = 1:F
	println("Type ", k, " has ", Y[k,w], " cores on ", w)
end

println()

for w = 1:W, k = 1:F, v = 1:V
	if Z[v,w,k] == 1
		println("Node ", v, " placed on ", w, " with type ", k)
	end
end
println("u = ", U)
