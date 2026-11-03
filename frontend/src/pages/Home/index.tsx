import { useCallback, useEffect, useMemo, useState } from 'react';
import type { FormEvent } from 'react';
import { Link } from 'react-router-dom';
import { Compass, LoaderCircle, MapPin, Search } from 'lucide-react';
import { getErrorMessage } from '../../api/client';
import { getNearbyPOIs, type POI } from '../../api/geo';
import {
  getRecommendedPoems,
  searchPoems,
  type PoemContent,
  type SearchPoemsResponse,
} from '../../api/poems';
import { useGeoLocation } from '../../hooks/useGeoLocation';

const DEFAULT_COORDS = {
  lat: 30.547,
  lon: 114.312,
};

const Home = () => {
  const { location, error: locationError, loading: locationLoading } = useGeoLocation({
    timeout: 7000,
    maximumAge: 30_000,
  });

  const [poiList, setPoiList] = useState<POI[]>([]);
  const [recommendPoems, setRecommendPoems] = useState<PoemContent[]>([]);
  const [searchResults, setSearchResults] = useState<SearchPoemsResponse['poems']>([]);
  const [keyword, setKeyword] = useState('');
  const [loading, setLoading] = useState(false);
  const [searching, setSearching] = useState(false);
  const [searched, setSearched] = useState(false);
  const [errorText, setErrorText] = useState('');

  const coords = useMemo(() => {
    if (location) {
      return {
        lat: location.lat,
        lon: location.lon,
      };
    }
    return DEFAULT_COORDS;
  }, [location]);

  const loadNearbyData = useCallback(async () => {
    setLoading(true);
    setErrorText('');

    try {
      const [poiResponse, poemResponse] = await Promise.all([
        getNearbyPOIs(coords.lat, coords.lon, 5000, 8),
        getRecommendedPoems(coords.lat, coords.lon, 9),
      ]);

      setPoiList(poiResponse.pois);
      setRecommendPoems(poemResponse.poems);
    } catch (error) {
      setErrorText(getErrorMessage(error, '加载首页数据失败'));
    } finally {
      setLoading(false);
    }
  }, [coords.lat, coords.lon]);

  useEffect(() => {
    void loadNearbyData();
  }, [loadNearbyData]);

  const handleSearch = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmedKeyword = keyword.trim();
    setSearched(true);
    if (!trimmedKeyword) {
      setSearchResults([]);
      return;
    }

    setSearching(true);
    try {
      const result = await searchPoems(trimmedKeyword, 6, 0);
      setSearchResults(result.poems);
    } catch (error) {
      setErrorText(getErrorMessage(error, '搜索失败'));
    } finally {
      setSearching(false);
    }
  };

  const showSearchEmpty = searched && keyword.trim().length > 0 && !searching && searchResults.length === 0;

  return (
    <div className="space-y-8">
      <section className="rounded-3xl border border-amber-100 bg-white/80 p-6 shadow-sm md:p-9">
        <p className="text-sm font-medium text-amber-700">以地理坐标读诗</p>
        <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 md:text-5xl">在这里，重新遇见古诗词</h1>
        <p className="mt-4 max-w-3xl text-slate-600">
          系统会根据你的定位推荐附近诗词与地点。支持搜索、查看详情、发起打卡，形成完整 Web 端体验。
        </p>

        <div className="mt-5 flex flex-wrap items-center gap-2 text-sm text-slate-600">
          <span className="rounded-full bg-slate-100 px-3 py-1">
            当前坐标: {coords.lat.toFixed(4)}, {coords.lon.toFixed(4)}
          </span>
          {locationLoading ? <span className="rounded-full bg-slate-100 px-3 py-1">定位中...</span> : null}
          {locationError ? <span className="rounded-full bg-rose-50 px-3 py-1 text-rose-700">{locationError}</span> : null}
          <button
            type="button"
            onClick={() => void loadNearbyData()}
            className="rounded-full bg-slate-900 px-3 py-1 text-white transition hover:bg-slate-700"
          >
            刷新推荐
          </button>
        </div>
      </section>

      <section className="rounded-2xl border border-slate-200 bg-white/90 p-4 md:p-6">
        <form onSubmit={handleSearch} className="flex flex-col gap-3 md:flex-row md:items-center">
          <div className="relative flex-1">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
            <input
              value={keyword}
              onChange={(event) => setKeyword(event.target.value)}
              placeholder="搜索诗名、作者或诗句"
              className="h-11 w-full rounded-xl border border-slate-300 pl-9 pr-3 text-sm outline-none transition focus:border-slate-500"
            />
          </div>
          <button
            type="submit"
            disabled={searching || keyword.trim().length === 0}
            className="inline-flex h-11 items-center justify-center rounded-xl bg-slate-900 px-4 text-sm text-white transition hover:bg-slate-700 disabled:bg-slate-400"
          >
            {searching ? <LoaderCircle className="animate-spin" size={16} /> : '搜索'}
          </button>
        </form>

        {searchResults.length > 0 ? (
          <div className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-2">
            {searchResults.map((poem) => (
              <Link
                to={`/poems/${poem.poem_id}`}
                key={`search-${poem.poem_id}`}
                className="rounded-xl border border-slate-200 p-4 transition hover:border-amber-300 hover:bg-amber-50"
              >
                <p className="font-semibold text-slate-900">{poem.title}</p>
                <p className="mt-1 text-sm text-slate-600">
                  {poem.author} · {poem.dynasty}
                </p>
                <p className="mt-2 line-clamp-2 text-sm text-slate-700">{poem.preview_line || poem.content?.[0]}</p>
              </Link>
            ))}
          </div>
        ) : null}
        {showSearchEmpty ? (
          <p className="mt-4 rounded-xl border border-dashed border-slate-300 bg-slate-50 px-4 py-3 text-sm text-slate-600">
            没找到匹配的诗词，试试「黄鹤楼」「李白」这类关键词。
          </p>
        ) : null}
      </section>

      <section className="space-y-4">
        <div className="flex items-center gap-2">
          <MapPin size={18} className="text-amber-700" />
          <h2 className="text-xl font-semibold text-slate-900">附近地点</h2>
        </div>
        {loading ? (
          <div className="rounded-2xl border border-slate-200 bg-white p-6 text-slate-600">正在加载附近地点...</div>
        ) : (
          <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
            {poiList.map((poi) => (
              <div key={poi.poi_id} className="rounded-2xl border border-slate-200 bg-white p-4">
                <p className="font-semibold text-slate-900">{poi.name}</p>
                <p className="mt-1 text-sm text-slate-600">{poi.ancient_name || poi.modern_name || poi.category}</p>
                <p className="mt-2 text-xs text-slate-500">距离约 {poi.distance} 米</p>
              </div>
            ))}
            {poiList.length === 0 ? (
              <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-sm text-slate-500">暂无附近地点数据</div>
            ) : null}
          </div>
        )}
      </section>

      <section className="space-y-4">
        <div className="flex items-center gap-2">
          <Compass size={18} className="text-amber-700" />
          <h2 className="text-xl font-semibold text-slate-900">推荐诗词</h2>
        </div>

        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
          {recommendPoems.map((poem) => (
            <Link
              to={`/poems/${poem.poem_id}`}
              key={poem.poem_id}
              className="group rounded-2xl border border-slate-200 bg-white p-5 transition hover:-translate-y-0.5 hover:border-amber-300 hover:shadow-md"
            >
              <div className="flex items-start justify-between gap-2">
                <div>
                  <h3 className="text-lg font-semibold text-slate-900">{poem.title}</h3>
                  <p className="text-sm text-slate-600">
                    {poem.author} · {poem.dynasty}
                  </p>
                </div>
                <span className="rounded-full bg-amber-50 px-2.5 py-1 text-xs text-amber-700">{poem.season_tag || '当季'}</span>
              </div>

              <p className="mt-3 line-clamp-2 text-sm leading-6 text-slate-700">{poem.preview_line}</p>
              <p className="mt-4 text-xs text-slate-500">{poem.related_poi?.name || '未知地点'} · {poem.distance} 米</p>
            </Link>
          ))}
          {recommendPoems.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-slate-300 bg-white p-6 text-sm text-slate-500">暂无推荐诗词</div>
          ) : null}
        </div>
      </section>

      {errorText ? <p className="rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{errorText}</p> : null}
    </div>
  );
};

export default Home;
