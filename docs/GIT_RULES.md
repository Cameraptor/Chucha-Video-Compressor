# Git Rules — Chucha Video Compressor

---

## Conventional Commits

Format: `type(scope): description`

| Type | Use for |
|------|---------|
| feat | New feature |
| fix | Bug fix |
| docs | Documentation only |
| refactor | Code change that neither fixes bug nor adds feature |
| chore | Build process, dependencies, tooling |
| perf | Performance improvement |

Examples:
```
feat(ui): add drop zone panel with drag-and-drop
fix(encode): correct bitrate calculation for H.265 codec
docs(readme): update v2 feature list and screenshots
chore: recompile EXE with ps2exe
```

Rules:
- Present tense: "add" not "added"
- No period at end
- Max 72 characters in subject line
- Body explains WHY (not WHAT) if needed

---

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| main | Production-ready code |
| feat/short-name | Feature work (v2 tasks) |
| fix/short-name | Bug fixes |

Solo developer — no develop branch needed. Feature branches merge to main via squash.

---

## Commit Hygiene

- Atomic commits: one logical change per commit
- Code + docs in same commit (DOCS_SYNC rule)
- No binary files >1MB in git (VideoCompressor.exe is ~237KB, OK)
- No secrets in any commit

---

**Last Updated:** 2026-04-10
