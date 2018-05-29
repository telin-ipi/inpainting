function [left,right,up,down] = find_neighbors_adaptive(blocks,i,M,N)

% ADDME: Finding neighbours of central block

x = blocks(1,i);
y = blocks(2,i);
sizex = blocks(3,i);
sizey = blocks(4,i);

% %left neighbor
% qy = find(blocks(2,:)+blocks(4,:)==y);
% qx = find(blocks(1,qy)<=x & blocks(1,qy)+blocks(3,qy)-1>=x);
% if (~isempty(qx))
%     left = qy(qx);
% else
%     left = 0;
% end
% %right neighbor
% qy = find(blocks(2,:)==y+sizey);
% qx = find(blocks(1,qy)<=x & blocks(1,qy)+blocks(3,qy)-1>=x);
% if (~isempty(qx))
%     right = qy(qx);
% else
%    right = 0;
% end
% 
% %upper neighbor
% qx = find(blocks(1,:)+blocks(3,:)==x);
% qy = find(blocks(2,qx)<=y & blocks(2,qx)+blocks(4,qx)-1>=y);
% if (~isempty(qy))
%     up = qx(qy);
% else
%    up = 0;
% end
% %down neighbor
% qx = find(blocks(1,:)==x+sizex);
% qy = find(blocks(2,qx)<=y & blocks(2,qx)+blocks(4,qx)-1>=y);
% if (~isempty(qy))
%     down = qx(qy);
% else
%    down = 0;
% end
zx = find(blocks(1,:)>=x);
zxx = find(blocks(1,zx)+blocks(3,zx)-1 <= x+sizex-1);
%left neighbor
zleft = find(blocks(2,zx(zxx))+blocks(4,zx(zxx))==y);
if (~isempty(zleft))
    left = zx(zxx(zleft));
elseif (y==1)
    left = 0;
else
    qy = find(blocks(2,:)+blocks(4,:)==y);
    qx = find(blocks(1,qy)<=x & blocks(1,qy)+blocks(3,qy)-1>=x);
    left = qy(qx);
end
%right neighbor
zright = find(blocks(2,zx(zxx))==y+sizey);
if (~isempty(zright))
    right = zx(zxx(zright));
elseif (y+sizey>N)
    right = 0;
else
    qy = find(blocks(2,:)==y+sizey);
    qx = find(blocks(1,qy)<=x & blocks(1,qy)+blocks(3,qy)-1>=x);
    right = qy(qx);
end
clear zx zxx;

zy = find(blocks(2,:)>=y);
zyy = find(blocks(2,zy)+blocks(4,zy)-1 <= y+sizey-1);
%upper neighbor
zup = find(blocks(1,zy(zyy))+blocks(3,zy(zyy))==x);
if (~isempty(zup))
%     [uval,upos] = sort(blocks(1,zy(zyy(zup))),'descend');
%     up = zy(zyy(zup(upos(1))));
    up = zy(zyy(zup));
elseif (x==1)
    up = 0;
else
    qx = find(blocks(1,:)+blocks(3,:)==x);
    qy = find(blocks(2,qx)<=y & blocks(2,qx)+blocks(4,qx)-1>=y);
    up = qx(qy);
end
%down neighbor
zdown = find(blocks(1,zy(zyy))==x+sizex);
if (~isempty(zdown))
    down = zy(zyy(zdown));
elseif (x+sizex>M)
    down = 0;
else
    qx = find(blocks(1,:)==x+sizex);
    qy = find(blocks(2,qx)<=y & blocks(2,qx)+blocks(4,qx)-1>=y);
    down = qx(qy);
end