# B — PCA 降維｜AI 協作背景知識

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

實作每折獨立 fit 的 PCA 模型與 transform，和 C 對齊降維輸出，讓 D/E 能直接接分類器。

PCA 是以最大資料變異方向建立正交基底。fit 僅用 train rows。mu 是 1×D、w 是 D×q、Z 是 N×q。validation 套用相同的 mu/w。q 不做外層性能調參，而是取 MATLAB rank 的數值秩，容差使用 MATLAB 官方預設。

## 手把手操作步驟

1. 先用 synthetic 6×4 矩陣測試 orientation、fit/transform shape 和中心化。
2. 載入 A 的 train_dataset.mat、F 的 fold_manifest.csv；確認 sampleID 對齊、X 為 200×1024、y/groupID 各 200 筆。
3. 取 outerFold=k 的列為 validation，其餘為 train。跑 fitPCA(Xtrain, ytrain)，保存該折 mean mu 和 directions w。
4. q 固定為 rank(Xtrain−mu)，使用 MATLAB rank 的 documented default tolerance；目前每折 Ntrain=160，q≤159。由 pca(...,'Algorithm','svd') 取得係數，只保留 1:q 欄。
5. 對 train 和 validation 都執行 Z=(X−mu)*w。validation 不重算平均或方向；五折各自重新 fit。
6. 每折記錄 q、explained variance、fitSeconds、transformSeconds 和 shape assertions。與 C 合併成 reduction_summary.csv，交給 D/E/F。
7. 把 PCA 示意圖、q 定義、各折實測 q/變異解釋率、限制與 F 核准的結果放入簡報和書面報告。


## 和配對角色一起交付

B/C 使用同一 X、同一 fold manifest、相同 fit/transform 契約；比較 PCA 無監督投影與 LDA 使用 y 的判別軸。共同交 reduction_summary.csv（每個 reducer/fold 一列：nTrain、nValid、inputD、outputQ、rank、fit/transform 秒數）。D/E 透過同一 reducer API 接線。

## 交付檔案與驗收

matlab/fitPCA.m；matlab/transformPCA.m；synthetic PCA tests；private reduction_summary.csv；報告中的 PCA 方法與 fold 結果。

完成條件：
- 合成資料測試通過；尺寸、欄位、label order 和有限值檢查通過。
- 每次 fit 都限定在當前 fold 的 train rows；validation 僅 transform、predict、計分。
- 設定、版本、seed、資料契約與輸出欄位有紀錄。
- 配對角色 review 後，方法與實際 F 結果已同時放入簡報和書面報告。
- git diff --check 通過；公開 commit 沒有任何私有資料。

## 給 AI 的背景提示

我負責 B。請依共同規格寫 fitPCA(Xtrain, ytrain) 與 transformPCA(model,X)。先推導 mu/w/Z 的矩陣尺寸，再用 MATLAB pca Algorithm svd 和 rank 預設容差決定 q。附 synthetic low-rank 測試、train/validation 使用同一 model 的測試、有限值及列順序檢查；不要加 q 門檻或 tuning。

提供給 AI 的內容只含函式介面、synthetic arrays、非識別尺寸、MATLAB release/toolbox 和已遮蔽錯誤訊息。不要上傳臉部影像、X 特徵、sample-level predictions、原始檔名、私人路徑或憑證。AI 產生的 code 要先由組員 review，再在指定 MATLAB 環境執行。

## 官方參考

https://www.mathworks.com/help/stats/pca.html；https://www.mathworks.com/help/matlab/ref/rank.html
