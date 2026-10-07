% Elbow method, within-cluster sum of squares (WCSS) for K = 3 ... 20.
% Each test image is flattened to one column of RGB values and clustered.

% Path to the dataset
path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');   % repository data folder
imgDir = fullfile('images', 'test');

% Get list of images
D = dir(fullfile(path, imgDir,'*.jpg'));

% Initialize variables to store WCSS
K_values = 3:20; 
wcss = zeros(size(K_values));

% Loop over the number of clusters
for k = K_values
    fprintf('Testing K = %d\n', k);
    
    % Initialize WCSS for this K
    wcss_k = 0;
    
    % Loop over all images
    for i = 1:numel(D)
        % Read image
        img = imread(fullfile(path, imgDir, D(i).name));
        
        % Convert image data into a list of points for clustering
        % Assuming image is grayscale; if it's color, you need to reshape it to be Mx3 where M is the number of pixels
        img_points = double(reshape(img, [], 1));
        
        % Perform K-means clustering
        [idx, C] = kmeans(img_points, k, 'EmptyAction', 'drop');
        
        % Calculate sum of squared distances (WCSS) for each cluster
        for j = 1:k
            cluster_points = img_points(idx == j);
            if ~isempty(cluster_points) % Check if cluster is not empty
                wcss_k = wcss_k + sum((cluster_points - C(j)).^2);
            end
        end
    end
    
    % Store the WCSS for this K
    wcss(k-2) = wcss_k; % Adjust index for K_values range
end

% Create a table of WCSS values
wcssTable = array2table(wcss', 'VariableNames', {'WCSS'}, 'RowNames', arrayfun(@num2str, K_values, 'UniformOutput', false));

% Display WCSS table
disp(wcssTable);

% Plot the WCSS against K values
figure;
plot(K_values, wcss, '-o');
title('WCSS vs Number of Clusters');
xlabel('Number of clusters (K)');
ylabel('Within-cluster Sum of Squares (WCSS)');
grid on;
