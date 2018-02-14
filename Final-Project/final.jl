using JuMP
using GLPK
using GLPKMathProgInterface

# Parameters
# T Service Function Chain (SFC) requests known in advance
T = 10

# We assume that F types of VNFs can be provisioned as
# firewall, IDS, proxy, load balancers, and so on.
F = 5

# W Number of physical nodes
W = 5

m = Model(solver=GLPKSolverMIP())

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
