# Rust architecture (Phase 2 deliverable)

**Status:** Blocked. Do not start until ADR-0001 is **Accepted** in `docs/DECISIONS.md`. Written by task J-100.

Planned sections:

1. Accepted option and scope (what moves to Rust, what stays)
2. Crate layout and dependency policy
3. Async runtime and concurrency model
4. Frontend/backend communication (implementing the existing contract; no renderer rewrite)
5. API compatibility requirements and how they are tested
6. Error handling and logging
7. Configuration management and migration of existing user config/data
8. Process lifecycle, shutdown and crash recovery
9. Cross-platform requirements (Linux, macOS, Windows)
10. Testing strategy (see J-101)
11. Rollback path (runtime switch back to the existing implementation)
12. Security considerations (IPC surface, credential storage, sidecar authentication)
