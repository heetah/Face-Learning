
function [labels, scores, classNames] = predictMLP(model, Ztest)
% predictMLP - 使用 MLP 模型預測分類結果
%
% 輸入：
%   model : 訓練完成的 MLP 模型
%   Ztest : M x d 測試特徵矩陣
%
% 輸出：
%   labels     : 預測類別
%   scores     : 各類別的分類分數
%   classNames : 分數對應的類別名稱

validateattributes(Ztest, {'double'}, ...
    {'2d', 'real', 'finite', 'nonempty', 'nonsparse'}, ...
    mfilename, 'Ztest');

% 1. 取得模型需要的特徵數量
inputDim = numel(model.PredictorNames);

% 2. 檢查輸入特徵維度
assert(size(Ztest, 2) == inputDim, ...
    '測試資料特徵維度錯誤');

% 3. 使用 MLP 進行預測
[labels, scores] = predict(model, Ztest);

% 4. 取得類別名稱
classNames = string(model.ClassNames);

end
