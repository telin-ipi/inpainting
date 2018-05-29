function [coordy, coordx, priority, labels, diff, diff1, nrLabelsPerBlock, nodeDblock] = comp_data_gist_ver4_adaptive_scaled_weighted(D, mask, labBlock, gmatches, Tuncertain, Tb, gap, blocks, gerrors)

% ADDME: Efficient energy minimization step1(INITIALIZATION)
% Assigning priorities to MRF nodes which determine their visiting order in
% the next phase (label pruning) 

%IN:
%   D: image matrix (whole image) consisting of source and target region;
%   target region is the missing region and therefore, its pixel values are
%   0 (black)
%   mask: matrix with dimensions of the image whose elements are 1 in the
%   source region and 0 in the target region
%OUT:
%   data: is a cell array of structures that represent nodes with fields
%       -x: x coordinate of the node in image
%       -y: y coordinate of the node in image
%       -nlabels: number of labels for each node
%       -labels: array of nlabels structures that represent labels for certain node
%       with fields:
%           -x: x coordinate of the node in image
%           -y: y coordinate of the node in image
%           -cost: data cost between node and label
%           -msg_up: incoming message to the observed node from the node
%           above
%           -msg_down: incoming message to the observed node from the node
%           below
%           -msg_right: incoming message to the observed node from the node
%           on the right
%           -msg_left: incoming message to the observed node from the node
%           on the left
%           -belief: belief of the observed node for the observed label
%       -pot_up: matrix of pairwise potentials between current node and its
%       neighbour above
%       -pot_down: matrix of pairwise potentials between current node and its
%       neighbour below
%       -pot_right: matrix of pairwise potentials between current node and its
%       right neighbour
%       -pot_left: matrix of pairwise potentials between current node and its
%       left neighbour


[M, N, c] = size(D);
sz = [M N];

maxnodes = ceil(((M-gap-1)/gap) * ((N-gap-1)/gap));
coordx = zeros(1,maxnodes);
coordy = zeros(1,maxnodes);
priority = zeros(1,maxnodes);
% nodeDblock = cell(1,maxnodes);

mask1 = ones(2*gap+1,2*gap+1);
mask1(gap+1,gap+1) = -numel(mask1);
labAll = find(conv2(mask,mask1,'same')==-1);
labAll = labAll';

node = 0;

% Empty assignments if nothing to be inpainted
labels = {};
diff = {};
diff1 = {};
nrLabelsPerBlock = {};
nodeDblock = {};

nbrBlocksPrevious = zeros(1,4);
%Implement looking for node coordinates in C if it's slow
for x = gap+1 : gap: M-gap
    for y = gap+1 : gap: N-gap
        %if there are zeros in the mask, it means the patch intersects the
        %target region and therefore it is considered as a node
        mask_patch = mask(x-gap : x+gap, y-gap : y+gap);
        if (~(all(all(mask_patch)))) 
            
            %maximum 4 blocks that a patch can intersect
            nbrBlocks = zeros(1,4);
             % Check if the target patch intersects other blocks
            endPts = [1 2*gap+1];
            %nbrBlocks(1,:) = [wx wy];
            k = 0;
            for i=endPts
                z = find(blocks(1,:)<=x-gap+i-1);
                zz = find(blocks(1,z)+blocks(3,z)-1>=x-gap+i-1);

                for j=endPts
                    q = find(blocks(2,z(zz))<=y-gap+j-1);
                    qq = find(blocks(2,z(zz(q)))+blocks(4,z(zz(q)))-1>=y-gap+j-1);  
                    nbr = z(zz(q(qq)));
                    if (~any(nbrBlocks==nbr)) %necessary cause not the whole image is covered in blocks
                        k = k+1;
                        nbrBlocks(k) = nbr;
                    end
                end
            end
            
            node = node+1;
            
            if (~isequal(nbrBlocks,nbrBlocksPrevious))
                if (nnz(nbrBlocks)==0)
                    lab = labAll;
                    nlab = numel(labAll);
                else
    %                 nlab = 0;
    %                 lab = [];
                    indBlock = [];
                    errorBlock = [];
                    m = 0;
                    for kk = 1 : k
                        nrSegm = length(gmatches{nbrBlocks(kk)});
                        for i = 1 : nrSegm
                            if (~any(indBlock == gmatches{nbrBlocks(kk)}(i)))
                                m = m+1;
                                indBlock(m) = gmatches{nbrBlocks(kk)}(i);
                                errorBlock(m) = gerrors{nbrBlocks(kk)}(i);
                            else
                                % added because of the case of a node
                                % intersecting multiple blocks; the case of
                                % unreliable blocks is covered during block
                                % matching
                                z = find(indBlock==gmatches{nbrBlocks(kk)}(i));
                                errorBlock(z) = min(errorBlock(z),gerrors{nbrBlocks(kk)}(i));
                            end
                        end
                    end
    %                 for i = 1:m
    %                     nlab = nlab + length(labBlock{indBlock(i)});
    %                     lab = cat(2,lab,labBlock{indBlock(i)});
    %                 end
                end
            end
            
            %node coordinates have to be saved because we have to know its
            %exact location
            coordy(node) = y;
            coordx(node) = x;
            
            %Dblock = 1-exp(-(errorBlock + max(errorBlock)));
            Dblock = 1-exp(-(errorBlock + Tb));
            nodeDblock{node} = Dblock;
            %this will be unacceptable for the labels in the big image
            labels{node} = [];
            nrLabelsPerBlock{node} = [];
            if (nnz(mask_patch))
                diff{node} = [];
                diff1{node} = [];
                for i = 1:m
                    %different computation, not based on lab position, because
                    %it cannot save all the label positions; we have to give
                    %maximal number of labels and then discard the zeros
                    nlab = length(labBlock{indBlock(i)});
                    lab = labBlock{indBlock(i)};
                    Dssd = compdata(M,N,D,D(x-gap : x+gap, y-gap : y+gap, :),logical(mask_patch),nlab,lab,gap);
                    Dsim = Dssd*Dblock(i);
                    diff{node} = cat(2,diff{node},Dsim);
                    diff1{node} = cat(2,diff1{node},Dssd);
                    labels{node} = cat(2,labels{node},lab);
                    nrLabelsPerBlock{node} = cat(2,nrLabelsPerBlock{node},nlab);
                end
                uncertainty = length(find(diff{node}-min(diff{node}) < Tuncertain));
            else
                nlab = 0;
                for i = 1:m
                    nlab = nlab + length(labBlock{indBlock(i)});
                    labels{node} = cat(2,labels{node},labBlock{indBlock(i)});
                    nrLabelsPerBlock{node} = cat(2,nrLabelsPerBlock{node},length(labBlock{indBlock(i)}));
                end
                diff{node} = zeros(1,nlab);
                diff1{node} = zeros(1,nlab);
                uncertainty = nlab;
            end
            
            priority(node) = numel(labels{node})/max(uncertainty,1);
            nbrBlocksPrevious = nbrBlocks;          
        end
        
    end
end
coordx(node+1:maxnodes) = [];
coordy(node+1:maxnodes) = [];
priority(node+1:maxnodes) = [];

