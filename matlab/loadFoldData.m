function [trainData, validationData, manifest] = loadFoldData(matPath, manifestPath, fold)
%LOADFOLDDATA Load one shared outer fold after strict row-alignment checks.

validateattributes(fold, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', '>=', 1, '<=', 5}, ...
    mfilename, 'fold');

S = load(char(string(matPath)));
requiredVariables = {'X', 'y', 'sampleID', 'groupID', 'preprocessSpec'};
missingVariables = requiredVariables(~isfield(S, requiredVariables));
if ~isempty(missingVariables)
    error('FaceLab:MissingDatasetVariables', ...
        'MAT file is missing required variables: %s.', ...
        strjoin(missingVariables, ', '));
end
validateTrainDataset(S.X, S.y, S.sampleID, S.groupID);

manifestPath = char(string(manifestPath));
importOptions = detectImportOptions(manifestPath, 'TextType', 'string');
importOptions = setvartype(importOptions, ...
    {'sampleID', 'groupID', 'label'}, 'string');
importOptions = setvartype(importOptions, 'outerFold', 'double');
manifest = readtable(manifestPath, importOptions);
validateFoldManifest(manifest);

if ~isequal(string(S.sampleID(:)), string(manifest.sampleID(:)))
    error('FaceLab:SampleAlignmentMismatch', ...
        'MAT and manifest sampleID values are not identical row by row.');
end
if ~isequal(string(S.groupID(:)), string(manifest.groupID(:)))
    error('FaceLab:GroupAlignmentMismatch', ...
        'MAT and manifest groupID values are not identical row by row.');
end
if ~isequal(string(S.y(:)), string(manifest.label(:)))
    error('FaceLab:LabelAlignmentMismatch', ...
        'MAT and manifest labels are not identical row by row.');
end

validationRows = double(manifest.outerFold) == fold;
trainingRows = ~validationRows;

trainData = localSubset(S, trainingRows);
validationData = localSubset(S, validationRows);
trainData.rowIndex = find(trainingRows);
validationData.rowIndex = find(validationRows);
trainData.outerFold = fold;
validationData.outerFold = fold;
end

function subset = localSubset(S, rows)
subset = struct();
subset.X = S.X(rows, :);
subset.y = S.y(rows);
subset.sampleID = S.sampleID(rows);
subset.groupID = S.groupID(rows);
if isfield(S, 'preprocessSpec')
    subset.preprocessSpec = S.preprocessSpec;
end
end
