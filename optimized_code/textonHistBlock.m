function y = textonHistBlock(imF, mask, blocks, nbins)
% 
% ADDMe: Computes histogram for one texture feature for each block

%
% Input
%   x = [nrows ncols]
%   mask = [nrows ncols]
% Output
%   y = [wx wy]


t = 1:nbins;
%figure

nBlocks = size(blocks,2);
y = zeros(nBlocks,nbins);
for i = 1:nBlocks 
    xstart = blocks(1,i);
    bsx = blocks(3,i);
    ystart = blocks(2,i);
    bsy = blocks(4,i);
    v = reshape(imF(xstart:xstart+bsx-1,ystart:ystart+bsy-1),1,bsx*bsy); %zero responses withing the target region won't influence the sum
    vMask = reshape(mask(xstart:xstart+bsx-1,ystart:ystart+bsy-1),1,bsx*bsy);
    vh = hist(v(vMask),t);
    numOnes = nnz(mask(xstart:xstart+bsx-1,ystart:ystart+bsy-1));
    if (numOnes)
        vh = vh/numOnes; %paying attention to take the mean of only responses within the source region
    end
    %set(gca,'xlim',[t(1) t(end)], 'ylim', [0 0.6]);
%         figure
%         subplot(1,2,1), bar(vh);
%         subplot(1,2,2), imagesc(x(nx(xx)+1:nx(xx+1), ny(yy)+1:ny(yy+1)));
    %subplot(wx,wy,k), bar(vh);
    y(i,:)=vh;
end