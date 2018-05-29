function [allBlocks1,backupBlockPos,blocks] = decomposition_adaptive_blocksize(img,fillRegion,mapTextons,nTex,bsmin,T,r)

% ADDME: top-down splitting procedure
%  Divides an image into blocks of adaptive size depending on the 'homogeneity'
%  of their texture. Directional flag is assigned to each block. This flag
%  determines the direction along witch the evaluation of the blocks
%  homogeneity will have the priority. Splitting along one side of the block
%  is constraind by block similarity threshold.

sz = [size(img,1) size(img,2)];

blockSize = floor(sz./2);
t = 1:nTex;

allBlocks = [];
newBlock = cell(1,4);
newBlockImg = cell(1,4);
currentBlockPos = zeros(5,4);

imgMasked = img.*repmat(double(~fillRegion),[1 1 3]);

%flag determining in which direction to split the block: 1 - vertical, 2 -
%horizontal; initially, depends on image dimensions
if (sz(1)<=sz(2))
    fs = 2;
else
    fs = 1;
end
for n = 1:2
    for m = 1:2
        newBlock{(n-1)*2+m} = mapTextons((m-1)*blockSize(1)+1:m*blockSize(1),(n-1)*blockSize(2)+1:n*blockSize(2),:);
        newBlockImg{(n-1)*2+m} = imgMasked((m-1)*blockSize(1)+1:m*blockSize(1),(n-1)*blockSize(2)+1:n*blockSize(2),:);
        currentBlockPos(:,(n-1)*2+m) = [(m-1)*blockSize(1)+1 (n-1)*blockSize(2)+1 blockSize(1) blockSize(2) fs]';
        %subplot(2,2,(m-1)*2+n), imshow(newBlockImg{(n-1)*2+m});
    end
end
        
currentBlock = newBlock;
currentBlockImg = newBlockImg;
k = 0;
b = 0;

while (~isempty(currentBlockPos))
    temp = [];
    tempImg = [];
    tempPos = [];
    for i = 1:length(currentBlock)
        %figure, imshow(currentBlockImg{i});
        mask = ~fillRegion(currentBlockPos(1,i):currentBlockPos(1,i)+currentBlockPos(3,i)-1,currentBlockPos(2,i):currentBlockPos(2,i)+currentBlockPos(4,i)-1);               %promenio
        numOnes = nnz(mask);
        if (numOnes > (0.5*currentBlockPos(3,i)*currentBlockPos(4,i)))
            
            %check whether horizontal or vertical split is necessary
            if (currentBlockPos(5,i)==1 && currentBlockPos(3,i)>bsmin(1))
                %split vertically
                blockSize = [currentBlockPos(3,i) currentBlockPos(4,i)];
                blockSize(1) = floor(blockSize(1)./2);
                [newBlock, newBlockImg, newBlockPos, g, keepBlock, flag] = splitVertically(currentBlock{i}, currentBlockImg{i}, currentBlockPos(:,i), blockSize, fillRegion, t, nTex, r);
            
                if (numel(keepBlock)==2)
                    Dr = chiTestTexton(g(1,:),g(2,:));
                    if (Dr>T)
                        if (all(flag==false))
                            temp = [temp newBlock];
                            tempImg = [tempImg newBlockImg];
                            tempPos = cat(2,tempPos,newBlockPos);
                        else
                            temp = [temp mat2cell(newBlock{~flag},[size(newBlock{~flag},1)],[size(newBlock{~flag},2)],[size(newBlock{~flag},3)])];
                            tempImg = [tempImg mat2cell(newBlockImg{~flag},[size(newBlockImg{~flag},1)],[size(newBlockImg{~flag},2)],[size(newBlockImg{~flag},3)])];
                            tempPos = cat(2,tempPos,newBlockPos(:,~flag));
                            k = k+1;
                            backupBlockPos(:,k) = newBlockPos(:,~flag);
                            allBlocks(:,k) = newBlockPos(:,flag);
                        end
                    elseif (currentBlockPos(4,i)>bsmin(2))
                        blockSize = [currentBlockPos(3,i) currentBlockPos(4,i)];
                        blockSize(2) = floor(blockSize(2)./2);
                        [newBlock, newBlockImg, newBlockPos, g, keepBlock, flag] = splitHorizontally(currentBlock{i}, currentBlockImg{i}, currentBlockPos(:,i), blockSize, fillRegion, t, nTex, r);
                        if (numel(keepBlock)==2)
                            Dr = chiTestTexton(g(1,:),g(2,:));
                            if (Dr>T)
                                
                                if (all(flag==false))
                                    temp = [temp newBlock];
                                    tempImg = [tempImg newBlockImg];
                                    tempPos = cat(2,tempPos,newBlockPos);
                                else
                                    temp = [temp mat2cell(newBlock{~flag},[size(newBlock{~flag},1)],[size(newBlock{~flag},2)],[size(newBlock{~flag},3)])];
                                    tempImg = [tempImg mat2cell(newBlockImg{~flag},[size(newBlockImg{~flag},1)],[size(newBlockImg{~flag},2)],[size(newBlockImg{~flag},3)])];
                                    tempPos = cat(2,tempPos,newBlockPos(:,~flag));
                                    k = k+1;
                                    backupBlockPos(:,k) = newBlockPos(:,~flag);
                                    allBlocks(:,k) = newBlockPos(:,flag);
                                end
                            else
                                k = k+1;
                                backupBlockPos(:,k) = zeros(5,1);
                                allBlocks(:,k) = currentBlockPos(:,i);
                            end
                        else
                            temp = [temp mat2cell(newBlock{keepBlock},[size(newBlock{keepBlock},1)],[size(newBlock{keepBlock},2)],[size(newBlock{keepBlock},3)])];
                            tempImg = [tempImg mat2cell(newBlockImg{keepBlock},[size(newBlockImg{keepBlock},1)],[size(newBlockImg{keepBlock},2)],[size(newBlockImg{keepBlock},3)])];
                            tempPos = cat(2,tempPos,newBlockPos(:,keepBlock));
                            if (keepBlock==1)
                                k = k+1;
                                backupBlockPos(:,k) = zeros(5,1);
                                allBlocks(:,k) = newBlockPos(:,2);
                            else
                                k = k+1;
                                backupBlockPos(:,k) = zeros(5,1);
                                allBlocks(:,k) = newBlockPos(:,1);
                            end
                        end
                    else
                        k = k+1;
                        backupBlockPos(:,k) = zeros(5,1);
                        allBlocks(:,k) = currentBlockPos(:,i);
                    end
                else
                    %keep the block with some known pixels as the current
                    %block while other one is not split further
                    temp = [temp mat2cell(newBlock{keepBlock},[size(newBlock{keepBlock},1)],[size(newBlock{keepBlock},2)],[size(newBlock{keepBlock},3)])];
                    tempImg = [tempImg mat2cell(newBlockImg{keepBlock},[size(newBlockImg{keepBlock},1)],[size(newBlockImg{keepBlock},2)],[size(newBlockImg{keepBlock},3)])];
                    tempPos = cat(2,tempPos,newBlockPos(:,keepBlock));
                    if (keepBlock==1)
                        k = k+1;
                        backupBlockPos(:,k) = zeros(5,1);
                        allBlocks(:,k) = newBlockPos(:,2);
                    else
                        k = k+1;
                        backupBlockPos(:,k) = zeros(5,1);
                        allBlocks(:,k) = newBlockPos(:,1);
                    end
                end
            elseif (currentBlockPos(5,i)==2 && currentBlockPos(4,i)>bsmin(2))
                %split horizontally
                blockSize = [currentBlockPos(3,i) currentBlockPos(4,i)];
                blockSize(2) = floor(blockSize(2)./2);
                [newBlock, newBlockImg, newBlockPos, g, keepBlock, flag] = splitHorizontally(currentBlock{i}, currentBlockImg{i}, currentBlockPos(:,i), blockSize, fillRegion, t, nTex, r);
            
                if (numel(keepBlock)==2)
                    Dr = chiTestTexton(g(1,:),g(2,:));
                    if (Dr>T)
                        
                        if (all(flag==false))
                            temp = [temp newBlock];
                            tempImg = [tempImg newBlockImg];
                            tempPos = cat(2,tempPos,newBlockPos);
                        else
                            temp = [temp mat2cell(newBlock{~flag},[size(newBlock{~flag},1)],[size(newBlock{~flag},2)],[size(newBlock{~flag},3)])];
                            tempImg = [tempImg mat2cell(newBlockImg{~flag},[size(newBlockImg{~flag},1)],[size(newBlockImg{~flag},2)],[size(newBlockImg{~flag},3)])];
                            tempPos = cat(2,tempPos,newBlockPos(:,~flag));
                            k = k+1;
                            backupBlockPos(:,k) = newBlockPos(:,~flag);
                            allBlocks(:,k) = newBlockPos(:,flag);
                        end
                    elseif (currentBlockPos(3,i)>bsmin(1))
                        blockSize = [currentBlockPos(3,i) currentBlockPos(4,i)];
                        blockSize(1) = floor(blockSize(1)./2);
                        [newBlock, newBlockImg, newBlockPos, g, keepBlock, flag] = splitVertically(currentBlock{i}, currentBlockImg{i}, currentBlockPos(:,i), blockSize, fillRegion, t, nTex, r);
                        if (numel(keepBlock)==2)
                            Dr = chiTestTexton(g(1,:),g(2,:));
                            if (Dr>T)
                                if (all(flag==false))
                                    temp = [temp newBlock];
                                    tempImg = [tempImg newBlockImg];
                                    tempPos = cat(2,tempPos,newBlockPos);
                                else
                                    temp = [temp mat2cell(newBlock{~flag},[size(newBlock{~flag},1)],[size(newBlock{~flag},2)],[size(newBlock{~flag},3)])];
                                    tempImg = [tempImg mat2cell(newBlockImg{~flag},[size(newBlockImg{~flag},1)],[size(newBlockImg{~flag},2)],[size(newBlockImg{~flag},3)])];
                                    tempPos = cat(2,tempPos,newBlockPos(:,~flag));
                                    k = k+1;
                                    backupBlockPos(:,k) = newBlockPos(:,~flag);
                                    allBlocks(:,k) = newBlockPos(:,flag);
                                end
                            else
                                k = k+1;
                                backupBlockPos(:,k) = zeros(5,1);
                                allBlocks(:,k) = currentBlockPos(:,i);
                            end
                        else
                            temp = [temp mat2cell(newBlock{keepBlock},[size(newBlock{keepBlock},1)],[size(newBlock{keepBlock},2)],[size(newBlock{keepBlock},3)])];
                            tempImg = [tempImg mat2cell(newBlockImg{keepBlock},[size(newBlockImg{keepBlock},1)],[size(newBlockImg{keepBlock},2)],[size(newBlockImg{keepBlock},3)])];
                            tempPos = cat(2,tempPos,newBlockPos(:,keepBlock));
                            if (keepBlock==1)
                                k = k+1;
                                backupBlockPos(:,k) = zeros(5,1);
                                allBlocks(:,k) = newBlockPos(:,2);
                            else
                                k = k+1;
                                backupBlockPos(:,k) = zeros(5,1);
                                allBlocks(:,k) = newBlockPos(:,1);
                            end
                        end
                    else
                        k = k+1;
                        backupBlockPos(:,k) = zeros(5,1);
                        allBlocks(:,k) = currentBlockPos(:,i);
                    end
                else
                    %keep the block with some known pixels as the current
                    %block while other one is not split further
                    temp = [temp mat2cell(newBlock{keepBlock},[size(newBlock{keepBlock},1)],[size(newBlock{keepBlock},2)],[size(newBlock{keepBlock},3)])];
                    tempImg = [tempImg mat2cell(newBlockImg{keepBlock},[size(newBlockImg{keepBlock},1)],[size(newBlockImg{keepBlock},2)],[size(newBlockImg{keepBlock},3)])];
                    tempPos = cat(2,tempPos,newBlockPos(:,keepBlock));
                    if (keepBlock==1)
                        k = k+1;
                        backupBlockPos(:,k) = zeros(5,1);
                        allBlocks(:,k) = newBlockPos(:,2);
                    else
                        k = k+1;
                        backupBlockPos(:,k) = zeros(5,1);
                        allBlocks(:,k) = newBlockPos(:,1);
                    end
                end
            else
                k = k+1;
                backupBlockPos(:,k) = zeros(5,1);
                allBlocks(:,k) = currentBlockPos(:,i);
            end
        else
            k = k+1;
            allBlocks(:,k) = currentBlockPos(:,i);
        end
    end
    currentBlock = temp;
    currentBlockImg = tempImg;
    currentBlockPos = tempPos;
end

allBlocks1 = cat(2,allBlocks,currentBlockPos);
%clear allBlocks currentBlock currentBlockImg currentBlockPos;
i = 0;
blockSize = floor(sz./2);
while (any(blockSize>=bsmin))
    i = i+1;
    dim(i) = blockSize(1);
    blockSize = floor(blockSize./2);
end

blocks = imgMasked;
for i=1:length(dim);    
  z = find(allBlocks1(3,:)==dim(i));    
  if (~isempty(z))   
      for k = 1:length(z)
          xstart = allBlocks1(1,z(k));
          ystart = allBlocks1(2,z(k));
          d1 = dim(i);
          d2 = allBlocks1(4,z(k));
          for c=1:3
              blocks(xstart+d1-1,ystart:ystart+d2-1,c) = 1;
              blocks(xstart:xstart+d1-1,ystart+d2-1,c) = 1;
          end
      end
  end
end
%figure, imshow(blocks);

