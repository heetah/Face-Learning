function tests = testRunCV
%TESTRUNCV End-to-end checks with synthetic, group-balanced data only.
tests = functiontests(localfunctions);
end

function setup(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
originalPath = path;
testCase.addTeardown(@path, originalPath);
addpath(fullfile(root, 'matlab'));
end

function testFourPipelinesShareFiveFolds(testCase)
[matPath, manifestPath, manifest, outputFolder] = syntheticFiles(testCase);
previousRng = rng;
results = runCV(matPath, manifestPath, outputFolder);
testCase.verifyEqual(rng, previousRng);

folds = results.foldMetrics;
summary = results.summaryMetrics;
testCase.verifyEqual(height(folds), 20);
testCase.verifyEqual(height(summary), 4);
testCase.verifyEqual(folds.nTrain, repmat(160, 20, 1));
testCase.verifyEqual(folds.nValid, repmat(40, 20, 1));
testCase.verifyEqual(folds.tn + folds.fp, repmat(20, 20, 1));
testCase.verifyEqual(folds.fn + folds.tp, repmat(20, 20, 1));
testCase.verifyEqual(folds.accuracy, folds.balancedAccuracy, 'AbsTol', 1e-14);
testCase.verifyTrue(all(isfinite(folds.AUC) & folds.AUC >= 0 & folds.AUC <= 1));
testCase.verifyTrue(all(isfinite(folds.trainSeconds) & folds.trainSeconds >= 0));
testCase.verifyTrue(all(isfinite(folds.inferenceSeconds) & folds.inferenceSeconds >= 0));

% A seventh direction exists only in the first validation fold.
pcaFoldOne = folds.fold == 1 & startsWith(folds.method, 'PCA');
testCase.verifyEqual(folds.featureDim(pcaFoldOne), [6; 6]);
testCase.verifyEqual(folds.featureDim(startsWith(folds.method, 'LDA')), ones(10, 1));
bayes = endsWith(folds.method, 'Bayes');
testCase.verifyEqual(folds.numParameters(bayes), 4 * folds.featureDim(bayes));
testCase.verifyEqual(folds.numParameters(~bayes), 10 * folds.featureDim(~bayes) + 32);

oof = results.oofPredictions;
testCase.verifyEqual(height(oof), 800);
testCase.verifyEqual(oof.score_man + oof.score_woman, ones(800, 1), 'AbsTol', 1e-8);
for k = 1:height(summary)
    fullMethod = oof(oof.method == summary.method(k), :);
    [~, byID] = ismember(manifest.sampleID, fullMethod.sampleID);
    testCase.assertTrue(all(byID > 0));
    testCase.verifyEqual(height(fullMethod), 200);
    testCase.verifyEqual(fullMethod.groupID(byID), manifest.groupID);
    testCase.verifyEqual(fullMethod.outerFold(byID), manifest.outerFold);
    testCase.verifyEqual(fullMethod.yTrue(byID), string(manifest.label));
    inputFolds = folds(folds.method == summary.method(k), :);
    testCase.verifyEqual(summary.AUCMean(k), mean(inputFolds.AUC), 'AbsTol', 1e-14);
    testCase.verifyEqual(summary.AUCSD(k), std(inputFolds.AUC, 0), 'AbsTol', 1e-14);
    testCase.verifyEqual(summary.overallAccuracy(k), mean(fullMethod.yTrue == fullMethod.yPred));
end

testCase.verifyEqual(height(results.reductionSummary), 10);
testCase.verifyEqual(height(results.classifierSummary), 20);
testCase.verifyEqual(height(unique(results.rocCurves(:, {'method', 'fold'}))), 20);
expectedFiles = ["fold_metrics.csv", "summary_metrics.csv", "oof_predictions.csv", ...
    "reduction_summary.csv", "classifier_summary.csv", "roc_curves.csv", ...
    "run_config.json", "mlp_training_history.mat", "cv_roc.png"];
testCase.verifyTrue(all(isfile(fullfile(outputFolder, expectedFiles))));
config = jsondecode(fileread(fullfile(outputFolder, 'run_config.json')));
testCase.verifyEqual(config.positiveClass, 'woman');
testCase.verifyEqual(config.trainDataSha256, sha256File(matPath));
testCase.verifyEqual(config.foldManifestSha256, sha256File(manifestPath));
testCase.verifyFalse(contains(fileread(fullfile(outputFolder, 'run_config.json')), ...
    'train_dataset.mat'));
history = load(fullfile(outputFolder, 'mlp_training_history.mat'));
testCase.verifyNumElements(history.mlpTrainingHistory, 10);
testCase.verifyError(@() runCV(matPath, manifestPath, outputFolder), 'FaceLab:CV:OutputExists');
end

function testRejectsMisalignedManifest(testCase)
[matPath, manifestPath, manifest, outputFolder] = syntheticFiles(testCase);
manifest.sampleID = circshift(manifest.sampleID, 1);
writetable(manifest, manifestPath);
testCase.verifyError(@() runCV(matPath, manifestPath, outputFolder), ...
    'FaceLab:SampleAlignmentMismatch');
testCase.verifyFalse(isfolder(outputFolder));
end

function [matPath, manifestPath, manifest, outputFolder] = syntheticFiles(testCase)
folder = tempname;
mkdir(folder);
testCase.addTeardown(@rmdir, folder, 's');
previousRng = rng;
restoreRng = onCleanup(@() rng(previousRng));
rng(951, 'twister');
labels = [repmat("man", 100, 1); repmat("woman", 100, 1)];
y = categorical(labels, ["man"; "woman"]);
sampleID = compose("synthetic-%03d", (1:200)');
groupID = labels + "-" + string(repmat(repelem((1:50)', 2), 2, 1));
X = zeros(200, 1024);
X(:, 1:6) = 0.15 + 0.50 * rand(200, 6);
X(:, 1) = X(:, 1) + 0.12 * (labels == "woman");
preprocessSpec = struct('gridSize', [32, 32]);
manifest = createFoldManifest(X, y, sampleID, groupID);
X(manifest.outerFold == 1, 7) = rand(40, 1);
matPath = fullfile(folder, 'train_dataset.mat');
manifestPath = fullfile(folder, 'fold_manifest.csv');
outputFolder = fullfile(folder, 'results');
save(matPath, 'X', 'y', 'sampleID', 'groupID', 'preprocessSpec');
writetable(manifest, manifestPath);
end
