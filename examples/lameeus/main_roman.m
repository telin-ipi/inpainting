% Inpainting for Roman

clc
clear all

%% variables
folder_in = '/home/lameeus/data/ghent_altar/roman/input/';


input_name = '16_VIS_reg.tif';
mask_name = 'crack_cnn.png';
out_name = 'roman_inpainting';

version = 0;
w = 400;
out_name = [out_name, '_v', num2str(version)];

if version == 0
    folder_out = '/home/lameeus/data/ghent_altar/roman/inpainting/v0/';
    f = 6;      % default is 8, 
    gap = 4;    % default is 6, 
    ext = 2*f;
    
elseif version == 4
    folder_out = '/home/lameeus/data/ghent_altar/roman/inpainting/v4';ex
    f = 4;
    gap = 2;
    ext = 5;

end

setting_name = ['_f', int2str(f), '_gap', int2str(gap) , '.bmp'];  

%% loading
mask_path = [folder_in, mask_name];
input_path = [folder_in, input_name];
out_path = [folder_out, out_name];

img = im2double(imread(input_path));
fillRegion = im2double(imread(mask_path) > 0.5);
fillRegion = fillRegion(:,:,1);
size(fillRegion)

test = img;
test(fillRegion > 0.5) = 1;

if(0)
    inpainting(img, fillRegion, out_path, f, gap)
elseif(0)
    %% cropping for fast
    img_crop = img(800:800+w, 1000:1000+w, :);
    fillRegion_crop = fillRegion(800:800+w, 1000:1000+w);
    test_crop = test(800:800+w, 1000:1000+w, :);
    
    if(0)
        max(test_crop(:))
        size(test_crop)
        min(test_crop(:))
    end
 
    inpainting(img_crop, fillRegion_crop, out_path, f, gap)
        
    nameout2 = [out_path, '_mask', setting_name];
    imwrite(uint8(test_crop*256),nameout2,'bmp');  
    nameout3 = [out_path, '_img', setting_name];
    imwrite(uint8(img_crop*256),nameout3,'bmp');

else
    w_crop = int32(w);
    
    size_im = size(img);
    
    n_h = idivide(size_im(1), w_crop, 'ceil');
    n_w = idivide(size_im(2), w_crop, 'ceil');
    
    for i_h = 2:n_h
        for i_w = 8:n_w-1
            out_path_ij = [out_path, '_h', num2str(i_h), '_w', num2str(i_w)];
            
            h0 = int32((i_h-1)*w_crop - ext);
            h1 = int32((i_h)*w_crop + ext);
            
            w0 = int32((i_w-1)*w_crop - ext);
            w1 = int32((i_w)*w_crop + ext);
            
            h0 = max(h0, 1);
            w0 = max(w0, 1);
            
            h1 = min(h1, size_im(1));
            w1 = min(w1, size_im(2));
                                 
            img_crop = img(h0:h1, w0:w1, :);
            fillRegion_crop = fillRegion(h0:h1, w0:w1, :);
            test_crop = test(h0:h1, w0:w1, :);
            
            %showing
            figure(1)
            imshow(test_crop)
            
            inpainting(img_crop, fillRegion_crop, out_path_ij, f, gap)
            nameout2 = [out_path_ij, '_mask', setting_name];
            imwrite(uint8(test_crop*256),nameout2,'bmp');  
            nameout3 = [out_path_ij, '_img', setting_name];
            imwrite(uint8(img_crop*256),nameout3,'bmp');
            
                
        end
    end     
end