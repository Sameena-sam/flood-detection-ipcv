clc;
clear;
close all;


mask_folder = fullfile(pwd, 'Mask');

[filename, pathname] = uigetfile({'*.jpg;*.png;*.jpeg'}, 'Select an Image');

if isequal(filename,0) || isequal(pathname,0)
    disp('No image selected');
    return;
end

img_path = fullfile(pathname, filename);


disp(['Selected file: ', img_path]);


if ~isfile(img_path)
    error('File does not exist or path is invalid.');
end


try
    img = imread(img_path);
catch
    error('Failed to read image. Try another image.');
end

figure('Name','Flood Detection Pipeline','NumberTitle','off');

subplot(3,4,1);
imshow(img);
title('Original Image');

%% PREPROCESS 
img_blur = imgaussfilt(img, 2);

subplot(3,4,2);
imshow(img_blur);
title('Gaussian Blur');

%% EDGE DETECTION
edges = edge(rgb2gray(img_blur), 'Canny');

subplot(3,4,3);
imshow(edges);
title('Edge Detection');

%% HSV 
img_hsv = rgb2hsv(img_blur);
S = img_hsv(:,:,2);
V = img_hsv(:,:,3);

subplot(3,4,4);
imshow(S);
title('Saturation Channel');

%% ADAPTIVE THRESHOLD
S_thresh = graythresh(S);
V_thresh = graythresh(V);

mask1 = S < S_thresh;
mask2 = V > V_thresh;

mask = mask1 & mask2;

subplot(3,4,5);
imshow(mask);
title('Adaptive Threshold');

%% MORPHOLOGY
se = strel('disk',5);

mask_open = imopen(mask, se);
mask_close = imclose(mask_open, se);

subplot(3,4,6);
imshow(mask_close);
title('Morphology Clean');

%% REMOVE SMALL OBJECTS
mask_clean = bwareaopen(mask_close, 500);

subplot(3,4,7);
imshow(mask_clean);
title('Final Binary Mask (Segmentation)');

%% OVERLAY
overlay = img;

overlay(:,:,1) = img(:,:,1) + uint8(mask_clean)*255;
overlay(:,:,2) = img(:,:,2) .* uint8(~mask_clean);
overlay(:,:,3) = img(:,:,3) .* uint8(~mask_clean);

subplot(3,4,8);
imshow(overlay);
title('Flood Overlay');

%% LOAD GROUND TRUTH
[~, name, ~] = fileparts(filename);

possible_paths = {
    fullfile(mask_folder, [name '.jpg'])
    fullfile(mask_folder, [name '.png'])
};

gt_found = false;

for i = 1:length(possible_paths)
    if exist(possible_paths{i}, 'file')
        gt_path = possible_paths{i};
        gt_found = true;
        break;
    end
end

if gt_found

    gt = imread(gt_path);

    if size(gt,3) == 3
        gt = rgb2gray(gt);
    end

    gt = imbinarize(gt);
    gt = imresize(gt, size(mask_clean));

    subplot(3,4,9);
    imshow(gt);
    title('Ground Truth');

    subplot(3,4,10);
    imshow(mask_clean);
    title('Predicted Mask');

    %% METRICS 
    pred = logical(mask_clean);
    gt = logical(gt);

    TP = sum((pred == 1) & (gt == 1), 'all');
    TN = sum((pred == 0) & (gt == 0), 'all');
    FP = sum((pred == 1) & (gt == 0), 'all');
    FN = sum((pred == 0) & (gt == 1), 'all');

    accuracy = (TP + TN) / (TP + TN + FP + FN + eps);
    precision = TP / (TP + FP + eps);
    recall = TP / (TP + FN + eps);
    f1 = 2 * (precision * recall) / (precision + recall + eps);
    iou = TP / (TP + FP + FN + eps);
    dice = (2*TP) / (2*TP + FP + FN + eps);

    fprintf('\n===== PERFORMANCE METRICS =====\n');
    fprintf('Accuracy  : %.4f\n', accuracy);
    fprintf('Precision : %.4f\n', precision);
    fprintf('Recall    : %.4f\n', recall);
    fprintf('F1 Score  : %.4f\n', f1);
    fprintf('IoU       : %.4f\n', iou);
    fprintf('Dice      : %.4f\n', dice);

    %% ERROR MAP
    error_map = pred ~= gt;

    subplot(3,4,11);
    imshow(error_map);
    title('Error Map (White = Wrong)');

    %% COMPARISON
    comparison = imoverlay(img, gt, [0 1 0]); % GT = green
    comparison = imoverlay(comparison, pred, [1 0 0]); % Prediction = red

    subplot(3,4,12);
    imshow(comparison);
    title('GT (Green) vs Pred (Red)');

else
    disp('Ground truth mask NOT found (check filename match)');
end

%%  HELPER FUNCTION 
function out = imoverlay(img, mask, color)
    img = im2double(img);
    out = img;
    for i = 1:3
        channel = out(:,:,i);
        channel(mask) = color(i);
        out(:,:,i) = channel;
    end
end