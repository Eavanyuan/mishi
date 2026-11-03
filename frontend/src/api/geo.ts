import { apiClient } from './client';

export interface POILocation {
  lat: number;
  lon: number;
}

export interface POI {
  poi_id: number;
  name: string;
  ancient_name: string;
  modern_name: string;
  location: POILocation;
  distance: number;
  category: string;
  description: string;
  poems_count: number;
}

export interface NearbyPOIsResponse {
  pois: POI[];
  total: number;
}

export interface GeofenceCheckRequest {
  user_lat: number;
  user_lon: number;
  poi_id: number;
}

export interface GeofenceCheckResponse {
  in_geofence: boolean;
  distance: number;
  match_type: string;
  poi_name: string;
}

/**
 * 查询附近POI
 * @param lat 纬度
 * @param lon 经度
 * @param radius 查询半径（米），默认5000
 * @param limit 返回数量，默认10
 */
export const getNearbyPOIs = async (
  lat: number,
  lon: number,
  radius?: number,
  limit?: number
): Promise<NearbyPOIsResponse> => {
  const params: any = { lat, lon };
  if (radius !== undefined) params.radius = radius;
  if (limit !== undefined) params.limit = limit;

  return apiClient.get('/geo/nearby', { params });
};

/**
 * 检查地理围栏（内部接口）
 * @param data 检查参数
 */
export const checkGeofence = async (
  data: GeofenceCheckRequest
): Promise<GeofenceCheckResponse> => {
  return apiClient.post('/geo/geofence/check', data);
};

export default {
  getNearbyPOIs,
  checkGeofence,
};