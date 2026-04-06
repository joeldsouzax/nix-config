# Knowledge DB Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Personal research knowledge base for arXiv papers and code repos with semantic search, contextual auto-recall in Hermes, and chat-driven ingestion.

**Architecture:** pgvector on existing PostgreSQL (port 5433), local embedding via sentence-transformers FastAPI server (port 8801), Python MCP server (stdio) for Hermes tools, and a Hermes memory provider plugin for contextual recall.

**Tech Stack:** PostgreSQL + pgvector, Python 3.11, FastAPI, sentence-transformers (snowflake-arctic-embed-m-v2.0), pymupdf, psycopg, mcp SDK, httpx

**Design doc:** `docs/plans/2026-04-06-knowledge-db-design.md`

---

### Task 1: Nix Infrastructure — pgvector + knowledge database

**Files:**
- Modify: `modules/home/ai-agents.nix`

**Step 1: Add pgvector extension to activation script**

In `modules/home/ai-agents.nix`, add to the `setupScript` after the existing `createdb paperclip` block:

```nix
# Inside setupScript, after the paperclip createdb block:
${pkgs.postgresql}/bin/createdb -h localhost -p ${pgPort} knowledge 2>/dev/null || true
${pkgs.postgresql}/bin/psql -h localhost -p ${pgPort} -d knowledge -c "CREATE EXTENSION IF NOT EXISTS vector" 2>/dev/null || true
```

**Step 2: Verify by running activation**

Run: `sudo darwin-rebuild switch --flake ~/.setup#joel`
Expected: knowledge database created with pgvector extension

**Step 3: Verify manually**

Run: `psql -h localhost -p 5433 -d knowledge -c "SELECT extname FROM pg_extension WHERE extname = 'vector'"`
Expected: `vector` in output

**Step 4: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(knowledge-db): add pgvector extension and knowledge database"
```

---

### Task 2: Embedding Server — FastAPI + sentence-transformers

**Files:**
- Create: `~/.local/share/embedding-server/server.py`
- Create: `~/.local/share/embedding-server/requirements.txt`
- Modify: `modules/home/ai-agents.nix`

**Step 1: Write the embedding server**

Create `~/.local/share/embedding-server/server.py`:

```python
"""Local embedding server — OpenAI-compatible /v1/embeddings endpoint.

Serves snowflake-arctic-embed-m-v2.0 via sentence-transformers on Apple Silicon (MPS).
"""

import os
import time
import uuid
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from pydantic import BaseModel

MODEL_NAME = os.environ.get("EMBEDDING_MODEL", "Snowflake/snowflake-arctic-embed-m-v2.0")
HOST = os.environ.get("HOST", "0.0.0.0")
PORT = int(os.environ.get("PORT", "8801"))

model = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global model
    from sentence_transformers import SentenceTransformer
    model = SentenceTransformer(MODEL_NAME)
    yield


app = FastAPI(lifespan=lifespan)


class EmbeddingRequest(BaseModel):
    input: str | list[str]
    model: str = MODEL_NAME


@app.post("/v1/embeddings")
async def embeddings(request: EmbeddingRequest):
    texts = request.input if isinstance(request.input, list) else [request.input]
    vectors = model.encode(texts, normalize_embeddings=True)
    return {
        "object": "list",
        "data": [
            {"object": "embedding", "embedding": vec.tolist(), "index": i}
            for i, vec in enumerate(vectors)
        ],
        "model": request.model,
        "usage": {"prompt_tokens": 0, "total_tokens": 0},
    }


@app.get("/health")
async def health():
    return {"status": "ok", "model": MODEL_NAME}


if __name__ == "__main__":
    uvicorn.run(app, host=HOST, port=PORT)
```

**Step 2: Write requirements.txt**

Create `~/.local/share/embedding-server/requirements.txt`:

```
sentence-transformers>=3.0
fastapi
uvicorn[standard]
```

**Step 3: Add Nix infrastructure for embedding server**

In `modules/home/ai-agents.nix`, add variables in the `let` block:

```nix
embeddingServerDir = "${dataDir}/embedding-server";
embeddingServerVenv = "${embeddingServerDir}/venv";
embeddingModel = "Snowflake/snowflake-arctic-embed-m-v2.0";
embeddingPort = "8801";
```

Add to `setupScript` (Darwin section, after the MLX setup block):

```bash
echo "Setting up embedding server..."
mkdir -p "${embeddingServerDir}"
if [ ! -d "${embeddingServerVenv}" ]; then
  ${pkgs.python311}/bin/python3.11 -m venv "${embeddingServerVenv}"
fi
${pkgs.uv}/bin/uv pip install --python "${embeddingServerVenv}/bin/python" \
  sentence-transformers fastapi "uvicorn[standard]" 2>/dev/null || true

echo "Pre-downloading embedding model ${embeddingModel}..."
${embeddingServerVenv}/bin/python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('${embeddingModel}')" 2>/dev/null || true
```

Add wrapper script in `let` block:

```nix
embeddingServerWrapper = pkgs.writeShellScript "embedding-server-wrapper" ''
  set -euo pipefail
  export PATH="${embeddingServerVenv}/bin:$PATH"
  cd "${embeddingServerDir}"
  exec ${embeddingServerVenv}/bin/python server.py
'';
```

Add launchd agent (inside `launchd.agents = lib.mkIf isDarwin {`):

```nix
embedding-server = {
  enable = true;
  config = {
    Label = "com.embedding-server.agent";
    ProgramArguments = [ "${embeddingServerWrapper}" ];
    WorkingDirectory = embeddingServerDir;
    KeepAlive = true;
    RunAtLoad = true;
    EnvironmentVariables = {
      EMBEDDING_MODEL = embeddingModel;
      PORT = embeddingPort;
    };
    StandardOutPath = "${homeDir}/Library/Logs/embedding-server.log";
    StandardErrorPath = "${homeDir}/Library/Logs/embedding-server.error.log";
  };
};
```

Add shell aliases (inside `programs.zsh.shellAliases`):

```nix
embedding-logs =
  if isDarwin
  then "tail -f ~/Library/Logs/embedding-server.log"
  else "echo 'Embedding server is Darwin-only'";
embedding-restart =
  if isDarwin
  then ''launchctl kickstart -k gui/"$(id -u)"/com.embedding-server.agent''
  else "echo 'Embedding server is Darwin-only'";
```

**Step 4: Write the server.py file via Nix (declarative)**

Instead of manually creating the file, manage it through `home.file` in `ai-agents.nix`:

```nix
home.file."${embeddingServerDir}/server.py" = {
  text = ''
    ... (server.py content from Step 1)
  '';
  force = true;
};
```

**Step 5: Deploy and verify**

Run: `sudo darwin-rebuild switch --flake ~/.setup#joel`
Then: `curl http://localhost:8801/health`
Expected: `{"status":"ok","model":"Snowflake/snowflake-arctic-embed-m-v2.0"}`

Test embedding: `curl -X POST http://localhost:8801/v1/embeddings -H "Content-Type: application/json" -d '{"input": "test query"}'`
Expected: JSON with 768-dimensional embedding vector

**Step 6: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(knowledge-db): add local embedding server with snowflake-arctic-embed"
```

---

### Task 3: Knowledge MCP Server — Database Layer

**Files:**
- Create: `~/.local/share/knowledge-mcp/db.py`
- Create: `~/.local/share/knowledge-mcp/requirements.txt`

**Step 1: Write requirements.txt**

Create `~/.local/share/knowledge-mcp/requirements.txt`:

```
psycopg[binary]>=3.1
httpx>=0.27
pymupdf>=1.24
mcp>=1.2.0,<2
```

**Step 2: Write the database layer with schema migration**

Create `~/.local/share/knowledge-mcp/db.py`:

```python
"""Database layer — pgvector schema, migrations, and query helpers."""

import os
import uuid
from contextlib import contextmanager
from typing import Optional

import psycopg
from psycopg.rows import dict_row

DATABASE_URL = os.environ.get("DATABASE_URL", "postgres://localhost:5433/knowledge")

SCHEMA_SQL = """
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS papers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    arxiv_id TEXT UNIQUE,
    title TEXT NOT NULL,
    authors TEXT[],
    abstract TEXT,
    published_at TIMESTAMPTZ,
    pdf_url TEXT,
    source TEXT DEFAULT 'arxiv',
    tags TEXT[] DEFAULT '{}',
    ingested_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS repos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    url TEXT UNIQUE,
    name TEXT NOT NULL,
    description TEXT,
    language TEXT,
    tags TEXT[] DEFAULT '{}',
    ingested_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_type TEXT NOT NULL,
    source_id UUID NOT NULL,
    content TEXT NOT NULL,
    chunk_index INT,
    section TEXT,
    embedding vector(768),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chunks_embedding
    ON chunks USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS idx_chunks_source
    ON chunks (source_type, source_id);
CREATE INDEX IF NOT EXISTS idx_papers_arxiv_id
    ON papers (arxiv_id);
CREATE INDEX IF NOT EXISTS idx_papers_tags
    ON papers USING gin (tags);
CREATE INDEX IF NOT EXISTS idx_repos_url
    ON repos (url);
CREATE INDEX IF NOT EXISTS idx_repos_tags
    ON repos USING gin (tags);
"""


def get_connection():
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)


def migrate():
    """Run schema migration — idempotent."""
    with get_connection() as conn:
        conn.execute(SCHEMA_SQL)
        conn.commit()


def insert_paper(conn, *, arxiv_id: str, title: str, authors: list[str],
                 abstract: str, published_at: str, pdf_url: str,
                 source: str = "arxiv", tags: list[str] | None = None) -> str:
    """Insert paper, return ID. Skip if arxiv_id already exists."""
    row = conn.execute(
        """INSERT INTO papers (arxiv_id, title, authors, abstract, published_at, pdf_url, source, tags)
           VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
           ON CONFLICT (arxiv_id) DO UPDATE SET title = EXCLUDED.title
           RETURNING id""",
        (arxiv_id, title, authors, abstract, published_at, pdf_url, source, tags or [])
    ).fetchone()
    return str(row["id"])


def insert_repo(conn, *, url: str, name: str, description: str = "",
                language: str = "", tags: list[str] | None = None) -> str:
    """Insert repo, return ID. Skip if URL already exists."""
    row = conn.execute(
        """INSERT INTO repos (url, name, description, language, tags)
           VALUES (%s, %s, %s, %s, %s)
           ON CONFLICT (url) DO UPDATE SET description = EXCLUDED.description
           RETURNING id""",
        (url, name, description, language, tags or [])
    ).fetchone()
    return str(row["id"])


def insert_chunks(conn, chunks: list[dict]):
    """Batch insert chunks with embeddings."""
    if not chunks:
        return
    with conn.cursor() as cur:
        for chunk in chunks:
            cur.execute(
                """INSERT INTO chunks (source_type, source_id, content, chunk_index, section, embedding, metadata)
                   VALUES (%s, %s, %s, %s, %s, %s::vector, %s)""",
                (chunk["source_type"], chunk["source_id"], chunk["content"],
                 chunk.get("chunk_index"), chunk.get("section"),
                 str(chunk["embedding"]), psycopg.types.json.Json(chunk.get("metadata", {})))
            )


def search_chunks(conn, embedding: list[float], *, top_k: int = 10,
                  source_type: str | None = None, tags: list[str] | None = None,
                  threshold: float = 0.0) -> list[dict]:
    """Semantic search over chunks with optional filters."""
    conditions = ["1=1"]
    params: list = [str(embedding), top_k]

    if source_type:
        conditions.append("c.source_type = %s")
        params.append(source_type)

    if tags:
        conditions.append("""(
            (c.source_type = 'paper' AND EXISTS (
                SELECT 1 FROM papers p WHERE p.id = c.source_id AND p.tags && %s
            )) OR
            (c.source_type = 'repo' AND EXISTS (
                SELECT 1 FROM repos r WHERE r.id = c.source_id AND r.tags && %s
            ))
        )""")
        params.extend([tags, tags])

    where = " AND ".join(conditions)

    rows = conn.execute(f"""
        SELECT c.*, 1 - (c.embedding <=> %s::vector) AS similarity
        FROM chunks c
        WHERE {where}
        ORDER BY c.embedding <=> %s::vector
        LIMIT %s
    """, [str(embedding)] + params[2:] + [str(embedding), top_k]).fetchall()

    if threshold > 0:
        rows = [r for r in rows if r["similarity"] >= threshold]

    return rows


def list_papers(conn, *, tags: list[str] | None = None,
                limit: int = 50, offset: int = 0) -> list[dict]:
    """List papers with optional tag filter."""
    if tags:
        return conn.execute(
            "SELECT * FROM papers WHERE tags && %s ORDER BY ingested_at DESC LIMIT %s OFFSET %s",
            (tags, limit, offset)
        ).fetchall()
    return conn.execute(
        "SELECT * FROM papers ORDER BY ingested_at DESC LIMIT %s OFFSET %s",
        (limit, offset)
    ).fetchall()


def list_repos(conn, *, tags: list[str] | None = None,
               limit: int = 50, offset: int = 0) -> list[dict]:
    """List repos with optional tag filter."""
    if tags:
        return conn.execute(
            "SELECT * FROM repos WHERE tags && %s ORDER BY ingested_at DESC LIMIT %s OFFSET %s",
            (tags, limit, offset)
        ).fetchall()
    return conn.execute(
        "SELECT * FROM repos ORDER BY ingested_at DESC LIMIT %s OFFSET %s",
        (limit, offset)
    ).fetchall()


def update_tags(conn, source_type: str, source_id: str,
                add_tags: list[str] | None = None,
                remove_tags: list[str] | None = None):
    """Add/remove tags on a paper or repo."""
    table = "papers" if source_type == "paper" else "repos"
    if add_tags:
        conn.execute(
            f"UPDATE {table} SET tags = array_cat(tags, %s) WHERE id = %s",
            (add_tags, source_id)
        )
    if remove_tags:
        conn.execute(
            f"UPDATE {table} SET tags = array_remove_all(tags, %s) WHERE id = %s",
            (remove_tags, source_id)
        )
```

**Step 3: Write a test for the database layer**

Create `~/.local/share/knowledge-mcp/tests/test_db.py`:

```python
"""Test database layer against real PostgreSQL."""

import os
import pytest
import psycopg

os.environ.setdefault("DATABASE_URL", "postgres://localhost:5433/knowledge_test")

from db import migrate, get_connection, insert_paper, insert_chunks, search_chunks


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Create test database and run migrations."""
    conn = psycopg.connect("postgres://localhost:5433/postgres")
    conn.autocommit = True
    conn.execute("DROP DATABASE IF EXISTS knowledge_test")
    conn.execute("CREATE DATABASE knowledge_test")
    conn.close()
    migrate()
    yield
    conn = psycopg.connect("postgres://localhost:5433/postgres")
    conn.autocommit = True
    conn.execute("DROP DATABASE IF EXISTS knowledge_test")
    conn.close()


@pytest.fixture
def conn():
    with get_connection() as c:
        yield c
        c.rollback()


def test_insert_and_search_paper(conn):
    paper_id = insert_paper(
        conn, arxiv_id="2401.00001", title="Test Paper",
        authors=["Author A"], abstract="About transformers",
        published_at="2024-01-01", pdf_url="https://arxiv.org/pdf/2401.00001"
    )
    # Fake embedding (768d zero vector with first element = 1)
    embedding = [0.0] * 768
    embedding[0] = 1.0
    insert_chunks(conn, [{
        "source_type": "paper", "source_id": paper_id,
        "content": "Transformers are great", "chunk_index": 0,
        "section": "abstract", "embedding": embedding,
    }])
    conn.commit()

    results = search_chunks(conn, embedding, top_k=5)
    assert len(results) >= 1
    assert results[0]["content"] == "Transformers are great"
```

**Step 4: Run the test**

Run: `cd ~/.local/share/knowledge-mcp && venv/bin/python -m pytest tests/test_db.py -v`
Expected: PASS

**Step 5: Commit**

```bash
git commit -m "feat(knowledge-db): database layer with pgvector schema and queries"
```

---

### Task 4: Knowledge MCP Server — Embedder Client

**Files:**
- Create: `~/.local/share/knowledge-mcp/ingestion/embedder.py`

**Step 1: Write the embedder client**

Create `~/.local/share/knowledge-mcp/ingestion/__init__.py` (empty).

Create `~/.local/share/knowledge-mcp/ingestion/embedder.py`:

```python
"""Client for the local embedding server."""

import os
import httpx

EMBEDDING_URL = os.environ.get("EMBEDDING_URL", "http://localhost:8801/v1")


async def embed_texts(texts: list[str]) -> list[list[float]]:
    """Embed a batch of texts via the local embedding server."""
    async with httpx.AsyncClient(timeout=120) as client:
        resp = await client.post(
            f"{EMBEDDING_URL}/embeddings",
            json={"input": texts},
        )
        resp.raise_for_status()
        data = resp.json()["data"]
        return [item["embedding"] for item in sorted(data, key=lambda x: x["index"])]


async def embed_text(text: str) -> list[float]:
    """Embed a single text."""
    result = await embed_texts([text])
    return result[0]
```

**Step 2: Commit**

```bash
git commit -m "feat(knowledge-db): embedding client for local server"
```

---

### Task 5: Knowledge MCP Server — Chunker

**Files:**
- Create: `~/.local/share/knowledge-mcp/ingestion/chunker.py`

**Step 1: Write the chunker**

Create `~/.local/share/knowledge-mcp/ingestion/chunker.py`:

```python
"""Text chunking with section awareness and overlap."""

import re


def chunk_text(text: str, *, max_tokens: int = 512, overlap: int = 64,
               section: str = "") -> list[dict]:
    """Split text into overlapping chunks of roughly max_tokens tokens.

    Uses whitespace tokenization (rough ~0.75 words per token approximation).
    Returns list of {content, chunk_index, section}.
    """
    # Rough token estimate: 1 token ≈ 4 chars
    max_chars = max_tokens * 4
    overlap_chars = overlap * 4

    if len(text) <= max_chars:
        return [{"content": text.strip(), "chunk_index": 0, "section": section}]

    chunks = []
    start = 0
    idx = 0
    while start < len(text):
        end = start + max_chars

        # Try to break at a sentence boundary
        if end < len(text):
            # Look for sentence end in last 20% of chunk
            search_start = start + int(max_chars * 0.8)
            match = None
            for m in re.finditer(r'[.!?]\s+', text[search_start:end]):
                match = m
            if match:
                end = search_start + match.end()

        chunk_text_str = text[start:end].strip()
        if chunk_text_str:
            chunks.append({
                "content": chunk_text_str,
                "chunk_index": idx,
                "section": section,
            })
            idx += 1

        start = end - overlap_chars
        if start >= len(text):
            break

    return chunks


def chunk_pdf_sections(sections: list[dict]) -> list[dict]:
    """Chunk a list of {section, text} dicts from PDF extraction.

    Each section is chunked independently, preserving section labels.
    """
    all_chunks = []
    global_idx = 0
    for sec in sections:
        chunks = chunk_text(sec["text"], section=sec.get("section", ""))
        for chunk in chunks:
            chunk["chunk_index"] = global_idx
            global_idx += 1
        all_chunks.extend(chunks)
    return all_chunks
```

**Step 2: Write tests**

Create `~/.local/share/knowledge-mcp/tests/test_chunker.py`:

```python
from ingestion.chunker import chunk_text, chunk_pdf_sections


def test_short_text_single_chunk():
    result = chunk_text("Hello world", max_tokens=512)
    assert len(result) == 1
    assert result[0]["content"] == "Hello world"
    assert result[0]["chunk_index"] == 0


def test_long_text_multiple_chunks():
    text = "word " * 1000  # ~5000 chars, well over 512 tokens
    result = chunk_text(text, max_tokens=128)
    assert len(result) > 1
    # Check overlap: last chunk's start overlaps previous chunk's end
    for i in range(1, len(result)):
        assert result[i]["chunk_index"] == i


def test_section_preserved():
    result = chunk_text("Some content", section="abstract")
    assert result[0]["section"] == "abstract"


def test_pdf_sections():
    sections = [
        {"section": "abstract", "text": "Short abstract."},
        {"section": "methods", "text": "word " * 500},
    ]
    result = chunk_pdf_sections(sections)
    assert result[0]["section"] == "abstract"
    assert any(c["section"] == "methods" for c in result)
    # Global indexing is sequential
    indices = [c["chunk_index"] for c in result]
    assert indices == list(range(len(result)))
```

**Step 3: Run tests**

Run: `cd ~/.local/share/knowledge-mcp && venv/bin/python -m pytest tests/test_chunker.py -v`
Expected: All PASS

**Step 4: Commit**

```bash
git commit -m "feat(knowledge-db): text chunker with section awareness and overlap"
```

---

### Task 6: Knowledge MCP Server — arXiv Ingestion

**Files:**
- Create: `~/.local/share/knowledge-mcp/ingestion/arxiv.py`

**Step 1: Write the arXiv ingestion module**

Create `~/.local/share/knowledge-mcp/ingestion/arxiv.py`:

```python
"""arXiv paper ingestion — API search, PDF download, text extraction, chunking."""

import re
import tempfile
import xml.etree.ElementTree as ET

import httpx
import pymupdf

from .chunker import chunk_text, chunk_pdf_sections
from .embedder import embed_texts

ARXIV_API = "http://export.arxiv.org/api/query"


async def search_arxiv(query: str, max_results: int = 5) -> list[dict]:
    """Search arXiv API, return paper metadata."""
    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.get(ARXIV_API, params={
            "search_query": f"all:{query}",
            "max_results": max_results,
            "sortBy": "relevance",
        })
        resp.raise_for_status()

    ns = {"atom": "http://www.w3.org/2005/Atom"}
    root = ET.fromstring(resp.text)
    papers = []
    for entry in root.findall("atom:entry", ns):
        arxiv_id_url = entry.find("atom:id", ns).text
        arxiv_id = arxiv_id_url.split("/abs/")[-1]

        authors = [a.find("atom:name", ns).text
                    for a in entry.findall("atom:author", ns)]

        pdf_link = None
        for link in entry.findall("atom:link", ns):
            if link.get("title") == "pdf":
                pdf_link = link.get("href")

        papers.append({
            "arxiv_id": arxiv_id,
            "title": entry.find("atom:title", ns).text.strip().replace("\n", " "),
            "authors": authors,
            "abstract": entry.find("atom:summary", ns).text.strip(),
            "published_at": entry.find("atom:published", ns).text,
            "pdf_url": pdf_link or f"https://arxiv.org/pdf/{arxiv_id}",
        })
    return papers


async def download_and_extract_pdf(pdf_url: str) -> list[dict]:
    """Download PDF and extract text with section detection.

    Returns list of {section, text} dicts.
    """
    async with httpx.AsyncClient(timeout=60, follow_redirects=True) as client:
        resp = await client.get(pdf_url)
        resp.raise_for_status()

    with tempfile.NamedTemporaryFile(suffix=".pdf") as tmp:
        tmp.write(resp.content)
        tmp.flush()

        doc = pymupdf.open(tmp.name)
        full_text = ""
        for page in doc:
            full_text += page.get_text() + "\n"
        doc.close()

    # Simple section detection via common headers
    section_pattern = re.compile(
        r'^(?:\d+\.?\s+)?(Abstract|Introduction|Related Work|Background|'
        r'Methods?|Methodology|Approach|Experiments?|Results?|Discussion|'
        r'Conclusion|References|Acknowledgment|Appendix)',
        re.MULTILINE | re.IGNORECASE
    )

    sections = []
    matches = list(section_pattern.finditer(full_text))

    if not matches:
        return [{"section": "full", "text": full_text}]

    # Text before first section header
    if matches[0].start() > 100:
        sections.append({"section": "preamble", "text": full_text[:matches[0].start()]})

    for i, match in enumerate(matches):
        section_name = match.group(1).lower()
        start = match.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(full_text)
        text = full_text[start:end].strip()
        if text and section_name != "references":
            sections.append({"section": section_name, "text": text})

    return sections


async def ingest_paper(paper_meta: dict, db_conn) -> dict:
    """Full ingestion pipeline for a single paper.

    1. Insert paper metadata
    2. Download + extract PDF
    3. Chunk text
    4. Embed chunks
    5. Store chunks with embeddings

    Returns summary dict.
    """
    from db import insert_paper, insert_chunks

    paper_id = insert_paper(
        db_conn,
        arxiv_id=paper_meta["arxiv_id"],
        title=paper_meta["title"],
        authors=paper_meta["authors"],
        abstract=paper_meta["abstract"],
        published_at=paper_meta["published_at"],
        pdf_url=paper_meta["pdf_url"],
    )

    sections = await download_and_extract_pdf(paper_meta["pdf_url"])
    chunks = chunk_pdf_sections(sections)

    if chunks:
        texts = [c["content"] for c in chunks]
        embeddings = await embed_texts(texts)
        for chunk, emb in zip(chunks, embeddings):
            chunk["source_type"] = "paper"
            chunk["source_id"] = paper_id
            chunk["embedding"] = emb
        insert_chunks(db_conn, chunks)

    db_conn.commit()
    return {
        "paper_id": paper_id,
        "arxiv_id": paper_meta["arxiv_id"],
        "title": paper_meta["title"],
        "chunks": len(chunks),
    }
```

**Step 2: Commit**

```bash
git commit -m "feat(knowledge-db): arXiv ingestion pipeline — search, PDF parse, chunk, embed"
```

---

### Task 7: Knowledge MCP Server — GitHub Ingestion

**Files:**
- Create: `~/.local/share/knowledge-mcp/ingestion/github.py`

**Step 1: Write the GitHub ingestion module**

Create `~/.local/share/knowledge-mcp/ingestion/github.py`:

```python
"""GitHub repo ingestion — clone, extract key files, chunk, embed."""

import os
import shutil
import subprocess
import tempfile

from .chunker import chunk_text
from .embedder import embed_texts

# File extensions worth indexing
CODE_EXTENSIONS = {
    ".py", ".js", ".ts", ".go", ".rs", ".java", ".c", ".cpp", ".h",
    ".nix", ".yaml", ".yml", ".toml", ".json", ".md", ".txt", ".sh",
}

MAX_FILE_SIZE = 100_000  # 100KB


async def ingest_repo(url: str, db_conn, *, tags: list[str] | None = None) -> dict:
    """Clone repo, extract key files, chunk, embed, store.

    Returns summary dict.
    """
    from db import insert_repo, insert_chunks

    tmpdir = tempfile.mkdtemp()
    try:
        subprocess.run(
            ["git", "clone", "--depth", "1", url, tmpdir],
            capture_output=True, check=True, timeout=120,
        )

        # Extract repo name from URL
        name = url.rstrip("/").split("/")[-1].replace(".git", "")

        # Read README for description
        description = ""
        for readme_name in ["README.md", "README.rst", "README.txt", "README"]:
            readme_path = os.path.join(tmpdir, readme_name)
            if os.path.isfile(readme_path):
                with open(readme_path) as f:
                    description = f.read()[:2000]
                break

        # Detect primary language (simple heuristic)
        ext_counts: dict[str, int] = {}
        for root, dirs, files in os.walk(tmpdir):
            dirs[:] = [d for d in dirs if not d.startswith(".")]
            for fname in files:
                ext = os.path.splitext(fname)[1]
                if ext in CODE_EXTENSIONS:
                    ext_counts[ext] = ext_counts.get(ext, 0) + 1
        language = max(ext_counts, key=ext_counts.get, default="")

        repo_id = insert_repo(
            db_conn, url=url, name=name,
            description=description[:500], language=language,
            tags=tags,
        )

        # Collect files to index
        files_to_index = []
        for root, dirs, files in os.walk(tmpdir):
            dirs[:] = [d for d in dirs if not d.startswith(".") and d != "node_modules"]
            for fname in files:
                ext = os.path.splitext(fname)[1]
                if ext not in CODE_EXTENSIONS:
                    continue
                fpath = os.path.join(root, fname)
                if os.path.getsize(fpath) > MAX_FILE_SIZE:
                    continue
                rel_path = os.path.relpath(fpath, tmpdir)
                with open(fpath) as f:
                    try:
                        content = f.read()
                    except UnicodeDecodeError:
                        continue
                files_to_index.append({"path": rel_path, "content": content})

        # Chunk and embed
        all_chunks = []
        for finfo in files_to_index:
            chunks = chunk_text(finfo["content"], section=finfo["path"])
            for chunk in chunks:
                chunk["source_type"] = "repo"
                chunk["source_id"] = repo_id
                chunk["metadata"] = {"file": finfo["path"]}
            all_chunks.extend(chunks)

        if all_chunks:
            texts = [c["content"] for c in all_chunks]
            # Embed in batches of 32
            all_embeddings = []
            for i in range(0, len(texts), 32):
                batch = texts[i:i+32]
                embs = await embed_texts(batch)
                all_embeddings.extend(embs)
            for chunk, emb in zip(all_chunks, all_embeddings):
                chunk["embedding"] = emb
            insert_chunks(db_conn, all_chunks)

        db_conn.commit()
        return {
            "repo_id": repo_id,
            "url": url,
            "name": name,
            "files_indexed": len(files_to_index),
            "chunks": len(all_chunks),
        }

    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
```

**Step 2: Commit**

```bash
git commit -m "feat(knowledge-db): GitHub repo ingestion pipeline"
```

---

### Task 8: Knowledge MCP Server — Search Module

**Files:**
- Create: `~/.local/share/knowledge-mcp/search.py`

**Step 1: Write the search module**

Create `~/.local/share/knowledge-mcp/search.py`:

```python
"""Semantic search with metadata enrichment."""

from db import get_connection, search_chunks, list_papers, list_repos
from ingestion.embedder import embed_text


async def semantic_search(query: str, *, top_k: int = 10,
                          source_type: str | None = None,
                          tags: list[str] | None = None,
                          threshold: float = 0.0) -> list[dict]:
    """Search knowledge base — embed query, find similar chunks, enrich with source metadata."""
    query_embedding = await embed_text(query)

    with get_connection() as conn:
        chunks = search_chunks(
            conn, query_embedding,
            top_k=top_k, source_type=source_type,
            tags=tags, threshold=threshold,
        )

        results = []
        for chunk in chunks:
            source_meta = {}
            if chunk["source_type"] == "paper":
                row = conn.execute(
                    "SELECT arxiv_id, title, authors, abstract FROM papers WHERE id = %s",
                    (chunk["source_id"],)
                ).fetchone()
                if row:
                    source_meta = dict(row)
            elif chunk["source_type"] == "repo":
                row = conn.execute(
                    "SELECT url, name, description FROM repos WHERE id = %s",
                    (chunk["source_id"],)
                ).fetchone()
                if row:
                    source_meta = dict(row)

            results.append({
                "content": chunk["content"],
                "section": chunk["section"],
                "similarity": round(chunk["similarity"], 4),
                "source_type": chunk["source_type"],
                "source": source_meta,
            })

    return results
```

**Step 2: Commit**

```bash
git commit -m "feat(knowledge-db): semantic search with metadata enrichment"
```

---

### Task 9: Knowledge MCP Server — MCP Entry Point

**Files:**
- Create: `~/.local/share/knowledge-mcp/server.py`
- Create: `~/.local/share/knowledge-mcp/__main__.py`

**Step 1: Write the MCP server**

Create `~/.local/share/knowledge-mcp/server.py`:

```python
"""Knowledge MCP Server — exposes search and ingestion tools to Hermes."""

import json
import logging

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

import db
from search import semantic_search
from ingestion.arxiv import search_arxiv, ingest_paper
from ingestion.github import ingest_repo
from ingestion.embedder import embed_texts

logger = logging.getLogger(__name__)

server = Server("knowledge")


@server.list_tools()
async def list_tools() -> list[Tool]:
    return [
        Tool(
            name="knowledge_search",
            description="Search your research knowledge base semantically. Returns relevant paper excerpts and code snippets.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "What to search for"},
                    "top_k": {"type": "integer", "description": "Max results (default 10)", "default": 10},
                    "source_type": {"type": "string", "enum": ["paper", "repo"], "description": "Filter by source type"},
                    "tags": {"type": "array", "items": {"type": "string"}, "description": "Filter by tags"},
                },
                "required": ["query"],
            },
        ),
        Tool(
            name="knowledge_ingest_arxiv",
            description="Search arXiv for papers and ingest them into the knowledge base. Can take an arXiv ID (e.g. '2401.12345') or a search query.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "arXiv ID or search query"},
                    "max_results": {"type": "integer", "description": "Max papers to ingest (default 3)", "default": 3},
                },
                "required": ["query"],
            },
        ),
        Tool(
            name="knowledge_ingest_repo",
            description="Clone and ingest a GitHub repository into the knowledge base.",
            inputSchema={
                "type": "object",
                "properties": {
                    "url": {"type": "string", "description": "GitHub repo URL"},
                    "tags": {"type": "array", "items": {"type": "string"}, "description": "Tags to assign"},
                },
                "required": ["url"],
            },
        ),
        Tool(
            name="knowledge_ingest_text",
            description="Store a text note or research finding in the knowledge base.",
            inputSchema={
                "type": "object",
                "properties": {
                    "content": {"type": "string", "description": "Text content to store"},
                    "title": {"type": "string", "description": "Title for the note"},
                    "tags": {"type": "array", "items": {"type": "string"}, "description": "Tags"},
                },
                "required": ["content", "title"],
            },
        ),
        Tool(
            name="knowledge_list",
            description="List papers and repos in the knowledge base.",
            inputSchema={
                "type": "object",
                "properties": {
                    "source_type": {"type": "string", "enum": ["paper", "repo"], "description": "Filter by type"},
                    "tags": {"type": "array", "items": {"type": "string"}, "description": "Filter by tags"},
                    "limit": {"type": "integer", "default": 20},
                },
            },
        ),
        Tool(
            name="knowledge_tag",
            description="Add or remove tags on a paper or repo.",
            inputSchema={
                "type": "object",
                "properties": {
                    "source_type": {"type": "string", "enum": ["paper", "repo"]},
                    "source_id": {"type": "string", "description": "UUID of the paper or repo"},
                    "add_tags": {"type": "array", "items": {"type": "string"}},
                    "remove_tags": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["source_type", "source_id"],
            },
        ),
    ]


@server.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    try:
        if name == "knowledge_search":
            results = await semantic_search(
                arguments["query"],
                top_k=arguments.get("top_k", 10),
                source_type=arguments.get("source_type"),
                tags=arguments.get("tags"),
            )
            return [TextContent(type="text", text=json.dumps(results, default=str))]

        elif name == "knowledge_ingest_arxiv":
            query = arguments["query"]
            max_results = arguments.get("max_results", 3)

            # Detect if it's an arXiv ID
            import re
            if re.match(r'^\d{4}\.\d{4,5}(v\d+)?$', query):
                papers = await search_arxiv(f"id:{query}", max_results=1)
            else:
                papers = await search_arxiv(query, max_results=max_results)

            results = []
            with db.get_connection() as conn:
                for paper in papers:
                    result = await ingest_paper(paper, conn)
                    results.append(result)

            return [TextContent(type="text", text=json.dumps(results, default=str))]

        elif name == "knowledge_ingest_repo":
            with db.get_connection() as conn:
                result = await ingest_repo(
                    arguments["url"], conn,
                    tags=arguments.get("tags"),
                )
            return [TextContent(type="text", text=json.dumps(result, default=str))]

        elif name == "knowledge_ingest_text":
            from ingestion.chunker import chunk_text
            chunks = chunk_text(arguments["content"])
            texts = [c["content"] for c in chunks]
            embeddings = await embed_texts(texts)

            with db.get_connection() as conn:
                paper_id = db.insert_paper(
                    conn,
                    arxiv_id=f"note-{arguments['title'][:50]}",
                    title=arguments["title"],
                    authors=[], abstract=arguments["content"][:500],
                    published_at=None, pdf_url="",
                    source="manual", tags=arguments.get("tags", []),
                )
                chunk_records = []
                for chunk, emb in zip(chunks, embeddings):
                    chunk_records.append({
                        "source_type": "paper", "source_id": paper_id,
                        "content": chunk["content"], "chunk_index": chunk["chunk_index"],
                        "section": "note", "embedding": emb,
                    })
                db.insert_chunks(conn, chunk_records)
                conn.commit()

            return [TextContent(type="text", text=json.dumps({
                "status": "stored", "title": arguments["title"], "chunks": len(chunks),
            }))]

        elif name == "knowledge_list":
            with db.get_connection() as conn:
                source_type = arguments.get("source_type")
                tags = arguments.get("tags")
                limit = arguments.get("limit", 20)
                result = {}
                if source_type != "repo":
                    result["papers"] = db.list_papers(conn, tags=tags, limit=limit)
                if source_type != "paper":
                    result["repos"] = db.list_repos(conn, tags=tags, limit=limit)
            return [TextContent(type="text", text=json.dumps(result, default=str))]

        elif name == "knowledge_tag":
            with db.get_connection() as conn:
                db.update_tags(
                    conn,
                    arguments["source_type"], arguments["source_id"],
                    add_tags=arguments.get("add_tags"),
                    remove_tags=arguments.get("remove_tags"),
                )
                conn.commit()
            return [TextContent(type="text", text=json.dumps({"status": "updated"}))]

        else:
            return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]

    except Exception as e:
        logger.exception("Tool call failed: %s", name)
        return [TextContent(type="text", text=json.dumps({"error": str(e)}))]


async def main():
    db.migrate()
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream)


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

Create `~/.local/share/knowledge-mcp/__main__.py`:

```python
from server import main
import asyncio
asyncio.run(main())
```

**Step 2: Commit**

```bash
git commit -m "feat(knowledge-db): MCP server with search and ingestion tools"
```

---

### Task 10: Hermes Memory Provider Plugin

**Files:**
- Create: `~/.local/share/hermes/plugins/memory/knowledge/__init__.py`
- Create: `~/.local/share/hermes/plugins/memory/knowledge/plugin.yaml`

**Step 1: Write the memory provider**

Create `~/.local/share/hermes/plugins/memory/knowledge/__init__.py`:

```python
"""Knowledge DB memory provider — contextual recall from research knowledge base.

Connects to the same pgvector database as the knowledge MCP server.
Provides automatic recall (prefetch) and synthesis (reflect) during Hermes conversations.
"""

import json
import logging
import os
import asyncio
from typing import Any, Dict, List

import httpx
import psycopg
from psycopg.rows import dict_row

from agent.memory_provider import MemoryProvider

logger = logging.getLogger(__name__)

DATABASE_URL = os.environ.get("KNOWLEDGE_DATABASE_URL", "postgres://localhost:5433/knowledge")
EMBEDDING_URL = os.environ.get("KNOWLEDGE_EMBEDDING_URL", "http://localhost:8801/v1")
RECALL_THRESHOLD = float(os.environ.get("KNOWLEDGE_RECALL_THRESHOLD", "0.7"))
RECALL_TOP_K = int(os.environ.get("KNOWLEDGE_RECALL_TOP_K", "5"))


def _embed_sync(text: str) -> list[float]:
    """Synchronous embedding call (for use in sync methods)."""
    resp = httpx.post(
        f"{EMBEDDING_URL}/embeddings",
        json={"input": text},
        timeout=30,
    )
    resp.raise_for_status()
    return resp.json()["data"][0]["embedding"]


def _search_sync(embedding: list[float], top_k: int = 5,
                 threshold: float = 0.7) -> list[dict]:
    """Search chunks synchronously."""
    with psycopg.connect(DATABASE_URL, row_factory=dict_row) as conn:
        rows = conn.execute("""
            SELECT c.content, c.section, c.source_type, c.source_id,
                   1 - (c.embedding <=> %s::vector) AS similarity,
                   CASE
                       WHEN c.source_type = 'paper' THEN (SELECT title FROM papers WHERE id = c.source_id)
                       WHEN c.source_type = 'repo' THEN (SELECT name FROM repos WHERE id = c.source_id)
                   END AS source_name
            FROM chunks c
            WHERE 1 - (c.embedding <=> %s::vector) >= %s
            ORDER BY c.embedding <=> %s::vector
            LIMIT %s
        """, (str(embedding), str(embedding), threshold, str(embedding), top_k)).fetchall()
    return [dict(r) for r in rows]


class KnowledgeMemoryProvider(MemoryProvider):
    """Provides contextual recall from the research knowledge base."""

    def __init__(self):
        self._session_id = ""
        self._available = False

    @property
    def name(self) -> str:
        return "knowledge"

    def is_available(self) -> bool:
        """Check if database and embedding server are reachable."""
        try:
            psycopg.connect(DATABASE_URL).close()
            resp = httpx.get(f"{EMBEDDING_URL.replace('/v1', '')}/health", timeout=5)
            self._available = resp.status_code == 200
        except Exception:
            self._available = False
        return self._available

    def initialize(self, session_id: str, **kwargs) -> None:
        self._session_id = session_id
        logger.info("Knowledge memory provider initialized for session %s", session_id)

    def system_prompt_block(self) -> str:
        try:
            with psycopg.connect(DATABASE_URL, row_factory=dict_row) as conn:
                paper_count = conn.execute("SELECT count(*) as c FROM papers").fetchone()["c"]
                repo_count = conn.execute("SELECT count(*) as c FROM repos").fetchone()["c"]
            return (
                f"# Research Knowledge Base\n"
                f"You have access to a personal knowledge base with {paper_count} papers "
                f"and {repo_count} code repos. Relevant research is automatically surfaced below. "
                f"Use knowledge_search for explicit queries."
            )
        except Exception:
            return ""

    def prefetch(self, query: str, *, session_id: str = "") -> str:
        """Recall relevant research before each turn."""
        if not query or not self._available:
            return ""
        try:
            embedding = _embed_sync(query)
            results = _search_sync(embedding, top_k=RECALL_TOP_K, threshold=RECALL_THRESHOLD)
            if not results:
                return ""

            lines = ["## Relevant Research (auto-recalled)"]
            for r in results:
                source_label = f"[{r['source_type']}] {r['source_name']}"
                lines.append(f"\n**{source_label}** (similarity: {r['similarity']:.2f}, section: {r['section']})")
                lines.append(f"> {r['content'][:300]}...")
            return "\n".join(lines)

        except Exception as e:
            logger.debug("Knowledge prefetch failed: %s", e)
            return ""

    def sync_turn(self, user_content: str, assistant_content: str, *, session_id: str = "") -> None:
        """No-op — we don't auto-store conversation turns."""
        pass

    def get_tool_schemas(self) -> list[dict]:
        """No extra tools — the MCP server handles explicit tool calls."""
        return []

    def handle_tool_call(self, tool_name: str, args: dict, **kwargs) -> str:
        return json.dumps({"error": "No tools — use knowledge MCP server"})

    def shutdown(self) -> None:
        logger.info("Knowledge memory provider shut down")

    def get_config_schema(self) -> list[dict]:
        return [
            {
                "key": "database_url",
                "description": "PostgreSQL connection URL for knowledge DB",
                "default": "postgres://localhost:5433/knowledge",
                "env_var": "KNOWLEDGE_DATABASE_URL",
            },
            {
                "key": "embedding_url",
                "description": "URL of the embedding server",
                "default": "http://localhost:8801/v1",
                "env_var": "KNOWLEDGE_EMBEDDING_URL",
            },
            {
                "key": "recall_threshold",
                "description": "Minimum similarity for auto-recall (0.0-1.0)",
                "default": "0.7",
                "env_var": "KNOWLEDGE_RECALL_THRESHOLD",
            },
        ]


def register(ctx) -> None:
    ctx.register_memory_provider(KnowledgeMemoryProvider())
```

**Step 2: Write plugin.yaml**

Create `~/.local/share/hermes/plugins/memory/knowledge/plugin.yaml`:

```yaml
name: knowledge
description: "Personal research knowledge base — auto-recalls relevant arXiv papers and code repos during conversations"
version: "1.0.0"
author: "joel"
```

**Step 3: Commit**

```bash
git commit -m "feat(knowledge-db): Hermes memory provider plugin for contextual recall"
```

---

### Task 11: Nix Integration — Wire Everything Together

**Files:**
- Modify: `modules/home/ai-agents.nix`

**Step 1: Add all knowledge-db infrastructure to ai-agents.nix**

This is the big integration task. Add to `modules/home/ai-agents.nix`:

1. **Variables** in `let` block:
```nix
knowledgeDir = "${dataDir}/knowledge-mcp";
knowledgeVenv = "${knowledgeDir}/venv";
embeddingServerDir = "${dataDir}/embedding-server";
embeddingServerVenv = "${embeddingServerDir}/venv";
embeddingModel = "Snowflake/snowflake-arctic-embed-m-v2.0";
embeddingPort = "8801";
```

2. **Embedding server wrapper** in `let` block:
```nix
embeddingServerWrapper = pkgs.writeShellScript "embedding-server-wrapper" ''
  set -euo pipefail
  export PATH="${embeddingServerVenv}/bin:$PATH"
  cd "${embeddingServerDir}"
  exec ${embeddingServerVenv}/bin/python server.py
'';
```

3. **Setup in activation script** (add after MLX server setup):
```bash
echo "Setting up embedding server..."
mkdir -p "${embeddingServerDir}"
if [ ! -d "${embeddingServerVenv}" ]; then
  ${pkgs.python311}/bin/python3.11 -m venv "${embeddingServerVenv}"
fi
${pkgs.uv}/bin/uv pip install --python "${embeddingServerVenv}/bin/python" \
  sentence-transformers fastapi "uvicorn[standard]" 2>/dev/null || true
echo "Pre-downloading embedding model ${embeddingModel}..."
${embeddingServerVenv}/bin/python -c \
  "from sentence_transformers import SentenceTransformer; SentenceTransformer('${embeddingModel}')" \
  2>/dev/null || true

echo "Setting up knowledge MCP server..."
mkdir -p "${knowledgeDir}"
if [ ! -d "${knowledgeVenv}" ]; then
  ${pkgs.python311}/bin/python3.11 -m venv "${knowledgeVenv}"
fi
${pkgs.uv}/bin/uv pip install --python "${knowledgeVenv}/bin/python" \
  "psycopg[binary]" httpx pymupdf "mcp>=1.2.0,<2" 2>/dev/null || true

# Create knowledge database
${pkgs.postgresql}/bin/createdb -h localhost -p ${pgPort} knowledge 2>/dev/null || true
${pkgs.postgresql}/bin/psql -h localhost -p ${pgPort} -d knowledge \
  -c "CREATE EXTENSION IF NOT EXISTS vector" 2>/dev/null || true
```

4. **Embedding server file** (managed by Nix):
```nix
home.file."${embeddingServerDir}/server.py" = {
  text = ''
    ... (embedding server.py content from Task 2)
  '';
  force = true;
};
```

5. **Launchd agent** for embedding server:
```nix
embedding-server = {
  enable = true;
  config = {
    Label = "com.embedding-server.agent";
    ProgramArguments = [ "${embeddingServerWrapper}" ];
    WorkingDirectory = embeddingServerDir;
    KeepAlive = true;
    RunAtLoad = true;
    EnvironmentVariables = {
      EMBEDDING_MODEL = embeddingModel;
      PORT = embeddingPort;
    };
    StandardOutPath = "${homeDir}/Library/Logs/embedding-server.log";
    StandardErrorPath = "${homeDir}/Library/Logs/embedding-server.error.log";
  };
};
```

6. **Hermes config update** — add MCP server and memory provider:
```nix
home.file.".hermes/config.yaml".text = ''
  model:
    default: ${mlxModel}
    provider: custom
    base_url: http://localhost:${mlxPort}/v1
  ui:
    show_reasoning: false
  mcp_servers:
    knowledge:
      command: "${knowledgeVenv}/bin/python"
      args: ["-m", "server"]
      env:
        DATABASE_URL: "postgres://localhost:${pgPort}/knowledge"
        EMBEDDING_URL: "http://localhost:${embeddingPort}/v1"
  memory:
    provider: knowledge
'';
```

7. **Shell aliases**:
```nix
embedding-logs =
  if isDarwin
  then "tail -f ~/Library/Logs/embedding-server.log"
  else "echo 'Embedding server not configured'";
embedding-restart =
  if isDarwin
  then ''launchctl kickstart -k gui/"$(id -u)"/com.embedding-server.agent''
  else "echo 'Embedding server not configured'";
knowledge-logs = "tail -f ~/Library/Logs/knowledge-mcp.log";
```

**Step 2: Deploy**

Run: `sudo darwin-rebuild switch --flake ~/.setup#joel`

**Step 3: Verify all services**

```bash
# Embedding server
curl http://localhost:8801/health

# Knowledge database
psql -h localhost -p 5433 -d knowledge -c "SELECT extname FROM pg_extension WHERE extname = 'vector'"

# Hermes MCP integration (start hermes, ask it to search)
hermes chat
# In Hermes: "search my knowledge base for transformers"
```

**Step 4: Commit**

```bash
git add modules/home/ai-agents.nix
git commit -m "feat(knowledge-db): wire embedding server, knowledge MCP, and memory provider into Nix"
```

---

### Task 12: End-to-End Test

**Step 1: Ingest a test paper via Hermes**

Start Hermes and say: "find and save the paper 'Attention Is All You Need'"

Expected: Hermes calls `knowledge_ingest_arxiv`, downloads PDF, chunks it, embeds it, stores in pgvector.

**Step 2: Search for it**

In Hermes: "search my knowledge base for multi-head attention"

Expected: Returns relevant chunks from the paper.

**Step 3: Test auto-recall**

Start a new Hermes session. Say: "I'm thinking about implementing a transformer from scratch"

Expected: Hermes's response includes auto-recalled context from the ingested paper (via the memory provider's prefetch).

**Step 4: Ingest a repo**

In Hermes: "save this repo to my knowledge base: https://github.com/karpathy/nanoGPT"

Expected: Clones, indexes key files, stores chunks.

**Step 5: Cross-source search**

In Hermes: "what do I know about GPT training?"

Expected: Returns results from both the paper and the repo.
