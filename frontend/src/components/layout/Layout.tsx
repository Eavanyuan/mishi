import { Outlet } from 'react-router-dom';
import Header from './Header';
import Footer from './Footer';

const Layout = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-amber-50 via-white to-slate-50 text-slate-900">
      <Header />
      <main className="mx-auto w-full max-w-6xl flex-1 px-4 py-6 md:py-10">
        <Outlet />
      </main>
      <Footer />
    </div>
  );
};

export default Layout;
