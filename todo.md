# arcline-email — Todo

The Rails app manages domains, mailboxes and aliases. Postfix, Dovecot and
OpenDKIM do the mail handling and read this app's database.

## Done
- [x] Rails admin app (replaces the from-scratch Go server plan)
- [x] Domain management, with enable/disable
- [x] Mailbox management: bcrypt passwords, quotas, enable/disable
- [x] Alias support (forward `info@` → real mailboxes)
- [x] Catch-all address support
- [x] Reject mail for unknown domains (Postfix domain lookup)
- [x] DKIM key generation per domain, and export for OpenDKIM
- [x] DNS record helper (MX, SPF, DKIM, DMARC) and a live DNS check
- [x] JSON output for scripts
- [x] Lookup configs for Postfix and Dovecot, tested against the schema

## Next
- [ ] Try the Postfix and Dovecot configs on a real mail host and write up the full install
- [ ] Let users change their own mailbox password (sign in through Nexus)
- [ ] Show each mailbox's quota usage (from Dovecot)
- [ ] Encrypt DKIM private keys at rest
- [ ] Per-domain limits on mailboxes and aliases

## Mail server (outside this app)
- [ ] TLS certificates for the mail host (Let's Encrypt)
- [ ] rspamd for spam filtering, SPF and DMARC checks on inbound mail
- [ ] Rate limiting and DNSBL checks in Postfix
- [ ] Deliverability testing and blacklist monitoring
- [ ] Metrics from Postfix and Dovecot into arcline-uptime

## Dropped
- A from-scratch SMTP and IMAP server. The Go skeleton for it is in the
  repository history.
