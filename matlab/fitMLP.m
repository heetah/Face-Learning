
function [model, info] = fitMLP(Ztrain, ytrain)
% fitMLP - 訓練 MLP 分類器
%
% 輸入：
%   Ztrain : N x d 特徵矩陣
%   ytrain : N x 1 分類標籤
%
% 輸出：
%   model : 訓練完成的 MLP
%   info  : 訓練相關資訊

validateattributes(Ztrain, {'double'}, ...
    {'2d', 'real', 'finite', 'nonempty', 'nonsparse'}, ...
    mfilename, 'Ztrain');
if ~iscategorical(ytrain) || ~iscolumn(ytrain) || isempty(ytrain)
    error('FaceLab:MLP:InvalidLabels', ...
        'ytrain must be a nonempty categorical column vector.');
end
if size(Ztrain, 1) ~= numel(ytrain)
    error('FaceLab:MLP:RowCount', ...
        'Ztrain rows must match the number of labels.');
end
if any(isundefined(ytrain))
    error('FaceLab:MLP:UndefinedLabels', ...
        'ytrain must not contain undefined labels.');
end
observedClasses = sort(string(categories(removecats(ytrain))));
if ~isequal(observedClasses(:), ["man"; "woman"])
    error('FaceLab:MLP:ClassNames', ...
        'ytrain classes must be exactly man and woman.');
end

% 3. 固定亂數種子
rng(2026, 'twister');

hiddenUnits = 10;
lambda = 0;
iterationLimit = 1000;

% 建立並訓練模型
timer = tic;

model = fitcnet(Ztrain, ytrain, ...
    'LayerSizes', hiddenUnits, ...
    'Activations', 'relu', ...
    'Standardize', true, ...
    'Lambda', lambda, ...
    'IterationLimit', iterationLimit);

% 記錄資訊

info.fitSeconds = toc(timer);
info.inputDim = size(Ztrain, 2);
info.hiddenUnits = hiddenUnits;
info.activation = "relu";
info.standardize = true;
info.lambda = lambda;
info.iterationLimit = iterationLimit;
info.rngSeed = 2026;
info.classNames = string(model.ClassNames);
info.matlabRelease = version('-release');

% 8. 計算模型參數總數
info.numParameters = 0;

for i = 1:numel(model.LayerWeights)
    info.numParameters = info.numParameters ...
        + numel(model.LayerWeights{i}) ...
        + numel(model.LayerBiases{i});
end

expectedParameters = 10 * info.inputDim + 32;
if info.numParameters ~= expectedParameters
    error('FaceLab:MLP:ParameterCount', ...
        'Expected %d trainable parameters, received %d.', ...
        expectedParameters, info.numParameters);
end

% 9. 記錄訓練歷史
info.trainingHistory = model.TrainingHistory;

end
