function [Z, transformSeconds] = transformPCA(model, X)
%TRANSFORMPCA Project rows using only the saved training mean and directions.
% X: N-by-D double. Z: N-by-q in exactly the same observation order.
% Optional timing measures this transform only; it does not refit PCA.
validateattributes(model, {'struct'}, {'scalar'}, mfilename, 'model');
required = {'mu', 'W', 'q', 'inputD'};
if ~all(isfield(model, required))
    error('FaceLab:PCA:InvalidModel', 'Model is missing required PCA fields.');
end
validateattributes(model.q, {'double'}, {'scalar', 'integer', 'positive', 'finite'});
validateattributes(model.inputD, {'double'}, {'scalar', 'integer', 'positive', 'finite'});
validateattributes(model.mu, {'double'}, {'real', 'finite', 'size', [1 model.inputD]});
validateattributes(model.W, {'double'}, ...
    {'real', 'finite', 'size', [model.inputD model.q]});
validateattributes(X, {'double'}, {'2d', 'real', 'finite', 'nonsparse'}, ...
    mfilename, 'X');
if size(X, 2) ~= model.inputD
    error('FaceLab:PCA:FeatureCount', ...
        'Expected %d feature columns, received %d.', model.inputD, size(X, 2));
end
started = tic;
Z = (X - model.mu) * model.W;
transformSeconds = toc(started);
if any(~isfinite(Z(:)))
    error('FaceLab:PCA:NonfiniteTransform', 'Projection produced nonfinite values.');
end
end
