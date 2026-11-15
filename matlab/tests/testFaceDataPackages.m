function tests = testFaceDataPackages
% Synthetic coverage of the train/test handoff. No official data is used.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
oldPath = path;
addTeardown(testCase, @() path(oldPath));
addpath(fileparts(fileparts(mfilename('fullpath'))));
end

function testTrainingContract(testCase)
[inputRoot, outputRoot] = createFolders(testCase);
man = zeros(640, 640, 3, 'uint8');
woman = repmat(intmax('uint8'), 640, 640, 3);
manFile = fullfile(outputRoot, 'synthetic-man.png');
womanFile = fullfile(outputRoot, 'synthetic-woman.png');
imwrite(man, manFile);
imwrite(woman, womanFile);
for group = 50:-1:1
    for image = 2:-1:1
        copyfile(manFile, fullfile(inputRoot, sprintf('man_%03d_%d.png', group, image)));
        copyfile(womanFile, fullfile(inputRoot, sprintf('woman_%03d_%d.png', group, image)));
    end
end

folder = prepareData(inputRoot, outputRoot);
S = load(fullfile(folder, 'train_dataset.mat'));
verifySize(testCase, S.X, [200, 1024]);
verifyEqual(testCase, S.X(:,1), [zeros(100,1); ones(100,1)]);
verifyEqual(testCase, categories(S.y), {'man'; 'woman'});
verifyEqual(testCase, S.sampleID([1, 200]), {'S0001'; 'S0200'});
verifyEqual(testCase, S.groupID([1, 2, 101, 200]), {'G0001'; 'G0001'; 'G0051'; 'G0100'});
verifyTrue(testCase, isfile(fullfile(folder, 'data_manifest.csv')));
verifyTrue(testCase, isfile(fullfile(folder, 'data_quality_summary.csv')));
end

function testOfficialLabelsAndFailedImage(testCase)
[inputRoot, outputRoot] = createFolders(testCase);
black = zeros(640, 640, 3, 'uint8');
white = repmat(intmax('uint8'), 640, 640, 3);
manFile = fullfile(outputRoot, 'synthetic-dark.png');
womanFile = fullfile(outputRoot, 'synthetic-light.png');
imwrite(black, manFile);
imwrite(white, womanFile);
n = (1:100)';
sourceFile = compose("image-%03d.png", n);
% Names carry no labels. A deliberately unsorted CSV determines the labels.
label = repmat(["woman"; "man"], 50, 1);
for k = 1:numel(n)
    fixture = manFile;
    if label(k) == "woman"
        fixture = womanFile;
    end
    copyfile(fixture, fullfile(inputRoot, char(sourceFile(k))));
end
labelFile = fullfile(outputRoot, 'official-labels.csv');
labelTable = table(sourceFile, label);
writetable(labelTable(end:-1:1, :), labelFile);

firstImage = fullfile(inputRoot, char(sourceFile(1)));
imwrite(zeros(640, 640, 'uint8'), firstImage);
verifyError(testCase, @() prepareTestData(inputRoot, labelFile, outputRoot), ...
    'FaceLab:InvalidFaceImage');
verifyEmpty(testCase, dir(fullfile(outputRoot, 'test_package_*')));
copyfile(womanFile, firstImage, 'f');

folder = prepareTestData(inputRoot, labelFile, outputRoot);
S = load(fullfile(folder, 'test_dataset.mat'));
verifySize(testCase, S.X, [100, 1024]);
verifyEqual(testCase, S.X(:,1), [zeros(50,1); ones(50,1)]);
verifyEqual(testCase, string(S.y), [repmat("man",50,1); repmat("woman",50,1)]);
verifyEqual(testCase, S.sampleID([1, 100]), {'T0001'; 'T0100'});
verifyEqual(testCase, S.preprocessSpec.version, 'FaceLab-preprocess-v1.1');
verifyTrue(testCase, isfile(fullfile(folder, 'test_data_manifest.csv')));
verifyFalse(testCase, isfile(fullfile(folder, 'train_dataset.mat')));

labelTable.sourceFile(2) = labelTable.sourceFile(1);
writetable(labelTable, labelFile);
verifyError(testCase, @() prepareTestData(inputRoot, labelFile, outputRoot), ...
    'FaceLab:InvalidTestLabels');
end

function [inputRoot, outputRoot] = createFolders(testCase)
root = tempname;
mkdir(root);
addTeardown(testCase, @() rmdir(root, 's'));
inputRoot = fullfile(root, 'images');
outputRoot = fullfile(root, 'output');
mkdir(inputRoot);
mkdir(outputRoot);
end
