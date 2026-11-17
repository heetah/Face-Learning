# Face-Learning 協作指引

## 開始任務

先讀下表中對應的角色文件。任務有指定角色時，使用任務指定的角色。否則依目前的角色分支判斷。在 `main` 或 `integration/*` 上，依本次要處理的模組選擇角色。若工作橫跨多個模組，讀取相關角色的文件。

| 角色 | 分支 | 工作指引 |
| --- | --- | --- |
| A | `feature/a-data-loader` | [A 的角色指引](docs/roles/a.md) |
| B | `feature/b-pca` | [B 的角色指引](docs/roles/b.md) |
| C | `feature/c-lda` | [C 的角色指引](docs/roles/c.md) |
| D | `feature/d-bayes` | [D 的角色指引](docs/roles/d.md) |
| E | `feature/e-mlp` | [E 的角色指引](docs/roles/e.md) |
| F | `feature/f-cv-runner` | [F 的角色指引](docs/roles/f.md) |

## 共用規則

- 以[現行專題規格](docs/PROJECT_SPECIFICATIONS.md)、[資料契約](docs/DATA_CONTRACT.md)和[團隊工作規則](docs/TEAM_WORKING_RULES.md)為準。角色文件中的歷史範例若與現行共用介面不同，使用現行介面。
- 開發時先用合成資料測試。人臉影像、特徵矩陣、逐筆預測和私人路徑留在團隊核准的私有位置。
- 將工作提交到對應的角色分支。把角色的程式與測試整合到 `main` 時，只帶入已審查的檔案。共用規則放在這份 `AGENTS.md`，角色專屬指引更新在 `docs/roles/`。
