function [diff, diffSSD] = calculate_weighted_diff_fast1(D, labelPos, neighbourLabels, nrLabelsPerBlock, Dblock, relPos, gap)

% ADDME: Calculate label pruning distance


nlab = length(labelPos);
L = size(neighbourLabels,2);
%neighbourLabels = node p
[indp, indq] = overlap_region(relPos, gap);
    
diff = calculatediffhelper(size(D,1), size(D,2), D, nlab, labelPos, L, neighbourLabels, indp, indq, gap);
%diff1 = calculate_diff(D, labelPos, neighbourLabels, relPos, gap);
diffSSD = diff;
for i = 1:numel(nrLabelsPerBlock)
    if (i==1)
        diff(1:nrLabelsPerBlock(i)) = diff(1:nrLabelsPerBlock(i)) .* Dblock(i);
    else
        diff(sum(nrLabelsPerBlock(1:i-1))+1:sum(nrLabelsPerBlock(1:i))) = diff(sum(nrLabelsPerBlock(1:i-1))+1:sum(nrLabelsPerBlock(1:i))) .* Dblock(i);
    end
end