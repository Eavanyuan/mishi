import { useState, useEffect } from 'react';

interface Location {
  lat: number;
  lon: number;
  accuracy: number;
  timestamp: number;
}

interface UseGeoLocationOptions {
  enableHighAccuracy?: boolean;
  timeout?: number;
  maximumAge?: number;
  watch?: boolean;
}

export const useGeoLocation = (options: UseGeoLocationOptions = {}) => {
  const {
    enableHighAccuracy = true,
    timeout = 10000,
    maximumAge = 0,
    watch = false,
  } = options;

  const [location, setLocation] = useState<Location | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  const mapGeoErrorMessage = (message: string, code?: number) => {
    const raw = message.toLowerCase();
    if (code === 1 || raw.includes('denied') || raw.includes('permission')) {
      return '定位权限被拒绝，请在浏览器中允许定位后重试';
    }
    if (code === 2 || raw.includes('unavailable')) {
      return '当前无法获取定位，请稍后重试';
    }
    if (code === 3 || raw.includes('timeout')) {
      return '定位超时，请检查网络或设备定位服务';
    }
    return '定位失败，请稍后重试';
  };

  useEffect(() => {
    if (!navigator.geolocation) {
      setError('当前浏览器不支持地理定位');
      setLoading(false);
      return;
    }

    const handleSuccess = (position: GeolocationPosition) => {
      setLocation({
        lat: position.coords.latitude,
        lon: position.coords.longitude,
        accuracy: position.coords.accuracy,
        timestamp: position.timestamp,
      });
      setError(null);
      setLoading(false);
    };

    const handleError = (err: GeolocationPositionError) => {
      setError(mapGeoErrorMessage(err.message, err.code));
      setLoading(false);
    };

    const geoOptions = {
      enableHighAccuracy,
      timeout,
      maximumAge,
    };

    setLoading(true);

    let watchId: number | undefined;

    if (watch) {
      watchId = navigator.geolocation.watchPosition(
        handleSuccess,
        handleError,
        geoOptions
      );
    } else {
      navigator.geolocation.getCurrentPosition(
        handleSuccess,
        handleError,
        geoOptions
      );
    }

    return () => {
      if (watchId !== undefined) {
        navigator.geolocation.clearWatch(watchId);
      }
    };
  }, [enableHighAccuracy, timeout, maximumAge, watch]);

  return { location, error, loading };
};
