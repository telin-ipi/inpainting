function [labelsNew, order, priority] = label_extraction_gist_weighted (D, sourceRegion, coordy, coordx, priority, diff, diff1, labels, nrLabelsPerBlock, nodeDblock, L, Tsim, Tuncertain, gap)

% ADDME: Efficient energy optimization step2(LABEL PRUNING)
% After computing the label-pruning distance measure for each node, nodes
% are visited in the order of their priority keeping L labels with the
% smallest distance measure and discarding the rest. For interior nodes,
% (label cost is 0) only available information is the one coming from 
% the neighbors. Each nod is visited only once during label pruning. Once
% chosen set of labels per node remains fixed throughout the rest of the
% energy optimization algorithm.

% labelPos: positions of the possible labels in the source region; only
% keep track of them, not the actual patches

tic;
nnodes = length(coordx);
committed = false(1,nnodes);
labelsNew = zeros(nnodes,L);
order = zeros(1,nnodes);
% diff = diff_old;
% labels = labels_old;
for time = 1:nnodes
    p = find_first(priority, committed)
    %label_pruning
    prunedLabels = label_pruning_art_fast(D, diff{p}, labels{p}, L, Tsim, gap);
    labels{p} = prunedLabels;
    committed(p) = 1;
    
    order(time) = p; 
    %updating difference and priority
    [up, down, right, left] = find_neighbours(coordy, coordx, p, gap);
    if (up && (committed(up) == 0))
        [diffW, diffSSD] = calculate_weighted_diff_fast1(D, labels{up}, labels{p}, nrLabelsPerBlock{up}, nodeDblock{up}, 'up', gap);
        diff{up} = diff{up} + diffW;
        diff1{up} = diff1{up} + diffSSD;
        priority(up) = update_priority_scaled(diff1{up}, Tuncertain);       %dodao _scaled jer nema samo update_priority
    end
    if (down && (committed(down) == 0))
        [diffW, diffSSD] = calculate_weighted_diff_fast1(D, labels{down}, labels{p}, nrLabelsPerBlock{down}, nodeDblock{down}, 'down', gap);
        diff{down} = diff{down} + diffW;
        diff1{down} = diff1{down} + diffSSD;
        priority(down) = update_priority_scaled(diff1{down}, Tuncertain);
    end
    if (right && (committed(right) == 0))
        [diffW, diffSSD] = calculate_weighted_diff_fast1(D, labels{right}, labels{p}, nrLabelsPerBlock{right}, nodeDblock{right}, 'right', gap);
        diff{right} = diff{right} + diffW;
        diff1{right} = diff1{right} + diffSSD;
        priority(right) = update_priority_scaled(diff1{right}, Tuncertain);
    end
    if (left && (committed(left) == 0))
        [diffW, diffSSD] = calculate_weighted_diff_fast1(D, labels{left}, labels{p}, nrLabelsPerBlock{left}, nodeDblock{left}, 'left', gap);
        diff{left} = diff{left} + diffW;
        diff1{left} = diff1{left} + diffSSD;
        priority(left) = update_priority_scaled(diff1{left}, Tuncertain);
    end
end

for i = 1 : nnodes
    
    
    labels_i = labels{i};
    
    depth = size(labels{i}, 2);    
    if depth < L
        print('not enough labels to choose from!')
        % LaMeeus: added since somethings labels not completely filled
        ncopy = idivide(L, depth, 'ceil');
        labels_i_copy = repmat(labels_i, 1, ncopy);
        labelsNew(i,:) = labels_i_copy(1:L);
        
    else
        labelsNew(i,:) = labels_i;
    end
    
   
end
clear diff labels committed;
T=toc




