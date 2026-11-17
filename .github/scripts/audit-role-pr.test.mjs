import assert from 'node:assert/strict';
import { test } from 'node:test';
import { audit } from './audit-role-pr.mjs';

const main = 'a'.repeat(40);
const role = 'b'.repeat(40);
const head = 'c'.repeat(40);
const pr = {
  number: 9, author: { login: 'liupiyan' }, baseRefName: 'feature/b-pca',
  headRefOid: head, state: 'OPEN', isDraft: false,
};

function gitFixture({
  staleHead = false, paths = ['matlab/fitPCA.m'], base = pr.baseRefName,
} = {}) {
  const target = base === 'main' ? main : role;
  return (command, ...args) => {
    if (command === 'rev-parse') {
      if (args[1] === `refs/remotes/origin/${base}`) return target;
      if (args[1] === 'refs/face-audit/pr/9') return head;
    }
    if (command === 'merge-base') {
      assert.deepEqual(args, [target, head]);
      return staleHead ? 'd'.repeat(40) : target;
    }
    if (command === 'diff') {
      assert.deepEqual(args, ['--no-renames', '--name-only', '-z', `${target}...${head}`, '--']);
      return paths.join('\0');
    }
    assert.fail(`Unexpected git call: ${command} ${args}`);
  };
}

test('audits a role PR using only its target branch and PR head', () => {
  assert.deepEqual(audit(pr, gitFixture()), { role, head, paths: ['matlab/fitPCA.m'] });
});

test('rejects unknown authors, wrong destinations and drafts', () => {
  assert.throws(() => audit({ ...pr, author: { login: 'stranger' } }), /No role/);
  assert.throws(() => audit({ ...pr, author: { login: 'constructor' } }), /No role/);
  assert.throws(() => audit({ ...pr, baseRefName: 'main' }), /must target feature\/b-pca/);
  assert.throws(() => audit({ ...pr, isDraft: true }), /Draft/);
});

test('excludes the maintainer from the member policy', () => {
  assert.deepEqual(audit({ ...pr, author: { login: 'heetah' } }), { skipped: true });
});

test('rejects a changed PR head', () => {
  assert.throws(() => audit({ ...pr, headRefOid: role }, gitFixture()), /head changed/);
});

test('rejects changes to other roles, workflow files and empty payloads', () => {
  for (const path of ['matlab/fitLDA.m', '.github/workflows/audit-role-pr.yml', 'assets/example.png']) {
    assert.throws(() => audit(pr, gitFixture({ paths: ['matlab/fitPCA.m', path] })), /outside/);
  }
  assert.throws(() => audit(pr, gitFixture({ paths: [] })), /no role changes/);
});

test('accepts the actual Bayes and MLP author/branch/path mappings', () => {
  const bayes = { ...pr, author: { login: 'Giakolan' }, baseRefName: 'feature/d-bayes' };
  const mlp = { ...pr, author: { login: 'uhumipaa' }, baseRefName: 'feature/e-mlp' };
  for (const [candidate, paths] of [
    [bayes, ['matlab/fitBayes.m', 'matlab/predictBayes.m', 'tests/testBayes.m']],
    [mlp, ['matlab/MLPtest.m', 'matlab/fitMLP.m', 'matlab/predictMLP.m']],
  ]) {
    assert.deepEqual(audit(candidate, gitFixture({ base: candidate.baseRefName, paths })).paths, paths);
  }
  assert.throws(() => audit({ ...bayes, baseRefName: mlp.baseRefName }), /must target feature\/d-bayes/);
});

const integration = {
  ...pr, author: { login: 'heetah' }, headRefName: 'integration/pca', isCrossRepository: false,
};

for (const [base, direction] of [['main', 'role-to-main'], ['feature/b-pca', 'main-to-role']]) {
  test(`${direction} admits only the three integration folders`, () => {
    const candidate = { ...integration, baseRefName: base };
    const paths = ['docs/roles/b.md', 'matlab/private/pool.m', 'tests/testPCA.m'];
    assert.equal(audit(candidate, gitFixture({ paths, base })).direction, direction);
    for (const path of ['README.md', 'AGENTS.md', '.github/workflows/check.yml', 'assets/map.svg', 'docs-old/old.md', 'docs']) {
      assert.throws(() => audit(candidate, gitFixture({ paths: [...paths, path], base })),
        /outside the integration folders/);
    }
    assert.throws(() => audit(candidate, gitFixture({ base, staleHead: true })),
      /current target branch/);
  });
}

test('integration requires a team branch and a configured destination', () => {
  assert.throws(() => audit({ ...integration, isCrossRepository: true }, gitFixture()), /team repository/);
  assert.throws(() => audit({ ...integration, baseRefName: 'other' }, gitFixture()), /configured role/);
});
