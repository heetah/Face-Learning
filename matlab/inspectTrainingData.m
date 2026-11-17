function inspectTrainingData
% Inspect a private training-image folder without displaying or copying images.
% Select the folder that directly contains the PNG files when prompted.

fprintf('Face-Learning training data check\n');
fprintf('Select the folder that directly contains the training PNG files.\n\n');

trainRoot = uigetdir(pwd, 'Select the folder containing training PNG files');
if isequal(trainRoot, 0)
    fprintf('No folder selected. Nothing was checked.\n');
    return;
end

files = dir(fullfile(trainRoot, '*.png'));
files = files(~[files.isdir]);
fileCount = numel(files);
fprintf('PNG files found: %d\n', fileCount);

if fileCount == 0
    fprintf('No PNG files found directly in the selected folder.\n');
    fprintf('Select the inner folder that contains the images, not its parent.\n');
    return;
end

names = {files.name};
tokens = regexp(names, '^(man|woman)_([^_]+)_([^_]+)\.png$', 'tokens', 'once');
validName = ~cellfun('isempty', tokens);
fprintf('Names matching class_group_image.png: %d / %d\n', ...
    sum(validName), fileCount);

classNames = {'man', 'woman'};
classCounts = zeros(1, 2);
groupKeys = cell(1, fileCount);
for k = 1:fileCount
    if validName(k)
        parsed = tokens{k};
        classIndex = find(strcmp(classNames, parsed{1}), 1);
        classCounts(classIndex) = classCounts(classIndex) + 1;
        groupKeys{k} = [parsed{1}, '_', parsed{2}];
    end
end

fprintf('man images: %d\n', classCounts(1));
fprintf('woman images: %d\n', classCounts(2));

if all(validName)
    uniqueGroups = unique(groupKeys);
    groupSizes = zeros(size(uniqueGroups));
    for k = 1:numel(uniqueGroups)
        groupSizes(k) = sum(strcmp(groupKeys, uniqueGroups{k}));
    end
    fprintf('Filename groups: %d\n', numel(uniqueGroups));
    fprintf('Groups containing exactly 2 images: %d / %d\n', ...
        sum(groupSizes == 2), numel(groupSizes));
else
    fprintf('Group counts skipped because some names do not match the required pattern.\n');
end

numberReadable = 0;
for k = 1:fileCount
    try
        readFaceImage(fullfile(trainRoot, files(k).name));
        numberReadable = numberReadable + 1;
    catch err
        if ~strcmp(err.identifier, 'FaceLab:InvalidFaceImage')
            rethrow(err);
        end
    end
end

fprintf('Images decoded as 640 x 640 8-bit RGB: %d / %d\n', numberReadable, fileCount);
fprintf('This check displays aggregate counts and does not save images or features.\n');
fprintf('Expected project count: 200 PNG files, with 100 man and 100 woman.\n');
end
