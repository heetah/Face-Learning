# FaceLab team working rules

## Purpose and source of requirements

The course handout requires a MATLAB gender-recognition project comparing PCA + Bayes, LDA + Bayes, PCA + MLP, and LDA + MLP. Run five-fold cross-validation on 200 training images (100 per class), then evaluate on a separate 100-image official test set (50 per class) after the code and settings are frozen. MATLAB is the formal experiment environment; the public website is a teaching demo.

The selected implementation details are in [PROJECT_SPECIFICATIONS.md](PROJECT_SPECIFICATIONS.md), and file shapes are in [DATA_CONTRACT.md](DATA_CONTRACT.md). If an engineering choice conflicts with the course handout, follow the handout and record the agreed change before rerunning results.

## Before coding

1. Read the project specifications, data contract, common rules, and your branch's README.md and AGENTS.md.
2. Get train_dataset.mat from the approved private team location. F creates fold_manifest.csv from these training samples only.
3. A keeps the official test_dataset.mat in a separate private location. Do not inspect or use its labels while implementing, cross-validating, comparing, or changing methods. F receives it only after the code and settings are frozen.
4. Check the MATLAB release and required functions with version -release, ver, and which functionName -all.
5. Run synthetic checks before using private training data.
6. Ask the partner responsible for the adjacent pipeline to verify function inputs, outputs, labels, and score order.

## Collaboration rules

- X rows are images; X columns are the 1,024 agreed block-average features. y, sampleID, and groupID stay aligned.
- Each training fold holds out whole filename groups, with class balance preserved. All four pipelines use F's exact training-only fold manifest.
- Fit preprocessing, PCA/LDA, classifiers, and any future model options only on the current training fold. Test images never enter CV or setting choices.
- Use only the settings in PROJECT_SPECIFICATIONS.md. A method change requires a written rationale, review by the affected pair, and an updated commit before results are rerun.
- B/C coordinate reducer fit/transform interfaces. D/E coordinate classifier labels and score outputs. A/F coordinate data, split, metrics, final test timing, slides, and report language.

## Data handling

Face pixels, training/test feature matrices, source filename maps, test labels, sample-level predictions, private paths, tokens, and passwords stay in the approved private location. Public GitHub and the public website contain code, documentation, synthetic examples, and reviewed aggregate results only.

## Reporting

F supplies separate five-fold and final-test result tables. Report course-required accuracy, ROC/AUC, feature dimensions, classifier parameter counts, training time, and inference time. Label cross-validation and official test results separately. Each person adds their method explanation and verified contribution to both the presentation and written report. Use the same names, settings, metric definitions, and values in both. Never describe training accuracy or cross-validation as the official test result. When A has not received the official test package, complete cross-validation and label final test evaluation as not run.

## Git workflow

1. **Start from your assigned team branch.** Run `git status --short` and fetch the team remote. Use `git fetch upstream` if `origin` is your fork, or `git fetch origin` if `origin` is the team repository. Branch from the remote-tracking ref for your role. If your work needs an interface change from `main`, coordinate a targeted update to your team branch with heetah.
2. **Review the diff against the PR target.** Use `git status --short` to find new files, `git diff` for unstaged edits, and `git diff --cached` for staged edits. Stage named files and use `git diff --cached --check` before committing. For a Bayes PR, review `git diff upstream/feature/d-bayes...HEAD`. Substitute your assigned branch and team remote, then confirm the intended files in GitHub's **Files changed** tab.
3. **Coordinate changes that cross role boundaries.** If another role's code or a shared interface needs to change, tell the owner which file or interface is affected, why the change is needed, and how it will be tested. Agree who will implement and review it before editing. If the two changes are delivered separately, link the dependent PRs so F knows which versions to test together.

Push your task branch and open a PR to your assigned team branch. The role audit checks authorship, the target branch, and assigned file paths. Request review and record the MATLAB release, tested commit, and test result.

When role changes are ready to integrate, the maintainer starts an `integration/*` branch from the current `main`, brings in the reviewed changes, and opens a PR to `main`. If `main` advances, update the integration branch before merging. For MATLAB or test changes, check the **MATLAB integration** workflow, which exercises the shared fold handoff to PCA and LDA with synthetic data. Keep private data out of commits and leave shared branch history intact.

## AI use

Share code, synthetic arrays, non-identifying shapes, MATLAB release, and exact error text after removing paths and filenames. Ask the AI to state assumptions and explain equations and every numeric setting. Do not share face images, raw feature vectors, official test data or labels, sample-level test predictions, or private file mappings.
