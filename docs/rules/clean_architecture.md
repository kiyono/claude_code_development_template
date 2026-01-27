# クリーンアーキテクチャ ルールドキュメント

Robert C. Martin（Uncle Bob）が提唱するクリーンアーキテクチャを本プロジェクトに適用するためのルール。

---

## 1. 基本原則

### 1.1 依存関係のルール

**依存は常に外側から内側へ向かう。内側のレイヤーは外側を知らない。**

```
外側（詳細）                              内側（抽象）
┌─────────────────────────────────────────────────────────┐
│ Frameworks & Drivers                                    │
│ (FastAPI, DuckDB, SQLite, 外部API)                      │
├─────────────────────────────────────────────────────────┤
│ Interface Adapters                                      │
│ (Controllers, Gateways, Presenters, Repositories実装)    │
├─────────────────────────────────────────────────────────┤
│ Application Business Rules (Use Cases)                  │
│ (IngestUseCase, SearchUseCase, AnswerUseCase)           │
├─────────────────────────────────────────────────────────┤
│ Enterprise Business Rules (Entities)                    │
│ (Document, Chunk, Embedding, Answer)                    │
└─────────────────────────────────────────────────────────┘
```

### 1.2 SOLID 原則

| 原則 | 説明 | 本プロジェクトでの適用 |
|------|------|----------------------|
| **S**RP (単一責任) | クラスは変更理由が 1 つだけ | UseCase は 1 つのビジネスルールのみ担当 |
| **O**CP (開放閉鎖) | 拡張に開き、修正に閉じる | 新しいデータソースは新クラス追加で対応 |
| **L**SP (リスコフ置換) | 派生クラスは基底クラスと置換可能 | Repository 実装は interface を完全に満たす |
| **I**SP (インターフェース分離) | 不要なメソッドに依存しない | 必要最小限の interface を定義 |
| **D**IP (依存関係逆転) | 抽象に依存、具象に依存しない | UseCase は Repository interface に依存 |

---

## 2. レイヤー別ルール

### 2.1 Domain 層（Entities）

**場所**: `src/domain/`

**責務**: ビジネスルールの中核。アプリケーションに依存しない普遍的なルール。

**ルール**:

```python
# OK: 純粋なデータ構造と不変オブジェクト
@dataclass(frozen=True)
class Document:
    id: str
    content: str
    created_at: datetime

# OK: ドメイン固有のバリデーション
@dataclass(frozen=True)
class Chunk:
    content: str

    def __post_init__(self):
        if len(self.content) == 0:
            raise ValueError("Chunk content cannot be empty")

# NG: 外部ライブラリへの依存
from sqlalchemy import Column  # 禁止
from fastapi import Request    # 禁止
```

**禁止事項**:
- 外部フレームワークへの依存（FastAPI, SQLAlchemy, DuckDB 等）
- I/O 操作（ファイル読み書き、HTTP リクエスト）
- 具象クラスへの依存

**許可事項**:
- Python 標準ライブラリ
- dataclass, typing, abc
- ドメイン内の他の Entity への依存

---

### 2.2 Application 層（Use Cases）

**場所**: `src/application/`

**責務**: アプリケーション固有のビジネスルール。ユースケースの実行。

**ルール**:

```python
# OK: 抽象（interface）への依存
class AnswerUseCase:
    def __init__(
        self,
        document_repo: DocumentRepository,  # interface
        vector_repo: VectorRepository,      # interface
        embedder: Embedder,                 # interface
        llm: LLM,                           # interface
    ):
        self._document_repo = document_repo
        self._vector_repo = vector_repo
        self._embedder = embedder
        self._llm = llm

    async def execute(self, question: str) -> Answer:
        # ビジネスロジックのみ記述
        ...

# NG: 具象クラスへの依存
from infrastructure.database.sqlite_repository import SQLiteDocumentRepository  # 禁止
```

**禁止事項**:
- Infrastructure 層の具象クラスへの直接依存
- Presentation 層への依存
- フレームワーク固有のコード

**許可事項**:
- Domain 層への依存
- Repository / Service の interface への依存
- Domain Entity の生成・操作

---

### 2.3 Infrastructure 層（Frameworks & Drivers）

**場所**: `src/infrastructure/`

**責務**: 外部サービスとの接続。技術的詳細の実装。

**ルール**:

```python
# OK: interface の実装
from domain.repositories import DocumentRepository

class SQLiteDocumentRepository(DocumentRepository):
    def __init__(self, db_path: str):
        self._conn = sqlite3.connect(db_path)

    async def save(self, document: Document) -> None:
        # SQLite 固有の実装
        self._conn.execute(...)

    async def find_by_id(self, doc_id: str) -> Document | None:
        # SQLite 固有の実装
        ...

# OK: 外部ライブラリの使用
import duckdb
import httpx
from openai import OpenAI
```

**禁止事項**:
- Application 層のロジックを記述
- ビジネスルールの判断

**許可事項**:
- 外部ライブラリの使用
- Domain 層の interface 実装
- 技術的な詳細（SQL, HTTP, ファイル操作）

---

### 2.4 Presentation 層（Interface Adapters）

**場所**: `src/presentation/`

**責務**: 外部とのインターフェース。HTTP リクエスト/レスポンスの変換。

**ルール**:

```python
# OK: フレームワーク固有のコード
from fastapi import APIRouter, Depends
from pydantic import BaseModel

class WebhookRequest(BaseModel):
    message: str
    is_mention: bool

@router.post("/webhook")
async def handle_webhook(
    request: WebhookRequest,
    answer_usecase: AnswerUseCase = Depends(get_answer_usecase)
) -> WebhookResponse:
    # データ変換のみ
    answer = await answer_usecase.execute(request.message)
    return WebhookResponse.from_domain(answer)

# NG: ビジネスロジックの記述
@router.post("/webhook")
async def handle_webhook(request: WebhookRequest):
    # ここでビジネスロジックを書かない
    if request.message.startswith("検索:"):  # 禁止: UseCase に移動すべき
        ...
```

**禁止事項**:
- ビジネスロジックの記述
- Domain Entity の直接操作（変換のみ許可）
- Infrastructure 層の具象クラスへの直接依存

**許可事項**:
- フレームワーク固有のコード（FastAPI, Pydantic）
- Application 層の UseCase への依存
- DI コンテナの設定

---

## 3. 依存性注入（DI）ルール

### 3.1 interface の定義場所

```
src/domain/repositories/       # Repository interface
src/infrastructure/*/          # interface の実装
src/presentation/dependencies.py  # DI 設定
```

### 3.2 DI パターン

```python
# presentation/dependencies.py
from functools import lru_cache

# 設定は 1 箇所で管理
@lru_cache
def get_settings() -> Settings:
    return Settings()

# 具象クラスのインスタンス化は Infrastructure 層の知識
def get_document_repo(settings: Settings = Depends(get_settings)):
    return SQLiteDocumentRepository(settings.sqlite_path)

# UseCase は抽象に依存
def get_answer_usecase(
    document_repo: DocumentRepository = Depends(get_document_repo),
    ...
) -> AnswerUseCase:
    return AnswerUseCase(document_repo, ...)
```

---

## 4. ファイル命名規則

| レイヤー | ファイル名パターン | 例 |
|---------|-------------------|-----|
| Domain/Entities | `{entity_name}.py` | `document.py`, `answer.py` |
| Domain/Repositories | `{entity}_repository.py` | `document_repository.py` |
| Application | `{action}_usecase.py` | `answer_usecase.py` |
| Infrastructure/DB | `{tech}_{entity}_repository.py` | `sqlite_document_repository.py` |
| Infrastructure/External | `{service}_client.py` | `chat_client.py` |
| Presentation/API | `{feature}_handler.py` | `webhook_handler.py` |

---

## 5. import ルール

### 5.1 許可される import 方向

```
Domain     ← Application ← Infrastructure
                ↑
           Presentation
```

### 5.2 import チェックリスト

```python
# domain/ 内のファイル
from domain.entities import ...      # OK
from application import ...          # NG
from infrastructure import ...       # NG
from presentation import ...         # NG

# application/ 内のファイル
from domain import ...               # OK
from application import ...          # OK (同一レイヤー)
from infrastructure import ...       # NG
from presentation import ...         # NG

# infrastructure/ 内のファイル
from domain import ...               # OK
from application import ...          # NG (通常は不要)
from infrastructure import ...       # OK (同一レイヤー)
from presentation import ...         # NG

# presentation/ 内のファイル
from domain import ...               # OK (データ変換用)
from application import ...          # OK
from infrastructure import ...       # OK (DI 設定のみ)
from presentation import ...         # OK (同一レイヤー)
```

---

## 6. 違反チェック方法

### 6.1 静的解析

```bash
# import 違反の検出（ruff / pylint カスタムルール）
ruff check src/ --select=I

# 依存関係の可視化
pydeps src/ --cluster
```

### 6.2 コードレビューチェックリスト

- [ ] Domain 層に外部ライブラリの import がないか
- [ ] Application 層が具象クラスに依存していないか
- [ ] Presentation 層にビジネスロジックが漏れていないか
- [ ] 新しい機能追加時、適切なレイヤーに配置されているか

---

## 7. 例外的なケース

### 7.1 許容される例外

| ケース | 理由 | 対応 |
|--------|------|------|
| logging | 横断的関心事 | 全レイヤーで使用可 |
| 設定値の参照 | 環境依存 | config.py 経由で参照 |
| 型ヒント用 import | 実行時に影響なし | `TYPE_CHECKING` ガード内で許可 |

```python
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from infrastructure.database import SQLiteDocumentRepository  # 型ヒント専用
```

---

## 8. 参考資料

- Robert C. Martin, "Clean Architecture: A Craftsman's Guide to Software Structure and Design"
- https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
