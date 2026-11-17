function tests = testFoldReducerIntegration
%TESTFOLDREDUCERINTEGRATION Exercise the fold-to-reducer handoff with synthetic data.
tests = functiontests(localfunctions);
end

function testSharedFoldFeedsBothReducers(testCase)
originalPath = path;
testCase.addTeardown(@path, originalPath);
root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root, 'matlab'));

tempFolder = tempname;
mkdir(tempFolder);
testCase.addTeardown(@rmdir, tempFolder, 's');

labels = [repmat("man", 100, 1); repmat("woman", 100, 1)];
y = categorical(labels, ["man", "woman"]);
sampleID = compose("sample-%03d", (1:200)');
groupNumbers = repmat(repelem((1:50)', 2), 2, 1);
groupID = labels + "-" + string(groupNumbers);
variation = repmat((1:100)' / 100, 2, 1);
X = zeros(200, 1024);
X(:, 1) = 0.2 * variation + 0.6 * (labels == "woman");
X(:, 2) = 0.5 * variation.^2;
preprocessSpec = struct('gridSize', [32, 32]);
matPath = fullfile(tempFolder, 'train_dataset.mat');
save(matPath, 'X', 'y', 'sampleID', 'groupID', 'preprocessSpec');

[~, ~, outputPaths] = prepareFHandoff(matPath, tempFolder);
[trainData, validationData] = loadFoldData(matPath, outputPaths.manifest, 1);
testCase.verifyEmpty(intersect(trainData.groupID, validationData.groupID));

pca = fitPCA(trainData.X, trainData.y);
lda = fitLDA(trainData.X, trainData.y);
pcaTrain = transformPCA(pca, trainData.X);
pcaValidation = transformPCA(pca, validationData.X);
ldaTrain = transformLDA(lda, trainData.X);
ldaValidation = transformLDA(lda, validationData.X);

testCase.verifySize(pcaTrain, [160 2]);
testCase.verifySize(pcaValidation, [40 2]);
testCase.verifySize(ldaTrain, [160 1]);
testCase.verifySize(ldaValidation, [40 1]);
testCase.verifyTrue(all(isfinite([pcaTrain(:); pcaValidation(:); ldaTrain(:); ldaValidation(:)])));
end
