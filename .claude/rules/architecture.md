---
description: クリーンアーキテクチャのルール（レイヤー構成、依存関係、importルール）
globs:
  - "src/**/*.py"
alwaysApply: false
---

# Architecture Rules

クリーンアーキテクチャ（Robert C. Martin）のルール。

## レイヤー構成

```
外側（詳細）                              内側（抽象）
┌─────────────────────────────────────────────────────────┐
│ Frameworks & Drivers (presentation/, infrastructure/)   │
├─────────────────────────────────────────────────────────┤
│ Interface Adapters (repositories/, gateways/)           │
├─────────────────────────────────────────────────────────┤
│ Use Cases (application/)                                │
├─────────────────────────────────────────────────────────┤
│ Entities (domain/)                                      │
└─────────────────────────────────────────────────────────┘
          ↑ 依存の方向（外側 → 内側のみ許可）
```

## 依存関係のルール（CRITICAL）

**依存は常に外側から内側へ。内側は外側を知らない。**

### Domain 層（Entities）

```python
# OK: 純粋なデータ構造
@dataclass(frozen=True)
class Document:
    id: str
    content: str

# NG: 外部ライブラリへの依存
from fastapi import Request     # 禁止
from sqlalchemy import Column   # 禁止
```

### Application 層（Use Cases）

```python
# OK: 抽象（interface）への依存
class AnswerUseCase:
    def __init__(self, document_repo: DocumentRepository):  # interface
        self._document_repo = document_repo

# NG: 具象クラスへの直接依存
from infrastructure.database.sqlite_repository import SQLiteDocumentRepository  # 禁止
```

### Infrastructure 層

```python
# OK: interface の実装
class SQLiteDocumentRepository(DocumentRepository):
    def __init__(self, db_path: str):
        self._conn = sqlite3.connect(db_path)
```

### Presentation 層

```python
# OK: UseCase の呼び出し
@router.post("/webhook")
async def handle_webhook(
    request: WebhookRequest,
    answer_usecase: AnswerUseCase = Depends(get_answer_usecase)
):
    return await answer_usecase.execute(request.message)

# NG: ビジネスロジックの記述
# ここでデータベースを直接操作しない
```

## import ルール

```python
# domain/ 内のファイル
from domain.entities import ...      # OK
from application import ...          # NG
from infrastructure import ...       # NG

# application/ 内のファイル
from domain import ...               # OK
from infrastructure import ...       # NG

# infrastructure/ 内のファイル
from domain import ...               # OK

# presentation/ 内のファイル
from domain import ...               # OK（データ変換用）
from application import ...          # OK
```

## チェックリスト

- [ ] Domain 層に外部ライブラリの import がない
- [ ] Application 層が具象クラスに依存していない
- [ ] Presentation 層にビジネスロジックがない
- [ ] 依存関係が外側から内側のみ
