function [manifest, counts] = createFoldManifest(X, y, sampleID, groupID, seed)
%CREATEFOLDMANIFEST Create the v1.1 group-stratified five-fold assignment.
%   [MANIFEST, COUNTS] = CREATEFOLDMANIFEST(X,Y,SAMPLEID,GROUPID) uses
%   MATLAB's Twister generator with seed 2026. The optional SEED exists for
%   synthetic testing; official project output must use 2026.

if nargin < 5 || isempty(seed)
    seed = 2026;
end
validateattributes(seed, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'integer', 'nonnegative'}, mfilename, 'seed');
validateTrainDataset(X, y, sampleID, groupID);

sampleID = string(sampleID(:));
groupID = string(groupID(:));
label = string(y(:));
outerFold = zeros(numel(label), 1);

previousRng = rng;
restoreRng = onCleanup(@() rng(previousRng));
rng(seed, 'twister');

classNames = ["man"; "woman"];
for c = 1:numel(classNames)
    classRows = label == classNames(c);
    groups = unique(groupID(classRows), 'stable');
    if numel(groups) ~= 50
        error('FaceLab:InvalidClassGroups', ...
            'Each class must contain exactly 50 groups.');
    end
    groups = groups(randperm(numel(groups)));
    for j = 1:numel(groups)
        fold = ceil(j / 10);
        rows = classRows & groupID == groups(j);
        outerFold(rows) = fold;
    end
end

manifest = table(sampleID, groupID, categorical(label, classNames), outerFold, ...
    'VariableNames', {'sampleID', 'groupID', 'label', 'outerFold'});
counts = validateFoldManifest(manifest);
end
