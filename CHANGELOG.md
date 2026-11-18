# Changelog

Each entry lists breaking changes first. Railway shows deployers an update when `main` changes.

## v3.19.0 (2026-11-18)

- First release of this template: Comentario v3.19.0 (`registry.gitlab.com/comentario/comentario:v3.19.0@sha256:3e11eb383e9d48b643970c5f33abc0c554607206d786256c5172823330e47602`) with Railway's Postgres.
- Wrapper: listens on Railway's `PORT`, and creates the superuser account from `ADMIN_EMAIL` and a generated `ADMIN_PASSWORD` on a loopback-only instance before the public port opens, so nobody can claim the instance first.
- README: Deploy on Railway button (template `comentario-1`).
