function labBlock = find_label_pos_per_adaptive_block_overlap(sourceRegion, w, blocks)

% ADDME: finding label positions

nBlocks = size(blocks,2);
labBlock = cell(1,nBlocks);
mask = ones(2*w+1,2*w+1);
mask(w+1,w+1) = -numel(mask);

for i = 1:nBlocks
    if (blocks(1,i)==1)
        xstart = blocks(1,i);
        bsx = blocks(3,i)+2*w;
    elseif (blocks(1,i)+blocks(3,i)-1==size(sourceRegion,1))
        xstart = blocks(1,i)-2*w;
        bsx = blocks(3,i)+2*w;
    else
        xstart = blocks(1,i)-w;
        bsx = blocks(3,i)+2*w;
    end
    if (blocks(2,i)==1)
        ystart = blocks(2,i);
        bsy = blocks(4,i)+2*w;
    elseif (blocks(2,i)+blocks(4,i)-1==size(sourceRegion,2))
        ystart = blocks(2,i)-2*w;
        bsy = blocks(4,i)+2*w;
    else
        ystart = blocks(2,i)-w;
        bsy = blocks(4,i)+2*w;
    end
      
    sz =size(sourceRegion);
    
    if xstart + bsx-1<sz(1) && ystart + bsy-1< sz(2)
        block = sourceRegion(xstart : xstart+bsx-1, ystart : ystart+bsy-1);
    else if xstart + bsx-1>sz(1) && ystart + bsy-1> sz(2)
            block = sourceRegion(xstart : end, ystart : end);
        else if xstart + bsx-1>sz(1)
                block = sourceRegion(xstart : end, ystart : ystart+bsy-1);
            else
                block = sourceRegion(xstart : xstart+bsx-1, ystart : end);
            end
        end
    end
    
    [I,J] = find(conv2(block,mask,'same')==-1);
    lab = (ystart-1+J'-1)*size(sourceRegion,1) + xstart-1+I';
    labBlock{i} = lab;
end