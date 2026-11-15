function packageFolder = prepareData(trainRoot, outputRoot)
%PREPAREDATA Build the private training package. Use Run to select folders.
packageFolder = '';
if nargin == 0
    trainRoot = uigetdir(pwd, 'Select the folder containing the 200 training PNGs');
    if isequal(trainRoot, 0)
        return;
    end
    outputRoot = selectFaceOutputFolder();
    if isequal(outputRoot, 0)
        return;
    end
elseif nargin ~= 2
    error('FaceLab:TrainingArguments', 'Supply both the training and private output folders.');
end
packageFolder = buildFaceDataset(trainRoot, outputRoot);
[~, name] = fileparts(packageFolder);
fprintf('Training package created in %s. X is 200 x 1024.\n', name);
end
