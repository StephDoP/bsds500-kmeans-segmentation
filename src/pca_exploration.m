function pca_exploration()
% Exploratory PCA of whole images (not used in the report): every image is
% flattened to one row and the train, validation and test sets are each
% reduced to their first 100 principal components.
    root = fileparts(fileparts(mfilename('fullpath')));   % repository root
    trainImagePath = fullfile(root, 'data', 'images', 'train');

    valImagePath = fullfile(root, 'data', 'images', 'val');

    testImagePath = fullfile(root, 'data', 'images', 'test');

% Load, standardize, and apply PCA to each dataset
    [trainData, trainDataPCA] = loadAndApplyPCA(trainImagePath);
    [valData, valDataPCA] = loadAndApplyPCA(valImagePath);
    [testData, testDataPCA] = loadAndApplyPCA(testImagePath);

    % Save the PCA-transformed datasets
    % save('trainPCA.mat', 'trainDataPCA');
    % save('valPCA.mat', 'valDataPCA');
    % save('testPCA.mat', 'testDataPCA');

    % Visualize the first three PCA images from the training set
    visualizeOriginalAndPCAImages(trainImagePath, trainData, trainDataPCA);
end

function [dataMatrix, dataMatrixPCA] = loadAndApplyPCA(imagePath)
    % Load images from the given path and apply PCA
    imageFiles = dir(fullfile(imagePath, '*.jpg')); % Load JPG images
    numImages = length(imageFiles);
    
    if numImages == 0
        error('No image files found in the specified directory: %s', imagePath);
    end

    firstImage = imread(fullfile(imagePath, imageFiles(1).name));
    [rows, cols, channels] = size(firstImage);
    dataMatrix = zeros(numImages, rows*cols*channels);

    for i = 1:numImages
        img = imread(fullfile(imagePath, imageFiles(i).name));
        dataMatrix(i, :) = img(:)';
    end

    % Apply PCA
    [~, dataMatrixPCA, ~] = pca(dataMatrix, 'NumComponents', min(100, size(dataMatrix, 2)));
end

function visualizeOriginalAndPCAImages(imagePath, originalData, pcaData)
    % Visualize the first three original images and their PCA-transformed format
    imageFiles = dir(fullfile(imagePath, '*.jpg')); % Assuming the images are in JPG format
    numImages = length(imageFiles);
    if numImages < 3
        error('Less than 3 images in the dataset');
    end

    figure;
    for i = 1:3
        % Display original image
        originalImg = imread(fullfile(imagePath, imageFiles(i).name));
        subplot(3, 2, 2*i-1), imshow(originalImg), title(['Original Image ', num2str(i)]);

        % Display the PCA-transformed data as a plot
        pcaImg = pcaData(i, :);
        subplot(3, 2, 2*i), plot(pcaImg), title(['PCA Data ', num2str(i)]);
    end
end

