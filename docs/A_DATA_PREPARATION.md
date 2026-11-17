# A｜準備訓練資料與正式測試資料

在學校 MATLAB 保留完整的 `matlab/` 目錄，包含 `matlab/private/`。若已有舊版封裝程式，請用這一輪的完整專案執行，以免 MATLAB 開到舊檔。

## 訓練資料

1. 開啟 `matlab/inspectTrainingData.m` 並按 **Run**。選擇直接放著 200 張 PNG 的資料夾。預檢會用和封裝相同的讀圖條件檢查 640 × 640、8-bit RGB。
2. 開啟 `matlab/prepareData.m` 並按 **Run**。選訓練圖片資料夾與 repo 外的私人輸出位置。結果會放在新的 `train_package_…` 子資料夾。
3. 把子資料夾中的 `train_dataset.mat` 私下交給組員。樣本順序、欄位和前處理版本相容於原本 F 的讀取方式。含檔名的 `data_manifest.csv` 由 A 私人保管。

## 正式測試資料

1. 取得授課端的 100 張正式測試圖及其對應標籤。將標籤整理成私人 CSV，欄位為 `sourceFile,label`。每列填圖片檔名與授課端標籤對應的 `man` 或 `woman`。圖片名稱不需符合訓練檔名格式。
2. 開啟 `matlab/prepareTestData.m` 並按 **Run**。依序選圖片資料夾、私人標籤 CSV 和 repo 外的私人輸出位置。若格式或標籤有差異，先與 F 核對資料契約再處理。
3. 新的 `test_package_…` 子資料夾包含 `test_dataset.mat` 和 `test_data_manifest.csv`。測試 ID 以 `T` 開頭，`TG` 是逐列佔位 ID，沒有經驗證的群組含義。正式測試資料等方法和設定固定後，才將 MAT 私下交給 F。

兩種封裝都在輸出位置先備妥整套檔案，再移到新子資料夾。已有的封裝可以保留。如果新版程式或正式資料的規格有差異，先和 F 核對 [資料契約](DATA_CONTRACT.md)。

## 合成驗收

將 Current Folder 切到 repo 根目錄，執行：

```matlab
assertSuccess(runtests('matlab/tests/testFaceDataPackages.m'))
```

測試自行建立假影像，驗證訓練與測試的列數、標籤與匿名 ID，以及不合規影像或標籤的拒絕行為。

## 送出 A 的程式變更

依[共用 Git 規範](TEAM_WORKING_RULES.md#git-workflow)同步團隊 `main`，請 AI 核對暫存區及整份分支差異，再由 A 確認後推送。PR 附上合成驗收結果。若變更會影響 F 讀取的欄位、排序或前處理版本，先和 F 約定修改範圍與驗收方式。
