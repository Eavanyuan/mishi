import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: number;
  username: string;
  email: string;
  avatar?: string;
}

interface AuthState {
  user: User | null;
  accessToken: string | null;
  refreshToken: string | null;
  deviceId: string | null;
  isAuthenticated: boolean;
  login: (user: User, accessToken: string, refreshToken: string | null, deviceId: string) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      user: null,
      accessToken: null,
      refreshToken: null,
      deviceId: null,
      isAuthenticated: false,
      login: (user, accessToken, refreshToken, deviceId) => {
        localStorage.setItem('access_token', accessToken);
        if (refreshToken) {
          localStorage.setItem('refresh_token', refreshToken);
        }
        localStorage.setItem('device_id', deviceId);
        localStorage.setItem('user_id', String(user.id));
        set({ user, accessToken, refreshToken, deviceId, isAuthenticated: true });
      },
      logout: () => {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        localStorage.removeItem('device_id');
        localStorage.removeItem('user_id');
        set({ user: null, accessToken: null, refreshToken: null, deviceId: null, isAuthenticated: false });
      },
      updateUser: (updatedUser) =>
        set((state) => ({
          user: state.user ? { ...state.user, ...updatedUser } : null,
        })),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        user: state.user,
        accessToken: state.accessToken,
        refreshToken: state.refreshToken,
        deviceId: state.deviceId,
        isAuthenticated: state.isAuthenticated,
      }),
      onRehydrateStorage: () => (state) => {
        if (!state?.accessToken) {
          return;
        }
        localStorage.setItem('access_token', state.accessToken);
        if (state.refreshToken) {
          localStorage.setItem('refresh_token', state.refreshToken);
        }
        if (state.deviceId) {
          localStorage.setItem('device_id', state.deviceId);
        }
        if (state.user?.id) {
          localStorage.setItem('user_id', String(state.user.id));
        }
      },
    }
  )
);
