function kmeans_segmentation()
% K-means segmentation of the BSDS500 test set (report section 4, Appendix A-2).
% Each pixel is described by (R, G, B, x, y), all scaled to [0, 1], and
% clustered with k = 3 ... 7. Every segmentation is scored against the first
% human ground truth; mean precision, recall and F1 are printed per k, then
% three random test images are shown with their segmentations.
% Requires the Statistics and Machine Learning Toolbox and the Image
% Processing Toolbox. Runtime: about 20 min for the 200 test images.

root = fileparts(fileparts(mfilename('fullpath')));   % repository root
testImagePath = fullfile(root, 'data', 'images', 'test');
testGtPath = fullfile(root, 'data', 'groundTruth', 'test');


[testImages, testGtImages] = loadImagesAndGT(testImagePath, testGtPath);


precisionScores = zeros(5, numel(testImages));
recallScores = zeros(5, numel(testImages));
f1Scores = zeros(5, numel(testImages));


for k = 3:7
    for i = 1:numel(testImages)
        segmentedImg = applyKMeansToImage(testImages{i}, k);
        [precision, recall, f1] = calculateMetrics(segmentedImg, testGtImages{i});
        precisionScores(k-2, i) = precision;
        recallScores(k-2, i) = recall;
        f1Scores(k-2, i) = f1;
    end
end


meanPrecision = mean(precisionScores, 2)';
meanRecall = mean(recallScores, 2)';
meanF1 = mean(f1Scores, 2)';
metricsMatrix = [meanPrecision; meanRecall; meanF1];
rowNames = {'Precision', 'Recall', 'F1'};
colNames = arrayfun(@(k) ['k=' num2str(k)], 3:7, 'UniformOutput', false);
metricsTable = array2table(metricsMatrix, 'RowNames', rowNames, 'VariableNames', colNames);

disp(metricsTable);


for k = 3:7
    figure;
    plot(precisionScores(k-2, :), recallScores(k-2, :), 'bo');
    title(['Precision vs Recall for k = ', num2str(k)]);
    xlabel('Precision');
    ylabel('Recall');
    axis([0 1 0 1]);
    grid on;
end


disp('F1 Scores for each k:');
disp(array2table(mean(f1Scores, 2)', 'VariableNames', {'k3', 'k4', 'k5', 'k6', 'k7'}));


indicesToDisplay = randperm(numel(testImages), 3);
for idx = indicesToDisplay
    img = testImages{idx};
    gt = testGtImages{idx};
    imgName = ['Test Image ', num2str(idx)];

    
    displayImageAndGT(img, gt, imgName);
    plotRGBFeatureSpace(img, imgName);
    displaySegmentations(img, 3:7, imgName);
end

end


function [images, gtImages] = loadImagesAndGT(imageDir, gtDir)
    imageFiles = dir(fullfile(imageDir, '*.jpg'));
    gtFiles = dir(fullfile(gtDir, '*.mat'));
    numImages = numel(imageFiles);
    images = cell(1, numImages);
    gtImages = cell(1, numImages);

    for i = 1:numImages
        images{i} = imread(fullfile(imageDir, imageFiles(i).name));
        gtData = load(fullfile(gtDir, gtFiles(i).name));
        gtImages{i} = gtData.groundTruth{1}.Segmentation;
    end
end


function displayImageAndGT(image, gt, titleText)
    figure;
    subplot(1,2,1); imshow(image); title([titleText ' - Original']);
    subplot(1,2,2); imshow(label2rgb(gt)); title([titleText ' - Ground Truth']);
end

function plotRGBFeatureSpace(img, imgName)
    r = img(:,:,1); g = img(:,:,2); b = img(:,:,3);
    figure('Name', [imgName, ' - RGB Feature Space'], 'NumberTitle', 'off');
    scatter3(r(:), g(:), b(:), 1, [r(:)/255, g(:)/255, b(:)/255], '.');
    title(['RGB Feature Space - ', imgName]);
    xlabel('Red'); ylabel('Green'); zlabel('Blue');
    grid on; axis tight;
end



function displaySegmentations(img, kRange, imgName)
    figure('Name', [imgName, ' - Segmentations'], 'NumberTitle', 'off');
    for k = kRange
        segmentedImg = applyKMeansToImage(img, k);
        subplot(1, length(kRange), k-min(kRange)+1), imshow(label2rgb(segmentedImg)), title(['k=', num2str(k)]);
    end
end


function segmentedImg = applyKMeansToImage(img, k)
    [rows, cols, ~] = size(img);
    imgReshaped = double(reshape(img, rows * cols, 3));

    
    imgNormalized = imgReshaped / 255;
    
   
    [x, y] = meshgrid(1:cols, 1:rows);
    xNormalized = x(:) / cols;
    yNormalized = y(:) / rows;

    features = [imgNormalized, xNormalized, yNormalized];

    % Apply k-means clustering
    [clusterIdx, ~] = kmeans(features, k, 'MaxIter', 1000, 'Replicates', 3);
    segmentedImg = reshape(clusterIdx, rows, cols);
end

function [precision, recall, f1] = calculateMetrics(segmentedImg, groundTruth)
    binarySegmented = segmentedImg > 1;  
    binaryGroundTruth = groundTruth > 1; 

    TP = sum((binarySegmented == 1) & (binaryGroundTruth == 1), 'all');
    FP = sum((binarySegmented == 1) & (binaryGroundTruth == 0), 'all');
    FN = sum((binarySegmented == 0) & (binaryGroundTruth == 1), 'all');

    precision = TP / (TP + FP);
    recall = TP / (TP + FN);

    if isnan(precision), precision = 0; end
    if isnan(recall), recall = 0; end

    if (precision + recall) == 0
        f1 = 0;
    else
        f1 = 2 * (precision * recall) / (precision + recall);
    end
end

