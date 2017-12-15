a = 1;
c = [
    0 0 20 10 0 0 0;
    0 0 20 0 0 5 0;
    20 20 0 15 0 0 0;
    10 0 15 0 a*10 0 5;
    0 0 0 10 0 30 25;
    0 5 0 0 30 0 0;
    0 0 0 5 25 0 0;
    ];

cvx_begin
    variable x(3) nonnegative
    variable f(3,7,7) nonnegative
    dual variables y{7,7}
    maximize(sum(log(x)))
    subject to
        for u = 1:7
            for v = 1:7
                f(1,u,v) + f(2,u,v) + f(3,u,v) <= c(u,v) : y{u,v}
            end
        end
        for u = 1:7
            if u == 1
                sum(f(1,u,:)) - sum(f(1,:,u)) == x(1)
            elseif u == 5
                sum(f(1,u,:)) - sum(f(1,:,u)) == -x(1)
            else
                sum(f(1,u,:)) - sum(f(1,:,u)) == 0
            end
        end
        for u = 1:7
            if u == 2
                sum(f(2,u,:)) - sum(f(2,:,u)) == x(2)
            elseif u == 6
                sum(f(2,u,:)) - sum(f(2,:,u)) == -x(2)
            else
                sum(f(2,u,:)) - sum(f(2,:,u)) == 0
            end
        end
        for u = 1:7
            if u == 4
                sum(f(3,u,:)) - sum(f(3,:,u)) == x(3)
            elseif u == 6
                sum(f(3,u,:)) - sum(f(3,:,u)) == -x(3)
            else
                sum(f(3,u,:)) - sum(f(3,:,u)) == 0
            end
        end
cvx_end


con = zeros(7,7);
for u = 1:7
    for v = 1:7
        if c(u,v) ~= 0
            con(u,v) = c(u,v) - f(1,u,v) - f(2,u,v) - f(3,u,v);
        else
            con(u,v) = -1;
        end
    end
end