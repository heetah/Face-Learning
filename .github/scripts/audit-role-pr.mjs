import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';

// Pilot entries observed in the upstream PR history. Confirm them with the
// maintainer before reusing the policy for an enforced check.
const scopes = {
  liupiyan: {
    base: 'feature/b-pca',
    files: ['matlab/fitPCA.m', 'matlab/transformPCA.m', 'tests/testPCA.m'],
  },
  bugtail: {
    base: 'feature/c-lda',
    files: [
      'matlab/fitLDA.m', 'matlab/transformLDA.m',
      'matlab/tests/test_LDA_math.m', 'matlab/tests/test_LDA_synthetic.m',
    ],
  },
  giakolan: {
    base: 'feature/d-bayes',
    files: ['matlab/fitBayes.m', 'matlab/predictBayes.m', 'tests/testBayes.m'],
  },
  uhumipaa: {
    base: 'feature/e-mlp',
    files: ['matlab/MLPtest.m', 'matlab/fitMLP.m', 'matlab/predictMLP.m'],
  },
  'cloud-sky-0128': {
    base: 'feature/f-cv-runner',
    files: [
      'matlab/createFoldManifest.m', 'matlab/loadFoldData.m',
      'matlab/prepareFHandoff.m', 'matlab/runFStageOne.m',
      'matlab/sha256File.m', 'matlab/validateFoldManifest.m',
      'matlab/validateTrainDataset.m', 'tests/testFoldManifest.m',
    ],
  },
};
const roleBranches = new Set(['feature/a-data-loader', ...Object.values(scopes).map((scope) => scope.base)]);
const integrationRoots = ['docs/', 'matlab/', 'tests/'];

function getRule(login) {
  const key = login?.toLowerCase();
  return Object.hasOwn(scopes, key) ? scopes[key] : undefined;
}

function integrationDirection(pr) {
  if (pr.baseRefName === 'main') return 'role-to-main';
  if (roleBranches.has(pr.baseRefName)) return 'main-to-role';
  throw new Error('Integration PRs must target main or a configured role branch.');
}

function usesIntegrationBranch(pr) {
  return pr.headRefName?.startsWith('integration/');
}

function changedPaths(git, base, head) {
  // Treat renames as delete/add, so both the old and the new path are checked.
  return git('diff', '--no-renames', '--name-only', '-z', `${base}...${head}`, '--')
    .split('\0')
    .filter(Boolean);
}

function auditIntegrationPaths(paths) {
  const outside = paths.filter((path) => !integrationRoots.some((root) => path.startsWith(root)));
  if (outside.length) {
    throw new Error(`Paths outside the integration folders (docs/, matlab/, tests/): ${JSON.stringify(outside)}`);
  }
}

function resolveHead(pr, git) {
  if (!/^[a-f0-9]{40}$/.test(pr.headRefOid)) throw new Error('Invalid PR head SHA.');
  const head = git('rev-parse', '--verify', `refs/face-audit/pr/${pr.number}`).trim();
  if (head !== pr.headRefOid) throw new Error('The PR head changed during the audit. Rerun it.');
  return head;
}

function auditIntegration(pr, git) {
  if (pr.isCrossRepository !== false) throw new Error('Integration PRs require a branch in the team repository.');
  const direction = integrationDirection(pr);
  if (pr.isDraft) throw new Error('Draft integration PRs are not ready for integration.');
  const head = resolveHead(pr, git);
  const base = git('rev-parse', '--verify', `refs/remotes/origin/${pr.baseRefName}`).trim();
  if (git('merge-base', base, head).trim() !== base) {
    throw new Error('Rebuild the integration branch from the current target branch.');
  }
  const paths = changedPaths(git, base, head);
  if (paths.length === 0) throw new Error('The PR has no file changes to integrate.');
  auditIntegrationPaths(paths);
  return { direction, base, head, paths };
}

export function audit(pr, git) {
  if (pr.state !== 'OPEN') throw new Error('The pull request is not open.');
  if (pr.author?.login?.toLowerCase() === 'heetah') {
    return usesIntegrationBranch(pr) ? auditIntegration(pr, git) : { skipped: true };
  }
  const rule = getRule(pr.author?.login);
  if (!rule) {
    throw new Error('No role is configured for this PR author.');
  }
  if (pr.baseRefName !== rule.base) {
    throw new Error(`The PR must target ${rule.base}.`);
  }
  if (pr.isDraft) throw new Error('Draft PRs are not ready for integration.');
  const head = resolveHead(pr, git);
  const role = git('rev-parse', '--verify', `refs/remotes/origin/${rule.base}`).trim();

  const paths = changedPaths(git, role, head);
  if (paths.length === 0) throw new Error('The PR has no role changes to audit.');
  auditIntegrationPaths(paths);
  const unexpected = paths.filter((path) => !rule.files.includes(path));
  if (unexpected.length) {
    throw new Error(`Paths outside the role allowlist: ${JSON.stringify(unexpected)}`);
  }
  return { role, head, paths };
}

function run(pullNumber) {
  if (!/^[1-9][0-9]*$/.test(pullNumber ?? '')) {
    throw new Error('Supply a positive PR number.');
  }
  const git = (...args) => execFileSync('git', args, { encoding: 'utf8', maxBuffer: 16 * 1024 ** 2 });
  const repo = process.env.GITHUB_REPOSITORY || 'heetah/Face-Learning';
  const pr = JSON.parse(execFileSync('gh', [
    'pr', 'view', pullNumber, '--repo', repo,
    '--json', 'number,author,baseRefName,headRefName,headRefOid,isCrossRepository,isDraft,state',
  ], { encoding: 'utf8' }));
  if (String(pr.number) !== pullNumber) throw new Error('Unexpected PR number returned by GitHub.');
  const rule = getRule(pr.author?.login);
  const maintainerIntegration = pr.author?.login?.toLowerCase() === 'heetah'
    && usesIntegrationBranch(pr) && pr.isCrossRepository === false
    && (pr.baseRefName === 'main' || roleBranches.has(pr.baseRefName));
  if (((rule && rule.base === pr.baseRefName) || maintainerIntegration) && !pr.isDraft && pr.state === 'OPEN') {
    // Fetch Git objects only. No PR checkout, hooks, build, or script execution.
    git('fetch', '--no-tags', 'origin',
      `+refs/heads/${pr.baseRefName}:refs/remotes/origin/${pr.baseRefName}`,
      `+refs/pull/${pullNumber}/head:refs/face-audit/pr/${pullNumber}`);
  }
  console.log(JSON.stringify(audit(pr, git), null, 2));
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  try {
    run(process.argv[2]);
  } catch (error) {
    console.error(`Role audit failed: ${error.message}`);
    process.exitCode = 1;
  }
}
