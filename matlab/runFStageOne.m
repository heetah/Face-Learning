function [manifest, counts, outputPaths, testResults] = runFStageOne(matPath)
%RUNFSTAGEONE Run synthetic tests before creating the private real manifest.

repoRoot = fileparts(fileparts(mfilename('fullpath')));
testFile = fullfile(repoRoot, 'tests', 'testFoldManifest.m');

fprintf('MATLAB release: %s\n', version('-release'));
fprintf('Running synthetic fold tests before reading private data...\n');
testResults = runtests(testFile);
assertSuccess(testResults);

fprintf('Synthetic tests passed. Preparing the private F handoff...\n');
[manifest, counts, outputPaths] = prepareFHandoff(matPath);
fprintf('Created fold_manifest.csv, fold_counts.csv, and fold_config.json.\n');
end
