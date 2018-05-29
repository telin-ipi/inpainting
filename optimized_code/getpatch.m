function [rows,cols] = getpatch(sz,p,w)
[x,y] = ind2sub(sz,p);  % 2*w+1 == the patch size
%p=p-1; y1=floor(p/sz(1))+1; p=rem(p,sz(1)); x1=floor(p)+1;
    
rows = (max(x-w,1):min(x+w,sz(1)))';
cols = max(y-w,1):min(y+w,sz(2));
