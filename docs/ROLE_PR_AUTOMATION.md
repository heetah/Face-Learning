# 角色分支的 PR 自動檢查與整合

## 試跑唯讀檢查

組員開啟、更新、改目標、重開 PR 或切換草稿狀態時，**Audit role pull request** 會自動試跑。也可從 **Run workflow** 選 `main`、填入 PR 編號重跑，尤其是 `main` 或角色分支剛更新時。檢查只讀取作者、Git refs 與檔名差異。通過時會列出被檢查的 `main`、目標分支、PR head SHA 和檔案。

自動觸發使用唯讀的 `pull_request_target` 工作。它從團隊預設分支執行檢查程式，只把組員提交當成 Git 資料讀取。公開 repo 的 GitHub Actions 事件政策可能會封鎖此事件。維護者可在 [GitHub 事件政策說明](https://docs.github.com/en/actions/reference/security/securely-using-pull_request_target#default-policy-for-pull_request_target) 查看是否需要明確允許。手動試跑仍可使用。

目前試跑名單依歷史 PR 設定，B 為 `liupiyan`、C 為 `bugtail`、D 為 `Giakolan`、E 為 `uhumipaa`、F 為 `cloud-sky-0128`。D、E 的路徑來自 [PR #12](https://github.com/heetah/Face-Learning/pull/12) 和 [PR #13](https://github.com/heetah/Face-Learning/pull/13)。正式啟用前須由維護者確認帳號、分支和可修改的檔案。未設定的帳號會被拒絕，`heetah` 跳過組員規則。新增檔案或跨角色變更先由維護者確認範圍。

## 第一階段：組員 PR → 角色分支

- PR 的 GitHub base 是角色分支。最新 `upstream/main` 則是 PR head 必須包含的 Git 提交。目標角色分支也須同步該提交，讓 diff 以共用整合版本為準。
- 依 PR 作者核對角色分支和可修改檔案。重新命名會核對舊、新兩個路徑。GitHub 上的角色分支需禁止可繞過檢查的直接推送。
- 正式版由受信任的 GitHub App 或等效服務在開啟 PR、推送更新、改 base 或重開時執行，將結果回報到實際 PR head。規則要求由該來源回報成功。合併前重新核對三個 SHA，因為 `main` 或角色分支可能在檢查之後更新。

## 第二階段：角色分支 → main

雙向自動整合的檔案範圍都是 `docs/`、`matlab/` 和 `tests/`。對團隊 repo 內由 heetah 開出的 `integration/*` PR，檢查會按 PR 目標判斷整合方向，並以目標分支目前版本核對**整份差異**。混入根目錄 README、AGENTS、`.github/`、`.gitignore`、`assets/` 等其他路徑時，整份 PR 會回報不合規。其他路徑要由維護者另行審查。組員送角色分支時，仍需同時符合個人檔案清單。

- 確認角色 PR 合併後，由 bot 從當時最新的 `main` 建立整合分支，只帶入該次已驗證的改動。舊角色分支可能有自己的 README、AGENTS 和圖檔。先確認整合分支的 diff，避免把歷史內容順帶放進 `main`。
- bot 開 PR 到 `main`。先重跑路徑檢查並執行適用的合成測試，再透過 GitHub Auto-merge 或 merge queue 合併。整合工作依序處理，合併衝突、測試失敗或 `main` 移動時重新驗證。
- 正式自動合併需要在 repo 設定保護規則、必要的檢查，以及 GitHub App 的最小寫入權限。具備寫入權限的流程只操作可信的 refs 和 GitHub metadata。合成測試在隔離 runner 執行，使用唯讀權限與合成資料。

## 反向同步：main → 角色分支

從當前角色分支建立 `integration/*`，只納入三個目錄內已核對的上游變更，再開 PR 到該角色分支。整合準備好後，檢查會比對實際 PR 的差異，防止角色 README、AGENTS 或其他檔案隨上游整批覆蓋。若同步版本也要符合組員 PR 的 `main` 祖先檢查，提交歷史須保留已同步的 `main` 作為合併父節點，並讓合併結果符合上述路徑限制。

本輪提供手動和自動的唯讀試跑。實際合併和必過規則須在確認帳號、路徑與測試環境後配置。
