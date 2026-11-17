function [manifest, counts, outputPaths] = prepareFHandoff(matPath, outputDirectory)
%PREPAREFHANDOFF Validate train_dataset.mat and write the private F handoff.
%   With no MATPATH, a file picker is shown. Output defaults to the MAT
%   file's folder so no private artifact needs to enter the public repo.

if nargin < 1 || strlength(string(matPath)) == 0
    [fileName, folder] = uigetfile('*.mat', 'Select private train_dataset.mat');
    if isequal(fileName, 0)
        error('FaceLab:SelectionCancelled', 'No MAT file was selected.');
    end
    matPath = fullfile(folder, fileName);
end
matPath = char(string(matPath));
if ~isfile(matPath)
    error('FaceLab:MissingDataset', 'The selected MAT file does not exist.');
end

if nargin < 2 || strlength(string(outputDirectory)) == 0
    outputDirectory = fileparts(matPath);
end
outputDirectory = char(string(outputDirectory));
if ~isfolder(outputDirectory)
    error('FaceLab:MissingOutputDirectory', ...
        'The private output directory must already exist.');
end

S = load(matPath);
requiredVariables = {'X', 'y', 'sampleID', 'groupID', 'preprocessSpec'};
missingVariables = requiredVariables(~isfield(S, requiredVariables));
if ~isempty(missingVariables)
    error('FaceLab:MissingDatasetVariables', ...
        'MAT file is missing required variables: %s.', ...
        strjoin(missingVariables, ', '));
end

[manifest, counts] = createFoldManifest( ...
    S.X, S.y, S.sampleID, S.groupID, 2026);

outputPaths = struct();
outputPaths.manifest = fullfile(outputDirectory, 'fold_manifest.csv');
outputPaths.counts = fullfile(outputDirectory, 'fold_counts.csv');
outputPaths.config = fullfile(outputDirectory, 'fold_config.json');

writetable(manifest, outputPaths.manifest);
writetable(counts, outputPaths.counts);

config = localConfiguration(matPath);
jsonText = localJSON(config);
fid = fopen(outputPaths.config, 'w', 'n', 'UTF-8');
if fid < 0
    error('FaceLab:ConfigWriteFailed', 'Could not create fold_config.json.');
end
closeConfig = onCleanup(@() fclose(fid));
fwrite(fid, jsonText, 'char');
end

function config = localConfiguration(matPath)
config = struct();
config.schemaVersion = '1.0';
config.projectSpecification = 'v1.1';
config.generator = 'createFoldManifest';
config.foldSeed = 2026;
config.rngAlgorithm = 'twister';
config.numberOfFolds = 5;
config.classOrder = {'man', 'woman'};
config.groupPreserving = true;
config.matlabRelease = version('-release');
config.matlabVersion = version;
config.dataPackageSHA256 = sha256File(matPath);
config.dataFileName = 'train_dataset.mat';
config.outputFiles = {'fold_manifest.csv', 'fold_counts.csv', 'fold_config.json'};
config.privatePathsRecorded = false;

toolboxInfo = ver;
toolboxes = repmat(struct('name', '', 'version', ''), numel(toolboxInfo), 1);
for k = 1:numel(toolboxInfo)
    toolboxes(k).name = toolboxInfo(k).Name;
    toolboxes(k).version = toolboxInfo(k).Version;
end
config.toolboxes = toolboxes;

repoRoot = fileparts(fileparts(mfilename('fullpath')));
[status, commit] = system(sprintf('git -C "%s" rev-parse HEAD', repoRoot));
if status == 0
    config.gitCommit = strtrim(commit);
else
    config.gitCommit = 'unavailable';
end
end

function jsonText = localJSON(config)
try
    jsonText = jsonencode(config, 'PrettyPrint', true);
catch
    jsonText = jsonencode(config);
end
end
