% this script is used to test the algorithm to be implemented in the
% function interpParam with a real image.

clear all;
image = double(imread('../data-subset/18.jpg'));
imsize = size(image);
nb_color  = 3;
nb_region = 3;
red = 1; blue = 2; green = 3;

%% gradient / regions
threshold = 10; % threshold to be considered in a certain region
regions = generateRegions(image, threshold);
% regions: 1 = horizontal gradient, 2 = vertical gradient, 3 = smooth 

%% generating A and b
raw = generateRaw(patternCFA(1), image); %TODO implement other CFA patterns
filter_len = 7; % filter is of size filter_len x filter_len
offset = (filter_len-1)/2;
 
% Matrices A, b cannot include whole image for SVD, first must take sub images.
step = 500;
sub_image   = image  (2*step:3*step, 2*step:3*step, :);
sub_raw     = raw    (2*step:3*step, 2*step:3*step, :);
sub_regions = regions(2*step:3*step, 2*step:3*step, :);

A = cell(nb_color, nb_region);
b = cell(nb_color, nb_region);
empty_flag = zeros(nb_color, nb_region);

for i = 1:nb_color
    for j = 1:nb_region
        [A{i,j}, b{i,j}, empty_flag(i,j)] = generateAb(sub_image, sub_raw, sub_regions, j, i, filter_len); 
    end
end

%% Solving Ax = b
% Minimal solution to equation using SVD and LS
x_svd = cell(nb_color, nb_region);
x_ls  = cell(nb_color, nb_region);

for i = 1:nb_color
    for j = 1:nb_region
        if(empty_flag(i,j) == 1); continue; end;
        x_ls{i,j}  = solveAb(A{i,j}, b{i,j}, filter_len, 'ls');
%       x_svd{i,j} = solveAb(A{i,j}, b{i,j}, filter_len, 'svd');
    end
end

%% Interpolation
% interpolated image given by b_est = Ax

image_interp = linInterp(raw, regions, empty_flag, x_ls);
% some problems with SVD because of small sample to compute coeff
% but overall seems to work ok.
image_trunc  = image(1+offset:end-offset, 1+offset:end-offset, :);
MSE = immse(image_interp, image_trunc);

