using JuMP
using GLPK
using GLPKMathProgInterface

struct SFCNode
	Cores::Int64
	Func::Int64
end


struct SFCRequest
	Nodes::Array{SFCNode}
	Links::Array{Tuple{Int64,Int64}}
end

# Parameters
## SFC Requests

SFCs = [
	SFCRequest([SFCNode(1, 1), SFCNode(2, 2)]
		   , [(1, 2)])
       ]

# T Service Function Chain (SFC) requests known in advance
T = size(SFCs)[1]

# We assume that F types of VNFs can be provisioned as
# firewall, IDS, proxy, load balancers, and so on.
F = 5

# Physical Network cores
N_core = [1, 2, 3, 4, 5]

# W Number of physical nodes
W = size(N_core)[1]

# VNFs
V = sum(size(r.Nodes)[1] for r in SFCs)
println(V)

m = Model(solver=GLPKSolverMIP())

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

# establishes the fact that at most a number
# of Vcores equal to the available ones are used for each server node w
@constraint(m, [w=1:W], sum(y[k,w] for k=1:F) <= N_core[w])

# expresses the condition that a VNF can
# be served by one only VNF instance
@constraint(m, [v=1:V], sum(sum(z[v,w,k] for w=1:W) for k=1:F) <= 1)

# To guarantee that a node v needing the application
# of a VNF type is mapped to a correct VNF instance
# we introduce this constraint
@constraint(m, [v=1:V,k=1:F,w=1:W], z[v,w,k] <= beta(v,k))

@objective(m, Max, sum(x[h] for h=1:T))

print(m)

status = @time solve(m)

println("Objective value: ", getobjectivevalue(m))
println("x = ", getvalue(x))
