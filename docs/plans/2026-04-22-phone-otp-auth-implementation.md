# Phone OTP Auth Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a phone OTP login/register flow where a verified phone number logs in an existing user or creates a new user automatically.

**Architecture:** Keep the existing JWT/session response shape. Add SMS OTP handlers under `/v1/auth/sms/*`, store OTP state in Redis when available, and use an explicit development fallback code for local/test mode. Update Flutter auth service/provider and register page to use phone OTP as the simplified default path.

**Tech Stack:** Go, Gin, pgx/PostgreSQL, Redis cache wrapper, Flutter, Riverpod, Dio, flutter_test.

---

### Task 1: Backend OTP Models And Handler Tests

**Files:**
- Modify: `backend/internal/model/user.go`
- Modify: `backend/internal/handler/integration_api_test.go`

**Steps:**
1. Add request structs for `SendSMSCodeRequest` and `SMSLoginRequest`.
2. Write integration test that calls `/v1/auth/sms/send-code` in dev mode and expects `dev_mode: true` plus code `123456`.
3. Write integration test that posts `/v1/auth/sms/login` with a new phone and code, expects token and a created user.
4. Write integration test that posts the same phone again and verifies it logs into the same user.
5. Run `go test ./internal/handler -run TestIntegrationSMSAuth -v`; expected red before implementation.

### Task 2: Backend OTP Implementation

**Files:**
- Modify: `backend/internal/handler/auth.go`
- Modify: `backend/internal/server/server.go`

**Steps:**
1. Add phone normalization and validation helpers.
2. Add OTP key helpers and a dev fallback code constant.
3. Implement `SendSMSCode(db/cache)` handler with cooldown and dev fallback.
4. Implement `SMSLogin(db, jwtSvc, cache)` handler with verification, auto-create, last-login update, JWT issue.
5. Register routes under `/v1/auth/sms/send-code` and `/v1/auth/sms/login`.
6. Run targeted backend tests until green.

### Task 3: Flutter Auth Service And Provider

**Files:**
- Modify: `mishi_app/lib/services/api/auth_service.dart`
- Modify: `mishi_app/lib/providers/auth_provider.dart`

**Steps:**
1. Add `sendSMSCode(phone)` returning dev code metadata.
2. Add `loginWithSMSCode(phone, code)` returning `LoginResponse`.
3. Add provider methods `sendSMSCode` and `loginWithSMSCode`.
4. Store tokens/user exactly like current login/register.
5. Run Flutter analyze after implementation.

### Task 4: Flutter Register Page Simplification

**Files:**
- Modify: `mishi_app/lib/features/auth/pages/register_page.dart`
- Test: `mishi_app/test/widget_test.dart` or new auth widget test if practical.

**Steps:**
1. Write/adjust widget test expecting “手机号快捷登录”, “手机号”, “验证码”, and no required password fields.
2. Verify test fails before UI update.
3. Replace registration form with phone/code form.
4. Implement send-code loading state and dev-code helper text.
5. Submit calls `loginWithSMSCode`.
6. Run Flutter test/analyze.

### Task 5: Verification

**Commands:**
- `cd backend && go test ./internal/handler -run TestIntegrationSMSAuth -v`
- `cd backend && go test ./...`
- `cd mishi_app && FVM_CACHE_PATH=/Users/yuanyuan/Documents/workspace/mishi/.fvm_cache fvm flutter analyze`
- `cd mishi_app && FVM_CACHE_PATH=/Users/yuanyuan/Documents/workspace/mishi/.fvm_cache fvm flutter test`

