% Elbow method, average within-cluster variance for K = 1 ... 10 (report Appendix A-1).
% Each test image is flattened to one column of RGB values and clustered.

path = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'data');   % repository data folder
imgDir = fullfile('images', 'test');

D = dir(fullfile(path, imgDir,'*.jpg'));

K_values = 1:10; % K 
variances = zeros(size(K_values));

for k = K_values
    fprintf('Testing K = %d\n', k);
    
   
    variance_k = 0;
    count_k = 0;

    for i = 1:numel(D)
       
        img = imread(fullfile(path, imgDir, D(i).name));
        
        % Convert image data into a list of points for clustering
        % Assuming image is grayscale; if it's color, you need to reshape it to be Mx3 where M is the number of pixels
        img_points = double(reshape(img, [], 1));
        
        
        [idx, C] = kmeans(img_points, k, 'EmptyAction', 'drop');
        
      
        for j = 1:k
            cluster_points = img_points(idx == j);
            if ~isempty(cluster_points) % Check if cluster is not empty
                variance_k = variance_k + var(cluster_points);
                count_k = count_k + 1; % Count non-empty clusters
            end
        end
    end
    
   
    variances(k) = variance_k / count_k;
end

% Plot the variance 
figure;
plot(K_values, variances, '-o');
title('Variance vs Number of Clusters');
xlabel('Number of clusters (K)');
ylabel('Average Within-cluster Variance');
grid on;
