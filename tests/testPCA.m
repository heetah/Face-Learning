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

function testLowRankReconstruction(testCase)
X = fixture;
m = fitPCA(X);
[Z, seconds] = transformPCA(m, X);
verifyEqual(testCase, m.q, 2);
verifyEqual(testCase, m.q, rank(X-mean(X,1)));
verifyEqual(testCase, m.rankTolerance, ...
    max(size(X))*eps(norm(X-mean(X,1))));
verifySize(testCase, m.mu, [1 4]);
verifySize(testCase, m.W, [4 2]);
verifySize(testCase, Z, [6 2]);
verifyEqual(testCase, m.W'*m.W, eye(2), 'AbsTol', 1e-10);
verifyEqual(testCase, mean(Z,1), zeros(1,2), 'AbsTol', 1e-10);
verifyEqual(testCase, Z*m.W'+m.mu, X, 'AbsTol', 1e-10);
verifyEqual(testCase, m.retainedVariancePercent, 100, 'AbsTol', 1e-8);
verifyGreaterThanOrEqual(testCase, m.fitSeconds, 0);
verifyGreaterThanOrEqual(testCase, seconds, 0);
end

function testValidationUsesSavedMeanAndRowOrder(testCase)
X = fixture;
m = fitPCA(X);
before = m;
Xvalid = X([4 1 6],:) + 50;
Z = transformPCA(m, Xvalid);
verifyEqual(testCase, Z, (Xvalid-before.mu)*before.W, 'AbsTol', 1e-10);
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
m = fitPCA(Xwide);
verifySize(testCase, m.W, [12 rank(Xwide-mean(Xwide,1))]);
m2 = fitPCA(Xwide + 100);
verifyEqual(testCase, m2.mu, m.mu + 100, 'AbsTol', 1e-10);
% Compare subspaces, not direction signs.
verifyEqual(testCase, m2.W*m2.W', m.W*m.W', 'AbsTol', 1e-10);
end

function testDefaultRankTolerance(testCase)
B = [1 0; -1 0; 0 1; 0 -1; 0 0; 0 0];
X = [B(:,1), B(:,2)*1e-18, zeros(6,2)];
m = fitPCA(X);
verifyEqual(testCase, m.q, rank(X));
verifyEqual(testCase, m.q, 1);
end

function testInvalidInputs(testCase)
verifyError(testCase, @() fitPCA(ones(6,4)), 'FaceLab:PCA:ZeroRank');
verifyError(testCase, @() fitPCA(ones(1,4)), 'FaceLab:PCA:TooFewRows');
m = fitPCA(fixture);
verifyError(testCase, @() transformPCA(m, ones(3,5)), 'FaceLab:PCA:FeatureCount');
verifyError(testCase, @() transformPCA(struct(), ones(3,4)), 'FaceLab:PCA:InvalidModel');
verifyTrue(testCase, rejects(@() fitPCA([NaN 1; 2 3])));
verifyTrue(testCase, rejects(@() fitPCA([Inf 1; 2 3])));
verifyTrue(testCase, rejects(@() transformPCA(m, NaN(1,4))));
verifyTrue(testCase, rejects(@() transformPCA(m, Inf(1,4))));
end

function rejected = rejects(action)
rejected = false;
try
    action();
catch
    rejected = true;
end
end
