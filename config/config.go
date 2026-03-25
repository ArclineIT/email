package config

import (
	"fmt"

	"github.com/BurntSushi/toml"
)

type Config struct {
	Server  ServerConfig  `toml:"server"`
	SMTP    SMTPConfig    `toml:"smtp"`
	IMAP    IMAPConfig    `toml:"imap"`
	TLS     TLSConfig     `toml:"tls"`
	Storage StorageConfig `toml:"storage"`
	Logging LoggingConfig `toml:"logging"`
}

type ServerConfig struct {
	Hostname string `toml:"hostname"`
}

type SMTPConfig struct {
	InboundAddr       string `toml:"inbound_addr"`
	SubmissionAddr    string `toml:"submission_addr"`
	SubmissionTLSAddr string `toml:"submission_tls_addr"`
}

type IMAPConfig struct {
	Addr    string `toml:"addr"`
	TLSAddr string `toml:"tls_addr"`
}

type TLSConfig struct {
	CertFile string `toml:"cert_file"`
	KeyFile  string `toml:"key_file"`
}

type StorageConfig struct {
	MaildirRoot string `toml:"maildir_root"`
}

type LoggingConfig struct {
	Level  string `toml:"level"`  // debug, info, warn, error
	Format string `toml:"format"` // json, text
}

// Load reads the TOML config file at path, applying defaults for any missing fields.
func Load(path string) (*Config, error) {
	cfg := defaults()
	if _, err := toml.DecodeFile(path, cfg); err != nil {
		return nil, fmt.Errorf("decode %s: %w", path, err)
	}
	return cfg, nil
}

func defaults() *Config {
	return &Config{
		Server: ServerConfig{
			Hostname: "localhost",
		},
		SMTP: SMTPConfig{
			InboundAddr:       ":25",
			SubmissionAddr:    ":587",
			SubmissionTLSAddr: ":465",
		},
		IMAP: IMAPConfig{
			Addr:    ":143",
			TLSAddr: ":993",
		},
		Storage: StorageConfig{
			MaildirRoot: "/var/mail",
		},
		Logging: LoggingConfig{
			Level:  "info",
			Format: "json",
		},
	}
}
