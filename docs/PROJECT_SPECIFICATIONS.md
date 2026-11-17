# Face-Learning project specifications v1.1

This file records the team's chosen implementation rules. It separates measured facts about the current image folder from engineering choices made so all six people can run the same experiment. If the course handout explicitly requires a different method, follow the handout and record the change in a reviewed commit before running results.

## Project goal

The course handout, PR_2026_專題說明文件_v1.pdf, requires a MATLAB gender-recognition system comparing four pipelines: PCA + Bayes, LDA + Bayes, PCA + MLP, and LDA + MLP. Each pipeline must use five-fold cross-validation on the training set and report accuracy, ROC/AUC, feature dimension, classifier parameter count, training time, and inference time. The handout also specifies a separate 100-image test set for final evaluation after training and cross-validation.

MATLAB is the formal implementation and experiment environment. GitHub contains source, schemas, synthetic tests, and reviewed documentation. The public FaceLab website is a teaching demonstration; its browser weights are not MATLAB weights or formal course results.

This file separates course requirements, facts checked in the supplied data, and engineering choices made so all six people can run the same experiment. When an implementation choice conflicts with a course requirement, the course requirement takes precedence and the team records the agreed change in a reviewed commit before running results.

## Facts and course requirements checked for v1.1

The course handout specifies 200 training images (100 per class) and a separate 100-image test set (50 per class). The supplied train folder checked for this update contains 200 PNG images: 100 tagged man and 100 tagged woman. All checked training files are 640 × 640 RGB PNGs. Their names follow class_group_image.png; each class has 50 filename groups with two images each.

For this project, the first filename token is the dataset class tag and the second token is the split group key. The group key keeps the two filename-paired training images in one fold; it is not a claim about a person's identity. Do not publish the original filename list.

The current handoff contains the 200 training PNGs. The course handout requires a separate official test package of 100 images (50 per class); A obtains this package from the instructor or another authorized source and stores it separately. The checked training folder contains no test images. Do not substitute a validation fold or create test images from the training set.

The training-image shape and color mode are measured facts. A verifies the official test image dimensions and RGB mode before conversion. If they differ from the fixed training input, stop and agree on a revised shared preprocessing contract; do not silently resize, crop, or convert them.

## A's handoff files

A creates these files in the team's approved private data location, outside the public repository:

- train_dataset.mat: the shared training feature matrix and labels. It contains X (200 × 1,024 double; one image per row), y (200 × 1 categorical with categories man and woman), anonymous sampleID and groupID values, and preprocessSpec.
- test_dataset.mat: a separate package for the official 100-image test set, containing X, y, anonymous sampleID/groupID, and preprocessSpec. The expected X shape is 100 × 1,024 only after A confirms the test images match the agreed input dimensions and RGB mode. If they do not, pause and update the contract first.
- data_manifest.csv and test_data_manifest.csv: private audit tables mapping each package's sample IDs to source filenames, labels, group IDs, dimensions, and read status. Keep both outside GitHub and the public Site.
- data_quality_summary.csv: counts and validation checks without filenames or full paths.

The test package remains sealed while the team implements, cross-validates, compares, or changes methods. A releases it to F only after the code and settings are frozen for final evaluation. Do not put either dataset, derived face features, filename maps, or sample-level predictions in GitHub, a public Site, or an AI prompt.

The row order within each package is fixed: class tag man before woman, then source filename in case-sensitive lexicographic order. Keep X, y, sampleID, and groupID aligned within that package. Training fold manifests contain training sample IDs only; test samples never enter cross-validation.

## Fixed image conversion

Every training image checked for v1.1 is a 640 × 640 RGB PNG. A rejects a training file that does not match that shape or color mode; do not silently crop, rotate, convert color, or substitute a different resize method. Apply the same conversion to the official test set only after confirming it has the same shape and RGB mode. If not, pause and revise this shared contract before evaluation.

For each image:

1. Convert pixel values to double precision and divide by 255, giving values in [0, 1].
2. Divide each 640 × 640 image into a 32 × 32 grid of non-overlapping blocks. Each block is therefore 20 × 20 pixels because 640 ÷ 32 = 20.
3. For each block, average every pixel's three RGB channel values. This gives one number per grid cell in [0, 1].
4. Flatten the 32 × 32 grid in row-major order. The resulting row has 1,024 features.

This matches the existing FaceLab teaching baseline and keeps the formal input small enough for the six-person MATLAB workflow. It is a fixed teaching baseline, not a claim that 32 × 32 is the best resolution. Every pipeline uses exactly this X; no role may add a private preprocessing step.

## Fixed fold plan

F owns one shared, deterministic, class-balanced, group-preserving five-fold manifest built from the 200 training images only. The 100 official test images are excluded from the manifest and from every cross-validation fit, validation, or setting choice.

- Set the MATLAB random generator to Twister with seed 2026 before creating the split. The seed is the project year and is fixed before comparing any model; it is a reproducibility setting, not a performance-tuning parameter.
- Shuffle the 50 group IDs separately within each class, then assign 10 groups of each class to each outer fold.
- Each validation fold therefore contains 20 groups and 40 images: 10 groups and 20 images per class. Each corresponding training fold contains 80 groups and 160 images: 40 groups and 80 images per class.
- Never split the two images belonging to the same group across folds.
- Save one row per sample in fold_manifest.csv with sampleID, groupID, label, and outerFold (1–5). All four pipelines read this exact training-only file. The official test package never appears in fold_manifest.csv.
- Check that every sample appears once as validation, no group appears in multiple validation folds, and each fold has the expected class and group counts.

F writes the manifest explicitly rather than relying on an ungrouped random split. This makes the grouping rule visible and reproducible across MATLAB releases.

There is no inner tuning loop in v1.0: PCA dimension is determined by training-fold numerical rank, LDA dimension follows the binary-class derivation, Gaussian Naive Bayes uses one fixed distribution, and MLP uses one fixed baseline architecture. Therefore no outer validation row is used to choose settings.

## Four fixed methods

### B — PCA

For each outer fold, fit PCA only on Xtrain. Center by that fold's column mean. Retain every numerically supported centered direction: q = rank(Xtrain − mean(Xtrain, 1)), using MATLAB rank's documented default tolerance max(size(A)) × eps(norm(A)). With 160 training rows, q cannot exceed 159; with 1,024 input features, PCA reduces the current input to at most 159 dimensions.

Store the training mean, directions, rank tolerance behavior, q, and explained-variance summary. Transform both training and validation rows with the same saved mean and directions. Do not fit PCA once on all 200 rows.

### C — Fisher LDA

Use the same row-per-image X and the aligned training-fold y. There are two classes, so the between-class mean differences span at most K − 1 = 1 direction. LDA therefore outputs exactly one feature when a valid direction exists.

The within-class residual matrix R has one row per training image and one column per input feature. Sw = R'R. With 160 training rows and two class means, rank(Sw) is at most 160 − 2 = 158, so Sw is singular for this 1,024-feature input. Do not call inv(Sw) or add a guessed ridge constant.

Use a thin SVD of R and MATLAB's documented numerical-rank tolerance. If R = UΣV', retain only the supported singular directions Vr and compute the minimum-norm Fisher solution w = Vr diag(1 ./ sr.^2) Vr' (mu_woman − mu_man). Normalize w and orient it so the woman training mean projects above the man training mean. Record rank(R), the tolerance used, and any degenerate-fold error. If no valid direction exists, stop that fold and report it; do not hide it with an arbitrary epsilon.

### D — Gaussian Naive Bayes

Use MATLAB fitcnb with DistributionNames set to normal and Prior set to empirical. The model estimates a Gaussian distribution for each feature within each class and assumes conditional feature independence. The outer training fold is balanced, so empirical class priors are equal. Do not add kernel smoothing or tune the distribution in v1.0.

### E — MLP

Use MATLAB fitcnet with one hidden fully connected layer of 10 units, ReLU activation, predictor standardization enabled, Lambda set to 0, and IterationLimit set to 1000. Use Twister seed 2026 immediately before fitting each fold. The 10-unit ReLU layer is the documented fitcnet baseline; it is fixed for reproducibility, not claimed optimal. Do not tune the network on outer validation data.

Record the exact MATLAB release, toolbox versions, training history, and model properties. Train on Ztrain only; fitcnet's standardization must be learned from that training matrix and then reused for validation. For input width d, hidden width h = 10, and two classes, trainable weights and biases total h(d + 1) + 2(h + 1) = 10d + 32. Report this count separately from standardization statistics.

## Shared MATLAB interface

All functions use rows as observations and columns as features.

- X: N × 1024 double.
- y: N × 1 categorical; category names man and woman.
- sampleID and groupID: one value per row, in exactly the same order.
- PCA: fitPCA(Xtrain, ytrain) returns a model; transformPCA(model, X) returns N × q.
- LDA: fitLDA(Xtrain, ytrain) returns a model; transformLDA(model, X) returns N × 1.
- Classifiers: fit on transformed training rows and ytrain; predict the validation rows and return predicted labels, continuous class scores, and the model's classNames.

The positive class for reported sensitivity and ROC/AUC is woman. Always locate the corresponding score column by comparing classNames; never assume a score column index.

## Required results and definitions

### Five-fold cross-validation on the 200 training images

F keeps one out-of-fold row per training sample and one fold summary per method:

- oof_predictions.csv (private): method, sampleID, groupID, outerFold, yTrue, yPred, score_man, score_woman.
- fold_metrics.csv: method, fold, nTrain, nValid, confusion counts, accuracy, balancedAccuracy, sensitivityMan, sensitivityWoman, and AUC.
- reduction_summary.csv: reducer, fold, input dimension, output dimension, data rank, LDA within-class rank where applicable, and fit/transform seconds.
- classifier_summary.csv: pipeline, fold, classifier settings, classNames order, trainable parameter count where applicable, and fit/predict seconds.
- run_config.json: Git commit, MATLAB release, toolbox versions, data/spec version, fold seed, class order, method settings, and a hash of the private data package without the local path.
- summary_metrics.csv: the five-fold mean and sample standard deviation for accuracy, balanced accuracy, AUC, training time, and validation inference time; also include pooled out-of-fold confusion counts and overall accuracy.

Accuracy, ROC curves, AUC, feature dimensions, classifier parameter counts, training time, and inference time are required by the course handout. Balanced accuracy is an additional class-aware metric selected by the team. The positive class for sensitivity and ROC/AUC is woman; locate the corresponding score column by comparing classNames, never by assuming a column index. Calculate AUC separately within each outer fold, then report mean ± sample standard deviation; do not pool scores from different fold models into one ROC curve. Use the same folds for every pipeline and record model fit and validation prediction time separately.

### Final evaluation on the separate 100-image test set

After all four pipelines pass review and their code and settings are frozen, F runs each pipeline once using all 200 training images to fit the reducer and classifier, then evaluates on the separate official 100-image test set. Test images are transformed by the already-fitted training models; never fit PCA, LDA, classifier standardization, or any other data-dependent step on test images. Do not tune or revise settings based on test results.

- final_test_summary.csv (aggregate only): pipeline, nTrain, nTest, accuracy, balancedAccuracy, AUC, reduced feature dimension, classifier parameter count, full-training fit seconds, and inference seconds for the 100 test images.
- Keep test labels, per-image predictions, scores, and confusion details in the approved private location. Only reviewed aggregate results may be committed or published.
- For the final model's ROC/AUC, use its continuous test scores with woman as the positive class. Report accuracy and AUC as the course requires; balanced accuracy is supplementary.
- Report the five-fold timing summary and the final full-training fit/test-inference timings as separate quantities. Do not mix them.

Run the final test after A obtains the official 100-image package and the team freezes code and settings. Before that handoff, label final test evaluation as not run; report the cross-validation results separately. Never substitute a validation fold for the official test set.

## Pair work and final handoff

B and C meet to test both reducer interfaces on the same synthetic matrix, then use the same training folds. They deliver fit/transform functions, reduction_summary.csv, rank/dimension explanations, and an agreed diagram showing image vector → reduced features.

D and E can validate their classifier interfaces in parallel with B/C by using synthetic feature matrices. Once the reducer APIs are ready, they connect both reducers and run Bayes/MLP on the same training folds. They agree on classNames and score columns, then give F the private out-of-fold predictions and classifier settings for all four combinations.

A prepares and checks the separate training and test packages; F creates the training-only manifest, runs the common cross-validation, and coordinates final test evaluation after settings are frozen. A and F check labels, group handling, fold counts, metric names, and report wording. Every person adds their method explanation and verified results to both the presentation and written report. Use the same method names, settings, metric definitions, and values in both documents. Do not fill in test results until the official test set is available and F has produced them.

## Privacy and review

Keep training and official test images, train_dataset.mat, test_dataset.mat, filename mappings, test labels, sample-level predictions, raw feature matrices, private paths, and credentials outside public GitHub and the public Site. Public commits contain code, schema, synthetic tests, and non-identifying aggregate documentation only. Do not put face data or file inventories in prompts to AI tools.

## Technical references

- MATLAB pca: https://www.mathworks.com/help/stats/pca.html
- MATLAB rank and its default numerical tolerance: https://www.mathworks.com/help/matlab/ref/rank.html
- MATLAB fitcnb: https://www.mathworks.com/help/stats/fitcnb.html
- MATLAB fitcnet: https://www.mathworks.com/help/stats/fitcnet.html
- MATLAB cvpartition: https://www.mathworks.com/help/stats/cvpartition.html
- Fisher's original paper: https://doi.org/10.1111/j.1469-1809.1936.tb02137.x
