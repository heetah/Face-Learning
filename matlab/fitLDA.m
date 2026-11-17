
function model = fitLDA(Xtrain, ytrain)
    % Fisher LDA Training
    % Xtrain: N x D feature matrix
    % ytrain: N x 1 categorical labels
    % model: trained LDA model

    %% Step 1: Validate Input

    [N, D] = size(Xtrain);

    if N < 3 || D < 1
        error('LDA requires at least 3 samples and 1 feature.');
    end

    if ~isnumeric(Xtrain) || ~isreal(Xtrain) || ...
            ~isa(Xtrain, 'double') || any(~isfinite(Xtrain(:)))
        error('Xtrain must contain finite real double values.');
    end

    if ~iscategorical(ytrain) || numel(ytrain) ~= N
        error('Invalid training labels.');
    end

    ytrain = ytrain(:);

    if any(isundefined(ytrain)) || ...
            ~all(ismember({'man', 'woman'}, categories(ytrain))) || ...
            numel(unique(ytrain)) ~= 2
        error('LDA requires man and woman labels.');
    end

    %% Step 2: Calculate Class Means

    Xman = Xtrain(ytrain == 'man', :);
    Xwoman = Xtrain(ytrain == 'woman', :);

    mu_man = mean(Xman, 1);
    mu_woman = mean(Xwoman, 1);
    mu = mean(Xtrain, 1);

    %% Step 3: Within-Class Residual Matrix

    Rman = Xman - mu_man;
    Rwoman = Xwoman - mu_woman;

    R = [Rman; Rwoman];

    %% Step 4: Thin SVD

    [~, S, V] = svd(R, 'econ');

    s = diag(S);

    % MATLAB rank default tolerance
    tol = max(size(R)) * eps(max(s));
    r = sum(s > tol);

    if r == 0
        error('LDA failed: zero numerical rank.');
    end

    %% Step 5: Calculate Projection Direction

    d = (mu_woman - mu_man)';

    Vr = V(:, 1:r);
    sr = s(1:r);

    % Moore-Penrose minimum-norm solution
    w = Vr * ((Vr' * d) ./ (sr .^ 2));

    if any(~isfinite(w)) || norm(w) == 0
        error('LDA failed: degenerate direction.');
    end

    % Normalize direction
    w = w / norm(w);

    % Make woman project higher than man
    meanDiff = (mu_woman - mu_man) * w;

    if ~isfinite(meanDiff) || meanDiff == 0
        error('LDA failed: class means have identical projections.');
    end
    
    if meanDiff < 0
        w = -w;
    end

    %% Step 6: Save Model

    model.mu = mu;
    model.w = w;
    
    % Rank information
    model.rankR = r;
    model.rankTolerance = tol;
    
    % Dimension information
    model.q = 1;
    model.inputDim = D;
    model.numSamples = N;
    
    % Class orientation
    model.positiveClass = 'woman';
    model.signOrientation = 'woman-higher';
    
end

