# Arcline Email

The admin side of Arcline's self-hosted mail: which domains the mail server
accepts, the mailboxes and aliases in each, and the DNS records each domain
needs.

## What changed from the original plan

This project began as a mail server written from scratch in Go (SMTP, IMAP,
Maildir storage). Only the configuration loader had been written.

The Ruby on Rails version does not speak SMTP or IMAP. A web framework is the
wrong tool for that, and Postfix and Dovecot already do it well. Instead this
app is the control plane the original roadmap called the "admin API": it owns
the database of domains, mailboxes and aliases, and **Postfix and Dovecot read
that database directly**. Ready-made lookup configs are in `deploy/`.

So the pieces are:

```
Browser ──→ arcline-email (Rails) ──→ SQLite ←── Postfix  (SMTP in and out)
                                         ↑
                                         └────── Dovecot  (IMAP, auth, delivery, quotas)
                                                 OpenDKIM (signing, keys exported from here)
```

If you would rather continue the from-scratch Go server, it is still in the
repository history.

## Features

- Domains, with an on/off switch and an optional catch-all address
- Mailboxes with bcrypt passwords and a quota each
- Aliases that forward to one or more addresses
- An address can be a mailbox or an alias, never both
- A 2048-bit DKIM key per domain, with the exact DNS records to publish
  (MX, SPF, DKIM, DMARC)
- "Check published DNS" compares those records with what is live
- JSON for every page, for scripts (send `Accept: application/json`)

## Requirements

- Ruby 4.0+
- SQLite 3 (bundled via the `sqlite3` gem)
- For actual mail: Postfix with `postfix-sqlite`, Dovecot with
  `dovecot-sqlite`, and OpenDKIM

## Setup

```bash
bin/setup --skip-server   # install gems and prepare the database
cp .env.example .env      # then fill in your values
bin/rails server          # http://localhost:3000, or PORT if set
```

## Connecting the mail server

Point `DATABASE_PATH` at a file Postfix and Dovecot can read, then copy the
configs from `deploy/`:

| File | Used by | Purpose |
|---|---|---|
| `deploy/postfix/sqlite-virtual-domains.cf` | Postfix | Which domains to accept |
| `deploy/postfix/sqlite-virtual-mailboxes.cf` | Postfix | Which mailboxes exist |
| `deploy/postfix/sqlite-virtual-aliases.cf` | Postfix | Alias forwarding |
| `deploy/postfix/sqlite-virtual-mailbox-identity.cf` | Postfix | Keeps real mailboxes ahead of the catch-all |
| `deploy/postfix/sqlite-virtual-catchall.cf` | Postfix | Per-domain catch-all |
| `deploy/postfix/main.cf.example` | Postfix | How the maps fit together |
| `deploy/dovecot/dovecot-sql.conf.ext` | Dovecot | Sign-in, mail location, quota |

The queries in those files are run against the real schema by the test suite,
so they cannot drift from the app unnoticed. They have not been run against a
live Postfix or Dovecot from here; test them on your server with `postmap -q`
and `doveadm auth test` before sending real mail through it.

Changes made in the admin take effect on the next lookup. Nothing needs to be
reloaded, except DKIM keys:

```bash
bin/rails 'email:dkim_export[/etc/opendkim]'   # keys, KeyTable, SigningTable
systemctl reload opendkim
```

Passwords are stored as bcrypt (`$2a$`), which Dovecot reads as `BLF-CRYPT`.

## DNS

Each domain's page lists the records to publish, and so does:

```bash
bin/rails 'email:dns[example.com]'
```

`EMAIL_MAIL_HOST` is the name the MX record points at. The suggested SPF
record is `v=spf1 mx -all` and the suggested DMARC policy is `p=quarantine`;
adjust them if a domain also sends mail from elsewhere.

## Environment variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | HTTP listen port |
| `DATABASE_PATH` | `storage/<env>.sqlite3` | SQLite database file, shared with Postfix and Dovecot |
| `EMAIL_MAIL_HOST` | `mail.arcline.it` | The mail server's hostname |
| `EMAIL_ADMIN_USERNAME` | — | Admin username (HTTP basic auth) |
| `EMAIL_ADMIN_PASSWORD` | — | Admin password |

In production the app refuses to load until `EMAIL_ADMIN_USERNAME` and
`EMAIL_ADMIN_PASSWORD` are set. In development it is open when they are unset.

DKIM private keys are stored in the database so they can be exported. Protect
the database file accordingly, and give Postfix and Dovecot read-only access.

## Tests

```bash
bin/rails test
bin/rubocop
bin/brakeman
```

## License

MIT. See [LICENSE](LICENSE).
