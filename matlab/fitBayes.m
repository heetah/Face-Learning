function [model, fitSeconds] = fitBayes(Ztrain, ytrain)
%FITBAYES Train Gaussian Naive Bayes on PCA/LDA features.
%   [model, fitSeconds] = fitBayes(Ztrain, ytrain)
%   Ztrain: N-by-D finite real numerical features.
%   ytrain: N labels using "man" and "woman".
%   fitSeconds: time spent in fitcnb (seconds).
%
%   Requires Statistics and Machine Learning Toolbox.

    if ~isnumeric(Ztrain) || ~isreal(Ztrain) || ndims(Ztrain) ~= 2 || ...
            isempty(Ztrain) || any(~isfinite(Ztrain(:)))
        error('fitBayes:InvalidFeatures', ...
            'Ztrain must be a nonempty, finite real numeric N-by-D matrix.');
    end
    if numel(ytrain) ~= size(Ztrain,1)
        error('fitBayes:SizeMismatch', ...
            'Number of labels must equal number of feature rows.');
    end
    y = categorical(string(ytrain(:)));
    if any(isundefined(y)) || ~isequal(sort(unique(string(y))), ["man"; "woman"])
        error('fitBayes:InvalidLabels', ...
            'Training labels must contain exactly man and woman.');
    end

    % Specified model: independent Gaussian features, empirical priors.
    t = tic;
    model = fitcnb(double(Ztrain), y, ...
        'DistributionNames', 'normal', ...
        'Prior', 'empirical', ...
        'ClassNames', categorical(["man"; "woman"]));
    fitSeconds = toc(t);
end
