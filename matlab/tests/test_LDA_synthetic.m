
clc;
clear;

%% Test 1: Normal Synthetic Data

X = [
    1 2;
    2 3;
    3 2;
    6 5;
    7 6;
    8 5
];

y = categorical({
    'man';
    'man';
    'man';
    'woman';
    'woman';
    'woman'
});

model = fitLDA(X, y);
Z = transformLDA(model, X);

assert(isequal(size(Z), [6, 1]));
assert(all(isfinite(Z)));

disp('Test 1 passed: Normal synthetic data.');

%% Test 2: High-Dimensional Data

rng(2026, 'twister');

X = rand(10, 30);
X(6:10, :) = X(6:10, :) + 0.5;

y = categorical([
    repmat({'man'}, 5, 1);
    repmat({'woman'}, 5, 1)
]);

model = fitLDA(X, y);
Z = transformLDA(model, X);

assert(isequal(size(Z), [10, 1]));
assert(all(isfinite(Z)));
assert(model.rankR <= 8);

disp('Test 2 passed: High-dimensional data.');

%% Test 3: Degenerate Data

X = [
    1 1;
    1 1;
    1 1;
    1 1
];

y = categorical({
    'man';
    'man';
    'woman';
    'woman'
});

failedAsExpected = false;

try
    model = fitLDA(X, y);
catch
    failedAsExpected = true;
end

assert(failedAsExpected, ...
    'Degenerate data should produce an error.');

disp('Test 3 passed: Degenerate data.');

%% Final Result

disp('All synthetic LDA tests passed.');
