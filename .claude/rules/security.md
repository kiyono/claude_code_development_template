---
description: Python/FastAPI セキュリティガイドライン（シークレット管理、入力バリデーション、SQLインジェクション対策）
globs:
  - "**/*.py"
alwaysApply: false
---

# Security Guidelines

Python/FastAPI セキュリティガイドライン。

## 必須セキュリティチェック

コミット前に確認:
- [ ] ハードコードされた秘密情報がない（API キー、パスワード、トークン）
- [ ] 全てのユーザー入力がバリデーションされている
- [ ] SQL インジェクション対策（パラメータ化クエリ）
- [ ] パストラバーサル対策
- [ ] 認証/認可が検証されている
- [ ] レート制限が設定されている
- [ ] エラーメッセージが機密情報を漏洩しない

## シークレット管理

```python
# NEVER: ハードコードされた秘密
api_key = "sk-proj-xxxxx"

# ALWAYS: 環境変数
import os
api_key = os.environ.get("SAKURA_API_KEY")

if not api_key:
    raise ValueError("SAKURA_API_KEY not configured")
```

## 入力バリデーション

```python
from pydantic import BaseModel, Field

class WebhookRequest(BaseModel):
    message: str = Field(min_length=1, max_length=10000)
    user_id: str = Field(pattern=r"^[a-zA-Z0-9_-]+$")
```

## SQL インジェクション対策

```python
# NEVER: 文字列連結
query = f"SELECT * FROM documents WHERE id = '{doc_id}'"

# ALWAYS: パラメータ化クエリ
cursor.execute("SELECT * FROM documents WHERE id = ?", [doc_id])
```

## ログ出力のサニタイズ

```python
# NEVER: 機密情報をログ出力
logger.info("User login", api_key=api_key, password=password)

# ALWAYS: 機密情報をマスク
logger.info("User login", user_id=user_id, authenticated=True)
```

## セキュリティ問題発見時

1. **即座に停止**
2. **security-reviewer** エージェントを使用
3. CRITICAL 問題を修正してから継続
4. 漏洩した秘密情報をローテート
5. 類似問題がないかコードベース全体をレビュー

## FastAPI セキュリティ

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer

security = HTTPBearer()

async def verify_token(credentials = Depends(security)):
    if not is_valid_token(credentials.credentials):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )
```
