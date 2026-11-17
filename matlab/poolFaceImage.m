function featureRow = poolFaceImage(I)
% Convert one 640-by-640 RGB uint8 image to a row of 1,024 features.
% Each feature is the mean of one non-overlapping 20-by-20-by-3 block.

if ~isa(I, 'uint8') || size(I, 1) ~= 640 || size(I, 2) ~= 640 || ...
        size(I, 3) ~= 3 || ndims(I) ~= 3
    error('poolFaceImage:InvalidImage', ...
        'Input must be a 640-by-640 RGB uint8 image.');
end

scaledImage = double(I) / 255;
blocks = reshape(scaledImage, [20, 32, 20, 32, 3]);
pooledGrid = squeeze(mean(mean(mean(blocks, 1), 3), 5));

% MATLAB stores columns first; transpose before linearizing for row-major order.
rowMajorGrid = pooledGrid.';
featureRow = rowMajorGrid(:).';
end
