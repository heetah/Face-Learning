function I = readFaceImage(filePath)
% One acceptance check shared by the image preflight and package builder.
try
    info = imfinfo(filePath);
    if numel(info) ~= 1 || info.Height ~= 640 || info.Width ~= 640 || ...
            ~strcmpi(info.ColorType, 'truecolor') || info.BitDepth ~= 24
        error('FaceLab:InvalidImageMetadata', 'Unexpected image metadata.');
    end
    I = imread(filePath);
    if ~isa(I, 'uint8') || ~isequal(size(I), [640, 640, 3])
        error('FaceLab:InvalidImageArray', 'Unexpected decoded image format.');
    end
catch
    error('FaceLab:InvalidFaceImage', ...
        'An image is unreadable or is not 640-by-640 8-bit RGB.');
end
end
