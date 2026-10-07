% Supervised approach, feature extraction (report section 5, Appendix A-3).
% Unfinished work: SLIC superpixels and a Gabor filter response per image,
% mean colour and Gabor features per superpixel, and a "same segment" label
% for every superpixel pair, saved to results/ for supervised_logreg.m.

clear
clc

root = fileparts(fileparts(mfilename('fullpath')));   % repository root
resultsDir = fullfile(root, 'results');
if ~isfolder(resultsDir), mkdir(resultsDir); end

trainImagePath = fullfile(root, 'data', 'images', 'train');
trainGtPath = fullfile(root, 'data', 'groundTruth', 'train');
    
imageFiles = dir(fullfile(trainImagePath, '*.jpg'));
numImages = length(imageFiles);

numSuperpixels = 10; 
compactness = 20;    
numIterations = 10;  
wavelength = 2;     
orientation = 90;   

allFeatures = [];
allLabels = [];

for i = 1:numImages
    imagePath = fullfile(trainImagePath, imageFiles(i).name);
    A = imread(imagePath);

    % SLIC 
    [L, N] = superpixels(A, numSuperpixels, 'Compactness', compactness, 'NumIterations', numIterations);

     % Gabor Feature Extraction
    gaborMag = imgaborfilt(rgb2gray(A), wavelength, orientation);

    outputImage = zeros(size(A), 'like', A);
    idx = label2idx(L);
    numRows = size(A, 1);
    numCols = size(A, 2);
    numChannels = size(A, 3); % RGB image

    features = zeros(N, 4); % For RGB and Gabor features

    for labelVal = 1:N

        superpixelIndices = idx{labelVal};
        red = A(superpixelIndices);
        green = A(superpixelIndices + numRows*numCols);
        blue = A(superpixelIndices + 2*numRows*numCols);
        gaborResponses = gaborMag(superpixelIndices);

        features(labelVal, 1) = mean(red); % Mean R
        features(labelVal, 2) = mean(green); % Mean G
        features(labelVal, 3) = mean(blue); % Mean B

        for ch = 1:numChannels
        channelIdx = idx{labelVal} + (ch-1) * numRows * numCols;
        outputImage(channelIdx) = mean(A(channelIdx));
        end

    end



    gtPath = fullfile(trainGtPath, replace(imageFiles(i).name, '.jpg', '.mat'));
    gtData = load(gtPath);
    gtLabelMatrix = groundTruthToLabelMatrix(gtData.groundTruth);

    for p = 1:N
        for q = p + 1:N
            featureVector = [features(p, :), features(q, :)];
            label = (gtLabelMatrix(p) == gtLabelMatrix(q));
            allFeatures = [allFeatures; featureVector];
            allLabels = [allLabels; label];
        end
    end

    features = zeros(N, 4); % For RGB and Gabor features

    BW = boundarymask(L);

    % Overlay the superpixel boundaries on the Gabor-filtered image
    combinedOutput = imoverlay(mat2gray(gaborMag), BW, [1 0 0]); % Overlay in red


    for labelVal = 1:N
        superpixelIndices = idx{labelVal};
        % Extract RGB values for the current superpixel
        R = A(superpixelIndices);
        G = A(superpixelIndices + numRows*numCols);
        B = A(superpixelIndices + 2*numRows*numCols);
        
        % RGB Features: Mean color within superpixel
        features(labelVal, 1) = mean(R); % Mean R
        features(labelVal, 2) = mean(G); % Mean G
        features(labelVal, 3) = mean(B); % Mean B
        
        % Edge Features: Mean Gabor response within superpixel
         gaborResponses = gaborMag(superpixelIndices);
        features(labelVal, 4) = mean(gaborResponses);
    end
    

  %%  
    % Display for the first three images
    if i <= 3
        gtPath = fullfile(trainGtPath, replace(imageFiles(i).name, '.jpg', '.mat'));
        gtData = load(gtPath);
        gtImage = label2rgb(groundTruthToLabelMatrix(gtData.groundTruth));

        figure;
        subplot(1, 5, 1);
        imshow(A);
        title('Original Image');
        
        subplot(1, 5, 2);
        imshow(outputImage, 'InitialMagnification', 67);
        title('Mean Color Superpixels');

        subplot(1, 5, 3);
        imshow(gtImage);
        title('Ground Truth');

        subplot(1, 5, 4);
        imshow(gaborMag(:,:,1), []); % Display the magnitude response of the first Gabor filter
        title('Gabor Filter Response');

        subplot(1, 5, 5);
        imshow(combinedOutput);
        title('Combined Superpixels and Gabor');

    end
end

save(fullfile(resultsDir, 'processed_train.mat'), 'allFeatures', 'allLabels');


%%
valImagePath = fullfile(root, 'data', 'images', 'val');
valGtPath = fullfile(root, 'data', 'groundTruth', 'val');
testImagePath = fullfile(root, 'data', 'images', 'test');
testGtPath = fullfile(root, 'data', 'groundTruth', 'test');

[valFeatures, valLabels] = processImages(valImagePath, valGtPath, numSuperpixels, compactness, numIterations, wavelength, orientation);
save(fullfile(resultsDir, 'processed_val.mat'), 'valFeatures', 'valLabels');

[valFeatures, valLabels] = processImages(valImagePath, valGtPath, numSuperpixels, compactness, numIterations, wavelength, orientation);
save(fullfile(resultsDir, 'processed_val.mat'), 'valFeatures', 'valLabels');

[testFeatures, testLabels] = processImages(testImagePath, testGtPath, numSuperpixels, compactness, numIterations, wavelength, orientation);
save(fullfile(resultsDir, 'processed_test.mat'), 'testFeatures', 'testLabels');

[trainGtFeatures, trainGtLabels] = processGT(trainGtPath, numSuperpixels, wavelength, orientation);
save(fullfile(resultsDir, 'processedGT_train.mat'), 'trainGtFeatures', 'trainGtLabels');

[valGtFeatures, valGtLabels] = processGT(valGtPath, numSuperpixels, wavelength, orientation);
save(fullfile(resultsDir, 'processedGT_val.mat'), 'valGtFeatures', 'valGtLabels');

[testGtFeatures, testGtLabels] = processGT(testGtPath, numSuperpixels, wavelength, orientation);
save(fullfile(resultsDir, 'processedGT_test.mat'), 'testGtFeatures', 'testGtLabels');


function [features, labels] = processImages(imagePath, gtPath, numSuperpixels, compactness, numIterations, wavelength, orientation)
    imageFiles = dir(fullfile(imagePath, '*.jpg'));
    numImages = length(imageFiles);
    allFeatures = [];
    allLabels = [];

    for i = 1:numImages
        imgPath = fullfile(imagePath, imageFiles(i).name);
        A = imread(imgPath);

        [L, N] = superpixels(A, numSuperpixels, 'Compactness', compactness, 'NumIterations', numIterations);

        gaborMag = imgaborfilt(rgb2gray(A), wavelength, orientation);

        features = zeros(N, 4); % Assuming 4 features (RGB and Gabor)

        idx = label2idx(L);
        numRows = size(A, 1);
        numCols = size(A, 2);
        for labelVal = 1:N
            redIdx = idx{labelVal};
            greenIdx = idx{labelVal} + numRows*numCols;
            blueIdx = idx{labelVal} + 2*numRows*numCols;
            gaborResponses = gaborMag(idx{labelVal});

            features(labelVal, :) = [mean(A(redIdx)), mean(A(greenIdx)), mean(A(blueIdx)), mean(gaborResponses)];
        end

        gtFile = fullfile(gtPath, replace(imageFiles(i).name, '.jpg', '.mat'));
        gtData = load(gtFile);
        gtLabelMatrix = groundTruthToLabelMatrix(gtData.groundTruth);

        for p = 1:N
            for q = p + 1:N
                featureVector = [features(p, :), features(q, :)];
                label = (gtLabelMatrix(p) == gtLabelMatrix(q));
                allFeatures = [allFeatures; featureVector];
                allLabels = [allLabels; label];
            end
        end
    end

    features = allFeatures;
    labels = allLabels;
end

function labelMatrix = groundTruthToLabelMatrix(groundTruth)
    labelMatrix = groundTruth{1}.Segmentation;
end



function [gtFeatures, gtLabels] = processGT(gtPath, numSuperpixels, wavelength, orientation)
    gtFiles = dir(fullfile(gtPath, '*.mat'));
    numGTImages = length(gtFiles);
    allGtFeatures = [];
    allGtLabels = [];

    for i = 1:numGTImages
        % Load ground truth
        gtFilePath = fullfile(gtPath, gtFiles(i).name);
        gtData = load(gtFilePath);
        gtMatrix = gtData.groundTruth; % Assuming groundTruth is the variable name in the .mat file

        % Similar to processImages, apply SLIC and Gabor filters
        % Assume gtMatrix is an image-like matrix
        [L, N] = superpixels(gtMatrix, numSuperpixels, 'Compactness', 20, 'NumIterations', 10);
        gaborMag = imgaborfilt(gtMatrix, wavelength, orientation);

        gtFeatures = zeros(N, 4);

        idx = label2idx(L);
        for labelVal = 1:N
            superpixelIndices = idx{labelVal};
            gaborResponses = gaborMag(superpixelIndices);
            gtFeatures(labelVal, :) = [mean(superpixelIndices), mean(gaborResponses)];
        end

        gtLabels = ones(N, 1);

        allGtFeatures = [allGtFeatures; gtFeatures];
        allGtLabels = [allGtLabels; gtLabels];
    end

    % Output
    gtFeatures = allGtFeatures;
    gtLabels = allGtLabels;
end

