# Knowledge DB Design — pgvector + MCP + Hermes Memory Provider

**Date**: 2026-04-06
**Status**: Approved

## Goal

Personal research knowledge base for arXiv papers and code repos. Supports semantic search, contextual auto-recall during Hermes conversations, synthesis across sources, and "find and save" ingestion via chat.

## Architecture

```
                          ┌──────────────────────────┐
                          │      Hermes Agent         │
                          │                           │
                          │  MCP client ──────────┐   │
                          │  Memory provider ───┐ │   │
                          └─────────────────────┼─┼───┘
                                                │ │
                            recall/retain/reflect│ │ tools (search, ingest, list, tag)
                                                │ │
                          ┌─────────────────────┼─┼───┐
                          │   knowledge-mcp     │ │   │
                          │   (stdio process)   ◄─┘   │
                          │                     │     │
                          │   memory provider   ◄─┘   │
                          └────────┬──────┬───────────┘
                                   │      │
                        embed      │      │  SQL + vector
                        queries    │      │  queries
                                   │      │
                    ┌──────────────┐│  ┌───┴────────────┐
                    │ MLX Embedding ││  │  PostgreSQL     │
                    │ Server :8801  ││  │  + pgvector     │
                    │ snowflake-    ││  │  :5433          │
                    │ arctic-embed  ││  │  DB: knowledge  │
                    └──────────────┘│  └────────────────┘
                                    │
                          ┌─────────┴─────────┐
                          │  Ingestion Layer   │
                          │  - arXiv API + PDF │
                          │  - GitHub clone    │
                          │  - chunker         │
                          └───────────────────┘
```

## Data Model

### papers
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| arxiv_id | TEXT UNIQUE | e.g. "2401.12345" |
| title | TEXT NOT NULL | |
| authors | TEXT[] | |
| abstract | TEXT | |
| published_at | TIMESTAMPTZ | |
| pdf_url | TEXT | |
| source | TEXT | 'arxiv', 'manual' |
| tags | TEXT[] | user or auto-generated |
| ingested_at | TIMESTAMPTZ | DEFAULT now() |

### repos
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| url | TEXT UNIQUE | GitHub URL |
| name | TEXT NOT NULL | |
| description | TEXT | |
| language | TEXT | |
| tags | TEXT[] | |
| ingested_at | TIMESTAMPTZ | DEFAULT now() |

### chunks
| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| source_type | TEXT NOT NULL | 'paper', 'repo' |
| source_id | UUID NOT NULL | FK to papers or repos |
| content | TEXT NOT NULL | ~512 token text chunk |
| chunk_index | INT | ordering within source |
| section | TEXT | 'abstract', 'methods', 'README', etc. |
| embedding | vector(768) | snowflake-arctic-embed-m-v2.0 |
| metadata | JSONB | flexible extra fields |

### Indexes
- `HNSW` on `chunks.embedding` using `vector_cosine_ops`
- B-tree on `papers.arxiv_id`, `repos.url`
- GIN on `papers.tags`, `repos.tags`

## MCP Server Tools

| Tool | Input | Behavior |
|---|---|---|
| `knowledge_search` | query (text), filters (tags, source, date_range), top_k | Embed query → pgvector cosine search with optional WHERE clauses → return chunks + source metadata |
| `knowledge_ingest_arxiv` | arxiv_id OR search_query, max_results | arXiv API → download PDF → pymupdf extract → chunk → embed → INSERT |
| `knowledge_ingest_repo` | github_url | Shallow clone → extract README + key source files → chunk → embed → INSERT |
| `knowledge_ingest_text` | content, title, tags | Direct text → chunk → embed → INSERT |
| `knowledge_list` | filters (source_type, tags, date_range) | SELECT from papers/repos with filters |
| `knowledge_tag` | source_type, source_id, add_tags, remove_tags | UPDATE tags array |

## Memory Provider

Plugin at `~/.local/share/hermes/plugins/memory/knowledge/`.

Implements `MemoryProvider` interface:
- **recall(query)** — Embed query → pgvector top-5 above threshold (0.7) → return chunk content with source citation
- **retain(content)** — Chunk + embed → INSERT with source_type='note'
- **reflect(topic)** — Broader search (top-20, lower threshold) → group by source → synthesize summary

Threshold configurable via `config.yaml`. Start at 0.7.

## Ingestion Pipeline

### arXiv
1. Query arXiv API (search or ID lookup)
2. Download PDF to temp dir
3. Extract text via pymupdf with section detection
4. Chunk by section boundaries, ~512 token windows with 64 token overlap
5. Embed all chunks via MLX embedding server (`POST /v1/embeddings`)
6. INSERT paper metadata + chunks in single transaction

### GitHub
1. Shallow clone repo
2. Extract: README, docstrings (via tree-sitter if available), key source files
3. Chunk by file/function boundaries
4. Embed + INSERT
5. Cleanup clone

## Infrastructure (Nix)

All managed in `ai-agents.nix`:

### New in activation script
- `CREATE EXTENSION IF NOT EXISTS vector` on knowledge database
- `createdb knowledge` on port 5433
- Create knowledge-mcp venv + install deps
- Download snowflake-arctic-embed model

### New launchd agent
- `embedding-server` on port 8801 running `mlx_lm server --model mlx-community/snowflake-arctic-embed-m-v2.0 --port 8801`

### Hermes config additions
```yaml
mcp_servers:
  knowledge:
    command: "~/.local/share/knowledge-mcp/venv/bin/python"
    args: ["-m", "server"]
    env:
      DATABASE_URL: "postgres://localhost:5433/knowledge"
      EMBEDDING_URL: "http://localhost:8801/v1"

memory:
  provider: knowledge
```

### New shell aliases
- `knowledge` — CLI for manual ingestion
- `knowledge-logs` — tail MCP server logs
- `embedding-logs` — tail embedding server logs
- `embedding-restart` — restart embedding launchd agent

## File Layout

```
~/.local/share/knowledge-mcp/
├── server.py              # MCP server entry point
├── ingestion/
│   ├── arxiv.py           # arXiv API + PDF download
│   ├── github.py          # Repo cloning + file extraction
│   ├── chunker.py         # Text → chunks with section awareness
│   └── embedder.py        # Calls embedding server HTTP API
├── search.py              # pgvector queries + metadata filters
├── db.py                  # Postgres connection + schema migrations
├── requirements.txt       # pymupdf, psycopg[binary], mcp, httpx
└── config.yaml            # DB URL, embedding URL, thresholds

~/.local/share/hermes/plugins/memory/knowledge/
├── __init__.py
├── provider.py            # MemoryProvider subclass → calls knowledge-mcp DB
└── config.yaml
```

## Embedding Model

**snowflake-arctic-embed-m-v2.0** (768d, ~430MB)
- Strong retrieval quality for technical/scientific text
- Runs locally via MLX on port 8801
- Supports matryoshka — can truncate to 256d for faster search if needed later

## Key Decisions

- **Separate DB** (`knowledge` not `paperclip`) — clean separation
- **Stdio MCP transport** — Hermes manages lifecycle, no extra port
- **Separate embedding server** on 8801 — doesn't block Qwen inference on 8800
- **HNSW index** — no training step, good recall, handles growth
- **0.7 similarity threshold** for auto-recall — tunable via config
- **512 token chunks with 64 token overlap** — good retrieval granularity
