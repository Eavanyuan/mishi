package service

import (
	"context"
	"fmt"
	"net/smtp"
	"strings"
	"time"

	"github.com/mishi-app/backend/internal/config"
)

type MailSender interface {
	SendPasswordReset(ctx context.Context, toEmail, resetToken string, expiresAt time.Time) error
}

type SMTPMailer struct {
	addr        string
	host        string
	username    string
	password    string
	fromAddress string
	fromName    string
	resetURL    string
}

func NewSMTPMailer(cfg config.EmailConfig) (*SMTPMailer, error) {
	if cfg.Host == "" || cfg.Port <= 0 || cfg.Username == "" || cfg.Password == "" || cfg.FromAddress == "" || strings.TrimSpace(cfg.ResetURL) == "" {
		return nil, fmt.Errorf("smtp config incomplete")
	}

	return &SMTPMailer{
		addr:        fmt.Sprintf("%s:%d", cfg.Host, cfg.Port),
		host:        cfg.Host,
		username:    cfg.Username,
		password:    cfg.Password,
		fromAddress: cfg.FromAddress,
		fromName:    cfg.FromName,
		resetURL:    strings.TrimSpace(cfg.ResetURL),
	}, nil
}

func (m *SMTPMailer) SendPasswordReset(ctx context.Context, toEmail, resetToken string, expiresAt time.Time) error {
	_ = ctx

	resetLink := m.resetURL
	if resetLink == "" {
		return fmt.Errorf("password reset url not configured")
	}
	resetLink = fmt.Sprintf("%s?token=%s", strings.TrimRight(resetLink, "/"), resetToken)

	subject := "Mishi 密码重置"
	body := fmt.Sprintf(
		"您好，\n\n我们收到了重置密码请求。\n\n重置链接：%s\n重置令牌：%s\n\n该链接和令牌将在 %s 失效。\n如果这不是您的操作，请忽略此邮件。\n",
		resetLink,
		resetToken,
		expiresAt.Local().Format(time.RFC3339),
	)

	msg := strings.Builder{}
	msg.WriteString(fmt.Sprintf("From: %s <%s>\r\n", m.fromName, m.fromAddress))
	msg.WriteString(fmt.Sprintf("To: %s\r\n", toEmail))
	msg.WriteString(fmt.Sprintf("Subject: %s\r\n", subject))
	msg.WriteString("MIME-Version: 1.0\r\n")
	msg.WriteString("Content-Type: text/plain; charset=\"UTF-8\"\r\n")
	msg.WriteString("\r\n")
	msg.WriteString(body)

	auth := smtp.PlainAuth("", m.username, m.password, m.host)
	return smtp.SendMail(m.addr, auth, m.fromAddress, []string{toEmail}, []byte(msg.String()))
}
