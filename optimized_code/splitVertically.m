function [newBlock, newBlockImg, newBlockPos, g, keepBlock, flag] = splitVertically(currentBlock, currentBlockImg, currentBlockPos, blockSize, fillRegion, t, nTex, r)

% ADDME: Splits the block vertically

newBlock = cell(1,2);
newBlockImg = cell(1,2);
newBlockPos = zeros(5,2);
keepBlock = [];
%diffGist = zeros(1,4);
g = zeros(2,nTex);
flag = false(1,2);
fs = 2;
%figure
for m = 1:2
    newBlock{m} = currentBlock((m-1)*blockSize(1)+1:m*blockSize(1),:,:);
    newBlockImg{m} = currentBlockImg((m-1)*blockSize(1)+1:m*blockSize(1),:,:);
    newBlockPos(:,m) = [(m-1)*blockSize(1)+currentBlockPos(1) currentBlockPos(2) blockSize(1) blockSize(2) fs]';
    maskNew = ~fillRegion(newBlockPos(1,m):newBlockPos(1,m)+blockSize(1)-1,newBlockPos(2,m):newBlockPos(2,m)+blockSize(2)-1);
    numOnes = nnz(maskNew);
    if (numOnes~=0)
        v = reshape(newBlock{m},1,numel(newBlock{m}));
        vMask = reshape(maskNew,1,numel(maskNew));
        vh = hist(v(vMask),t);
        if (numOnes)
            vh = vh/numOnes; %paying attention to take the mean of only responses within the source region
        end
        g(m,:) = vh;
        keepBlock = cat(1,keepBlock,m);
    end
    %subplot(2,1,m), imshow(newBlockImg{m});
    %subplot(2,1,m), imagesc(newBlock{m});
    if (numOnes<=(r*blockSize(1)*blockSize(2)))
        flag(m) = true;
    end
end