
function Z = transformLDA(model, X)

    %% Step 1: Validate Model

    if ~isstruct(model) || ~isscalar(model)
        error('Invalid LDA model.');
    end

    requiredFields = {'mu', 'w', 'inputDim', 'q'};

    if ~all(isfield(model, requiredFields))
        error('LDA model is missing required fields.');
    end

    D = model.inputDim;

    if ~isscalar(D) || ~isnumeric(D) || ...
            ~isfinite(D) || D < 1 || D ~= floor(D)
        error('Invalid model input dimension.');
    end

    if ~isa(model.mu, 'double') || ...
            ~isequal(size(model.mu), [1, D]) || ...
            any(~isfinite(model.mu(:)))
        error('Invalid LDA model mean.');
    end

    if ~isa(model.w, 'double') || ...
            ~isreal(model.w) || ...
            ~isequal(size(model.w), [D, 1]) || ...
            any(~isfinite(model.w(:))) || norm(model.w) == 0
        error('Invalid LDA projection direction.');
    end

    if ~isequal(model.q, 1)
        error('Invalid LDA output dimension.');
    end

    %% Step 2: Validate Input

    if ~isa(X, 'double') || ~isreal(X) || ...
            any(~isfinite(X(:))) || ...
            size(X, 2) ~= D
        error('Invalid input feature matrix.');
    end

    %% Step 3: Project Data

    Z = (X - model.mu) * model.w;

    %% Step 4: Validate Output

    if any(~isfinite(Z(:)))
        error('LDA transformation produced invalid values.');
    end

end
