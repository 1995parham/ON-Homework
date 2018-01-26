using JuMP
using GLPK
using GLPKMathProgInterface

# Parameters
# Demands
# destination source delay
D = [
     1 2 5;
     1 3 5;
     1 4 10;
     2 4 10;
     2 8 6;
    ]
Ds = size(D)[1]

# Vertices
V = 8
# Edges wight
# 100 is Inf wight in this problem
W = fill(1, V, V)
W[1, 1] = 100
W[2, 2] = 100
W[3, 3] = 100
W[4, 4] = 100
W[5, 5] = 100
W[6, 6] = 100
W[7, 7] = 100
W[8, 8] = 100

# K8

# Edges delay
Z = fill(5, V, V)

# lambda
lambda = fill(0.25, 8)

m = Model(solver=GLPKSolverMIP())

@variable(m, x[1:Ds,1:V,1:V] >= 0, Bin)
for i = 1:Ds
	for u = 1:V
		if u == D[i,1]
			@constraint(m, sum(x[i,u,v] for v=1:V) - sum(x[i,v,u] for v=1:V) == 1)
		elseif u == D[i,2]
			@constraint(m, sum(x[i,u,v] for v=1:V) - sum(x[i,v,u] for v=1:V) == -1)
		else
			@constraint(m, sum(x[i,u,v] for v=1:V) - sum(x[i,v,u] for v=1:V) == 0)
		end
	end
end
@objective(m, Min, sum(x[i,u,v]W[u,v] for i=1:Ds,u=1:V,v=1:V) + sum(lambda[i] * (sum(x[i,u,v]Z[u,v] for u=1:V,v=1:V) - D[i,3]) for i=1:Ds))

print(m)

status = @time solve(m)

println("Objective value: ", getobjectivevalue(m))
println("x = ", getvalue(x))
