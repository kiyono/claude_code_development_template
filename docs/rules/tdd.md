# TDD（テスト駆動開発）ルールドキュメント

t-wada（和田卓人）氏が提唱する TDD の原則を本プロジェクトに適用するためのルール。

---

## 1. TDD の基本サイクル

### 1.1 Red → Green → Refactor

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│    ┌─────────┐         ┌─────────┐         ┌─────────┐     │
│    │   Red   │ ──────▶ │  Green  │ ──────▶ │Refactor │     │
│    │         │         │         │         │         │     │
│    │ テスト   │         │ 最小限の │         │ コード   │     │
│    │ を書く   │         │ 実装    │         │ を改善   │     │
│    └─────────┘         └─────────┘         └─────────┘     │
│         ▲                                       │          │
│         │                                       │          │
│         └───────────────────────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

| フェーズ | 目的 | 所要時間目安 |
|---------|------|------------|
| **Red** | 失敗するテストを書く | 数分 |
| **Green** | テストを通す最小限のコードを書く | 数分 |
| **Refactor** | コードを改善する（テストは維持） | 数分〜 |

### 1.2 サイクルの粒度

**小さく回す**ことが重要。

```
NG: 大きなサイクル
テスト10個書く → 実装 → リファクタリング

OK: 小さなサイクル
テスト1個書く → 実装 → リファクタリング
テスト1個書く → 実装 → リファクタリング
...
```

---

## 2. テストファースト原則

### 2.1 プロダクションコードより先にテストを書く

```python
# 1. まずテストを書く（Red）
def test_chunk_splits_text_by_token_limit():
    chunker = Chunker(max_tokens=100)
    text = "これは長いテキストです..." * 100

    chunks = chunker.split(text)

    assert len(chunks) > 1
    for chunk in chunks:
        assert count_tokens(chunk.content) <= 100

# 2. テストが失敗することを確認
# pytest => FAILED

# 3. 最小限の実装を書く（Green）
class Chunker:
    def __init__(self, max_tokens: int):
        self.max_tokens = max_tokens

    def split(self, text: str) -> list[Chunk]:
        # 最小限の実装
        ...

# 4. テストが成功することを確認
# pytest => PASSED

# 5. リファクタリング（Refactor）
# テストを維持しながらコードを改善
```

### 2.2 テストを書く前にコードを書かない

**例外なし**。どんなに自明な実装でもテストが先。

```python
# NG: 実装してからテストを書く
class Document:
    def __init__(self, content: str):
        self.content = content  # 先に書いてしまった

def test_document_has_content():  # 後からテスト
    ...

# OK: テストを先に書く
def test_document_has_content():
    doc = Document(content="テスト")
    assert doc.content == "テスト"

# その後に実装
class Document:
    def __init__(self, content: str):
        self.content = content
```

---

## 3. テストの書き方ルール

### 3.1 Arrange-Act-Assert（AAA）パターン

```python
def test_answer_usecase_returns_citations():
    # Arrange: 準備
    document_repo = MockDocumentRepository()
    document_repo.add(Document(id="1", content="関連情報"))
    vector_repo = MockVectorRepository()
    vector_repo.set_search_result(["1"])
    usecase = AnswerUseCase(document_repo, vector_repo, ...)

    # Act: 実行
    answer = await usecase.execute("質問")

    # Assert: 検証
    assert len(answer.citations) == 1
    assert answer.citations[0].document_id == "1"
```

### 3.2 1 テスト 1 検証

```python
# NG: 複数の検証を 1 テストに詰め込む
def test_document():
    doc = Document(content="test")
    assert doc.content == "test"
    assert doc.id is not None
    assert doc.created_at is not None
    chunk = doc.to_chunk()
    assert chunk.content == "test"

# OK: 検証ごとにテストを分ける
def test_document_has_content():
    doc = Document(content="test")
    assert doc.content == "test"

def test_document_has_auto_generated_id():
    doc = Document(content="test")
    assert doc.id is not None

def test_document_has_created_at():
    doc = Document(content="test")
    assert doc.created_at is not None

def test_document_converts_to_chunk():
    doc = Document(content="test")
    chunk = doc.to_chunk()
    assert chunk.content == "test"
```

### 3.3 テスト名は仕様を表す

```python
# NG: 曖昧なテスト名
def test_answer():
    ...

def test_search_1():
    ...

# OK: 仕様を表すテスト名
def test_answer_includes_citations_from_retrieved_documents():
    ...

def test_search_returns_empty_list_when_no_similar_documents():
    ...

def test_search_returns_top_k_most_similar_documents():
    ...
```

命名規則: `test_{対象}_{条件}_{期待結果}` または `test_{対象}_{期待される振る舞い}`

---

## 4. テストの種類と配置

### 4.1 テストピラミッド

```
          /\
         /  \        E2E テスト
        /    \       - 少数
       /──────\      - 実行時間: 長い
      /        \     - Webhook 経由の全体フロー
     /──────────\
    /            \   統合テスト
   /              \  - 中程度
  /────────────────\ - 実行時間: 中
 /                  \- UseCase + 実際の Repository
/────────────────────\
        単体テスト
        - 多数
        - 実行時間: 短い
        - 個々のクラス・関数
```

### 4.2 ディレクトリ構成

```
tests/
├── conftest.py              # 共通 fixtures
├── unit/                    # 単体テスト
│   ├── domain/
│   │   ├── test_document.py
│   │   └── test_chunk.py
│   ├── application/
│   │   ├── test_answer_usecase.py
│   │   └── test_ingest_usecase.py
│   └── infrastructure/
│       ├── test_local_embedder.py
│       └── test_chunker.py
├── integration/             # 統合テスト
│   ├── test_ingest_flow.py
│   └── test_search_flow.py
└── e2e/                     # E2E テスト
    └── test_webhook.py
```

### 4.3 各テストレベルのルール

| レベル | Mock 使用 | 外部依存 | 実行頻度 |
|--------|----------|---------|---------|
| 単体 | 全て Mock | なし | 常時（保存時） |
| 統合 | 一部 Mock | DB（テスト用） | CI/CD |
| E2E | なし | 全て実際のもの | デプロイ前 |

---

## 5. Mock の使い方

### 5.1 Mock は境界に対して使う

```python
# OK: 外部境界（Repository, 外部 API）を Mock
class TestAnswerUseCase:
    def test_execute_calls_repository(self):
        document_repo = Mock(spec=DocumentRepository)
        document_repo.find_by_ids.return_value = [...]

        usecase = AnswerUseCase(document_repo, ...)
        await usecase.execute("質問")

        document_repo.find_by_ids.assert_called_once()

# NG: 内部実装を Mock
class TestAnswerUseCase:
    def test_execute(self):
        usecase = AnswerUseCase(...)
        usecase._build_prompt = Mock()  # 内部メソッドを Mock するのは避ける
```

### 5.2 Mock の設定は最小限に

```python
# NG: 過剰な Mock 設定
mock_repo.find_by_id.return_value = Document(...)
mock_repo.find_by_ids.return_value = [...]
mock_repo.save.return_value = None
mock_repo.delete.return_value = None  # テストで使わないのに設定

# OK: テストに必要な設定のみ
mock_repo.find_by_ids.return_value = [Document(...)]
```

### 5.3 Fake オブジェクトの活用

複雑な Mock より Fake（簡易実装）を使う。

```python
# tests/fakes/fake_document_repository.py
class FakeDocumentRepository(DocumentRepository):
    def __init__(self):
        self._documents: dict[str, Document] = {}

    async def save(self, document: Document) -> None:
        self._documents[document.id] = document

    async def find_by_id(self, doc_id: str) -> Document | None:
        return self._documents.get(doc_id)

    async def find_by_ids(self, doc_ids: list[str]) -> list[Document]:
        return [self._documents[id] for id in doc_ids if id in self._documents]

# テストで使用
def test_ingest_saves_document():
    repo = FakeDocumentRepository()
    usecase = IngestUseCase(repo, ...)

    await usecase.execute(raw_data)

    assert await repo.find_by_id("doc_1") is not None
```

---

## 6. テストの独立性

### 6.1 各テストは独立して実行可能

```python
# NG: テスト間の依存
class TestDocument:
    doc = None  # クラス変数で状態共有

    def test_create(self):
        self.doc = Document(content="test")

    def test_content(self):
        assert self.doc.content == "test"  # test_create に依存

# OK: 各テストが独立
class TestDocument:
    def test_create_document(self):
        doc = Document(content="test")
        assert doc is not None

    def test_document_has_content(self):
        doc = Document(content="test")
        assert doc.content == "test"
```

### 6.2 テストの実行順序に依存しない

```python
# pytest.ini
[pytest]
# ランダム順序で実行して依存を検出
addopts = -p no:randomly  # または pytest-randomly を使用
```

### 6.3 外部状態をクリーンアップ

```python
@pytest.fixture
def db_connection():
    conn = sqlite3.connect(":memory:")
    yield conn
    conn.close()  # 必ずクリーンアップ

@pytest.fixture
def clean_db(db_connection):
    yield db_connection
    # テスト後にデータを削除
    db_connection.execute("DELETE FROM documents")
```

---

## 7. 実装の進め方

### 7.1 明白な実装（Obvious Implementation）

テストを書いた後、実装が明らかな場合は一気に書く。

```python
def test_document_has_content():
    doc = Document(content="test")
    assert doc.content == "test"

# 明白な実装: 一気に書く
@dataclass
class Document:
    content: str
```

### 7.2 仮実装（Fake It）

実装が不明確な場合、まずハードコードで通す。

```python
def test_chunker_splits_text():
    chunker = Chunker(max_tokens=100)
    chunks = chunker.split("長いテキスト...")
    assert len(chunks) == 2

# 仮実装: ハードコードで通す
class Chunker:
    def split(self, text: str) -> list[Chunk]:
        return [Chunk("chunk1"), Chunk("chunk2")]  # ハードコード

# 次のテストで一般化を強制
def test_chunker_splits_different_text():
    chunker = Chunker(max_tokens=100)
    chunks = chunker.split("別の長いテキスト...")
    assert len(chunks) == 3  # 前のハードコードでは通らない
```

### 7.3 三角測量（Triangulation）

複数のテストケースで実装を導く。

```python
def test_token_counter_counts_ascii():
    assert count_tokens("hello") == 1

def test_token_counter_counts_japanese():
    assert count_tokens("こんにちは") == 3  # 日本語は複数トークン

def test_token_counter_counts_mixed():
    assert count_tokens("hello世界") == 3
```

---

## 8. リファクタリングルール

### 8.1 テストが Green の時だけリファクタリング

```
Red    → リファクタリング禁止
Green  → リファクタリング OK
```

### 8.2 リファクタリング中はテストを変更しない

```python
# リファクタリング前
def calculate_similarity(vec1, vec2):
    # 長い実装...
    return result

# リファクタリング後（テストはそのまま）
def calculate_similarity(vec1, vec2):
    return _dot_product(vec1, vec2) / (_norm(vec1) * _norm(vec2))

def _dot_product(vec1, vec2):
    ...

def _norm(vec):
    ...
```

### 8.3 小さなステップでリファクタリング

```
1. 変数名を変更 → テスト実行 → Green 確認
2. メソッド抽出 → テスト実行 → Green 確認
3. クラス分割 → テスト実行 → Green 確認
```

---

## 9. pytest 設定

### 9.1 conftest.py

```python
# tests/conftest.py
import pytest
from unittest.mock import AsyncMock, Mock

@pytest.fixture
def mock_document_repo():
    repo = AsyncMock(spec=DocumentRepository)
    return repo

@pytest.fixture
def mock_vector_repo():
    repo = AsyncMock(spec=VectorRepository)
    return repo

@pytest.fixture
def mock_embedder():
    embedder = Mock(spec=Embedder)
    embedder.embed.return_value = [[0.1] * 1024]
    return embedder

@pytest.fixture
def mock_llm():
    llm = Mock(spec=LLM)
    llm.generate.return_value = "回答"
    return llm
```

### 9.2 pytest.ini

```ini
[pytest]
testpaths = tests
asyncio_mode = auto
addopts = -v --tb=short --strict-markers
markers =
    unit: 単体テスト
    integration: 統合テスト
    e2e: E2Eテスト
    slow: 実行時間の長いテスト
```

### 9.3 テスト実行コマンド

```bash
# 全テスト
pytest

# 単体テストのみ
pytest tests/unit/

# マーカー指定
pytest -m unit
pytest -m "not slow"

# カバレッジ
pytest --cov=src --cov-report=html
```

---

## 10. TDD アンチパターン

### 10.1 避けるべきパターン

| アンチパターン | 問題点 | 対策 |
|--------------|--------|------|
| **テスト後付け** | 実装に引っ張られる | テストファースト厳守 |
| **巨大テスト** | 失敗原因が不明 | 1 テスト 1 検証 |
| **脆いテスト** | 実装変更で壊れる | 振る舞いをテスト |
| **遅いテスト** | 実行を避ける | Mock 活用、テスト分離 |
| **テストの重複** | メンテナンスコスト | 共通 fixture 活用 |

### 10.2 脆いテストを避ける

```python
# NG: 実装詳細をテスト（脆い）
def test_answer_usecase_calls_methods_in_order():
    usecase = AnswerUseCase(...)
    await usecase.execute("質問")

    # 呼び出し順序をテスト（実装変更で壊れやすい）
    assert mock_embedder.embed.call_count == 1
    assert mock_vector_repo.search.call_count == 1
    assert mock_document_repo.find_by_ids.call_count == 1

# OK: 振る舞いをテスト（安定）
def test_answer_usecase_returns_answer_with_citations():
    usecase = AnswerUseCase(...)
    answer = await usecase.execute("質問")

    assert answer.content is not None
    assert len(answer.citations) > 0
```

---

## 11. 参考資料

- 和田卓人, "テスト駆動開発" (Kent Beck 著の翻訳)
- t-wada, "TDD Boot Camp" 資料
- https://t-wada.hatenablog.jp/
- Kent Beck, "Test Driven Development: By Example"
