function D = output_art_mincut(OutMask, labels, order, coordy, coordx, Din, sourceRegion, gap)
sz = [size(Din,1) size(Din,2)];
%{
dest_map = true(sz(1),sz(2));
for i = 1 : length(coordx)
    yt = coordy(i);
    xt = coordx(i);
    dest_map(xt-gap : xt+gap, yt-gap : yt+gap) = false;
end
%}
dest_map = sourceRegion;
D = Din.*repmat(dest_map,[1 1 3]);
filt_w = 4;
smooth_filt = binomialFilter(filt_w)*binomialFilter(filt_w)';
%OUT:
%   -target: original missing region filled with patches determined by BP
nnodes = length(labels);

norder = length(order);
if norder < nnodes
    % This is not expected. possible inpainting region to small, too little
    % possible candidates
    msg1 = ['norder < nnodes :' num2str(norder) ' < ' num2str(nnodes) '\n%s'];
    msg2 = 'patch is possibly too small';
    warning(msg1, msg2)
    
    % make nnodes smaller
    nnodes = norder;
end
% 
% nnodes
% order
% msg = 'HI'
% warning(msg)

for time = 1:nnodes
    p = order(time);
    yt = coordy(p);
    xt = coordx(p);
    
    %add image blending, but the formula is not clear
    [rows,cols] = getpatch(sz,labels(p,OutMask(p)),gap);
    existingPatch = D(xt-gap : xt+gap, yt-gap : yt+gap,:);
    newPatch = Din(rows,cols,:);
    err_sq = sum((newPatch - existingPatch).^2,3)/3;
    blend_mask = false(size(err_sq));
    if (xt > gap+1 && yt > gap+1),
        blend_mask = dpmain(err_sq,gap);
    elseif (xt == gap+1 && yt == gap+1),
    elseif (xt == gap+1),
        blend_mask(:,1:gap) = dp(err_sq(:,1:gap));
    else 
        blend_mask(1:gap,:) = blend_mask(1:gap,:) ...
        | dp(err_sq(1:gap,:)')';
    end;
    blend_mask = rconv2(double(blend_mask),smooth_filt);
    blend_mask_rgb = repmat(blend_mask,[1 1 3]);
    D(xt-gap : xt+gap, yt-gap : yt+gap,:) ...
	  = existingPatch.*blend_mask_rgb + newPatch.*(1-blend_mask_rgb);
    dest_map(xt-gap : xt+gap, yt-gap : yt+gap) = true;
    D = D.*double(repmat(dest_map,[1 1 3]));
end
%sourceRegion = rconv2(1-sourceRegion,smooth_filt);
% D = Din.*repmat(sourceRegion,[1 1 3]) + D.*repmat(1-sourceRegion,[1 1 3]);