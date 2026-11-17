function model = fitPCA(Xtrain, ytrain)
%FITPCA Fit train-only PCA according to project specification v1.1.
% Xtrain: N-by-D finite double, with one observation per row.
% ytrain: required N-element categorical labels, matching the LDA argument order.
% Labels are validated but never used to compute the PCA model.
% model.mu: 1-by-D; model.w: D-by-q; q = rank(Xtrain-model.mu).
% No validation rows, standardization, or dimension tuning are used.
% Uses base MATLAB SVD only; no Statistics toolbox is required.
narginchk(2, 2);
validateattributes(Xtrain, {'double'}, ...
    {'2d', 'real', 'finite', 'nonempty', 'nonsparse'}, mfilename, 'Xtrain');
if size(Xtrain, 1) < 2
    error('FaceLab:PCA:TooFewRows', 'PCA requires at least two training rows.');
end
if ~iscategorical(ytrain) || ~isvector(ytrain) || ...
        numel(ytrain) ~= size(Xtrain, 1) || any(isundefined(ytrain(:)))
    error('FaceLab:PCA:InvalidLabels', ...
        'ytrain must contain one defined categorical label per training row.');
end
started = tic;
mu = mean(Xtrain, 1);
A = Xtrain - mu;
q = rank(A); % MATLAB default tolerance; do not add a custom cutoff.
rankTolerance = max(size(A)) * eps(norm(A));
if q == 0
    error('FaceLab:PCA:ZeroRank', 'Centered training data have zero numerical rank.');
end
% A = U*S*V'; right singular vectors are PCA directions.
[~, S, coeff] = svd(A, 'econ');
singularValues = diag(S);
latent = singularValues.^2 / (size(Xtrain, 1) - 1);
explained = 100 * singularValues.^2 / sum(singularValues.^2);
model = struct();
model.reducer = 'PCA';
model.specVersion = 'v1.1';
model.mu = mu;
model.algorithm = 'svd-econ';
model.w = coeff(:, 1:q); % PCA directions remain D-by-q.
model.q = q;
model.rank = q;
model.rankTolerance = rankTolerance;
model.rankRule = 'rank(A), default max(size(A))*eps(norm(A))';
model.inputDim = size(Xtrain, 2);
model.numSamples = size(Xtrain, 1);
model.latent = latent(1:q);
model.explained = explained(1:q); % percentages of total training variance
model.retainedVariancePercent = sum(model.explained);
model.fitSeconds = toc(started);
model.matlabRelease = version('-release');
model.toolbox = ver('stats');
if any(~isfinite(model.w(:))) || any(~isfinite(model.explained(:)))
    error('FaceLab:PCA:NonfiniteModel', 'PCA returned nonfinite values.');
end
end
