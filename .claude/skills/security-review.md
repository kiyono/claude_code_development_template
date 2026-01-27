---
name: security-review
description: Python/FastAPI セキュリティレビュー。認証、ユーザー入力、API エンドポイント、機密データを扱うコード変更時に使用。
---

# セキュリティレビュー (Python/FastAPI)

## 起動条件

- 認証/認可の実装時
- ユーザー入力の処理時
- 新規 API エンドポイント作成時
- シークレット/認証情報の扱い時
- ファイルアップロード処理時
- データベースクエリ作成時
- 外部 API 統合時

## セキュリティチェックリスト

### 1. シークレット管理

#### NG: ハードコード

```python
# CRITICAL: 絶対にやってはいけない
api_key = "sk-proj-xxxxx"
db_password = "password123"
```

#### OK: 環境変数

```python
import os

api_key = os.environ.get("SAKURA_API_KEY")
if not api_key:
    raise ValueError("SAKURA_API_KEY not configured")
```

#### 検証項目
- [ ] ハードコードされた API キー、トークン、パスワードがない
- [ ] 全シークレットが環境変数に
- [ ] `.env` が `.gitignore` に含まれている
- [ ] git 履歴にシークレットがない

### 2. 入力バリデーション

#### Pydantic によるバリデーション

```python
from pydantic import BaseModel, Field, validator


class WebhookRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=10000)
    user_id: str = Field(..., regex=r"^[a-zA-Z0-9_-]+$")
    is_mention: bool

    @validator("message")
    def sanitize_message(cls, v: str) -> str:
        # 危険な文字をエスケープ
        return v.strip()


@router.post("/webhook")
async def webhook(request: WebhookRequest):
    # request は既にバリデーション済み
    ...
```

#### ファイルアップロードバリデーション

```python
from fastapi import UploadFile, HTTPException

ALLOWED_EXTENSIONS = {".pdf", ".txt", ".md"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB


async def validate_upload(file: UploadFile) -> None:
    # 拡張子チェック
    ext = Path(file.filename).suffix.lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(400, f"Invalid file type: {ext}")

    # サイズチェック
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(400, "File too large (max 10MB)")

    await file.seek(0)  # リセット
```

#### 検証項目
- [ ] 全ユーザー入力が Pydantic でバリデーション
- [ ] ファイルアップロードが制限（サイズ、タイプ、拡張子）
- [ ] ブラックリストではなくホワイトリスト
- [ ] エラーメッセージが機密情報を漏らさない

### 3. SQL インジェクション防止

#### NG: 文字列連結

```python
# CRITICAL: SQL インジェクション脆弱性
query = f"SELECT * FROM documents WHERE id = '{doc_id}'"
cursor.execute(query)
```

#### OK: パラメータ化クエリ

```python
# SQLite
cursor.execute(
    "SELECT * FROM documents WHERE id = ?",
    [doc_id]
)

# DuckDB
cursor.execute(
    "SELECT * FROM vectors WHERE id = $1",
    [doc_id]
)

# SQLAlchemy
session.query(Document).filter(Document.id == doc_id).first()
```

#### 検証項目
- [ ] 全データベースクエリがパラメータ化
- [ ] SQL に文字列連結がない
- [ ] ORM/クエリビルダーを正しく使用

### 4. パストラバーサル防止

#### NG: ユーザー入力をパスに直接使用

```python
# CRITICAL: パストラバーサル脆弱性
file_path = f"./data/{user_input}"
with open(file_path) as f:
    content = f.read()
```

#### OK: パス検証

```python
from pathlib import Path


def safe_file_read(user_input: str, base_dir: str = "./data") -> str:
    base = Path(base_dir).resolve()
    target = (base / user_input).resolve()

    # パストラバーサルチェック
    if not str(target).startswith(str(base)):
        raise ValueError("Invalid path: path traversal detected")

    if not target.exists():
        raise FileNotFoundError(f"File not found: {user_input}")

    return target.read_text()
```

### 5. 認証/認可

#### FastAPI 認証ミドルウェア

```python
from fastapi import Depends, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Security(security),
) -> User:
    token = credentials.credentials

    try:
        payload = verify_token(token)
        user = await get_user(payload["user_id"])
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return user
    except TokenExpiredError:
        raise HTTPException(status_code=401, detail="Token expired")
    except InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")


@router.get("/protected")
async def protected_endpoint(
    current_user: User = Depends(get_current_user),
):
    return {"user": current_user.id}
```

#### 認可チェック

```python
@router.get("/users/{user_id}")
async def get_user_data(
    user_id: str,
    current_user: User = Depends(get_current_user),
):
    # 認可チェック: 自分のデータか管理者のみ
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Forbidden")

    return await get_user_data(user_id)
```

#### 検証項目
- [ ] 認証が必要なエンドポイントに認証チェック
- [ ] センシティブな操作に認可チェック
- [ ] トークンが適切に検証される
- [ ] セッション管理がセキュア

### 6. CORS 設定

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# 本番環境では具体的なオリジンを指定
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],  # 本番
    # allow_origins=["*"],  # 開発時のみ
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Authorization", "Content-Type"],
)
```

### 7. レート制限

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)


@router.post("/webhook")
@limiter.limit("10/minute")
async def webhook(request: Request, body: WebhookRequest):
    ...


@router.post("/search")
@limiter.limit("5/minute")  # 重い処理はより厳しく
async def search(request: Request, body: SearchRequest):
    ...
```

### 8. 機密データのログ出力防止

#### NG: 機密情報をログ

```python
# CRITICAL: 機密情報がログに
logger.info("Request", api_key=api_key, password=password)
```

#### OK: サニタイズしてログ

```python
import structlog

logger = structlog.get_logger()


def sanitize_for_log(data: dict) -> dict:
    sensitive_keys = {"password", "token", "api_key", "secret"}
    return {
        k: "***" if k.lower() in sensitive_keys else v
        for k, v in data.items()
    }


logger.info("Request processed", user_id=user_id, authenticated=True)
```

### 9. エラーハンドリング

#### NG: 内部エラーを公開

```python
# CRITICAL: スタックトレースを公開
except Exception as e:
    return {"error": str(e), "stack": traceback.format_exc()}
```

#### OK: 汎用エラーメッセージ

```python
from fastapi import HTTPException
import structlog

logger = structlog.get_logger()


@router.post("/api/endpoint")
async def endpoint():
    try:
        result = await process()
        return {"success": True, "data": result}
    except ValidationError as e:
        # バリデーションエラーは詳細を返す
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        # 内部エラーは詳細を隠す
        logger.error("Internal error", error=str(e), exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="An internal error occurred. Please try again.",
        )
```

### 10. 依存関係セキュリティ

```bash
# 脆弱性チェック
uv run pip-audit

# 依存関係の更新
uv sync --upgrade

# 特定パッケージの更新
uv add package@latest
```

#### 検証項目
- [ ] 定期的に `pip-audit` を実行
- [ ] 既知の脆弱性がない
- [ ] `uv.lock` がコミットされている
- [ ] Dependabot が有効

## セキュリティテスト

```python
# tests/security/test_auth.py
class TestAuthentication:
    def test_requires_authentication(self, client: TestClient):
        """認証なしでアクセス拒否"""
        response = client.get("/api/protected")
        assert response.status_code == 401

    def test_invalid_token_rejected(self, client: TestClient):
        """無効なトークンを拒否"""
        response = client.get(
            "/api/protected",
            headers={"Authorization": "Bearer invalid"},
        )
        assert response.status_code == 401


class TestAuthorization:
    def test_cannot_access_other_user_data(self, client: TestClient):
        """他ユーザーのデータにアクセス不可"""
        response = client.get(
            "/api/users/other-user-id",
            headers={"Authorization": f"Bearer {user_token}"},
        )
        assert response.status_code == 403


class TestInputValidation:
    def test_rejects_invalid_input(self, client: TestClient):
        """無効な入力を拒否"""
        response = client.post(
            "/api/webhook",
            json={"message": ""},  # 空のメッセージ
        )
        assert response.status_code == 422

    def test_rejects_sql_injection(self, client: TestClient):
        """SQL インジェクションを拒否"""
        response = client.get("/api/documents/'; DROP TABLE documents; --")
        assert response.status_code in (400, 404)


class TestRateLimiting:
    def test_enforces_rate_limits(self, client: TestClient):
        """レート制限が機能"""
        for _ in range(15):
            response = client.post("/api/webhook", json={"message": "test"})

        assert response.status_code == 429
```

## デプロイ前チェックリスト

- [ ] **シークレット**: ハードコードなし、全て環境変数
- [ ] **入力バリデーション**: 全ユーザー入力をバリデーション
- [ ] **SQL インジェクション**: 全クエリがパラメータ化
- [ ] **パストラバーサル**: ファイルパスを検証
- [ ] **認証**: 適切なトークン処理
- [ ] **認可**: ロールチェック実装
- [ ] **CORS**: 本番用に適切に設定
- [ ] **レート制限**: 全エンドポイントで有効
- [ ] **HTTPS**: 本番で強制
- [ ] **エラーハンドリング**: 機密情報を漏らさない
- [ ] **ログ**: 機密データを記録しない
- [ ] **依存関係**: 脆弱性なし

## セキュリティ分析コマンド

```bash
# シークレットの検出
grep -r "api[_-]?key\|password\|secret\|token" --include="*.py" src/

# 脆弱な依存関係のチェック
uv run pip-audit

# Bandit（Python セキュリティリンター）
uv run bandit -r src/
```

---

**重要**: セキュリティは妥協不可。1 つの脆弱性がシステム全体を危険にさらす。疑問がある場合は慎重に。
