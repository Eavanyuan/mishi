import { useMemo, useState } from 'react';
import type { FormEvent } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { BookOpenText, CalendarCheck2, LoaderCircle, MapPin, User } from 'lucide-react';
import { login, logout } from '../../api/auth';
import { getErrorMessage } from '../../api/client';
import { useAuthStore } from '../../stores/useAuthStore';

function getOrCreateDeviceId(): string {
  const cached = localStorage.getItem('device_id');
  if (cached) {
    return cached;
  }

  const generated =
    typeof crypto !== 'undefined' && 'randomUUID' in crypto
      ? crypto.randomUUID()
      : `web-${Date.now()}-${Math.random().toString(16).slice(2)}`;
  localStorage.setItem('device_id', generated);
  return generated;
}

const Header = () => {
  const location = useLocation();
  const { user, isAuthenticated, login: onLogin, logout: onStoreLogout } = useAuthStore();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [errorText, setErrorText] = useState('');
  const loginDisabled = submitting || !email.trim() || !password.trim();

  const navItems = useMemo(
    () => [
      { to: '/', label: '首页', icon: <MapPin size={16} /> },
      { to: '/checkin', label: '打卡', icon: <CalendarCheck2 size={16} /> },
      { to: '/profile', label: '我的', icon: <User size={16} /> },
    ],
    []
  );

  const handleLogin = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setSubmitting(true);
    setErrorText('');

    try {
      const deviceId = getOrCreateDeviceId();
      const result = await login({
        email: email.trim(),
        password,
        device_id: deviceId,
      });

      onLogin(
        {
          id: result.user.id,
          username: result.user.nickname,
          email: email.trim(),
          avatar: result.user.avatar_url,
        },
        result.access_token,
        result.refresh_token ?? null,
        deviceId
      );
    } catch (error) {
      const message = getErrorMessage(error, '登录失败，请检查账号密码');
      setErrorText(message === '未授权' ? '邮箱或密码错误，请重试' : message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleLogout = async () => {
    try {
      await logout();
    } catch {
      // 忽略登出接口失败，确保本地状态可退出
    } finally {
      onStoreLogout();
    }
  };

  return (
    <header className="sticky top-0 z-30 border-b border-slate-200/80 bg-white/90 backdrop-blur">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-3 px-4 py-3 md:flex-row md:items-center md:justify-between">
        <div className="flex items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-2 text-slate-900">
            <BookOpenText className="text-amber-600" size={22} />
            <span className="text-xl font-semibold tracking-tight">觅诗</span>
          </Link>
          <span className="hidden rounded-full bg-amber-50 px-2.5 py-1 text-xs text-amber-700 md:inline">地理诗词推荐</span>
        </div>

        <nav className="flex items-center gap-2 overflow-x-auto pb-1 md:pb-0">
          {navItems.map((item) => {
            const active = location.pathname === item.to;
            return (
              <Link
                key={item.to}
                to={item.to}
                className={`inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-sm transition ${
                  active
                    ? 'bg-slate-900 text-white'
                    : 'bg-slate-50 text-slate-700 hover:bg-slate-100 hover:text-slate-900'
                }`}
              >
                {item.icon}
                {item.label}
              </Link>
            );
          })}
        </nav>

        {isAuthenticated ? (
          <div className="flex items-center gap-3">
            <span className="text-sm text-slate-600">你好，{user?.username ?? '诗友'}</span>
            <button
              type="button"
              onClick={handleLogout}
              className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100"
            >
              退出
            </button>
          </div>
        ) : (
          <form onSubmit={handleLogin} className="flex flex-wrap items-center gap-2 md:justify-end">
            <input
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="h-9 w-40 rounded-lg border border-slate-300 px-3 text-sm outline-none transition focus:border-slate-500"
              placeholder="邮箱"
              type="email"
            />
            <input
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="h-9 w-28 rounded-lg border border-slate-300 px-3 text-sm outline-none transition focus:border-slate-500"
              placeholder="密码"
              type="password"
            />
            <button
              type="submit"
              disabled={loginDisabled}
              className="inline-flex h-9 items-center justify-center rounded-lg bg-slate-900 px-3 text-sm text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:bg-slate-400"
            >
              {submitting ? <LoaderCircle className="animate-spin" size={16} /> : '登录'}
            </button>
            {errorText ? <span className="text-xs text-rose-600">{errorText}</span> : null}
          </form>
        )}
      </div>
    </header>
  );
};

export default Header;
