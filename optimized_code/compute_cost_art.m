function cost = compute_cost_art(D, sourceRegion, coordy, coordx, labels, gap)

% ADDME: label cost
% Label cost Vi(xi) measures the agreement of a node with its labels. Common sum of
% squared differences(SSD) is used as a distance measure between the values
% of the known pixels in the WxW neighborhood of the node i and the 
% corresponding pixel values of the label at xi. If the WxW neighborhood
% of a node is completely inside target region the label cost is zero. 

sz = [size(D,1) size(D,2)];
nnodes = length(coordy);
L = size(labels,2);

cost = zeros(nnodes,L);
for p = 1:nnodes
    maskPatch = sourceRegion(coordx(p)-gap : coordx(p)+gap, coordy(p)-gap : coordy(p)+gap);
    if (nnz(maskPatch))
        for i = 1:L
            [rowsq,colsq] = getpatch(sz,labels(p,i),gap); 
            cost(p,i) = ssd3(D(coordx(p)-gap : coordx(p)+gap, coordy(p)-gap : coordy(p)+gap,:), D(rowsq,colsq,:), repmat(maskPatch,[1 1 3]));
        end
    end
end