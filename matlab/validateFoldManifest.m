function counts = validateFoldManifest(manifest)
%VALIDATEFOLDMANIFEST Validate the shared five-fold manifest and count rows.

requiredVariables = ["sampleID", "groupID", "label", "outerFold"];
if ~istable(manifest) || ...
        ~all(ismember(requiredVariables, string(manifest.Properties.VariableNames)))
    error('FaceLab:InvalidManifestSchema', ...
        'Manifest must contain sampleID, groupID, label, and outerFold.');
end
if height(manifest) ~= 200
    error('FaceLab:InvalidManifestHeight', 'Manifest must contain 200 rows.');
end

sampleID = string(manifest.sampleID(:));
groupID = string(manifest.groupID(:));
label = string(manifest.label(:));
outerFold = double(manifest.outerFold(:));

if any(ismissing(sampleID)) || any(strlength(sampleID) == 0) || ...
        numel(unique(sampleID)) ~= 200
    error('FaceLab:InvalidManifestSampleID', ...
        'Manifest sampleID values must be present and unique.');
end
if any(ismissing(groupID)) || any(strlength(groupID) == 0)
    error('FaceLab:InvalidManifestGroupID', ...
        'Manifest groupID values must be present.');
end
if ~isequal(sort(unique(label)), ["man"; "woman"])
    error('FaceLab:InvalidManifestLabels', ...
        'Manifest labels must be exactly man and woman.');
end
if any(~isfinite(outerFold)) || any(outerFold ~= fix(outerFold)) || ...
        any(outerFold < 1) || any(outerFold > 5)
    error('FaceLab:InvalidFoldValue', ...
        'outerFold values must be integers from 1 through 5.');
end

[groups, ~, groupIndex] = unique(groupID);
if numel(groups) ~= 100
    error('FaceLab:InvalidManifestGroups', ...
        'Manifest must contain exactly 100 groupID values.');
end
for g = 1:numel(groups)
    rows = groupIndex == g;
    if sum(rows) ~= 2 || numel(unique(label(rows))) ~= 1 || ...
            numel(unique(outerFold(rows))) ~= 1
        error('FaceLab:GroupLeakage', ...
            'Every group must have two same-label rows in one fold.');
    end
end

fold = (1:5)';
validationTotal = zeros(5, 1);
validationMan = zeros(5, 1);
validationWoman = zeros(5, 1);
validationGroups = zeros(5, 1);
validationManGroups = zeros(5, 1);
validationWomanGroups = zeros(5, 1);
trainingTotal = zeros(5, 1);
trainingMan = zeros(5, 1);
trainingWoman = zeros(5, 1);
trainingGroups = zeros(5, 1);

for k = 1:5
    valid = outerFold == k;
    train = ~valid;
    validationTotal(k) = sum(valid);
    validationMan(k) = sum(valid & label == "man");
    validationWoman(k) = sum(valid & label == "woman");
    validationGroups(k) = numel(unique(groupID(valid)));
    validationManGroups(k) = numel(unique(groupID(valid & label == "man")));
    validationWomanGroups(k) = numel(unique(groupID(valid & label == "woman")));
    trainingTotal(k) = sum(train);
    trainingMan(k) = sum(train & label == "man");
    trainingWoman(k) = sum(train & label == "woman");
    trainingGroups(k) = numel(unique(groupID(train)));
end

if any(validationTotal ~= 40) || any(validationMan ~= 20) || ...
        any(validationWoman ~= 20) || any(validationGroups ~= 20) || ...
        any(validationManGroups ~= 10) || any(validationWomanGroups ~= 10) || ...
        any(trainingTotal ~= 160) || any(trainingMan ~= 80) || ...
        any(trainingWoman ~= 80) || any(trainingGroups ~= 80)
    error('FaceLab:InvalidFoldCounts', ...
        'Every fold must have 40 validation rows (20/class) and 160 training rows (80/class).');
end

counts = table(fold, validationTotal, validationMan, validationWoman, ...
    validationGroups, validationManGroups, validationWomanGroups, ...
    trainingTotal, trainingMan, trainingWoman, trainingGroups);
end
