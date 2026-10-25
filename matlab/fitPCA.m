function model = fitPCA(Xtrain)
%FITPCA Fit train-only PCA according to project specification v1.1.
% Xtrain: N-by-D finite double, with one observation per row.
% model.mu: 1-by-D; model.W: D-by-q; q = rank(Xtrain-model.mu).
% No labels, validation rows, standardization, or dimension tuning are used.
% Requires Statistics and Machine Learning Toolbox (pca).
validateattributes(Xtrain, {'double'}, ...
    {'2d', 'real', 'finite', 'nonempty', 'nonsparse'}, mfilename, 'Xtrain');
if size(Xtrain, 1) < 2
    error('FaceLab:PCA:TooFewRows', 'PCA requires at least two training rows.');
end
started = tic;
mu = mean(Xtrain, 1);
A = Xtrain - mu;
q = rank(A); % MATLAB default tolerance; do not add a custom cutoff.
rankTolerance = max(size(A)) * eps(norm(A));
if q == 0
    error('FaceLab:PCA:ZeroRank', 'Centered training data have zero numerical rank.');
end
[coeff, ~, latent, ~, explained, fittedMu] = pca(Xtrain, ...
    'Algorithm', 'svd', 'Centered', true, 'Economy', true, 'Rows', 'all');
if size(coeff, 2) < q
    error('FaceLab:PCA:InsufficientDirections', ...
        'pca returned fewer directions than the training numerical rank.');
end
model = struct();
model.reducer = 'PCA';
model.specVersion = 'v1.1';
model.mu = fittedMu;
model.W = coeff(:, 1:q);
model.q = q;
model.rank = q;
model.rankTolerance = rankTolerance;
model.rankRule = 'rank(A), default max(size(A))*eps(norm(A))';
model.inputD = size(Xtrain, 2);
model.nTrain = size(Xtrain, 1);
model.latent = latent(1:q);
model.explained = explained(1:q); % percentages of total training variance
model.retainedVariancePercent = sum(model.explained);
model.fitSeconds = toc(started);
model.matlabRelease = version('-release');
model.toolbox = ver('stats');
if any(~isfinite(model.W(:))) || any(~isfinite(model.explained(:)))
    error('FaceLab:PCA:NonfiniteModel', 'PCA returned nonfinite values.');
end
end
