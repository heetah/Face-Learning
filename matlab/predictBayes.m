function [labels, scores, classNames, predictSeconds] = predictBayes(model, Zvalid)
%PREDICTBAYES Predict labels and posterior scores with trained Bayes model.
%   [labels, scores, classNames] = predictBayes(model, Zvalid)
%   [labels, scores, classNames, predictSeconds] = predictBayes(model, Zvalid)
%   labels: M-by-1 categorical (predicted man/woman labels).
%   scores: M-by-2 double (posterior scores for each class).
%   classNames: 2-by-1 string, matching scores columns.
%   scores(:,j) corresponds to classNames(j), not a hard-coded class.
%   predictSeconds excludes input checking and metadata retrieval.
%   Calling predictBayes with NO arguments runs a small standalone demo.
%   Formal integration should always pass (model, Zvalid).

    if nargin == 0
        % Convenience demo only; not the project evaluation dataset.
        ZtrainDemo = [
           -0.2 0.1; 0.1 -0.2; 0.2 0.2; -0.1 -0.1; 0.3 0; 0 0.3;
            1.8 2.0; 2.1 1.9; 2.2 2.2; 1.9 1.8; 2.3 2.0; 2.0 2.3
        ];
        ytrainDemo = [repmat("man",6,1); repmat("woman",6,1)];
        [demoModel, fitSeconds] = fitBayes(ZtrainDemo, ytrainDemo);
        demoZvalid = [0 0; 2 2];
        [labels, scores, classNames, predictSeconds] = ...
            predictBayes(demoModel, demoZvalid);
        fprintf('labels (M-by-1):\n');
        disp(labels);
        fprintf('scores (M-by-2):\n');
        disp(scores);
        fprintf('classNames (column order):\n');
        disp(classNames);
        fprintf('fitcnb: %.6f s; predict: %.6f s\n', ...
            fitSeconds, predictSeconds);
        fprintf('For real use: predictBayes(model, Zvalid)\n');
        return;
    elseif nargin ~= 2
        error('predictBayes:InputCount', ...
            'Provide both model and Zvalid, or call predictBayes with no arguments for a demo.');
    end

    if ~isnumeric(Zvalid) || ~isreal(Zvalid) || ndims(Zvalid) ~= 2 || ...
            isempty(Zvalid) || any(~isfinite(Zvalid(:)))
        error('predictBayes:InvalidFeatures', ...
            'Zvalid must be a nonempty, finite real numeric N-by-D matrix.');
    end
    if size(Zvalid,2) ~= numel(model.PredictorNames)
        error('predictBayes:DimensionMismatch', ...
            'Feature dimension does not match trained model.');
    end

    t = tic;
    [labels, scores] = predict(model, double(Zvalid));
    predictSeconds = toc(t);
    % Explicit output contract: M-by-1 labels, M-by-2 scores,
    % and one class name per score column.
    labels = categorical(labels(:));
    classNames = string(model.ClassNames(:));
    if size(scores,1) ~= size(Zvalid,1) || ...
            size(scores,2) ~= 2 || numel(classNames) ~= 2
        error('predictBayes:UnexpectedOutputShape', ...
            'Expected labels M-by-1, scores M-by-2, and 2 class names.');
    end

    if any(~isfinite(scores(:)))
        error('predictBayes:InvalidScores', ...
            'Prediction scores contain NaN or Inf. Check Gaussian fits.');
    end
end
