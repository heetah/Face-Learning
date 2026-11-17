function [Z, transformSeconds] = transformPCA(model, X)
%TRANSFORMPCA Project rows using only the saved training mean and directions.
% X: N-by-D double. Z: N-by-q in exactly the same observation order.
% Optional timing measures this transform only; it does not refit PCA.
validateattributes(model, {'struct'}, {'scalar'}, mfilename, 'model');
required = {'mu', 'w', 'q', 'inputDim'};
if ~all(isfield(model, required))
    error('FaceLab:PCA:InvalidModel', 'Model is missing required PCA fields.');
end
validateattributes(model.q, {'double'}, {'scalar', 'integer', 'positive', 'finite'});
validateattributes(model.inputDim, {'double'}, {'scalar', 'integer', 'positive', 'finite'});
validateattributes(model.mu, {'double'}, {'real', 'finite', 'size', [1 model.inputDim]});
validateattributes(model.w, {'double'}, ...
    {'real', 'finite', 'size', [model.inputDim model.q]});
validateattributes(X, {'double'}, {'2d', 'real', 'finite', 'nonsparse'}, ...
    mfilename, 'X');
if size(X, 2) ~= model.inputDim
    error('FaceLab:PCA:FeatureCount', ...
        'Expected %d feature columns, received %d.', model.inputDim, size(X, 2));
end
started = tic;
Z = (X - model.mu) * model.w;
transformSeconds = toc(started);
if any(~isfinite(Z(:)))
    error('FaceLab:PCA:NonfiniteTransform', 'Projection produced nonfinite values.');
end
end
