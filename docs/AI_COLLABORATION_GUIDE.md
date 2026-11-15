# FaceLab AI 協作背景知識與提示

## 推送前的 AI 審查

開工前，先從團隊遠端 fetch 最新 `main`，再以該版本開任務分支或更新現有工作分支。若上一輪改動仍未合入 `main`，把 PR 連結或分支名稱與狀態告訴 heetah。完整操作見[共同協作規範](TEAM_WORKING_RULES.md#git-workflow)。

可將以下提示交給 AI：

> 我的角色是＿＿，這次任務是＿＿，約定可修改的檔案是＿＿。請用 `git status --short`、`git diff` 和 `git diff --cached` 檢查檔案與改動。提交後，請用 `git diff <團隊遠端>/main...HEAD` 檢查整份準備推送的差異，並列出每個檔案修改的原因。若 PR 指定其他目標分支，再對該分支檢查一次。發現需要改別人的檔案或共用介面時，請先指出影響和測試方式，交由我與負責人協調。

推送前由組員確認 AI 的檢查結果。工作分支保有可執行的完整專案，PR 只交本次任務約定的改動。

這份文件是六位組員在請 AI 協助前要先讀的專案背景。AI 協助解釋、寫程式草稿、檢查介面與整理文件；公式設定依本專案規格與 MATLAB 官方文件。組員要在 MATLAB 執行並檢查後，才把程式與數值當成成果。

## 專題和工具的關係

本專題用 MATLAB 正式完成四種管線：PCA + Gaussian Naive Bayes、PCA + MLP、Fisher LDA + Gaussian Naive Bayes、Fisher LDA + MLP。GitHub 放程式與版本紀錄；MATLAB 執行降維、分類與五折驗證；公開網站解釋流程，不代表 MATLAB 實驗結果；draw.io 保存六人流程圖。

## 固定資料與方法規格

權威規格文件：[PROJECT_SPECIFICATIONS.md](PROJECT_SPECIFICATIONS.md)。

課程資料分為 200 張訓練圖與獨立的 100 張正式測試圖。只用訓練資料做五折交叉驗證；正式測試資料要等程式和設定鎖定後才交給 F。AI 協作只使用合成矩陣和去識別錯誤訊息，不能提供測試影像、測試標籤、特徵向量或逐筆預測。課程規定的正式測試資料為獨立的 100 張影像，由 A 向授課端取得並封存；程式與設定鎖定後才交給 F。

目前訓練資料夾有 200 張 640 × 640 RGB PNG，man/woman 標籤各 100 張；每一類有 50 個檔名群組，每群組兩張。資料標籤取檔名第一段；第二段只當作分折群組鍵，不宣稱這是身分辨識結果。A 用 32 × 32 個 20 × 20 RGB 區塊平均，產生 200 × 1,024 的 X。像素值先轉成 double 除以 255，特徵列依影像網格列優先順序展開。

A 私下交給所有人 train_dataset.mat，內含 X、y、sampleID、groupID、preprocessSpec。F 私下交給所有人 fold_manifest.csv。不要把影像、X、原始檔名或逐筆預測放到公開 GitHub、公開網站或 AI 對話。

外層驗證固定為五折、同類別內按 groupID 分組。Twister seed 固定為 2026。每個 validation fold 有 10 個 man 群組及 10 個 woman 群組，共 40 張；train 有 160 張。四條管線使用 F 的同一個 manifest。

PCA 在每個 train fold 保留中心化矩陣的全部數值秩方向，q = rank(Xtrain − mean(Xtrain,1))，使用 MATLAB rank 的預設 SVD 容差。二分類 Fisher LDA 輸出 K−1 = 1 維；Sw 秩不足時以 SVD 的 Moore-Penrose 最小範數解處理，不加任意 ridge 常數。Bayes 固定為 fitcnb normal distribution、empirical priors。MLP 固定為 fitcnet 單一 10-unit ReLU 隱藏層、Standardize=true、Lambda=0、IterationLimit=1000，訓練前重設 Twister seed 2026。版本、toolbox 和實際模型設定要記入 run_config.json。

## 請 AI 遵守的規則

1. 先讀 PROJECT_SPECIFICATIONS.md，再處理程式。不要自行改輸入形狀、預處理、折數、類別順序、演算法設定或指標。
2. 公式要定義符號、矩陣方向與每個矩陣的尺寸。說明推導與使用條件。
3. 數值參數要指出來自專案規格、數學推導或 MATLAB 官方設定的哪一項。不要補上沒有根據的 epsilon、維度、閾值、learning rate 或搜尋範圍。
4. 每一折的 fit 都只看 train rows。validation rows 僅供 transform、predict 和評估。
5. 先用合成數據寫一個能執行的最小測試，再使用私有資料。檢查尺寸、列順序、有限值、類別和分數欄位。
6. 不傳送人臉影像、衍生特徵矩陣、逐筆測試結果、原始檔名、私人路徑、帳密或 token。
7. AI 提供的程式先由組員 review，再在指定 MATLAB release 和 toolbox 執行。沒有執行的結果不可以寫成已驗證。

## 共用載入和折資料步驟

1. 將 A 的 train_dataset.mat 與 F 的 fold_manifest.csv 放在私有資料夾；不要放入 repo。
2. 在 MATLAB Current Folder 切到 repo 根目錄，檢查 version -release、ver、which pca -all、which fitcnb -all、which fitcnet -all。
3. 載入 MAT 檔與 fold CSV，確認 X 有 200 列和 1,024 欄，y/sampleID/groupID 都有 200 列。
4. 確認 manifest 的 sampleID 排序與 MAT 檔逐列相同；每個 group 只有一個 outerFold。
5. 對某一折取 outerFold 等於該折的列做 validation，其餘列做 train。
6. 只用 Xtrain/ytrain fit 降維及分類器；再把 Xvalid 用相同 reducer model 轉換，最後 predict。
7. 保存該折結果到私有 run 資料夾。把 aggregate metrics 交給 F；依結果共同更新簡報和書面報告。

## A｜資料整理

A 讀取私有 PNG 與來源檔名，驗證 200 張、每類 100 張、640 × 640 RGB、每群組兩張；按固定排序建立 sampleID/groupID 和 y。每張影像切成 20 × 20 × 3 區塊，平均 RGB 值，轉成 1,024 個 row-major 特徵。A 輸出 train_dataset.mat、私有 data_manifest.csv、無檔名的品質摘要、prepareData.m、資料介面說明和合成測試。

A 和 F 一起確認類別標籤、groupID、報告用語；A 的方法說明也要整理到簡報與書面報告。

可給 AI 的提示：我負責 A。依 PROJECT_SPECIFICATIONS.md 寫 MATLAB 資料檢查流程。請只使用合成矩陣示範，不要要求我貼任何真實影像或檔名。逐項檢查檔案數量、shape、RGB mode、標籤比例、每組張數、行列對齊、NaN/Inf 和固定的區塊平均公式。輸出 train_dataset.mat 的 schema、可讀錯誤訊息和單元測試。

## B｜PCA

對 Xtrain 的每一欄中心化，保存訓練平均 mu 和主方向 W。若 q = rank(Xtrain − mu)，則 W 為 1,024 × q，Ztrain = (Xtrain − mu)W 為 Ntrain × q。Xvalid 使用同一 mu 和 W。q 依訓練折的數值秩決定，不使用 outer validation。

B 和 C 一起驗收兩個 reducer 介面和維度表。B 把 fitPCA/transformPCA 交給 D、E、F；和 D/E 用 synthetic Z 檢查分類器接線。B 的簡報、書面報告需說清楚 PCA 投影、q 的 rank 規則、各折 q 值與限制。

可給 AI 的提示：我負責 B。依專案規格設計 fitPCA(Xtrain) 和 transformPCA(model,X)。先寫尺寸推導、fit/transform 不變條件和 rank 的容差來源，再給 MATLAB 程式及合成低秩矩陣測試。validation 使用 fit 保存的 mu/W；不要新增 q 門檻或調參流程。

## C｜Fisher LDA

K 類別的類內散佈為 Sw = Σk Σi (xi − μk)'(xi − μk)，類間散佈為 Sb = Σk nk(μk − μ)'(μk − μ)。二分類的類平均差最多一個獨立方向，所以輸出 1 維。當 D=1,024、Ntrain=160 時，Sw 秩最多 158，不能直接 inv(Sw)。

C 和 B 同步矩陣方向、fit/transform 欄位和 rank 診斷。C 把 fitLDA/transformLDA 交給 D、E、F；和 B 一起完成 reduction_summary.csv。書面報告需列出 Sw 秩、使用 SVD pseudoinverse 的理由與失敗檢查。

可給 AI 的提示：我負責 C。請從 Xtrain 為 N×D、ytrain 為 N×1 推導 class means、Sw、Sb 和二分類維度上限，標註尺寸。用 SVD 實作 Moore-Penrose 最小範數解，使用 MATLAB rank 預設容差；禁止 inv(Sw) 和自行加入 epsilon。提供退化案例測試與 validation transform 測試。

## D｜Gaussian Naive Bayes

對 PCA 與 LDA 各自產生的 Ztrain，使用 fitcnb，DistributionNames=normal、Prior=empirical。predict 回傳 labels、scores 和 ClassNames；正類 woman 的分數欄以 ClassNames 查找，不依賴固定欄號。Score 的意義依 MATLAB 輸出名稱與官方說明記錄，不把分數誤寫成未校準的機率。

D 和 E 一起核對類別次序、預測介面與計分表。D 分別測 PCA→Bayes、LDA→Bayes，交給 F 私有 oof_predictions.csv 逐筆列與 classifier_summary.csv；把 normal/empirical 設定、Gaussian conditional-independence 假設、結果與限制寫入簡報與書面報告。

可給 AI 的提示：我負責 D。請依專案規格寫 fitBayes/predictBayes wrapper，使用 fitcnb normal distribution 和 empirical prior。以合成矩陣確認 ClassNames 與 scores 欄的對應，輸出 PCA 與 LDA 的同一介面。不要新增平滑常數或調整分布。

## E｜MLP

E 使用 fitcnet，一個 10-unit ReLU 隱藏層，Standardize=true、Lambda=0、IterationLimit=1000。每一外層訓練折內由 fitcnet 學習標準化統計，再將同一模型套用 validation。seed、MATLAB release、toolbox、TrainingHistory、weights/biases 和分開的 fit/predict 時間都要保存。

輸入寬度 d 時，trainable weight/bias 數為 10(d+1)+2(10+1)=10d+32。PCA 和 LDA 各有自己的 d；標準化均值和標準差不是可訓練網路參數，另行記錄。

E 和 D 共用 label/score 契約，分別測 PCA→MLP 和 LDA→MLP，將私有 oof_predictions.csv 逐筆列和 classifier_summary.csv 交給 F。簡報和書面報告必須說明 10-unit ReLU 是固定 baseline，不宣稱是最佳模型。

可給 AI 的提示：我負責 E。請依專案規格建立 fitMLP/predictMLP，明列 LayerSizes=10、Activations=relu、Standardize=true、Lambda=0、IterationLimit=1000 和 RNG seed。計算權重與偏置數，測試兩類 labels/scores/ClassNames 對應和只用 train fold 標準化；不要呼叫 hyperparameter optimization。

## F｜五折驗證和整合

F 取得 train_dataset.mat，為每類 group ID 分別以 seed 2026 隨機排列，再平均分給五折；保存 fold_manifest.csv。F 驗證一個 group 不可跨 fold，且每折兩類各 20 張 validation、總數 40；train 每類 80 張、總數 160。四種方法共用同一 manifest。

F 每折呼叫 B/C fit reducer，再呼叫 D/E fit classifier；只對該折 validation 輸出 OOF predictions。彙整 confusion counts、accuracy、balanced accuracy、woman-positive AUC、fit/predict 時間與維度。A/F 對齊簡報和書面報告中的流程名稱、數據來源、指標及限制。

可給 AI 的提示：我負責 F。依 PROJECT_SPECIFICATIONS.md 寫 createFoldManifest/runCV。以 synthetic IDs 測試群組不跨折、每折類別數、同一 manifest 被四種方法共用、所有 fit 只看到 train indices。產生 fold_metrics.csv 和 private oof_predictions.csv 的欄位說明；不要把逐筆資料寫入公開 repo。

## MATLAB 官方參考

- pca: https://www.mathworks.com/help/stats/pca.html
- rank: https://www.mathworks.com/help/matlab/ref/rank.html
- fitcnb: https://www.mathworks.com/help/stats/fitcnb.html
- fitcnet: https://www.mathworks.com/help/stats/fitcnet.html
- cvpartition: https://www.mathworks.com/help/stats/cvpartition.html
- Fisher LDA: https://doi.org/10.1111/j.1469-1809.1936.tb02137.x
