function packageFolder = buildFaceDataset(imageRoot, outputRoot, testLabelFile)
% Build a complete package in a staging folder before publishing it locally.
if ~isfolder(imageRoot) || ~isfolder(outputRoot)
    error('FaceLab:InvalidDataFolder', 'The source and private output folders must exist.');
end

isTest = nargin == 3;
classNames = ["man"; "woman"];
if isTest
    [names, labels] = readOfficialLabels(testLabelFile);
    expectedPerClass = 50;
    packageType = 'test';
    manifestName = 'test_data_manifest.csv';
else
    files = dir(fullfile(imageRoot, '*.png'));
    names = string({files(~[files.isdir]).name}).';
    pattern = '^(man|woman)_([^_]+)_([^_]+)\.png$';
    tokens = regexp(cellstr(names), pattern, 'tokens', 'once');
    if any(cellfun('isempty', tokens))
        error('FaceLab:InvalidTrainingName', 'Training filenames must follow class_group_image.png.');
    end
    labels = string(cellfun(@(t) t{1}, tokens, 'UniformOutput', false));
    groupKeys = string(cellfun(@(t) [t{1}, '_', t{2}], tokens, 'UniformOutput', false));
    expectedPerClass = 100;
    packageType = 'train';
    manifestName = 'data_manifest.csv';
end
names = names(:);
labels = labels(:);
classCounts = [sum(labels == classNames(1)); sum(labels == classNames(2))];
if any(classCounts ~= expectedPerClass) || numel(names) ~= 2 * expectedPerClass
    error('FaceLab:InvalidClassCounts', 'Expected exactly %d images of each class.', expectedPerClass);
end

% Class first, then case-sensitive filename order. Apply one permutation to every field.
manRows = find(labels == classNames(1));
womanRows = find(labels == classNames(2));
[~, manOrder] = sort(names(manRows));
[~, womanOrder] = sort(names(womanRows));
order = [manRows(manOrder); womanRows(womanOrder)];
names = names(order);
labels = labels(order);
n = numel(names);
if isTest
    sampleID = arrayfun(@(k) sprintf('T%04d', k), (1:n)', 'UniformOutput', false);
    % Official labels do not provide verified groups. These IDs are row placeholders.
    groupID = arrayfun(@(k) sprintf('TG%04d', k), (1:n)', 'UniformOutput', false);
else
    [~, ~, groupIndex] = unique(groupKeys(order), 'stable');
    groupSizes = accumarray(groupIndex(:), 1);
    if numel(groupSizes) ~= 100 || any(groupSizes ~= 2)
        error('FaceLab:InvalidTrainingGroups', 'Expected 100 training groups of two images.');
    end
    sampleID = arrayfun(@(k) sprintf('S%04d', k), (1:n)', 'UniformOutput', false);
    groupID = arrayfun(@(k) sprintf('G%04d', k), groupIndex(:), 'UniformOutput', false);
end

preprocessSpec = struct( ...
    'version', 'FaceLab-preprocess-v1.1', ...
    'inputHeight', 640, 'inputWidth', 640, 'inputChannels', 3, 'inputBitDepth', 8, ...
    'pixelScaling', 'double(I) / 255', ...
    'poolingBlockHeight', 20, 'poolingBlockWidth', 20, ...
    'outputGridHeight', 32, 'outputGridWidth', 32, ...
    'channelAggregation', 'mean over all RGB values in each block', ...
    'flattenOrder', 'row-major', 'featureCount', 1024);
X = zeros(n, preprocessSpec.featureCount);
for k = 1:n
    I = readFaceImage(fullfile(imageRoot, char(names(k))));
    X(k, :) = poolFaceImage(I);
end
y = categorical(cellstr(labels), cellstr(classNames));
if ~isequal(size(X), [n, preprocessSpec.featureCount]) || ...
        any(~isfinite(X(:)) | X(:) < 0 | X(:) > 1) || any(isundefined(y))
    error('FaceLab:InvalidFeaturePackage', 'Feature package validation failed.');
end

% Unique sibling paths ensure each run has its own output, even when retried.
stageFolder = tempname(outputRoot);
[created, ~] = mkdir(stageFolder);
if ~created
    error('FaceLab:StageCreationFailed', 'Cannot create a staging folder in the private location.');
end
cleanup = onCleanup(@() removeStage(stageFolder));
[~, token] = fileparts(stageFolder);
finalFolder = fullfile(outputRoot, [packageType, '_package_', token]);
datasetName = [packageType, '_dataset.mat'];
save(fullfile(stageFolder, datasetName), 'X', 'y', 'sampleID', 'groupID', 'preprocessSpec', '-v7');

height = repmat(preprocessSpec.inputHeight, n, 1);
width = repmat(preprocessSpec.inputWidth, n, 1);
bitDepth = repmat(preprocessSpec.inputBitDepth * preprocessSpec.inputChannels, n, 1);
readStatus = repmat("ok", n, 1);
manifest = table(sampleID, groupID, cellstr(labels), cellstr(names), ...
    height, width, bitDepth, readStatus, 'VariableNames', ...
    {'sampleID', 'groupID', 'label', 'sourceFile', 'height', 'width', 'bitDepth', 'readStatus'});
writetable(manifest, fullfile(stageFolder, manifestName));

if ~isTest
    check = ["pngCount"; "manCount"; "womanCount"; "groupCount"; "imagesPerGroup"; ...
        "imageHeight"; "imageWidth"; "RGBChannels"; "featureRows"; ...
        "featureColumns"; "allFeaturesFinite"; "featureRange"];
    value = [string([n; classCounts; numel(groupSizes); groupSizes(1); ...
        preprocessSpec.inputHeight; preprocessSpec.inputWidth; preprocessSpec.inputChannels; ...
        size(X, 1); size(X, 2)]); "true"; "[0,1]"];
    writetable(table(check, value), fullfile(stageFolder, 'data_quality_summary.csv'));
end

[moved, ~] = movefile(stageFolder, finalFolder);
if ~moved
    error('FaceLab:PublishFailed', 'Unable to finish writing the private data package.');
end
packageFolder = finalFolder;
end

function [names, labels] = readOfficialLabels(labelFile)
if ~isfile(labelFile)
    error('FaceLab:MissingTestLabels', 'Select a private CSV containing official test labels.');
end
try
    options = detectImportOptions(labelFile, 'TextType', 'string');
    required = {'sourceFile', 'label'};
    options = setvartype(options, required, 'string');
    rows = readtable(labelFile, options);
catch
    error('FaceLab:InvalidTestLabels', 'The test label CSV must contain sourceFile and label columns.');
end
names = rows.sourceFile;
labels = rows.label;
if any(ismissing(names) | ismissing(labels)) || ...
        any(~ismember(labels, ["man", "woman"])) || ...
        any(strlength(names) == 0 | names == "." | names == ".." | ...
            contains(names, ["/", "\", ":"])) || numel(unique(lower(names))) ~= numel(names)
    error('FaceLab:InvalidTestLabels', 'Use unique filenames without paths and official man/woman labels.');
end
end

function removeStage(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end
