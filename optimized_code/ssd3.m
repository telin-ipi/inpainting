function value = ssd3(d, dp, mask)

% ADDME:  common sum of squered differences
% Used as a distance measure while computing label cost and pairwise
% potentional

if (nargin==2)
    value = sum(sum(sum((d - dp).^2)));
else
    value = sum(sum(sum(mask.*(d - dp).^2)));
end