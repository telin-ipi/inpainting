function Dr = chiTestTexton(gp,g)

% ADDME: Computes the difference for each block and feature

Dr = zeros(1,size(g,1));
for j = 1:size(g,1)
    for t = 1:size(g,2)
        E = (gp(t) + g(j,t))/2;
        if (E~=0)
            Dr(j) = Dr(j) + (gp(t)-E)^2/E;
        end
    end    
end