# arcline-email — Todo

## Phase 1: MVP (Core Mail Flow)

### Project Setup
- [ ] Initialize Go module (`go mod init arcline-email`)
- [ ] Set up directory structure (`cmd/`, `internal/`, `config/`)
- [ ] Add `.gitignore`
- [ ] Wire up config parsing (TOML)
- [ ] Structured logging (`log/slog`)
- [ ] Graceful shutdown (signal handling)

### SMTP — Inbound (Port 25)
- [ ] Basic SMTP listener using `emersion/go-smtp`
- [ ] Receive inbound mail for local domains
- [ ] TLS support (STARTTLS)
- [ ] Reject mail for unknown domains
- [ ] Write received messages to Maildir

### SMTP — Submission (Ports 587 / 465)
- [ ] Authenticated submission listener
- [ ] SASL PLAIN / LOGIN auth
- [ ] Enforce auth before relaying
- [ ] Outbound routing via MX DNS lookup
- [ ] Delivery retry queue with backoff

### IMAP (Ports 143 / 993)
- [ ] IMAP server using `emersion/go-imap`
- [ ] Authenticate users
- [ ] Serve mailboxes from Maildir storage
- [ ] Support INBOX, Sent, Drafts, Trash folders
- [ ] IDLE command support

### Storage
- [ ] Maildir layout per user (`/var/mail/{domain}/{user}/`)
- [ ] Message write (new mail delivery)
- [ ] Message read / list / delete (for IMAP)
- [ ] Quota tracking (basic)

### Authentication
- [ ] User store (flat file or SQLite — TBD)
- [ ] Password hashing (bcrypt)
- [ ] Domain and mailbox management (add/remove)

### TLS
- [ ] Load cert/key from disk
- [ ] Auto-renew via ACME / Let's Encrypt (optional)

---

## Phase 2: Mail Hygiene

- [ ] DKIM signing on outbound mail
- [ ] DKIM verification on inbound mail
- [ ] SPF record lookup and enforcement
- [ ] DMARC policy parsing and enforcement
- [ ] Reject or quarantine based on DMARC policy
- [ ] DNSBL checks on inbound connections (basic blocklist)

---

## Phase 3: Admin & Operations

- [ ] Admin HTTP API (manage domains, mailboxes, aliases)
- [ ] Alias support (forward `info@` → real mailbox)
- [ ] Catch-all address support
- [ ] Metrics endpoint (Prometheus)
- [ ] Log shipping / structured access logs
- [ ] Systemd unit file

---

## Phase 4: Hardening

- [ ] Rate limiting on SMTP connections
- [ ] Connection-level blocklist (IP deny list)
- [ ] Greylisting (optional)
- [ ] rspamd milter integration (optional)
- [ ] Deliverability testing (SPF/DKIM/DMARC pass verification)
- [ ] Blacklist monitoring

---

## Stretch / Future

- [ ] Webmail UI (separate project)
- [ ] Multi-domain virtual hosting
- [ ] Sieve filtering support
- [ ] JMAP support
