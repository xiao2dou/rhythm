# Contributing

## Development

1. Fork and clone repository
2. Create a branch with prefix `codex/` or `feature/`
3. Implement changes with tests or manual verification notes
4. Open a pull request with:
   - change summary
   - verification steps
   - risk and rollback notes

## Code Style

- Keep logic modular (`TimerEngine`, `OverlayManager`, `LockMonitor`)
- Prefer explicit state transitions over implicit side effects
- Avoid changing unrelated behavior in the same PR

## Commit Convention

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `chore: ...`
