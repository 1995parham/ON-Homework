n = 2;
cvx_begin
    variable x(n)
    minimize((x(1)-6)^2 + (x(2)-4)^2)
    subject to
        x(1) >= 3
        x(1) + x(2) <= 8
        x(2) <= x(1)
cvx_end