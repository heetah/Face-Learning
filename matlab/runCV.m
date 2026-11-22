function results = runCV(matPath, manifestPath, outputFolder, options)
%RUNCV Evaluate the four Face-Learning methods using the shared five folds.
%   RESULTS = RUNCV(MATPATH, MANIFESTPATH, OUTPUTFOLDER) writes one complete
%   set of results to a new folder in the team's approved private location.
%   GitCommit may be supplied for a reviewed Git snapshot. Code and input
%   hashes are recorded even when running from an exported folder.

arguments
    matPath (1,1) string
    manifestPath (1,1) string
    outputFolder (1,1) string
    options.GitCommit (1,1) string = ""
    options.WriteROCPlot (1,1) logical = true
end

[parentFolder, outputFolder] = outputLocation(outputFolder);
if ismissing(options.GitCommit) || (strlength(options.GitCommit) > 0 && ...
        isempty(regexp(options.GitCommit, '^[0-9a-fA-F]{7,40}$', 'once')))
    error('FaceLab:CV:InvalidGitCommit', 'GitCommit must be a Git revision hash.');
end

methodOrder = ["PCA + Bayes"; "LDA + Bayes"; "PCA + MLP"; "LDA + MLP"];
classOrder = ["man"; "woman"];
config = runConfig(matPath, manifestPath, options.GitCommit, methodOrder, classOrder);
previousRng = rng;
restoreRng = onCleanup(@() rng(previousRng));

reducers = ["PCA", "LDA"];
fitReducers = {@fitPCA, @fitLDA};
transformReducers = {@transformPCA, @transformLDA};
classifiers = ["Bayes", "MLP"];
foldRows = cell(20, 1);
classRows = cell(20, 1);
reductionRows = cell(10, 1);
predictionRows = cell(20, 1);
rocRows = cell(20, 1);
historyRows = cell(10, 1);

for fold = 1:5
    [training, validation] = loadFoldData(matPath, manifestPath, fold);
    for r = 1:numel(reducers)
        [trainFeatures, validationFeatures, reduction] = reduceFold( ...
            reducers(r), fold, fitReducers{r}, transformReducers{r}, training, validation.X);
        reductionIndex = (fold - 1) * numel(reducers) + r;
        reductionRows{reductionIndex} = reduction;
        for c = 1:numel(classifiers)
            method = reducers(r) + " + " + classifiers(c);
            index = (reductionIndex - 1) * numel(classifiers) + c;
            try
                [classification, labels, scores, history] = classifyFold( ...
                    classifiers(c), method, fold, trainFeatures, training.y(:), ...
                    validationFeatures, classOrder);
                [foldRows{index}, predictionRows{index}, rocRows{index}] = scoreFold( ...
                    method, fold, numel(training.y), validation, labels, scores, ...
                    reduction, classification);
            catch cause
                failure = MException('FaceLab:CV:PipelineFailed', ...
                    'Fold %d failed for %s.', fold, char(method));
                throw(addCause(failure, cause));
            end
            classRows{index} = classification;
            if classifiers(c) == "MLP"
                historyRows{reductionIndex} = struct('method', method, ...
                    'fold', fold, 'trainingHistory', history);
            end
        end
    end
end

if ~strcmp(config.trainDataSha256, sha256File(matPath)) || ...
        ~strcmp(config.foldManifestSha256, sha256File(manifestPath))
    error('FaceLab:CV:InputChanged', 'An input file changed during cross-validation.');
end

results = struct();
results.foldMetrics = struct2table(vertcat(foldRows{:}));
results.classifierSummary = struct2table(vertcat(classRows{:}));
results.reductionSummary = struct2table(vertcat(reductionRows{:}));
results.oofPredictions = vertcat(predictionRows{:});
results.rocCurves = vertcat(rocRows{:});
results.summaryMetrics = summarizeFolds(results.foldMetrics, methodOrder);
results.runConfig = config;
mlpTrainingHistory = vertcat(historyRows{:});
writeResults(parentFolder, outputFolder, results, mlpTrainingHistory, options.WriteROCPlot);
end

function [parentFolder, outputFolder] = outputLocation(outputFolder)
if ismissing(outputFolder) || strlength(strtrim(outputFolder)) == 0
    error('FaceLab:CV:OutputRequired', 'Specify a new private output folder.');
end
[parentFolder, name, extension] = fileparts(outputFolder);
if strlength(parentFolder) == 0
    parentFolder = string(pwd);
end
outputFolder = fullfile(parentFolder, name + extension);
if isfolder(outputFolder) || isfile(outputFolder)
    error('FaceLab:CV:OutputExists', 'Choose a new output folder for this run.');
end
if ~isfolder(parentFolder)
    error('FaceLab:CV:OutputParentMissing', 'The output parent folder must exist.');
end
end

function config = runConfig(matPath, manifestPath, gitCommit, methods, classOrder)
config = struct('gitCommit', gitCommit, 'matlabRelease', version('-release'), ...
    'matlabVersion', version, 'platform', computer, 'toolboxes', ver, ...
    'dataContractVersion', '1.1', 'projectSpecificationVersion', '1.1', ...
    'outerFolds', 5, 'foldSeed', 2026, 'foldGenerator', 'twister', ...
    'positiveClass', 'woman', 'scoreColumnOrder', classOrder, 'methods', methods);
config.trainDataSha256 = sha256File(matPath);
config.foldManifestSha256 = sha256File(manifestPath);
config.pca = struct('dimensionRule', 'rank of centered training matrix');
config.lda = struct('outputDimension', 1, 'solver', 'SVD Moore-Penrose minimum norm');
config.bayes = struct('distribution', 'normal', 'prior', 'empirical', ...
    'parameterCount', 'Count fitted Gaussian means and standard deviations; exclude priors.');
config.mlp = struct('hiddenUnits', 10, 'activation', 'relu', 'standardize', true, ...
    'lambda', 0, 'iterationLimit', 1000, 'rngSeed', 2026, ...
    'parameterCount', 'Count network weights and biases; exclude standardization statistics.');
config.timing = struct('trainSeconds', 'Reducer fit + training transform + classifier fit', ...
    'inferenceSeconds', 'Validation transform + classifier predict for all 40 rows', ...
    'scope', 'Wall-clock seconds; excludes data loading, metric computation and output');
config.roc = 'Computed separately for each fold from woman scores; five-fold sample SD.';
for name = ["runCV", "loadFoldData", "validateTrainDataset", "validateFoldManifest", ...
        "fitPCA", "transformPCA", "fitLDA", "transformLDA", ...
        "fitBayes", "predictBayes", "fitMLP", "predictMLP"]
    source = which(char(name));
    if isempty(source)
        error('FaceLab:CV:MissingModule', 'Missing MATLAB module %s.', char(name));
    end
    config.codeSha256.(char(name)) = sha256File(source);
end
end

function [trainFeatures, validationFeatures, row] = reduceFold( ...
        reducer, fold, fitFunction, transformFunction, training, validationX)
try
    started = tic;
    model = fitFunction(training.X, training.y(:));
    fitSeconds = toc(started);
    started = tic;
    trainFeatures = transformFunction(model, training.X);
    trainTransformSeconds = toc(started);
    started = tic;
    validationFeatures = transformFunction(model, validationX);
    validationTransformSeconds = toc(started);
catch cause
    failure = MException('FaceLab:CV:ReducerFailed', ...
        'Fold %d failed during %s reduction.', fold, char(reducer));
    throw(addCause(failure, cause));
end

withinClassRank = NaN;
retainedVariancePercent = NaN;
if reducer == "PCA"
    dataRank = model.rank;
    retainedVariancePercent = model.retainedVariancePercent;
else
    withinClassRank = model.rankR;
    dataRank = rank(training.X - model.mu);
end
row = struct('reducer', reducer, 'fold', fold, 'inputDim', model.inputDim, ...
    'outputDim', model.q, 'dataRank', dataRank, 'withinClassRank', withinClassRank, ...
    'rankTolerance', model.rankTolerance, 'retainedVariancePercent', retainedVariancePercent, ...
    'fitSeconds', fitSeconds, 'trainTransformSeconds', trainTransformSeconds, ...
    'validationTransformSeconds', validationTransformSeconds);
end

function [row, labels, scores, history] = classifyFold( ...
        classifier, method, fold, trainFeatures, yTrain, validationFeatures, classOrder)
history = [];
if classifier == "Bayes"
    started = tic;
    model = fitBayes(trainFeatures, yTrain);
    fitSeconds = toc(started);
    started = tic;
    [labels, scores, names] = predictBayes(model, validationFeatures);
    predictSeconds = toc(started);
    numParameters = sum(cellfun(@numel, model.DistributionParameters), 'all');
    settings = "normal distribution; empirical prior";
else
    started = tic;
    [model, info] = fitMLP(trainFeatures, yTrain);
    fitSeconds = toc(started);
    started = tic;
    [labels, scores, names] = predictMLP(model, validationFeatures);
    predictSeconds = toc(started);
    numParameters = info.numParameters;
    history = info.trainingHistory;
    settings = "10 ReLU units; Standardize=true; Lambda=0; IterationLimit=1000; seed=2026";
end

names = string(names(:));
labels = string(labels(:));
nValid = size(validationFeatures, 1);
if ~isequal(sort(names), classOrder) || ~isequal(size(scores), [nValid, 2]) || ...
        ~isreal(scores) || any(~isfinite(scores), 'all') || ...
        numel(labels) ~= nValid || any(ismissing(labels)) || any(~ismember(labels, classOrder))
    error('FaceLab:CV:InvalidPredictions', 'Invalid labels, scores, or score-column names.');
end
[~, columns] = ismember(classOrder, names);
scores = scores(:, columns);
row = struct('method', method, 'fold', fold, 'classifier', classifier, ...
    'settings', settings, 'modelClassNames', strjoin(string(model.ClassNames(:)), ','), ...
    'returnedScoreClassNames', strjoin(names, ','), 'featureDim', size(trainFeatures, 2), ...
    'numParameters', numParameters, 'fitSeconds', fitSeconds, 'predictSeconds', predictSeconds);
end

function [row, predictions, roc] = scoreFold( ...
        method, fold, nTrain, validation, labels, scores, reduction, classification)
truth = string(validation.y(:));
actualWoman = truth == "woman";
predictedWoman = labels == "woman";
nValid = numel(truth);
tn = sum(~actualWoman & ~predictedWoman);
fp = sum(~actualWoman & predictedWoman);
fn = sum(actualWoman & ~predictedWoman);
tp = sum(actualWoman & predictedWoman);
sensitivityMan = tn / (tn + fp);
sensitivityWoman = tp / (tp + fn);
[fpr, tpr, threshold, auc] = perfcurve(actualWoman, scores(:, 2), true);
row = struct('method', method, 'fold', fold, 'nTrain', nTrain, 'nValid', nValid, ...
    'tn', tn, 'fp', fp, 'fn', fn, 'tp', tp, 'accuracy', (tn + tp) / nValid, ...
    'balancedAccuracy', (sensitivityMan + sensitivityWoman) / 2, ...
    'sensitivityMan', sensitivityMan, 'sensitivityWoman', sensitivityWoman, 'AUC', auc, ...
    'featureDim', reduction.outputDim, 'numParameters', classification.numParameters, ...
    'trainSeconds', reduction.fitSeconds + reduction.trainTransformSeconds + classification.fitSeconds, ...
    'inferenceSeconds', reduction.validationTransformSeconds + classification.predictSeconds);
predictions = table(repmat(method, nValid, 1), string(validation.sampleID(:)), ...
    string(validation.groupID(:)), repmat(fold, nValid, 1), truth, labels, scores(:, 1), scores(:, 2), ...
    'VariableNames', {'method', 'sampleID', 'groupID', 'outerFold', 'yTrue', 'yPred', 'score_man', 'score_woman'});
roc = table(repmat(method, numel(fpr), 1), repmat(fold, numel(fpr), 1), fpr, tpr, threshold, ...
    'VariableNames', {'method', 'fold', 'fpr', 'tpr', 'threshold'});
end

function summary = summarizeFolds(foldMetrics, methodOrder)
rows = cell(numel(methodOrder), 1);
metrics = ["accuracy", "balancedAccuracy", "AUC", "trainSeconds", "inferenceSeconds"];
for k = 1:numel(methodOrder)
    t = foldMetrics(foldMetrics.method == methodOrder(k), :);
    assert(isequal(sort(t.fold), (1:5)'), 'FaceLab:CV:IncompleteFolds', ...
        'Every method must have one result for each fold.');
    row = struct('method', methodOrder(k), 'nFolds', height(t), 'nOOF', sum(t.nValid), ...
        'tn', sum(t.tn), 'fp', sum(t.fp), 'fn', sum(t.fn), 'tp', sum(t.tp), ...
        'overallAccuracy', sum(t.tn + t.tp) / sum(t.nValid), ...
        'featureDimMin', min(t.featureDim), 'featureDimMax', max(t.featureDim), ...
        'numParametersMin', min(t.numParameters), 'numParametersMax', max(t.numParameters));
    for metric = metrics
        row.(char(metric + "Mean")) = mean(t.(char(metric)));
        row.(char(metric + "SD")) = std(t.(char(metric)), 0);
    end
    rows{k} = row;
end
summary = struct2table(vertcat(rows{:}));
end

function writeResults(parentFolder, outputFolder, results, mlpTrainingHistory, writePlot)
staging = tempname(char(parentFolder));
[ok, message] = mkdir(staging);
if ~ok
    error('FaceLab:CV:OutputFailed', '%s', message);
end
removeStaging = onCleanup(@() cleanupStaging(staging));
writetable(results.foldMetrics, fullfile(staging, 'fold_metrics.csv'));
writetable(results.summaryMetrics, fullfile(staging, 'summary_metrics.csv'));
writetable(results.oofPredictions, fullfile(staging, 'oof_predictions.csv'));
writetable(results.reductionSummary, fullfile(staging, 'reduction_summary.csv'));
writetable(results.classifierSummary, fullfile(staging, 'classifier_summary.csv'));
writetable(results.rocCurves, fullfile(staging, 'roc_curves.csv'));
writelines(string(jsonencode(results.runConfig, 'PrettyPrint', true)), fullfile(staging, 'run_config.json'));
save(fullfile(staging, 'mlp_training_history.mat'), 'mlpTrainingHistory');
if writePlot
    plotROCs(results.rocCurves, results.summaryMetrics, fullfile(staging, 'cv_roc.png'));
end
if isfolder(outputFolder) || isfile(outputFolder)
    error('FaceLab:CV:OutputExists', 'Choose a new output folder for this run.');
end
[ok, message] = movefile(staging, char(outputFolder));
if ~ok
    error('FaceLab:CV:OutputFailed', '%s', message);
end
end

function cleanupStaging(staging)
if isfolder(staging)
    rmdir(staging, 's');
end
end

function plotROCs(curves, summary, outputFile)
fig = figure('Visible', 'off', 'Color', 'white', 'Position', [100 100 920 660]);
closeFigure = onCleanup(@() close(fig));
layout = tiledlayout(fig, 2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
for k = 1:height(summary)
    ax = nexttile(layout);
    hold(ax, 'on');
    plot(ax, [0 1], [0 1], ':', 'Color', [0.5 0.5 0.5], 'HandleVisibility', 'off');
    for fold = 1:5
        data = curves(curves.method == summary.method(k) & curves.fold == fold, :);
        plot(ax, data.fpr, data.tpr, 'LineWidth', 1.25, 'DisplayName', sprintf('Fold %d', fold));
    end
    grid(ax, 'on');
    xlim(ax, [0 1]);
    ylim(ax, [0 1]);
    title(ax, sprintf('%s | AUC %.3f +/- %.3f', char(summary.method(k)), ...
        summary.AUCMean(k), summary.AUCSD(k)), 'Interpreter', 'none');
    legend(ax, 'Location', 'southeast');
end
xlabel(layout, 'False positive rate');
ylabel(layout, 'True positive rate');
title(layout, 'Five-fold ROC curves | positive class: woman');
exportgraphics(layout, outputFile, 'Resolution', 180);
end
