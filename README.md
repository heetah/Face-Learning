# Face-Learning｜MATLAB 人臉影像分類專題

本專題比較 PCA ＋ Gaussian Naive Bayes、LDA ＋ Gaussian Naive Bayes、PCA ＋ MLP、LDA ＋ MLP。四種方法共用影像前處理與分組五折。正式實驗在 MATLAB 執行。[FaceLab 網站](https://face-learning-lab-heetah-20261015.divine-siren-9327.chatgpt.site/)提供課程概念與操作示範。

## 目前進度

| 分支 | 可用功能 |
| --- | --- |
| [`main`](https://github.com/heetah/Face-Learning/tree/main) | 已包含 A–E 的資料前處理、PCA、Fisher LDA、Gaussian Naive Bayes、MLP，以及 F 的五折分組建立與載入。 |
| [`develop/Phase-1`](https://github.com/heetah/Face-Learning/tree/develop/Phase-1) | 已合併四種方法的五折執行入口 `runCV` 與 `testRunCV` 合成整合測試。 [PR #36](https://github.com/heetah/Face-Learning/pull/36) |

訓練集有 200 張影像，每張轉為 1,024 個特徵。同組影像放在同一折，每折 160 筆訓練、40 筆驗證。正式評估另需 100 張獨立測試圖，待程式與設定定稿後執行。

## 快速開始

### 1. 下載開發分支

首次下載：

```bash
git clone --branch develop/Phase-1 https://github.com/heetah/Face-Learning.git
cd Face-Learning
```

已經有 clone 的組員，切到本地的 `develop/Phase-1` 後執行 `git pull --ff-only`。若尚未建立本地分支，可用 `git fetch origin` 再執行 `git switch --track origin/develop/Phase-1`。

### 2. 確認本機 MATLAB 和工具箱

在 MATLAB 將 **Current Folder** 設為 `Face-Learning` 根目錄。在你實際要執行專題的 MATLAB 中確認版本與工具箱：

```matlab
version
ver stats
which fitcnb
which fitcnet
which perfcurve
```

Bayes 訓練、MLP 訓練和 ROC／AUC 分別使用 `fitcnb`、`fitcnet` 和 `perfcurve`，皆需 **Statistics and Machine Learning Toolbox**。三支函式都要能找到路徑。若授權可用但函式找不到，確認該 MATLAB 環境已安裝並能載入工具箱。

Windows 桌面版請使用 [MathWorks Downloads](https://www.mathworks.com/downloads/) 的 **Windows** 安裝程式。若已有 MATLAB，用相同 release 的安裝程式補裝工具箱。MATLAB Online 顯示的 Linux 版本是瀏覽器所連的雲端環境。 [MathWorks 補裝工具箱說明](https://www.mathworks.com/help/install/ug/add-to-existing-installation.html)

### 3. 先跑完整合成測試

下列指令會用合成資料驗證四種方法與共用五折，並檢查指標和輸出檔。

```matlab
clear
clc
addpath(fullfile(pwd, 'matlab'), '-begin')
assertSuccess(runtests(fullfile('tests', 'testRunCV.m')));
```

若需要單獨檢查分折與降維介面，可執行 `assertSuccess(runtests('tests/testFoldReducerIntegration.m'))`。單獨驗證 Bayes 可執行 `run('tests/testBayes.m')`。

### 4. 用私有資料跑完整五折

由 A 執行 [`prepareData`](matlab/prepareData.m) 產出私有的 `train_dataset.mat`。F 如已提供同一份訓練資料對應的 `fold_manifest.csv`，直接使用即可。若還沒有清單，由 F 執行 [`runFStageOne`](matlab/runFStageOne.m)，使用 `outputPaths.manifest` 取得新清單路徑。

```matlab
matPath = 'path/to/train_dataset.mat';
manifestPath = 'path/to/fold_manifest.csv';

privateFolder = uigetdir(pwd, 'Select a private output folder outside the Git repo');
assert(~isequal(privateFolder, 0), 'No output folder selected.');
outputFolder = tempname(privateFolder);

results = runCV(matPath, manifestPath, outputFolder);
disp(results.summaryMetrics)
disp(outputFolder)
```

把前兩個路徑換成你的私人資料路徑。選擇 **Git repo 外已存在的私人資料夾**，`runCV` 會在裡面建立新的結果子資料夾。成功後應有四列方法摘要、20 列逐折指標，並輸出 `summary_metrics.csv`、`fold_metrics.csv`、`cv_roc.png` 和 `run_config.json`。逐筆預測 `oof_predictions.csv`、MAT 資料、影像、原始檔名對照和分折清單都留在團隊核准的私人位置。

獨立測試要在五折完成、設定固定後，使用全部 200 張訓練圖重訓，再評估另外 100 張測試圖。`runCV` 的輸出用於五折驗證。

## 新版 GitHub 協作流程

1. 從團隊 repo 最新的 `develop/Phase-1` 開工作分支。功能用 `feature/<名稱>`，修正用 `fix/<名稱>`。分支名稱依這次工作命名。
2. 在自己的分支修改與測試。提交前檢查 `git status --short` 和 `git diff --check`，並只 stage 本次要交付的檔案。
3. 推到團隊 repo，開 PR，**base 選 `develop/Phase-1`**。在 **Files changed** 確認範圍，並附上執行過的測試及結果。
4. 等整合版本穩定後，由團隊開 **`develop/Phase-1` → `main`** 的 PR。

以下以修改 README 為例，假設 `origin` 指向團隊 repo：

```bash
git fetch origin
git switch -c fix/readme-instructions origin/develop/Phase-1
# 編輯並核對 README 後
git diff --check
git add -- README.md
git commit -m "Update setup and collaboration instructions"
git push -u origin fix/readme-instructions
```

**Audit role pull request** 已停用。**MATLAB integration** 目前在符合路徑條件、目標為 `main` 的團隊 repo PR 上執行，涵蓋共用五折與 PCA／LDA 的介面。送 `develop/Phase-1` 的 PR 時，在 MATLAB 執行適用的合成測試並把結果寫進 PR。

## 相關文件

- [專題規格](docs/PROJECT_SPECIFICATIONS.md)
- [資料契約](docs/DATA_CONTRACT.md)
- [A 的資料準備指引](docs/A_DATA_PREPARATION.md)
- [F 的五折與評估指引](docs/roles/f.md)
- [AI 協作指引](docs/AI_COLLABORATION_GUIDE.md)
