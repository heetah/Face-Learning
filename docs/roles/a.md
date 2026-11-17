# A — 資料整理與共用介面｜AI 協作背景知識

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

整理原始影像並產生全組唯一的 train_dataset.mat；A 不切 fold、不 fit PCA/LDA、不訓練 classifier。

A 是所有方法的輸入邊界。每筆 sampleID、groupID、y 必須與 X 的相同行完全對齊。當資料條件不符合已定規格時，停止產檔並留下無檔名錯誤摘要。train_dataset.mat 是影像衍生特徵，仍需按人臉資料管理。

## 手把手操作步驟

1. 在 MATLAB 先記錄 version -release、ver；Current Folder 切到 Face-Learning repo 根目錄。
2. 將 trainRoot 設成只含本次訓練 PNG 的私人資料夾。執行 dir(fullfile(trainRoot,'*.png'))，依檔名排序，檢查檔名格式 class_group_image.png。
3. 解析第一段成 man/woman 標籤；前兩段形成 split group key。建立 sampleID S0001…S0200 與匿名 groupID G0001…G0100；原始檔名和對照表只保留在私人 data_manifest.csv。
4. 每張圖用 imread 讀取，拒絕非 640×640 RGB 檔。double(I)/255 後分成 32×32 格，每格平均 20×20×3 個值。將網格轉置後 row-major 展平，寫入 X。
5. 將 y 建成 categories 固定為 man、woman 的 categorical；建立 preprocessSpec，記錄尺寸、block size、值域、flatten order 和版本。
6. 驗收 X 為 200×1024、兩類各 100、每類 50 組且每組 2 筆、X 全為 finite 且值在 [0,1]、欄位順序對齊。用 synthetic image matrix 驗證 pooling 與 flattening。
7. 私下保存 train_dataset.mat 和 data_manifest.csv；把 train_dataset.mat 交給 B–F。GitHub 只提交程式、schema、synthetic tests。


## 和配對角色一起交付

和 F 一起核對標籤/群組意義、樣本數與每折資料表；A 校對資料來源與前處理文字，F 校對切分與指標。兩人共同檢查簡報和書面報告使用相同名詞、圖表標籤與數據說法。

## 交付檔案與驗收

matlab/prepareData.m；docs/DATA_CONTRACT.md；synthetic tests；private train_dataset.mat、data_manifest.csv、data_quality_summary.csv。

完成條件：
- 合成資料測試通過；尺寸、欄位、label order 和有限值檢查通過。
- 每次 fit 都限定在當前 fold 的 train rows；validation 僅 transform、predict、計分。
- 設定、版本、seed、資料契約與輸出欄位有紀錄。
- 配對角色 review 後，方法與實際 F 結果已同時放入簡報和書面報告。
- git diff --check 通過；公開 commit 沒有任何私有資料。

## 給 AI 的背景提示

我負責 A。請依共同規格設計 MATLAB prepareData.m；先列出輸入欄位、shape 和每個斷言，再給程式。檔名第一段作 dataset class tag，第二段作分折 group key；只用合成資料測試 20×20×3 區塊平均、row-major 展平、數量/群組檢查與 X/y/sampleID 對齊。不要要求我貼真實影像、檔名或私人路徑。

提供給 AI 的內容只含函式介面、synthetic arrays、非識別尺寸、MATLAB release/toolbox 和已遮蔽錯誤訊息。不要上傳臉部影像、X 特徵、sample-level predictions、原始檔名、私人路徑或憑證。AI 產生的 code 要先由組員 review，再在指定 MATLAB 環境執行。

## 官方參考

https://www.mathworks.com/help/matlab/ref/imread.html
