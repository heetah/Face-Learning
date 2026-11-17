function packageFolder = prepareTestData(testRoot, labelFile, outputRoot)
%PREPARETESTDATA Build the independent official test package.
% With no arguments, pick the image folder, official label CSV, and private output.
% The label CSV must contain sourceFile and label columns.
packageFolder = '';
if nargin == 0
    testRoot = uigetdir(pwd, 'Select the folder containing the 100 official test images');
    if isequal(testRoot, 0)
        return;
    end
    [name, folder] = uigetfile('*.csv', 'Select the private CSV of official test labels');
    if isequal(name, 0)
        return;
    end
    labelFile = fullfile(folder, name);
    outputRoot = selectFaceOutputFolder();
    if isequal(outputRoot, 0)
        return;
    end
elseif nargin ~= 3
    error('FaceLab:TestArguments', 'Supply the test folder, label CSV, and private output folder.');
end
packageFolder = buildFaceDataset(testRoot, outputRoot, labelFile);
[~, name] = fileparts(packageFolder);
fprintf('Official test package created in %s. X is 100 x 1024.\n', name);
end
