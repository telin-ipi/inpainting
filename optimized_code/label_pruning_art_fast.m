function [labelsOut] = label_pruning_art_fast(D, diff, labels, L, Tsim, gap)
sz = [size(D,1) size(D,2)];
maxLabels = length(labels);

%difference in comparison with the node (target patch)
[diff, index] = sort(diff, 'ascend');

labelsOrdered = labels(index(1:maxLabels));
%discarding labels that are similar with each other
%labelsOut = labelpruninghelper(sz(1), sz(2), D, maxLabels, labelsOrdered, L, gap, Tsim);
Lfinal = min(L,maxLabels);
labelsOut=labelsOrdered(1:Lfinal);


