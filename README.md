[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/comentario-1?utm_medium=integration&utm_source=button&utm_campaign=comentario)

# Comentario on Railway

A Railway template for [Comentario](https://comentario.app) (MIT), a privacy-focused comment engine for websites and blogs, and the maintained successor of Commento. You add two lines of HTML to your pages and Comentario serves threaded comments with moderation, voting, social and SSO login, spam checks and an admin UI.

**Version:** Comentario **v3.19.0**, from the official `registry.gitlab.com/comentario/comentario` image, pinned by version and digest in the [`Dockerfile`](Dockerfile).

## What it deploys

| Service | Source | Public | Storage |
|---|---|---|---|
| Comentario | this repo (`Dockerfile`: `FROM registry.gitlab.com/comentario/comentario:v3.19.0@sha256:3e11eb38…`) | yes, health check `/api/config` | everything in Postgres (comments, users, avatars, settings) |
| Postgres | Railway's Postgres | no (private network) | volume at `/var/lib/postgresql/data` |

What the small wrapper ([`start.sh`](start.sh)) adds to the official image:

- **Listens on Railway's `PORT`** on all interfaces, so the public domain, the health check and the private network all reach it.
- **No open superuser.** Comentario makes the first account that signs up the instance superuser. On a fresh public URL anybody could take it. So before the public port opens, the wrapper starts Comentario on `127.0.0.1` only, signs up `ADMIN_EMAIL` with the generated `ADMIN_PASSWORD` (the first account, so the superuser), stops that instance and starts the real one. On later boots the account already exists and is left unchanged.
- **Start order.** Railway starts services in any order. Comentario retries the database, and the database migrations run before the public port opens.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | *(you enter it)* | Email of the superuser account created on first boot. Your login. |
| `ADMIN_PASSWORD` | `${{secret(24)}}` | Its password, generated per deployment. Read it in the Comentario service's **Variables** tab. |
| `COMENTARIO_SERVER_SIGNING_KEY` | `${{secret(64)}}` | Signs emailed links (password reset, email change), so they stay valid across restarts. |
| `BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Comentario's public address. Change it if you add a custom domain. |
| `COMENTARIO_POSTGRES_HOST`, `_PORT`, `_DATABASE`, `_USERNAME`, `_PASSWORD` | `${{Postgres.PGHOST}}` and the matching references | Private network. |
| `PORT` | `8080` | |

Optional, add them to the Comentario service when you need them (names from upstream's [secrets](https://docs.comentario.app/en/configuration/backend/secrets/) and [static configuration](https://docs.comentario.app/en/configuration/backend/static/) docs):

- **Email** (notifications, password resets, sign-up confirmation): `COMENTARIO_SMTP_HOST`, `COMENTARIO_SMTP_PORT`, `COMENTARIO_SMTP_USERNAME`, `COMENTARIO_SMTP_PASSWORD`, `COMENTARIO_SMTP_EMAIL_FROM`. Without them Comentario sends no email, and new accounts are confirmed straight away.
- **Social login:** for example `COMENTARIO_IDP_GITHUB_KEY` and `COMENTARIO_IDP_GITHUB_SECRET` (also Google, GitLab, Facebook, Apple, LinkedIn, Twitter/X and OIDC), as in upstream's [identity provider](https://docs.comentario.app/en/configuration/idps/) docs.
- **Spam checks:** `COMENTARIO_EXTENSIONS_AKISMET_KEY` and the other extension keys.

## After deploying

1. Wait until both services are green, then open the Comentario domain and log in with `ADMIN_EMAIL` and the `ADMIN_PASSWORD` from the Variables tab. Change the password under your profile if you like: the wrapper never resets it.
2. Go to **Domains → New domain**, enter the host of your website (for example `blog.example.com`) and save.
3. Copy the snippet from the domain's **Installation** tab into your pages where comments should appear. It looks like this:
   ```html
   <script defer src="https://YOUR-COMENTARIO-DOMAIN/comentario.js"></script>
   <comentario-comments></comentario-comments>
   ```
4. Under **Configuration** (superuser only), check the instance settings: who may sign up, whether new users may add domains, and so on.

To use your own domain for Comentario, add it in the service's **Settings → Networking**, then set `BASE_URL` to `https://` plus that domain and redeploy.

## Updates

Railway tells everyone who deployed this template when `main` of this repo changes, and you choose when to apply the update. Each change is listed in [CHANGELOG.md](CHANGELOG.md), breaking changes first. Comentario runs its database migrations on start. Back up the Postgres volume before a major upgrade and read the [release notes](https://gitlab.com/comentario/comentario/-/releases).

Maintainers: bump the `FROM` pin (version and digest together) and add a `CHANGELOG.md` entry.

## Licence

This wrapper is MIT-licensed. Comentario is MIT-licensed by its authors.
