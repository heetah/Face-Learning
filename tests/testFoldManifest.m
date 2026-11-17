function tests = testFoldManifest
%TESTFOLDMANIFEST Synthetic tests only; no private data is loaded.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testFolder = fileparts(mfilename('fullpath'));
repoRoot = fileparts(testFolder);
addpath(fullfile(repoRoot, 'matlab'));
testCase.TestData.repoRoot = repoRoot;
end

function testCreatesBalancedGroupPreservingFolds(testCase)
[X, y, sampleID, groupID] = localSyntheticDataset();
[manifest, counts] = createFoldManifest(X, y, sampleID, groupID);

verifyEqual(testCase, string(manifest.Properties.VariableNames), ...
    ["sampleID", "groupID", "label", "outerFold"]);
verifyEqual(testCase, height(manifest), 200);
verifyEqual(testCase, counts.validationTotal, repmat(40, 5, 1));
verifyEqual(testCase, counts.validationMan, repmat(20, 5, 1));
verifyEqual(testCase, counts.validationWoman, repmat(20, 5, 1));
verifyEqual(testCase, counts.validationGroups, repmat(20, 5, 1));
verifyEqual(testCase, counts.trainingTotal, repmat(160, 5, 1));
verifyEqual(testCase, counts.trainingMan, repmat(80, 5, 1));
verifyEqual(testCase, counts.trainingWoman, repmat(80, 5, 1));

groups = unique(manifest.groupID, 'stable');
for g = 1:numel(groups)
    rows = manifest.groupID == groups(g);
    verifyEqual(testCase, numel(unique(manifest.outerFold(rows))), 1);
end
end

function testOfficialSeedIsDeterministicAndCallerRngIsRestored(testCase)
[X, y, sampleID, groupID] = localSyntheticDataset();
rng(19, 'twister');
callerState = rng;
[manifest1, ~] = createFoldManifest(X, y, sampleID, groupID);
verifyEqual(testCase, rng, callerState);
[manifest2, ~] = createFoldManifest(X, y, sampleID, groupID);
verifyEqual(testCase, manifest1, manifest2);
end

function testRejectsMixedLabelGroup(testCase)
[X, y, sampleID, groupID] = localSyntheticDataset();
groupID(101:102) = groupID(1);
verifyError(testCase, ...
    @() createFoldManifest(X, y, sampleID, groupID), ...
    'FaceLab:InvalidGroups');
end

function testRejectsDuplicateSampleID(testCase)
[X, y, sampleID, groupID] = localSyntheticDataset();
sampleID(2) = sampleID(1);
verifyError(testCase, ...
    @() createFoldManifest(X, y, sampleID, groupID), ...
    'FaceLab:DuplicateSampleID');
end

function testRejectsWrongContractRowOrder(testCase)
[X, y, sampleID, groupID] = localSyntheticDataset();
rowOrder = [101:200, 1:100];
verifyError(testCase, ...
    @() createFoldManifest(X(rowOrder, :), y(rowOrder), ...
        sampleID(rowOrder), groupID(rowOrder)), ...
    'FaceLab:InvalidRowOrder');
end

function testWritesAndReloadsPrivateHandoff(testCase)
[X, y, sampleID, groupID] = localSyntheticDataset();
preprocessSpec = struct('gridSize', [32, 32]);
privateFolder = tempname;
mkdir(privateFolder);
removePrivateFolder = onCleanup(@() rmdir(privateFolder, 's'));
matPath = fullfile(privateFolder, 'train_dataset.mat');
save(matPath, 'X', 'y', 'sampleID', 'groupID', 'preprocessSpec');

[manifest, counts, outputPaths] = prepareFHandoff(matPath, privateFolder);
verifyTrue(testCase, isfile(outputPaths.manifest));
verifyTrue(testCase, isfile(outputPaths.counts));
verifyTrue(testCase, isfile(outputPaths.config));
verifyEqual(testCase, height(manifest), 200);
verifyEqual(testCase, height(counts), 5);

config = jsondecode(fileread(outputPaths.config));
verifyEqual(testCase, config.foldSeed, 2026);
verifyEqual(testCase, string(config.rngAlgorithm), "twister");
verifyFalse(testCase, config.privatePathsRecorded);

[trainData, validationData] = loadFoldData(matPath, outputPaths.manifest, 1);
verifySize(testCase, trainData.X, [160, 1024]);
verifySize(testCase, validationData.X, [40, 1024]);
verifyEqual(testCase, sum(string(trainData.y) == "man"), 80);
verifyEqual(testCase, sum(string(validationData.y) == "woman"), 20);
end

function [X, y, sampleID, groupID] = localSyntheticDataset()
X = zeros(200, 1024);
labels = [repmat("man", 100, 1); repmat("woman", 100, 1)];
y = categorical(labels, ["man", "woman"]);
sampleID = compose("sample-%03d", (1:200)');
groupNumbers = repelem((1:50)', 2);
groupID = [compose("man-group-%02d", groupNumbers); ...
    compose("woman-group-%02d", groupNumbers)];
end
