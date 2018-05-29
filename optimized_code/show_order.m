function orderImg = show_order(img,sourceRegion,order,coordx,coordy,gap)
[M,N,c] = size(img);
orderImg = zeros(M,N,c);
orderImg(:,:,1) = sourceRegion*255;
for i=1:length(order)
    p = order(i);
    for j = 1 : c
        orderImg(coordx(p)-gap:coordx(p)+gap,coordy(p)-gap:coordy(p)+gap,j) = floor(i*255/length(order));
    end
end
%figure, imshow(uint8(orderImg));