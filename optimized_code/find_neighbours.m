function [up, down, right, left] = find_neighbours(coordy, coordx, p, gap)
y = coordy(p);
x = coordx(p);
nnodes = length(coordy);
up = 0;
down = 0;
right = 0;
left = 0;
for i=1:nnodes
    if ((coordx(i) == x-gap) && (coordy(i) == y))
        up = i;
    end
    if ((coordx(i) == x+gap) && (coordy(i) == y))
        down = i;
    end
    if ((coordx(i) == x) && (coordy(i) == y+gap))
        right = i;
    end
    if ((coordx(i) == x) && (coordy(i) == y-gap))
        left = i;
    end
end