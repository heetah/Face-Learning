
clc;
clear;

% 1. 建立人工資料
rng(2026);

X1 = randn(100, 2) + [-0.5, -0.5];
X2 = randn(100, 2) + [0.5, 0.5];

X = [X1; X2];

y = categorical([ ...
    repmat("man", 100, 1);
    repmat("woman", 100, 1)]);

% 2. 切分資料
idx = randperm(200);

Ztrain = X(idx(1:160), :);
ytrain = y(idx(1:160));

Ztest = X(idx(161:200), :);
ytest = y(idx(161:200));

% 3. 呼叫自己寫的訓練函式
[model, info] = fitMLP(Ztrain, ytrain);

% 4. 呼叫自己寫的預測函式
[labels, scores, classNames] = ...
    predictMLP(model, Ztest);

% 5. 計算準確率
accuracy = mean(labels == ytest) * 100;

% 6. 顯示結果
fprintf('Accuracy: %.2f%%\n', accuracy);
fprintf('Training time: %.4f seconds\n', ...
    info.fitSeconds);
fprintf('Input dimension: %d\n', ...
    info.inputDim);
fprintf('Hidden units: %d\n', ...
    info.hiddenUnits);
fprintf('Parameters: %d\n', ...
    info.numParameters);

disp('Class names:');
disp(classNames);

disp('First 5 prediction scores:');
disp(scores(1:5, :));
