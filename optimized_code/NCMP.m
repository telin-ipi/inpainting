function [new_bel, OutMask, iter] = NCMP (loc, pot, InitMask, coordx, coordy, gap, max_iter)

% ADDME: Efficient energy optimization step3(NEIGBOURHOOD-CONSENSUS MESSAGE PASSING - NCMP)
% In this algorithm one joint message is sent from the whole neighbourhoood 
% of the central node i to the cental node i.

% calculates most likely labels for each node in the MRF inpainting algorithm using neighbourhood-consensus message passing. 
% Here, missing region is modelled as a multi-label Markov Random Field (MRF) with 4-neighbourhood.
% Input:
%       loc - nnodes x nlabels matrix containing local measurements for
%       each node, Pr(measurement = m| X = x); nnodes is the number of nodes in the MRF
%	  and nlabels is number of possible labels
%       for each node of a MRF.
%
%       pot - 4-D matrix (nnodes x nneighbours x nlabels x nlabels) containing pairwise potentials
%       between all pairs of nodes in the network, thus also spatially varying 
%
%       InitMask - initial mask obtained by maximizing the likelihood loc
%
%       coordx, coordy - vectors containing vertical and horizontal location of a node in the image (I use it to find the indices of neighbours)
%
%	  gap - determines the patch size as 2*gap+1
%
%       max_iter - maximum number of iterations
%
% Output:
%       new_bel - nnodes x nlabels matrix containing calculated belief
%       for each node
%
%       OutMask - vector containing nnodes elements which represent MAP estimates at each node
%
%       iter - final number of iterations

[nnodes, nlabels] = size(loc);

% initialise messages
msg = ones(nnodes,nlabels);

%initialise beliefs to so the maximum value 1 corresponds to the label of
%initial mask
OutMask = InitMask;
bel = zeros(nnodes,nlabels);
for i=1:nnodes
    bel(i,InitMask(i)) = 1;
end

new_bel = bel;
converged = 0;
iter = 1;
%Etot = zeros(1,max_iter);
while ~converged && (iter <= max_iter)
    for p=1:nnodes
        %indexes in the 2nd dim of matrix pot: 1 2 3 4
        [up, down, right, left] = find_neighbours(coordy, coordx, p, gap); %this I use for inpainting because my mask is of irregular shape and the nodes are assigned an index in the raster scan order; you can use whatever you need to find the indices of your 4 neighbours
        nbrs = [up down right left];
        for i = 1:length(nbrs)
            if (nbrs(i))
                potMatrix(:,:) = pot(p,i,:,:);
                msg(p,:) = potMatrix * bel(nbrs(i),:)';
            end
        end
        msg(p,:) = exp(-msg(p,:));    
        new_bel(p,:) = msg(p,:).*loc(p,:);
        new_bel(p,:) = normalise_new_inf(new_bel(p,:));
    end
    
    %check convergence (when the mask hasn't changed in one iteration
    [max_bel,new_OutMask] = max(new_bel,[],2);
    %{
    err_mask = abs(new_OutMask(:) - OutMask(:));
    if (nnz(err_mask) == 0)
        converged = 1;
    end
    %} 
    OutMask = new_OutMask;
%     Ed = 0;
%     Es = 0;
%     committed = zeros(1,nnodes);
%     for p=1:nnodes
%         [up, down, right, left] = find_neighbours(coordy, coordx, p, gap);
%         nbrs = [up down right left];
%         for i = 1:length(nbrs)
%             if (nbrs(i) && (committed(nbrs(i))==0))
%                 Es = Es + pot(p,i,OutMask(p),OutMask(nbrs(i)));
%                 Ed = Ed - log(loc(p,OutMask(p)));
%             end
%         end
%         committed(p) = 1;
%     end
%     
%     Etot(iter) = Ed + Es;
    iter = iter + 1;
    bel = new_bel;
end
iter = iter-1;