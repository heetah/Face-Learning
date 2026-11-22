clear
clc
addpath(fullfile(pwd, 'matlab'), '-begin')

assert(~isempty(which('fitcnb')) && ~isempty(which('fitcnet')) && ...
       ~isempty(which('perfcurve')), ...
       'This MATLAB session must provide fitcnb, fitcnet, and perfcurve.');

% 先用合成資料驗證四種方法
assertSuccess(runtests(fullfile(pwd, 'tests', 'testRunCV.m')));

% 再用真實訓練資料跑完整五折
privateFolder = uigetdir(pwd, 'Select a private output folder outside the Git repo');
assert(~isequal(privateFolder, 0), 'No output folder selected.');

outputFolder = tempname(privateFolder);
results = runCV('train_dataset.mat', 'fold_manifest.csv', outputFolder);

disp(results.summaryMetrics)
disp(outputFolder)