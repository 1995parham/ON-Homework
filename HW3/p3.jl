using JuMP
using GLPK
using GLPKMathProgInterface

# Parameters
# Channels
# use 5 instead of 12 chennel
C = 5

# Vertices
# use 5 instead of 11 vertices
V = 5

# Radio
R = [2 1 3 3 2 4 4 4 3 2 1]

# Edges
E = [
     (1,2)
     (1,3)
     (2,1)
     (2,4)
     (2,5)
     (3,1)
     (3,4)
#     (3,7)
     (4,2)
     (4,3)
     (4,5)
#     (4,6)
     (5,2)
     (5,4)
#     (5,6)
#     (5,10)
#     (6,4)
#     (6,5)
#     (6,8)
#     (6,10)
#     (7,3)
#     (7,8)
#     (7,9)
#     (8,6)
#     (8,7)
#     (8,10)
#     (8,9)
#     (8,11)
#     (9,7)
#     (9,8)
#     (9,11)
#     (10,5)
#     (10,6)
#     (10,8)
#     (11,8)
#     (11,9)
    ]

# Interferences
I = Dict{Tuple{Int64,Int64},Array{Tuple{Int64,Int64}}}()
for e1 in E
	I[e1[1], e1[2]] = Array{Tuple{Int64,Int64}}(0)
	for e2 in E
		if e1[1] == e2[1] && e1[2] != e2[2]
			push!(I[e1[1],e1[2]], e2)
		end
		if e1[1] != e2[1] && e1[2] == e2[2]
			push!(I[e1[1],e1[2]], e2)
		end
		if e1[1] != e2[2] && e1[2] == e2[1]
			push!(I[e1[1],e1[2]], e2)
		end
		if e1[1] == e2[2] && e1[2] != e2[1]
			push!(I[e1[1],e1[2]], e2)
		end
		if e1[1] == e2[2] && e1[2] == e2[1]
			push!(I[e1[1],e1[2]], e2)
		end
	end
end

m = Model(solver=GLPKSolverMIP())

@variable(m, x[1:C,1:V,1:V] >= 0, Bin)
@variable(m, y[1:C,1:V] >= 0, Bin)
@variable(m, z[1:V,1:V,1:V,1:V] >= 0, Bin)

@constraint(m, [e in E], sum(x[c,e[1],e[2]] for c=1:C) == 1)
@constraint(m, [e in E, c=1:C], x[c,e[1],e[2]] <= y[c,e[1]])
@constraint(m, [e in E, c=1:C], x[c,e[1],e[2]] <= y[c,e[2]])
@constraint(m, [v=1:V], sum(y[c,v] for c=1:C) <= R[v])
@constraint(m, [e in E, c=1:C, i in I[e]], x[c,e[1],e[2]] + x[c,i[1],i[2]] - 1 <= z[e[1],e[2],i[1],i[2]])

@objective(m, Min, sum(sum(z[e[1],e[2],i[1],i[2]] for i in I[e]) for e in E))

print(m)

status = @time solve(m)

println("Objective value: ", getobjectivevalue(m))
println("x = ", getvalue(x))
