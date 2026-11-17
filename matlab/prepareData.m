function prepareData
% Build A's private train_dataset.mat from the approved training PNG folder.
% The source images, filename map, and MAT package remain in a private folder.

fprintf('Face-Learning training package builder\n');
fprintf('Choose the folder that directly contains the 200 PNG files.\n');
trainRoot = uigetdir(pwd, 'Select the folder containing training PNG files');
if isequal(trainRoot, 0)
    fprintf('No input folder selected. Nothing was created.\n');
    return;
end

files = dir(fullfile(trainRoot, '*.png'));
if numel(files) ~= 200
    error('prepareData:WrongImageCount', ...
        'Expected 200 PNG files directly in the selected folder; found %d.', ...
        numel(files));
end

names = {files.name};
tokens = regexp(names, '^(man|woman)_([^_]+)_([^_]+)\.png$', 'tokens', 'once');
validName = ~cellfun('isempty', tokens);
if ~all(validName)
    error('prepareData:InvalidFilename', ...
        'Some filenames do not match class_group_image.png. No package was created.');
end

labelsText = cell(1, numel(files));
groupKeys = cell(1, numel(files));
for k = 1:numel(files)
    parsed = tokens{k};
    labelsText{k} = parsed{1};
    groupKeys{k} = [parsed{1}, '_', parsed{2}];
end

% Fixed row order: class man then woman, with case-sensitive filename sorting.
manRows = find(strcmp(labelsText, 'man'));
womanRows = find(strcmp(labelsText, 'woman'));
[~, manOrder] = sort(names(manRows));
[~, womanOrder] = sort(names(womanRows));
order = [manRows(manOrder), womanRows(womanOrder)];
files = files(order);
names = names(order);
labelsText = labelsText(order);
groupKeys = groupKeys(order);

classCounts = [sum(strcmp(labelsText, 'man')), sum(strcmp(labelsText, 'woman'))];
if any(classCounts ~= 100)
    error('prepareData:WrongClassBalance', ...
        'Expected 100 man and 100 woman images; found %d and %d.', ...
        classCounts(1), classCounts(2));
end

uniqueGroupKeys = {};
groupIndex = zeros(1, numel(groupKeys));
for k = 1:numel(groupKeys)
    found = find(strcmp(uniqueGroupKeys, groupKeys{k}), 1);
    if isempty(found)
        uniqueGroupKeys{end + 1} = groupKeys{k}; %#ok<AGROW>
        found = numel(uniqueGroupKeys);
    end
    groupIndex(k) = found;
end
groupSizes = accumarray(groupIndex(:), 1);
if numel(uniqueGroupKeys) ~= 100 || any(groupSizes ~= 2)
    error('prepareData:InvalidGroups', ...
        'Expected 100 filename groups with exactly 2 images each. No package was created.');
end
for classIndex = 1:2
    className = {'man', 'woman'};
    classGroupCount = numel(unique(groupIndex(strcmp(labelsText, className{classIndex}))));
    if classGroupCount ~= 50
        error('prepareData:InvalidClassGroups', ...
            'Expected 50 filename groups per class. No package was created.');
    end
end

sampleID = cell(numel(files), 1);
groupID = cell(numel(files), 1);
for k = 1:numel(files)
    sampleID{k} = sprintf('S%04d', k);
    groupID{k} = sprintf('G%04d', groupIndex(k));
end

X = zeros(200, 1024, 'double');
height = zeros(200, 1);
width = zeros(200, 1);
bitDepth = zeros(200, 1);
for k = 1:numel(files)
    filePath = fullfile(trainRoot, files(k).name);
    try
        info = imfinfo(filePath);
        if info.Height ~= 640 || info.Width ~= 640 || ...
                ~strcmpi(info.ColorType, 'truecolor') || info.BitDepth ~= 24
            error('prepareData:InvalidImageFormat', ...
                'Image format check failed.');
        end
        I = imread(filePath);
        X(k, :) = poolFaceImage(I);
    catch
        error('prepareData:ImageCheckFailed', ...
            'An image failed the 640-by-640 8-bit RGB read check. No package was created; inspect the source folder locally.');
    end
    height(k) = info.Height;
    width(k) = info.Width;
    bitDepth(k) = info.BitDepth;
end

y = categorical(labelsText(:), {'man', 'woman'});
if ~isequal(size(X), [200, 1024]) || numel(y) ~= 200 || ...
        any(~isfinite(X(:))) || any(X(:) < 0) || any(X(:) > 1)
    error('prepareData:PackageValidationFailed', ...
        'Feature package validation failed. No package was created.');
end

preprocessSpec = struct( ...
    'version', 'FaceLab-preprocess-v1.1', ...
    'inputHeight', 640, ...
    'inputWidth', 640, ...
    'inputChannels', 3, ...
    'inputBitDepth', 8, ...
    'pixelScaling', 'double(I) / 255', ...
    'poolingBlockHeight', 20, ...
    'poolingBlockWidth', 20, ...
    'outputGridHeight', 32, ...
    'outputGridWidth', 32, ...
    'channelAggregation', 'mean over all RGB values in each block', ...
    'flattenOrder', 'row-major', ...
    'featureCount', 1024);

fprintf('\nPackage checks passed: X is 200 x 1024, labels are balanced, and features are finite in [0,1].\n');
fprintf('Choose an approved PRIVATE output folder outside the public GitHub repository.\n');
outputRoot = uigetdir(pwd, 'Select a PRIVATE folder for the data package');
if isequal(outputRoot, 0)
    fprintf('No output folder selected. No files were created.\n');
    return;
end

confirmPrivate = questdlg( ...
    'Confirm this is a private folder outside the public GitHub repository. Face-derived data and filenames must stay private.', ...
    'Confirm private output location', 'Yes, private folder', 'Cancel', ...
    'Cancel');
if ~strcmp(confirmPrivate, 'Yes, private folder')
    fprintf('Output cancelled. No files were created.\n');
    return;
end

datasetPath = fullfile(outputRoot, 'train_dataset.mat');
manifestPath = fullfile(outputRoot, 'data_manifest.csv');
summaryPath = fullfile(outputRoot, 'data_quality_summary.csv');
if exist(datasetPath, 'file') || exist(manifestPath, 'file') || exist(summaryPath, 'file')
    error('prepareData:OutputExists', ...
        'One or more output files already exist. Choose a new private folder to avoid overwriting them.');
end
save(datasetPath, 'X', 'y', 'sampleID', 'groupID', 'preprocessSpec', '-v7');

manifest = table(sampleID, groupID, labelsText(:), names(:), height, width, bitDepth, ...
    'VariableNames', {'sampleID', 'groupID', 'label', 'sourceFile', ...
    'height', 'width', 'bitDepth'});
writetable(manifest, manifestPath);

check = {'pngCount'; 'manCount'; 'womanCount'; 'groupCount'; ...
    'imagesPerGroup'; 'imageHeight'; 'imageWidth'; 'RGBChannels'; ...
    'featureRows'; 'featureColumns'; 'allFeaturesFinite'; 'featureRange'};
value = {'200'; '100'; '100'; '100'; '2'; '640'; '640'; '3'; ...
    '200'; '1024'; 'true'; '[0,1]'};
writetable(table(check, value), summaryPath);

fprintf('\nCreated private files:\n');
fprintf('train_dataset.mat: X 200 x 1024, y, sampleID, groupID, preprocessSpec\n');
fprintf('data_manifest.csv: private filename-to-ID mapping\n');
fprintf('data_quality_summary.csv: non-identifying validation summary\n');
fprintf('Keep all three files in the approved private folder; do not upload them to GitHub or the website.\n');
end
