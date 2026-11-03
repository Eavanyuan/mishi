import { createBrowserRouter } from 'react-router-dom';
import Home from './pages/Home';
import PoemDetail from './pages/PoemDetail';
import Checkin from './pages/Checkin';
import Profile from './pages/Profile';
import Layout from './components/layout/Layout';

export const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      {
        index: true,
        element: <Home />,
      },
      {
        path: 'poems/:id',
        element: <PoemDetail />,
      },
      {
        path: 'checkin',
        element: <Checkin />,
      },
      {
        path: 'profile',
        element: <Profile />,
      },
    ],
  },
]);