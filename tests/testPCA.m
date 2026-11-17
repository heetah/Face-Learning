function tests = testPCA
% Synthetic-only tests; never loads a private dataset or writes face features.
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
root = fileparts(fileparts(mfilename('fullpath')));
testCase.TestData.originalPath = path;
addpath(fullfile(root, 'matlab'));
end

function teardownOnce(testCase)
path(testCase.TestData.originalPath);
end

function X = fixture
% Deterministic 6-by-4 matrix with centered rank two.
B = [-2 0; -1 1; 0 -1; 1 2; 2 -2; 0 0];
X = B * [1 2 0 -1; 0 1 3 2] + [10 20 30 40];
end

function y = fixtureLabels
y = categorical({'man'; 'man'; 'man'; 'woman'; 'woman'; 'woman'});
end

function testLowRankReconstruction(testCase)
X = fixture;
m = fitPCA(X, fixtureLabels);
[Z, seconds] = transformPCA(m, X);
verifyEqual(testCase, m.q, 2);
verifyEqual(testCase, m.algorithm, 'svd-econ');
expectedLatent = svd(X-mean(X,1)).^2/(size(X,1)-1);
verifyEqual(testCase, m.latent, expectedLatent(1:2), 'AbsTol', 1e-10);
verifyEqual(testCase, m.q, rank(X-mean(X,1)));
verifyEqual(testCase, m.rankTolerance, ...
    max(size(X))*eps(norm(X-mean(X,1))));
verifySize(testCase, m.mu, [1 4]);
verifySize(testCase, m.w, [4 2]);
verifySize(testCase, Z, [6 2]);
verifyEqual(testCase, m.w'*m.w, eye(2), 'AbsTol', 1e-10);
verifyEqual(testCase, mean(Z,1), zeros(1,2), 'AbsTol', 1e-10);
verifyEqual(testCase, Z*m.w'+m.mu, X, 'AbsTol', 1e-10);
verifyEqual(testCase, m.retainedVariancePercent, 100, 'AbsTol', 1e-8);
verifyGreaterThanOrEqual(testCase, m.fitSeconds, 0);
verifyGreaterThanOrEqual(testCase, seconds, 0);
end

function testValidationUsesSavedMeanAndRowOrder(testCase)
X = fixture;
m = fitPCA(X, fixtureLabels);
before = m;
Xvalid = X([4 1 6],:) + 50;
Z = transformPCA(m, Xvalid);
verifyEqual(testCase, Z, (Xvalid-before.mu)*before.w, 'AbsTol', 1e-10);
verifyEqual(testCase, transformPCA(m, Xvalid([3 1 2],:)), ...
    Z([3 1 2],:), 'AbsTol', 1e-10);
% Appending an unrelated row must not change existing rows' projections.
Zextra = transformPCA(m, [Xvalid; 1000*ones(1,4)]);
verifyEqual(testCase, Zextra(1:3,:), Z, 'AbsTol', 1e-10);
verifyEqual(testCase, m, before);
verifySize(testCase, transformPCA(m, zeros(0,4)), [0 2]);
end

function testWideInputAndIndependentFits(testCase)
X = fixture;
Xwide = [X, 2*X, -X];
m = fitPCA(Xwide, fixtureLabels);
verifySize(testCase, m.w, [12 rank(Xwide-mean(Xwide,1))]);
m2 = fitPCA(Xwide + 100, fixtureLabels);
verifyEqual(testCase, m2.mu, m.mu + 100, 'AbsTol', 1e-10);
% Compare subspaces, not direction signs.
verifyEqual(testCase, m2.w*m2.w', m.w*m.w', 'AbsTol', 1e-10);
end

function testDefaultRankTolerance(testCase)
B = [1 0; -1 0; 0 1; 0 -1; 0 0; 0 0];
X = [B(:,1), B(:,2)*1e-18, zeros(6,2)];
m = fitPCA(X, fixtureLabels);
verifyEqual(testCase, m.q, rank(X));
verifyEqual(testCase, m.q, 1);
end

function testInvalidInputs(testCase)
verifyError(testCase, @() fitPCA(ones(6,4), fixtureLabels), 'FaceLab:PCA:ZeroRank');
verifyError(testCase, @() fitPCA(ones(1,4), categorical({'man'})), 'FaceLab:PCA:TooFewRows');
m = fitPCA(fixture, fixtureLabels);
verifyError(testCase, @() transformPCA(m, ones(3,5)), 'FaceLab:PCA:FeatureCount');
verifyError(testCase, @() transformPCA(struct(), ones(3,4)), 'FaceLab:PCA:InvalidModel');
verifyTrue(testCase, rejects(@() fitPCA([NaN 1; 2 3], categorical({'man'; 'woman'}))));
verifyTrue(testCase, rejects(@() fitPCA([Inf 1; 2 3], categorical({'man'; 'woman'}))));
verifyTrue(testCase, rejects(@() transformPCA(m, NaN(1,4))));
verifyTrue(testCase, rejects(@() transformPCA(m, Inf(1,4))));
end

function testLabelsDoNotAffectPCA(testCase)
X = fixture;
y = categorical({'man'; 'man'; 'man'; 'woman'; 'woman'; 'woman'});
aligned = fitPCA(X, y);
permuted = fitPCA(X, y([6 5 4 3 2 1]));
verifyEqual(testCase, aligned.mu, mean(X, 1));
verifyEqual(testCase, permuted.w, aligned.w, 'AbsTol', 1e-12);
verifyEqual(testCase, aligned.inputDim, 4);
verifyEqual(testCase, aligned.numSamples, 6);
verifyEqual(testCase, aligned.q, 2);
verifyError(testCase, @() fitPCA(X, y(1:5)), 'FaceLab:PCA:InvalidLabels');
verifyError(testCase, @() fitPCA(X, ones(6,1)), 'FaceLab:PCA:InvalidLabels');
end

function testOldInterfaceRemoved(testCase)
X = fixture;
m = fitPCA(X, fixtureLabels);
verifyFalse(testCase, any(isfield(m, {'W', 'inputD', 'nTrain'})));
verifyTrue(testCase, rejects(@() fitPCA(X)));
legacy = rmfield(m, {'w', 'inputDim', 'numSamples'});
legacy.W = m.w;
legacy.inputD = m.inputDim;
legacy.nTrain = m.numSamples;
verifyError(testCase, @() transformPCA(legacy, X), 'FaceLab:PCA:InvalidModel');
Xvalid = X([6 2 4], :) + 20;
verifyEqual(testCase, transformPCA(m, Xvalid), ...
    (Xvalid - m.mu) * m.w, 'AbsTol', 1e-12);
end

function rejected = rejects(action)
rejected = false;
try
    action();
catch
    rejected = true;
end
end
