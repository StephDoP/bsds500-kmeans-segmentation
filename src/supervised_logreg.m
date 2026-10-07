% Supervised approach, classifier stub (report section 5): logistic regression
% on the superpixel-pair features written by slic_gabor_features.m. Unfinished:
% it trains and predicts but never scores the validation predictions.

clear; clc;

resultsDir = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'results');

% Load processed training data
load(fullfile(resultsDir, 'processed_train.mat')); % Loads allFeatures and allLabels from training data
load(fullfile(resultsDir, 'processed_val.mat'));   % Loads valFeatures and valLabels from validation data

% Train logistic regression model on full training data
X_train = allFeatures;
y_train = allLabels;
y_train_lr = categorical(y_train);
mdl = mnrfit(X_train, y_train_lr);

% Predict on validation data
probabilities_val = mnrval(mdl, valFeatures);
predictedLabels_val = probabilities_val(:, 2) > 0.5;

% Define the path to the validation ground truth .mat file
valGtPath = fullfile(fileparts(resultsDir), 'data', 'groundTruth', 'val');
