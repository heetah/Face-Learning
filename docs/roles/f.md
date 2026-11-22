# F — 五折驗證與結果整合｜AI 協作背景知識

## 專題背景與固定規格

本課程要用 MATLAB 建立人臉性別辨識系統，比較 PCA + Bayes、LDA + Bayes、PCA + MLP、LDA + MLP 四種方法；課程要求 200 張訓練圖（男女各 100）、五折交叉驗證，以及獨立的 100 張正式測試圖（男女各 50）。報告需包含 Accuracy、ROC/AUC、特徵維度、分類器參數量、訓練與推論時間。

MATLAB 是正式實驗環境；GitHub 分支放程式、合成測試與文件；人臉資料和逐筆預測放私人位置；網站只做教學展示。A 封裝資料、F 只用訓練集建立共同 folds、B/C 配對實作降維、D/E 配對實作分類器，最後由 A/F 整合四種管線和報告。正式測試資料等程式與設定鎖定後才交給 F。

目前交付的 train 資料夾含 200 張訓練圖；課程另規定獨立 100 張正式測試圖，由 A 向授課端取得並封存。不可自行製造測試資料，也不可把 validation fold 稱為正式測試結果。完整數學設定、資料契約、共同規範與 AI 使用方式見 docs/ 下四份共用文件。

## 六人共用的固定規格

- 專題比較四條 MATLAB 管線：PCA→Gaussian Naive Bayes、PCA→MLP、Fisher LDA→Gaussian Naive Bayes、Fisher LDA→MLP。
- 目前訓練資料是 200 張 640×640 RGB PNG，man/woman 各 100 張；每類 50 個檔名群組，每組 2 張。檔名第一段是此資料集的 class tag，第二段只當 fold group key，不宣稱是真實身分。
- A 產生私人 train_dataset.mat：X 為 200×1024 double、y 為 200×1 categorical、sampleID/groupID 各 200 筆、另有 preprocessSpec。X 的每列是一張影像，欄為特徵。
- 固定前處理：RGB 先轉 double 除以 255；每張 640×640 影像切成 32×32 個 20×20×3 區塊，對每個區塊全部 RGB 值取平均；按影像網格列優先展平成 1,024 維。各角色不得另做 resize、crop 或 scaling。
- F 產生私人 fold_manifest.csv，欄位 sampleID、groupID、label、outerFold。每類的 50 組以 Twister seed 2026 分別打散，平均分到五折；每折 validation 是 40 張、每類 20 張，train 是 160 張、每類 80 張。兩張同組影像永遠在同一折。
- 四條管線讀同一份 fold manifest。每折的 PCA/LDA 和分類器都只用該折 train fit；validation 僅 transform、predict 和計分。
- PCA q = 中心化 Xtrain 的 MATLAB rank；採 rank 預設 tolerance max(size(A))*eps(norm(A))。二分類 LDA 輸出 K−1=1 維；Sw 使用 SVD Moore-Penrose 最小範數解，不加猜測的 ridge 常數。
- Bayes 固定 fitcnb normal distribution、empirical prior。MLP 固定 fitcnet 一層 10-unit ReLU，Standardize=true、Lambda=0、IterationLimit=1000；每次 fit 前重設 Twister seed 2026。
- 正類固定 woman；prediction scores 欄位依 model.ClassNames 找出。交叉驗證報告 balanced accuracy 及 fold AUC 的 mean±sample SD；AUC 先逐 fold 計算。五折結果不得稱正式 test 結果。
- 影像、train_dataset.mat、原始檔名映射、fold manifest、sample-level predictions 和私人路徑不得上傳公開 GitHub 或網站。程式、schema、synthetic tests 和審核後的 aggregate results 才能公開。
- 全員使用同一 MATLAB release；每次 run 記錄 version -release、ver、Git commit、data/spec version 和設定。簡報與書面報告用相同的方法名、設定、指標和數字。

共用規格與交付文件：[PROJECT_SPECIFICATIONS.md](../PROJECT_SPECIFICATIONS.md) · [DATA_CONTRACT.md](../DATA_CONTRACT.md) · [TEAM_WORKING_RULES.md](../TEAM_WORKING_RULES.md) · [AI_COLLABORATION_GUIDE.md](../AI_COLLABORATION_GUIDE.md)


## 角色責任

產生唯一的 group-stratified fold manifest，執行四條 pipeline 的共同評估並整理簡報/報告數值。

此資料有 50 groups/class、每組2張、總200張。五折均分讓每折兩類各10 groups/20 images validation；不能用 sample-wise cvpartition 把同組照片拆開。Balanced accuracy=(sensitivityMan+sensitivityWoman)/2。AUC 要在每折各自用 woman score 計算，再平均；跨 fold models 的 scores 不 pooled 成單一 ROC。

## 手把手操作步驟

1. 載入 train_dataset.mat，驗證 X=200×1024、各類100筆、每類50組、每組2筆、sampleID/y/groupID與X列一致。
2. 設 rng(2026,'twister')。man、woman 各自取 50 個 groupID，以 randperm 打散；每 10 組指定 outerFold 1 到 5。
3. 建 fold_manifest.csv，每筆一列，欄位 sampleID/groupID/label/outerFold。驗證每個 group 只在一折；每折validation總40張、每類20張；train總160張、每類80張。
4. 保存一次 fold manifest；所有方法讀同一檔，不得各自再切分。資料異常時停止，不丟棄樣本後繼續。
5. 對 fold=1..5：取 train/validation rows；依序跑 PCA→Bayes、PCA→MLP、LDA→Bayes、LDA→MLP；所有 fit 僅收該折train，validation只做 transform/predict。
6. 保存每筆 OOF prediction 的 method、sampleID、groupID、fold、yTrue、yPred、score_man、score_woman；保存 fold-level confusion counts、accuracy、balancedAccuracy、sensitivity、AUC。
7. 每個 fold 內以 woman 為正類計算 AUC，再報五折 mean/sample SD；另彙整五折 OOF confusion counts 與 overall accuracy。分開計 fit/predict 秒數。
8. 寫 run_config.json（Git commit、MATLAB release、toolboxes、data/spec version、seed、pipeline settings），把 private predictions 給組員；彙總表與圖供簡報和書面報告引用。


## 和配對角色一起交付

和 A 對齊資料語意與固定前處理；和 B/C 核對每折 fit boundaries、q/rank 和 reducer summary；和 D/E 核對 ClassNames、score columns、predictions rows 和固定設定。F 統一結果名稱與統計定義。

## 交付檔案與驗收

matlab/createFoldManifest.m；matlab/runCV.m；synthetic fold/leakage tests；private fold_manifest.csv、oof_predictions.csv、fold_metrics.csv、summary_metrics.csv、run_config.json；核准後的報告圖表。

完成條件：
- 合成資料測試通過；尺寸、欄位、label order 和有限值檢查通過。
- 每次 fit 都限定在當前 fold 的 train rows；validation 僅 transform、predict、計分。
- 設定、版本、seed、資料契約與輸出欄位有紀錄。
- 配對角色 review 後，方法與實際 F 結果已同時放入簡報和書面報告。
- git diff --check 通過；公開 commit 沒有任何私有資料。

## 給 AI 的背景提示

我負責 F。依共同規格用合成 sample/group IDs 寫 createFoldManifest 和 runCV。驗證 group 不跨 fold、class balance、每折 counts、相同 manifest 被四種方法使用和所有 fit 僅看到 training indices。產生 private OOF、fold_metrics、summary_metrics、run_config schema；不要把逐筆影像資料放入公開 repo。

提供給 AI 的內容只含函式介面、synthetic arrays、非識別尺寸、MATLAB release/toolbox 和已遮蔽錯誤訊息。不要上傳臉部影像、X 特徵、sample-level predictions、原始檔名、私人路徑或憑證。AI 產生的 code 要先由組員 review，再在指定 MATLAB 環境執行。

## 五折整合入口

`runCV.m` 使用已整合的 B–E 模組執行四種方法；F 分支需先同步 main 中的這些模組。

```matlab
addpath('matlab');
assertSuccess(runtests('tests/testRunCV.m'));
results = runCV(matPath, manifestPath, outputFolder);
```

輸出指標 CSV、ROC 圖與執行紀錄。`outputFolder` 請指定私人位置下尚不存在的資料夾。

## 官方參考

https://www.mathworks.com/help/stats/cvpartition.html
