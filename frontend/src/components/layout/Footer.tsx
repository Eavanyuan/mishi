import { Link } from 'react-router-dom';

const Footer = () => {
  return (
    <footer className="mt-12 border-t border-slate-200 bg-white/90">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-4 px-4 py-6 text-sm text-slate-600 md:flex-row md:items-center md:justify-between">
        <div>
          <p className="font-medium text-slate-900">觅诗 · 让诗词回到地理现场</p>
          <p className="mt-1 text-xs">© 2026 Mishi Team</p>
        </div>
        <nav className="flex items-center gap-4">
          <Link to="/" className="hover:text-slate-900">
            首页
          </Link>
          <Link to="/checkin" className="hover:text-slate-900">
            打卡
          </Link>
          <Link to="/profile" className="hover:text-slate-900">
            我的
          </Link>
        </nav>
        <p className="text-xs">support@mishi.app</p>
      </div>
    </footer>
  );
};

export default Footer;
