function [mapTextons, C, gfull] = textonGenerateContrastNorm(img,fillRegion,nTex,orientationsPerScale)

% ADDME: creating contextual descriptors
% Contextual descriptors characterize spatial content and texture within
% blocks. Texture is extracted using multi-channel filtering. Contextual
% descriptors are implemented as texton histograms.

sz = [size(img,1) size(img,2)];
Nfilters = sum(orientationsPerScale);
border = 32;
szPadded = sz + [2*border 2*border];

G = createGabor(orientationsPerScale, szPadded);

imgMirror = padarray(img, [border border], 'symmetric');
gfull = zeros(sz(1), sz(2), Nfilters);
data = zeros(nnz(~fillRegion),Nfilters);
imgProc = single(fft2(rgb2gray(imgMirror))); 

%figure
for n = 1:Nfilters
    imgFilt = abs(ifft2(imgProc.*G(:,:,n)));
    g = imgFilt(border+1:szPadded(1)-border,border+1:szPadded(2)-border); 
    gfull(:,:,n) = g; 
end

gfullL2 = sqrt(sum(gfull.^2,3));
gfullNorm = gfull .* repmat(log10(1 + gfullL2./0.03)./gfullL2, [1 1 Nfilters]);
for n = 1:Nfilters
    g = gfullNorm(:,:,n);
    data(:,n) = g(~fillRegion);
end
%clustering = computing textons
step = floor(size(data,1)/nTex);
initData = data(1:step:nTex*step,:);
[IDX,C] = kmeans(data,nTex,'start',initData, 'MaxIter',1000);
mapTextons = zeros(szPadded(1)-2*border, szPadded(2)-2*border);
mapTextons(~fillRegion) = IDX;
mapTextons = reshape(mapTextons,szPadded(1)-2*border, szPadded(2)-2*border);