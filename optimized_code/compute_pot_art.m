function pot = compute_pot_art(D, coordy, coordx, labels, gap)

% ADDME: pairwise potential 
% Pairwise potential Vjk(xj,xk) is similarly as label cost defined as the
% SSD between labels centered at xj and xk in their nodes' overlap region.
% Check the function compute_cost_art for more detail

nnodes = length(coordy);
L = size(labels,2);

pot = zeros(nnodes,4,L,L);
for p = 1:nnodes
    %indexes in the matrix: 1 2 3 4 respectively
    [up, down, right, left] = find_neighbours(coordy, coordx, p, gap);
    
    if (right)
        potMat = comp_matrix_pot_art(D, labels(p,:), labels(right,:), gap, 'right'); 
        pot(p,3,:,:) = potMat;
        pot(right,4,:,:) = potMat';
    end
    if (down)
        potMat = comp_matrix_pot_art(D, labels(p,:), labels(down,:), gap, 'down'); 
        pot(p,2,:,:) = potMat;
        pot(down,1,:,:) = potMat';
    end
end

clear potMat;