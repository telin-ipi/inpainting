% for inpainting of paintings

%% variables
input_folder = '/home/lameeus/data/ghent_altar/input/';
input_name = '19_clean_crop_scale.tif';

mask_folder = '/home/lameeus/data/ghent_altar/classification/';
mask_name = 'class_hand_vno_clean.tif';

out_folder = '/home/lameeus/data/ghent_altar/inpainting/';
out_name = 'hand';

f = 8;      % default is 8, 
gap = 6;    % default is 6, 

version = 1;
w = 100;
out_name = [out_name, '_v', num2str(version)];

%% loading
mask_path = [mask_folder, mask_name];
input_path = [input_folder, input_name];
out_path = [out_folder, out_name];

img = im2double(imread(input_path));
fillRegion = im2double(imread(mask_path) > 0.5);

test = img;
test(fillRegion > 0.5) = 1;

%% run script

if(0)
    inpainting(img, fillRegion, out_path, f, gap)
else
    %% cropping for fast

    img_crop = img(1000:1000+w, 1000:1000+w, :);
    fillRegion_crop = fillRegion(1000:1000+w, 1000:1000+w, :);
    test_crop = test(1000:1000+w, 1000:1000+w, :);
    
    max(test_crop(:))
    size(test_crop)
    min(test_crop(:))
    
    return
    
    setting_name = ['_f', int2str(f), '_gap', int2str(gap) , '.bmp'];  
    
    nameout2 = [out_path, '_mask', setting_name];
    imwrite(uint8(test_crop*256),nameout2,'bmp');
    
    nameout3 = [out_path, '_img', setting_name];
    imwrite(uint8(img_crop*256),nameout3,'bmp');
    
    inpainting(img_crop, fillRegion_crop, out_path, f, gap)
  
end


