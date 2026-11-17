function summary = validateTrainDataset(X, y, sampleID, groupID)
%VALIDATETRAINDATASET Validate the private v1.1 training-data contract.
%   SUMMARY = VALIDATETRAINDATASET(X,Y,SAMPLEID,GROUPID) stops on any
%   contract violation. It deliberately returns counts only, never private
%   identifiers or feature values.

expectedRows = 200;
expectedFeatures = 1024;
expectedLabels = ["man"; "woman"];

if ~isa(X, 'double') || ~isreal(X) || ~isequal(size(X), [expectedRows, expectedFeatures])
    error('FaceLab:InvalidXShape', ...
        'X must be a real 200-by-1024 double matrix.');
end
if ~all(isfinite(X(:)))
    error('FaceLab:NonFiniteX', 'X must not contain NaN or Inf values.');
end
if any(X(:) < 0) || any(X(:) > 1)
    error('FaceLab:XOutOfRange', 'Every X value must be in [0, 1].');
end

if ~iscategorical(y) || ~isvector(y) || numel(y) ~= expectedRows
    error('FaceLab:InvalidY', 'y must be a 200-element categorical vector.');
end
y = y(:);
if any(isundefined(y))
    error('FaceLab:UndefinedLabel', 'y must not contain undefined labels.');
end
actualLabels = sort(string(categories(y)));
if ~isequal(actualLabels(:), expectedLabels)
    error('FaceLab:InvalidLabels', ...
        'y categories must be exactly man and woman.');
end

sampleID = localIDStrings(sampleID, expectedRows, 'sampleID');
groupID = localIDStrings(groupID, expectedRows, 'groupID');
label = string(y);
expectedRowLabels = [repmat("man", 100, 1); repmat("woman", 100, 1)];
if ~isequal(label, expectedRowLabels)
    error('FaceLab:InvalidRowOrder', ...
        'Rows must follow the v1.1 order: 100 man, then 100 woman.');
end

if numel(unique(sampleID)) ~= expectedRows
    error('FaceLab:DuplicateSampleID', 'sampleID values must be unique.');
end

[groups, ~, groupIndex] = unique(groupID);
groupSizes = accumarray(groupIndex, 1);
if numel(groups) ~= 100 || any(groupSizes ~= 2)
    error('FaceLab:InvalidGroups', ...
        'Expected exactly 100 groupID values with two rows per group.');
end

for g = 1:numel(groups)
    if numel(unique(label(groupIndex == g))) ~= 1
        error('FaceLab:MixedLabelGroup', ...
            'Each groupID must belong to exactly one class.');
    end
end

classCounts = zeros(2, 1);
classGroupCounts = zeros(2, 1);
for c = 1:numel(expectedLabels)
    rows = label == expectedLabels(c);
    classCounts(c) = sum(rows);
    classGroupCounts(c) = numel(unique(groupID(rows)));
end
if any(classCounts ~= 100) || any(classGroupCounts ~= 50)
    error('FaceLab:InvalidClassBalance', ...
        'Expected 100 rows and 50 two-row groups for each class.');
end

summary = table(expectedLabels, classCounts, classGroupCounts, ...
    'VariableNames', {'label', 'sampleCount', 'groupCount'});
end

function values = localIDStrings(values, expectedRows, variableName)
if ~isvector(values) || numel(values) ~= expectedRows
    error('FaceLab:InvalidIDShape', ...
        '%s must contain exactly 200 values.', variableName);
end
if isnumeric(values) && any(~isfinite(values(:)))
    error('FaceLab:MissingID', '%s must not contain missing values.', variableName);
end
values = string(values(:));
if any(ismissing(values)) || any(strlength(values) == 0)
    error('FaceLab:MissingID', '%s must not contain missing or empty values.', variableName);
end
end
