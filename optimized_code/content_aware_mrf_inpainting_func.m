function [path_out_img, path_out_fill] = content_aware_mrf_inpainting_func(inpaintImg, inpaintMask, param_f, ...
     number_of_textons, orientations_per_scale , threshold_sim, constraind_source_region, ...
     number_of_labels, number_of_iterations, patch_size)
% ADDME: context-aware global MRF-based inpaintig method 
%
% function [path_out_img, path_out_fill] = content_aware_mrf_inpainting_func1(inpaintImg, inpaintMask, param_f, ...
%      number_of_textons, orientations_per_scale , threshold_sim, constraind_source_region, ...
%      number_of_labels, number_of_iterations, patch_size)
%
% parametars of the function:
%               in: inpaintImg               - name of original image 
%                                                enter as string inside '' with extention
%                   inpaintMask              - name of the mask
%                                                enter as strig inside '' with extention
%                   param_f                  - defining min image block
%                   number_of_textons        - nuber of textons 
%                   orientations_per_scale   - number of orientations over 3 scales
%                                               enter inside []
%                   threshold_sim            - if orientations per scale is:
%                                               [6 6 6] recommended value is 0.15
%                                               [8 8 8] recommended value is 0.2
%                   constraind_source_region - max number of blocks from where the patches are considerd
%                                               recommended value is 10
%                   number_of_labels         - number of labels kept after pruning 
%                                               recommended value is 10
%                   number_of_iterations     - recommended value is 10
%                   patch_size               - defined as gap = 2*gap+1 
%                                               recommended value is 6
%
% Image inpainting is an image processing task of filling in the missing
% Region in an image in a visually plausible way. First the user is asked to
% Load an image, which is going to be inpainted and the mask of the image.
% Next step is to employ contextual (textural) descriptors to guide and improve 
% The inpainting process. Contextual descriptors are normalized texton histograms 
% Computed from Gabor filter responses. Image is divided into regions based on 
% The context into blocks of adaptive size. This strategy is called top-down 
% Splitting procedure, which is based on contextual descriptors. Inpainting is
% MRF-based.
% 
% Based on the following paper:
% T. Ružic and A. Pižurica, “Context-aware patch-based image inpainting using Markov random field modeling,” 
% IEEE Transactions on Image Processing, vol. 24, no. 1, pp. 444-456, Jan 2015
% 
% Code written by PhD Tijana Ruzic
% Code optimized and made more user-friendly by student Mihailo Drljaca

%
% Define variables:
%       img                  - original image 
%       fillRegion           - mask of the image i.e.
%                               specifies the region that is going to be inpainted
%       sourceRegion         - complement of fillRegion i.e.
%                               specifies the region that is known and from
%                               where patches are being taken
%       f                    - defining min image block i.e. 
%                               width and length are divided by f to get 
%                               minimmum width and length of the image block
%       bsmin                - contains min block size
%       nTex                 - number of textons
%                                defind as a number of clusters in which partitions od points in data matrix are stored (kmeans function)
%                                used while calculating contextual descriptors,
%                                while decomposing image into blocks of adaptive size
%                                while calculating histogram for one texture  feature for each block
%       orientationsPerScale - number of orientations over 3 scales 
%                               used while calculating contextual descriptors
%       Ts                   - block similarity threshold (decomposing image)
%                               used while decomposing image into blocks of adaptive size
%       Tb                   - block similarity threshold (context aware patch selection)
%                               used while calculating gist matches only for blocks that intersect the target region
%                               while calculating cell array of structures that represent nodes with fields
%                               while calculating Tuncertain
%       nGistMatches         - max number of blocks from where the patches are considerd (max size of constraind source region)
%                               used while calculating gist matches only for blocks that intersect the target region
%       L                    - number of labels kept after pruning 
%                               used while keeping track of positions of the possible labels not the actual patches in the source region
%                               i.e. label pruning
%       ITER                 - number of iterations
%                               used while calculating most likely labels for each node in the MRF inpainting algorithm
%       gap                  - determines the patch size as 2*gap+1 
%       pot                  - 4-D matrix (nnodes x nneighbours x nlabels x nlabels) containing pairwise potentials 
%                               between all pairs of nodes in the network, thus also spatially varying 
%       cost                 - label cost
%                               measures the agreement of a node with its labels
%       loc                  - nnodes x nlabels matrix containing local measurements for each node
%       nnodes               - number of nodes in the MRF
%       nlabels              - number of possible labels for each node of a MRF.
%       initMask             - initial mask obtained by maximizing the likelihood loc
%       target1              - original missing region filled with patches
%       nameout              - inpainted image
%       nameout1             - image of filling order, darker regions were inpainted first


%ADDIND PATH TO THE FOLDER WITH IMAGES
img_path = input('Enter the path of the image: ','s');
addpath(img_path);

%LOADING IMAGE THAT IS GOING TO BE INPAINTED

img = inpaintImg;
fillRegion = inpaintMask;


% img = input('Enter the name of the picture with the extention: ','s');
% fillRegion = input('Enter the name of the mask with the extention: ','s');

img = im2double(imread(img));
fillRegion = im2double(imread(fillRegion));

figure(1);
subplot(1,2,1);
imshow(img);
title('Original image');
subplot(1,2,2);
imshow(fillRegion);
title('Mask of the image');

%DEFINING MINIMUM IMAGE BLOCK
f = param_f;

bsmin = floor(size(fillRegion)./f);
bsmin = [bsmin(1) bsmin(2)];

img = img(1:bsmin(1)*f,1:bsmin(2)*f,:);                                     %size of the image and the mask is being modified
fillRegion = fillRegion(1:bsmin(1)*f,1:bsmin(2)*f);                         %these sizes are now equal and comprised of integer 
sourceRegion = 1-fillRegion;                                                %number od blocks

figure(2);
subplot(1,2,1);
imshow(fillRegion);
title('Fill Region');
subplot(1,2,2);
imshow(sourceRegion);
title('Source Region');

%DEFINIG PARAMETARS No.1
nTex = number_of_textons;
orientationsPerScale = orientations_per_scale; 
Ts = threshold_sim;
Tb = threshold_sim;
 nGistMatches = constraind_source_region;

r = 0.5;

%CALCULATING CONTEXTUAL DESCRIPTORS
disp('Contextual descriptors are being calculated i.e. mapTextons...');
[mapTextons, C, gfull] = textonGenerateContrastNorm ...
    (img,fillRegion,nTex,orientationsPerScale);

%DIVISON INTO BLOCKS OF ADAPTIVE SIZE
disp('Image is being decomposed into blocks of adaptive size...');
[allBlocks1,backupBlockPos,blocks] = decomposition_adaptive_blocksize...
    (img,fillRegion,mapTextons,nTex,bsmin,Ts,r);

figure(3);
imshow(blocks);
title('Decomposed image into blocks of adaptive size...');
       
%COMPUTING HISTOGRAM FOR INE TEXTURE FEATURE FOR EACH BLOCK
disp('computing histogram for one texture feature for each block...');
gstartTexton = textonHistBlock(mapTextons, ~fillRegion, allBlocks1, nTex);

%CALCULATING GIST MATCHES ONLY FOR BLOCKS THAT INTERSECT THE TARGET REGION
disp('Calculate gist matches only for blocks that intersect the target region');
[gmatchesTexton,nbrsTexton,gerrorsTexton] = gist_matches_all_adaptive_blocksize_weighted ...
    (gstartTexton, ~fillRegion, allBlocks1, nGistMatches, Tb); 

%DEFINIG PARAMETARS No.2
L = int16(number_of_labels);
ITER = number_of_iterations;
gap = patch_size;

Tsim = 9.3707;
Tuncertain = 4.6854 * exp(-2*Tb);

%FINDING LABEL POSITION
disp('Finding label position...');
tic;
labBlock = find_label_pos_per_adaptive_block_overlap(sourceRegion, gap, allBlocks1);
T2 = toc;


%EFFICIENT ENERGY OPTIMIZATION STEP 1
%ASSIGNING PRIORITIES TO MRF NODES 
disp('Efficient energy optimization step 1(initialization)...');
tic;
[coordy, coordx, priority, labels, diff, diff_ssd, nrLabelsPerBlock, nodeDblock] = ... 
    comp_data_gist_ver4_adaptive_scaled_weighted(img, sourceRegion, labBlock, ...
    gmatchesTexton, Tuncertain, Tb, gap, allBlocks1, gerrorsTexton);
T3 = toc;

%EFFICIENT ENERGY OPTIMIZATION STEP 2
%LABEL PRUNING
disp('Efficient energy optimization step 2(label pruning)...');
tic;
[labelsNew, order, priorityNew] = label_extraction_gist_weighted ...
    (img, sourceRegion, coordy, coordx, priority, diff, diff_ssd, labels, ...
    nrLabelsPerBlock, nodeDblock, L, Tsim, Tuncertain, gap);
T4 = toc;

%COMPUTING PAIRWISE POTENTIAL MATRIX Vjk(xj,xk)
disp('Computing the pairwise potential matrix Vjk(xj,xk)...');
tic;
pot = compute_pot_art(img, coordy, coordx, labelsNew, gap);

%COMPUTING LABEL COST Vi(xi)
disp('Computing the label cost Vi(xi)...');
cost = compute_cost_art(img, sourceRegion, coordy, coordx, labelsNew, gap);
loc = exp(-cost);
[max_value, InitMask] = max(loc,[],2);

%EFFICIENT ENERGY OPTIMIZATION STEP 3
%NEIGBOURHOOD-CONSENSUS MESSAGE PASSING(NCPM)
disp('Efficient energy optimization step 3(neighbourhood-consensus message passing)...');
[beliefs, OutMask, iter] = NCMP(loc, pot, InitMask, coordx, coordy, gap, ITER);
T5 = toc;

%PROCESS ORIGINAL MISSING REGION FILLED WITH PATCHES 
disp('Processing original missing region filled with patches...');
target1 = output_art_mincut(OutMask, labelsNew, order, coordy, coordx, img, sourceRegion, gap);

%GIVING THE NAME TO THE INPAINTED IMAGE
img_out_path = input('Enter the path of the out image: ','s');
addpath(img_out_path);
img_out_path = strcat(img_out_path,'/');

nameout = input('Enter the name of the inpainted image with the extention: ','s');
nameout = strcat(img_out_path,nameout);
imwrite(target1,nameout,'bmp');


orderImg = show_order(img,sourceRegion,order,coordx,coordy,gap);            
nameout1 = input('Enter the name of the filling order image with the extention: ','s');
nameout1 = strcat(img_out_path,nameout1);
imwrite(uint8(orderImg),nameout1,'bmp');

figure(4);
subplot(1,3,1);
imshow(img);
title('Original image');
subplot(1,3,2);
imshow(nameout);
title('Inpainted image');
subplot(1,3,3);
imshow(nameout1);
title('Filling order');

path_out_img =nameout;
path_out_fill = nameout1;