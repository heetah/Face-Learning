
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

% 1. 檢查資料大小
assert(size(Ztrain, 1) == numel(ytrain), ...
    '特徵與標籤數量不一致');

% 2. 檢查特徵是否有效
assert(isnumeric(Ztrain) && ...
    all(isfinite(Ztrain(:))), ...
    '特徵必須是有限數值');

% 3. 固定亂數種子
rng(2026, 'twister');

cv = cvpartition(ytrain, 'Holdout', 0.2);

Zfit = Ztrain(training(cv), :);
yfit = ytrain(training(cv));

Zval = Ztrain(test(cv), :);
yval = ytrain(test(cv));

% 將設定集中管理，避免修改時漏掉
hiddenUnits = 10;
lambda = 0;

% 建立並訓練模型
timer = tic;

model = fitcnet(Zfit, yfit, ...
    'LayerSizes', hiddenUnits, ...
    'Activations', 'relu', ...
    'Standardize', true, ...
    'Lambda', lambda, ...
    'IterationLimit', 1000, ...
    'ValidationData', {Zval, yval}, ...
    'ValidationPatience', 10);

% 記錄資訊
info.fitSeconds = toc(timer);
info.inputDim = size(Zfit, 2);
info.hiddenUnits = hiddenUnits;
info.lambda = lambda;
info.classNames = string(model.ClassNames);

% 8. 計算模型參數總數
info.numParameters = 0;

for i = 1:numel(model.LayerWeights)
    info.numParameters = info.numParameters ...
        + numel(model.LayerWeights{i}) ...
        + numel(model.LayerBiases{i});
end

% 9. 記錄訓練歷史
info.trainingHistory = model.TrainingHistory;

end
