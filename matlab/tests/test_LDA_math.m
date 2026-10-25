clc;
clear;

%% Test: Known LDA Direction

X = [
    1 1;
    2 1;
    3 1;
    5 2;
    6 2;
    7 2
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

% Expected direction: positive X-axis
expectedW = [1; 0];

% Verify projection direction
assert(norm(model.w - expectedW) < 1e-10, ...
    'Incorrect LDA projection direction.');

% Verify output dimensions
assert(isequal(size(Z), [6, 1]));

% Verify woman projects higher
assert(mean(Z(y == 'woman')) > mean(Z(y == 'man')));

disp('Known-direction LDA test passed.');