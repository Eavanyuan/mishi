import { useEffect, useMemo, useState } from 'react';
import { Award, BookOpenText, CalendarClock, LoaderCircle, MapPin, User } from 'lucide-react';
import { type CheckinHistoryItem, getCheckinHistory } from '../../api/checkins';
import { getErrorMessage } from '../../api/client';
import { getProfile, type UserProfile } from '../../api/profile';
import { useAuthStore } from '../../stores/useAuthStore';

const Profile = () => {
  const { user, isAuthenticated } = useAuthStore();
  const userId = Number(localStorage.getItem('user_id') || user?.id || 0);

  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [history, setHistory] = useState<CheckinHistoryItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState('');

  useEffect(() => {
    const fetchData = async () => {
      if (!isAuthenticated || !userId) {
        return;
      }

      setLoading(true);
      setErrorText('');
      try {
        const [profileResp, historyResp] = await Promise.all([
          getProfile(userId),
          getCheckinHistory(undefined, 12, 0),
        ]);
        setProfile(profileResp.user);
        setHistory(historyResp.checkins);
      } catch (error) {
        setErrorText(getErrorMessage(error, '加载个人信息失败'));
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
  }, [isAuthenticated, userId]);

  const stats = useMemo(
    () => ({
      checkins: profile?.checkin_count ?? history.length,
      poems: profile?.poem_view_count ?? 0,
      audioPlays: profile?.audio_play_count ?? 0,
      cities: new Set(history.map((item) => `${item.location.lat.toFixed(2)}-${item.location.lon.toFixed(2)}`)).size,
    }),
    [history, profile]
  );

  if (!isAuthenticated) {
    return <div className="rounded-2xl bg-amber-50 p-6 text-amber-800">请先登录，查看你的打卡与诗词旅程。</div>;
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <section className="rounded-3xl border border-slate-200 bg-white p-6 md:p-8">
        <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div className="flex items-center gap-4">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-amber-100">
              <User className="text-amber-700" size={32} />
            </div>
            <div>
              <h1 className="text-2xl font-semibold text-slate-900">{profile?.nickname ?? user?.username ?? '诗友'}</h1>
              <p className="mt-1 text-sm text-slate-600">用户ID: {userId} · 类型: {profile?.user_type ?? 'normal'}</p>
            </div>
          </div>
          {loading ? (
            <p className="text-sm text-slate-500">
              <LoaderCircle className="mr-1 inline-block animate-spin" size={14} />
              同步中...
            </p>
          ) : null}
        </div>

        <div className="mt-6 grid grid-cols-2 gap-3 md:grid-cols-4">
          <div className="rounded-xl bg-slate-100 p-4 text-center">
            <p className="text-2xl font-semibold">{stats.checkins}</p>
            <p className="mt-1 text-xs text-slate-600">累计打卡</p>
          </div>
          <div className="rounded-xl bg-slate-100 p-4 text-center">
            <p className="text-2xl font-semibold">{stats.poems}</p>
            <p className="mt-1 text-xs text-slate-600">诗词浏览</p>
          </div>
          <div className="rounded-xl bg-slate-100 p-4 text-center">
            <p className="text-2xl font-semibold">{stats.audioPlays}</p>
            <p className="mt-1 text-xs text-slate-600">诵读播放</p>
          </div>
          <div className="rounded-xl bg-slate-100 p-4 text-center">
            <p className="text-2xl font-semibold">{stats.cities}</p>
            <p className="mt-1 text-xs text-slate-600">足迹地点簇</p>
          </div>
        </div>
      </section>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <section className="space-y-4 lg:col-span-2">
          <article className="rounded-2xl border border-slate-200 bg-white p-5">
            <h2 className="flex items-center text-lg font-semibold text-slate-900">
              <CalendarClock className="mr-2" size={18} />
              打卡历史
            </h2>
            <div className="mt-4 space-y-3">
              {history.map((item) => (
                <div key={item.checkin_id} className="rounded-xl border border-slate-200 p-4">
                  <p className="font-medium text-slate-900">{item.poi_name}</p>
                  <p className="mt-1 text-sm text-slate-600">{item.poem_title}</p>
                  <p className="mt-1 text-xs text-slate-500">{new Date(item.checkin_time).toLocaleString('zh-CN')}</p>
                </div>
              ))}
              {history.length === 0 ? <p className="text-sm text-slate-500">还没有打卡记录，去首页探索第一首诗吧。</p> : null}
            </div>
          </article>
        </section>

        <aside className="space-y-4">
          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <Award className="mr-2" size={18} />
              徽章进度
            </h3>
            <p className="mt-3 text-sm text-slate-600">当前账号已完成 {Math.min(stats.checkins, 6)} 个里程碑。</p>
            <div className="mt-3 h-2 rounded-full bg-slate-200">
              <div
                className="h-2 rounded-full bg-amber-500"
                style={{ width: `${Math.min(100, Math.round((stats.checkins / 20) * 100))}%` }}
              />
            </div>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <MapPin className="mr-2" size={18} />
              足迹摘要
            </h3>
            <p className="mt-3 text-sm text-slate-600">最近打卡地点：{history[0]?.poi_name ?? '暂无'}</p>
            <p className="mt-1 text-sm text-slate-600">最近对应诗词：{history[0]?.poem_title ?? '暂无'}</p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <BookOpenText className="mr-2" size={18} />
              使用建议
            </h3>
            <ul className="mt-3 space-y-2 text-sm text-slate-600">
              <li>1. 首页开启定位，获取更精准推荐。</li>
              <li>2. 详情页可触发 AI 解读与诵读。</li>
              <li>3. 完成打卡后返回此页会自动刷新记录。</li>
            </ul>
          </div>
        </aside>
      </div>

      {errorText ? <p className="rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{errorText}</p> : null}
    </div>
  );
};

export default Profile;
