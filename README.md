# arcline-email

A self-hosted mail server written in Go. Handles inbound and outbound SMTP, IMAP access, DKIM signing, and SPF/DMARC verification — no third-party relay required.

## Status

Early development. Not production-ready.

## Goals

- Full SMTP server (inbound on port 25, submission on 587/465)
- IMAP server (143/993) for client access
- Maildir-based message storage
- Username/password authentication with SASL
- TLS on all listeners (Let's Encrypt or bring-your-own cert)
- DKIM signing for outbound mail
- SPF and DMARC verification for inbound mail
- Outbound routing via MX DNS lookup
- Admin API for managing domains, mailboxes, and aliases

## Non-Goals (for now)

- Webmail UI
- Anti-spam scoring engine (may integrate rspamd via milter later)
- Multi-server clustering

## Tech Stack

- **Language:** Go 1.22+
- **SMTP:** `emersion/go-smtp`
- **IMAP:** `emersion/go-imap`
- **Mail parsing:** `emersion/go-message`
- **SASL:** `emersion/go-sasl`
- **Storage:** Maildir (filesystem)
- **Config:** TOML

## Project Layout

```
arcline-email/
├── cmd/
│   └── arcline-email/   — main entry point
├── internal/
│   ├── smtp/            — SMTP server (inbound + submission)
│   ├── imap/            — IMAP server
│   ├── storage/         — Maildir storage layer
│   ├── auth/            — user authentication
│   ├── dkim/            — DKIM signing and verification
│   ├── spf/             — SPF checking
│   ├── dmarc/           — DMARC policy enforcement
│   └── admin/           — admin API
├── config/              — config parsing and validation
├── docs/                — protocol notes, architecture docs
├── todo.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Building

```sh
go build ./cmd/arcline-email
```

## Running

```sh
./arcline-email --config /etc/arcline-email/config.toml
```

## Configuration

See `docs/config.md` (coming soon).

## License

MIT. See [LICENSE](LICENSE).
