# D — Gaussian Naive Bayes 分類器｜AI 協作背景知識

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

對 PCA/LDA 特徵分別訓練 Gaussian Naive Bayes，回傳清楚的類別、分數和 fit/predict 記錄。

Gaussian Naive Bayes 以每個 class/feature 的 Gaussian 分布估計 likelihood，並假設給定 class 後各 feature conditionally independent。固定 normal/empirical，不在 validation 選分布或先驗。MATLAB scores 欄位順序以 model.ClassNames 為準。

## 手把手操作步驟

1. 先和 E 用 synthetic Z 對齊 fit/predict input、label type、ClassNames 和 scores 欄位。
2. 載入 A 的 MAT 與 F 的 CSV，驗證 sampleID 列順序；每一 fold 取得 Xtrain/ytrain 和 Xvalid/yvalid。
3. 建 PCA→Bayes 線：用 B 的 fitPCA(Xtrain) fit reducer；transform train 和 validation；只用 Ztrain/ytrain fitcnb。
4. 建 LDA→Bayes 線：用 C 的 fitLDA(Xtrain,ytrain) fit reducer；transform train 和 validation；只用 Ztrain/ytrain fitcnb。
5. 固定 fitcnb 的 DistributionNames='normal'、Prior='empirical'；不加平滑、不調分布。外層 training 每類等量，empirical priors 會依該 fold 實際頻率估計。
6. 對 validation 呼叫 predict。保存 yhat、scores、model.ClassNames；用 ClassNames 找 woman 分數欄，不能硬寫欄號。
7. 每個 fold/兩條 Bayes pipeline 都記錄 fitSeconds、predictSeconds、class names、設定和錯誤檢查；sample-level oof_predictions.csv 逐筆列私下交 F；欄位依共同規格。
8. 與 E 合併 classifier_summary.csv；和 E 一起把 Bayes 假設、兩組結果、限制和 F 的指標放進簡報與書面報告。


## 和配對角色一起交付

D/E 用完全相同的 reducer outputs、outer fold、y、正類 woman 和 score 欄位。D 產 PCA→Bayes、LDA→Bayes；E 產 PCA→MLP、LDA→MLP。共同交 classifier_summary.csv 與私有 oof_predictions.csv 的四條 pipeline rows 給 F，並互相審閱假設、曲線和結果名稱。

## 交付檔案與驗收

matlab/fitBayes.m；matlab/predictBayes.m；synthetic score-order tests；private classifier_summary.csv、私有 oof_predictions.csv 的兩條 pipeline rows；簡報與書面報告中的 Bayes 假設與結果。

完成條件：
- 合成資料測試通過；尺寸、欄位、label order 和有限值檢查通過。
- 每次 fit 都限定在當前 fold 的 train rows；validation 僅 transform、predict、計分。
- 設定、版本、seed、資料契約與輸出欄位有紀錄。
- 配對角色 review 後，方法與實際 F 結果已同時放入簡報和書面報告。
- git diff --check 通過；公開 commit 沒有任何私有資料。

## 給 AI 的背景提示

我負責 D。依共同規格用 fitcnb DistributionNames=normal、Prior=empirical，建立 PCA/LDA 共用的 fit/predict wrapper。用 synthetic matrices 驗證 labels、scores、ClassNames、woman score 查找和 train-only fit。不要新增 smoothing 或 hyperparameter optimization。

提供給 AI 的內容只含函式介面、synthetic arrays、非識別尺寸、MATLAB release/toolbox 和已遮蔽錯誤訊息。不要上傳臉部影像、X 特徵、sample-level predictions、原始檔名、私人路徑或憑證。AI 產生的 code 要先由組員 review，再在指定 MATLAB 環境執行。

## 官方參考

https://www.mathworks.com/help/stats/fitcnb.html
