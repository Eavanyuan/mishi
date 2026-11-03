import { useCallback, useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { CheckCircle2, LoaderCircle, MapPin } from 'lucide-react';
import { type CheckinHistoryItem, getCheckinHistory, submitCheckin } from '../../api/checkins';
import { getErrorMessage } from '../../api/client';
import { getNearbyPOIs, type POI } from '../../api/geo';
import { getRecommendedPoems, type PoemContent } from '../../api/poems';
import { useGeoLocation } from '../../hooks/useGeoLocation';
import { useAuthStore } from '../../stores/useAuthStore';

const FALLBACK_LAT = 30.547;
const FALLBACK_LON = 114.312;

const Checkin = () => {
  const [searchParams] = useSearchParams();
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
  const initialPoemId = Number(searchParams.get('poem_id') ?? '0');
  const initialPoiId = Number(searchParams.get('poi_id') ?? '0');

  const { location, error: locationError, loading: locating } = useGeoLocation({
    timeout: 7000,
    maximumAge: 30_000,
  });

  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errorText, setErrorText] = useState('');
  const [successText, setSuccessText] = useState('');

  const [poiList, setPoiList] = useState<POI[]>([]);
  const [poems, setPoems] = useState<PoemContent[]>([]);
  const [history, setHistory] = useState<CheckinHistoryItem[]>([]);
  const [selectedPoiId, setSelectedPoiId] = useState<number>(0);
  const [selectedPoemId, setSelectedPoemId] = useState<number>(0);

  const coords = useMemo(
    () => ({
      lat: location?.lat ?? FALLBACK_LAT,
      lon: location?.lon ?? FALLBACK_LON,
      accuracy: location?.accuracy ?? 20,
    }),
    [location]
  );

  const loadData = useCallback(async () => {
    setLoading(true);
    setErrorText('');

    try {
      const [poiResp, poemResp] = await Promise.all([
        getNearbyPOIs(coords.lat, coords.lon, 5000, 10),
        getRecommendedPoems(coords.lat, coords.lon, 10),
      ]);

      setPoiList(poiResp.pois);
      setPoems(poemResp.poems);

      if (!selectedPoiId) {
        setSelectedPoiId(initialPoiId || poiResp.pois[0]?.poi_id || 0);
      }
      if (!selectedPoemId) {
        setSelectedPoemId(initialPoemId || poemResp.poems[0]?.poem_id || 0);
      }

      const token = localStorage.getItem('access_token');
      if (token) {
        const historyResp = await getCheckinHistory(undefined, 8, 0);
        setHistory(historyResp.checkins);
      }
    } catch (error) {
      setErrorText(getErrorMessage(error, '加载打卡数据失败'));
    } finally {
      setLoading(false);
    }
  }, [coords.lat, coords.lon, initialPoiId, initialPoemId, selectedPoiId, selectedPoemId]);

  useEffect(() => {
    void loadData();
  }, [loadData]);

  const selectedPoi = poiList.find((poi) => poi.poi_id === selectedPoiId) ?? null;
  const selectedPoem = poems.find((poem) => poem.poem_id === selectedPoemId) ?? null;
  const usingPoiFallbackLocation =
    Boolean(initialPoiId && initialPoemId && selectedPoi) && (selectedPoi?.distance ?? 0) > 100;
  const submitCoords = useMemo(
    () => ({
      lat: usingPoiFallbackLocation ? selectedPoi?.location.lat ?? coords.lat : coords.lat,
      lon: usingPoiFallbackLocation ? selectedPoi?.location.lon ?? coords.lon : coords.lon,
      accuracy: usingPoiFallbackLocation ? 10 : coords.accuracy,
    }),
    [coords.accuracy, coords.lat, coords.lon, selectedPoi, usingPoiFallbackLocation]
  );
  const canSubmit = isAuthenticated && !submitting && !loading && Boolean(selectedPoi && selectedPoem);

  const handleSubmitCheckin = async () => {
    if (!selectedPoi || !selectedPoem) {
      setErrorText('请先选择地点与诗词');
      return;
    }

    if (!localStorage.getItem('access_token')) {
      setErrorText('请先在右上角登录，再执行打卡');
      return;
    }

    setSubmitting(true);
    setErrorText('');
    setSuccessText('');

    try {
      const deviceId =
        localStorage.getItem('device_id') ||
        (typeof crypto !== 'undefined' && 'randomUUID' in crypto
          ? crypto.randomUUID()
          : `web-${Date.now()}-${Math.random().toString(16).slice(2)}`);
      localStorage.setItem('device_id', deviceId);

      const result = await submitCheckin({
        poi_id: selectedPoi.poi_id,
        poem_id: selectedPoem.poem_id,
        lat: submitCoords.lat,
        lon: submitCoords.lon,
        gps_accuracy: submitCoords.accuracy,
        device_info: {
          device_id: deviceId,
          device_model: navigator.platform || 'web-browser',
          os_version: navigator.userAgent,
          is_emulator: false,
          is_rooted: false,
        },
      });

      setSuccessText(`打卡成功：${result.poi_name} · ${result.poem_title}`);

      const historyResp = await getCheckinHistory(undefined, 8, 0);
      setHistory(historyResp.checkins);
    } catch (error) {
      setErrorText(getErrorMessage(error, '打卡失败'));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <section className="rounded-3xl border border-slate-200 bg-white p-6 md:p-8">
        <h1 className="text-3xl font-semibold text-slate-900">诗词打卡</h1>
        <p className="mt-2 text-sm text-slate-600">
          坐标 {submitCoords.lat.toFixed(4)}, {submitCoords.lon.toFixed(4)}
          {locationError ? ` · 定位提示: ${locationError}` : ''}
        </p>
        {usingPoiFallbackLocation ? (
          <p className="mt-3 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-700">
            当前未拿到浏览器定位，已临时使用所选地点坐标完成 Web 演示打卡。
          </p>
        ) : null}
      </section>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <section className="space-y-6 lg:col-span-2">
          <article className="rounded-2xl border border-slate-200 bg-white p-5">
            <h2 className="text-lg font-semibold text-slate-900">1. 选择地点</h2>
            <div className="mt-3 grid grid-cols-1 gap-2 md:grid-cols-2">
              {poiList.map((poi) => (
                <button
                  key={poi.poi_id}
                  type="button"
                  onClick={() => setSelectedPoiId(poi.poi_id)}
                  className={`rounded-xl border p-3 text-left text-sm transition ${
                    selectedPoiId === poi.poi_id
                      ? 'border-amber-400 bg-amber-50'
                      : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'
                  }`}
                >
                  <p className="font-medium text-slate-900">{poi.name}</p>
                  <p className="mt-1 text-xs text-slate-600">距离 {poi.distance} 米</p>
                </button>
              ))}
            </div>
          </article>

          <article className="rounded-2xl border border-slate-200 bg-white p-5">
            <h2 className="text-lg font-semibold text-slate-900">2. 选择诗词</h2>
            <div className="mt-3 grid grid-cols-1 gap-2">
              {poems.map((poem) => (
                <button
                  key={poem.poem_id}
                  type="button"
                  onClick={() => setSelectedPoemId(poem.poem_id)}
                  className={`rounded-xl border p-3 text-left text-sm transition ${
                    selectedPoemId === poem.poem_id
                      ? 'border-amber-400 bg-amber-50'
                      : 'border-slate-200 hover:border-slate-300 hover:bg-slate-50'
                  }`}
                >
                  <p className="font-medium text-slate-900">{poem.title}</p>
                  <p className="mt-1 text-xs text-slate-600">
                    {poem.author} · {poem.dynasty}
                  </p>
                  <p className="mt-1 text-xs text-slate-500">{poem.preview_line}</p>
                </button>
              ))}
            </div>
          </article>

          <article className="rounded-2xl border border-slate-200 bg-white p-5">
            <button
              type="button"
              onClick={() => void handleSubmitCheckin()}
              disabled={!canSubmit}
              className="inline-flex h-11 items-center justify-center rounded-xl bg-slate-900 px-4 text-sm text-white transition hover:bg-slate-700 disabled:bg-slate-400"
            >
              {submitting ? <LoaderCircle className="animate-spin" size={16} /> : <CheckCircle2 size={16} />}
              <span className="ml-2">{isAuthenticated ? '立即打卡' : '登录后打卡'}</span>
            </button>

            {!isAuthenticated ? (
              <p className="mt-3 rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-700">请先在右上角登录，再执行打卡</p>
            ) : null}
            {successText ? <p className="mt-3 rounded-lg bg-emerald-50 px-3 py-2 text-sm text-emerald-700">{successText}</p> : null}
            {errorText ? <p className="mt-3 rounded-lg bg-rose-50 px-3 py-2 text-sm text-rose-700">{errorText}</p> : null}
          </article>
        </section>

        <aside className="space-y-4">
          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <MapPin className="mr-2" size={18} />
              当前选择
            </h3>
            <p className="mt-3 text-sm text-slate-700">地点：{selectedPoi?.name ?? '未选择'}</p>
            <p className="mt-1 text-sm text-slate-700">诗词：{selectedPoem?.title ?? '未选择'}</p>
            <p className="mt-1 text-xs text-slate-500">定位精度：{Math.round(submitCoords.accuracy)}m</p>
            {locating ? <p className="mt-2 text-xs text-slate-500">定位更新中...</p> : null}
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="text-lg font-semibold text-slate-900">最近打卡</h3>
            <div className="mt-3 space-y-3">
              {history.map((item) => (
                <div key={item.checkin_id} className="rounded-xl border border-slate-200 p-3">
                  <p className="text-sm font-medium text-slate-900">{item.poi_name}</p>
                  <p className="mt-1 text-xs text-slate-600">{item.poem_title}</p>
                  <p className="mt-1 text-xs text-slate-500">{new Date(item.checkin_time).toLocaleString('zh-CN')}</p>
                </div>
              ))}
              {history.length === 0 ? <p className="text-sm text-slate-500">登录后可查看个人打卡历史</p> : null}
            </div>
          </div>
        </aside>
      </div>
    </div>
  );
};

export default Checkin;
