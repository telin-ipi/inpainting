function [f, gap] = inpaint_all(f, gap)
% inpaint all images found in 'output_folder'
% for default f can be set to 8 and gap to 6
%% settings

i_start = 1;    % default 1
i_end = 17;     % default 17

output_folder = '/ipi/research/lameeus/data/inpainting/inpainting_results/';

%% information

% f = 8;      % default is 8, 
% gap = 6;    % default is 6, 

%% start script

% Generate all the inpaintings

input_folder = '/home/lameeus/data/inpainting/';
mask_name = [input_folder, 'mask.bmp'];

fillRegion = im2double(imread(mask_name));

%imshow(fillRegion)

%shape = size(fillRegion)
%fillRegion = zeros(shape);

%fillRegion(200:220, 200:220) = 1.0;

% imshow(fillRegion)
% int('1')


for i = i_start : i_end
    
input_name = [input_folder, int2str(i), '_mask1.bmp'];

%% Own settings

setting_name = ['_f', int2str(f), '_gap', int2str(gap) , '.bmp'];
nameout = [output_folder, int2str(i), '_out', setting_name];
nameout1 = [output_folder, int2str(i), '_order', setting_name];
    
   
%% From content_aware_mrf_inpainting.m
    
img = im2double(imread(input_name));


fprintf('min block size f = %i\n', f)



bsmin = floor(size(fillRegion)./f);
bsmin = [bsmin(1) bsmin(2)];

img = img(1:bsmin(1)*f,1:bsmin(2)*f,:);                                     %size of the image and the mask is being modified
fillRegion = fillRegion(1:bsmin(1)*f,1:bsmin(2)*f);                         %these sizes are now equal and comprised of integer 
sourceRegion = 1-fillRegion;                                                %number od blocks

%DEFINIG PARAMETARS No.1
disp('Default parametars are: ');
disp('nTex = 18');
disp('orientationsPerScale = [6 6 6]');
disp('Ts = 0.15');
disp('Tb = 0.15');
disp('nGistMatches = 10');

nTex = 18;
orientationsPerScale = [6 6 6];
Ts = 0.15;
Tb = 0.15;
nGistMatches = 10;

r = 0.5;

%CALCULATING CONTEXTUAL DESCRIPTORS
disp('Contextual descriptors are being calculated i.e. mapTextons...');
[mapTextons, C, gfull] = textonGenerateContrastNorm ...
    (img,fillRegion,nTex,orientationsPerScale);

%DIVISON INTO BLOCKS OF ADAPTIVE SIZE
disp('Image is being decomposed into blocks of adaptive size...');
[allBlocks1,backupBlockPos,blocks] = decomposition_adaptive_blocksize...
    (img,fillRegion,mapTextons,nTex,bsmin,Ts,r);

%COMPUTING HISTOGRAM FOR INE TEXTURE FEATURE FOR EACH BLOCK
disp('computing histogram for one texture feature for each block...');
gstartTexton = textonHistBlock(mapTextons, ~fillRegion, allBlocks1, nTex);

%CALCULATING GIST MATCHES ONLY FOR BLOCKS THAT INTERSECT THE TARGET REGION
disp('Calculate gist matches only for blocks that intersect the target region');
[gmatchesTexton,nbrsTexton,gerrorsTexton] = gist_matches_all_adaptive_blocksize_weighted ...
    (gstartTexton, ~fillRegion, allBlocks1, nGistMatches, Tb); 

%DEFINIG PARAMETARS No.2
disp('Default parametars are: ');
disp('L = 10');
disp('ITER = 10');

L = int16(10);
ITER = 10;
fprintf('gap = %i\n', gap)

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



imwrite(target1,nameout,'bmp');

orderImg = show_order(img,sourceRegion,order,coordx,coordy,gap);

imwrite(uint8(orderImg),nameout1,'bmp');

end