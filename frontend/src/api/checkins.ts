import { apiClient } from './client';

export interface DeviceInfo {
  device_id: string;
  device_model: string;
  os_version: string;
  is_emulator: boolean;
  is_rooted: boolean;
}

export interface CheckinRequest {
  poi_id: number;
  poem_id: number;
  lat: number;
  lon: number;
  gps_accuracy: number;
  device_info: DeviceInfo;
}

export interface BadgeUnlocked {
  badge_id: number;
  badge_name: string;
  badge_icon: string;
}

export interface CheckinResponse {
  checkin_id: number;
  poi_name: string;
  poem_title: string;
  checkin_time: string;
  badge_unlocked: BadgeUnlocked | null;
  card_url: string;
}

export interface CheckinHistoryItem {
  checkin_id: number;
  poi_name: string;
  poem_title: string;
  checkin_time: string;
  location: {
    lat: number;
    lon: number;
  };
  card_url: string;
}

export interface CheckinHistoryResponse {
  checkins: CheckinHistoryItem[];
  total: number;
  stats: {
    total_checkins: number;
    total_pois: number;
    total_cities: number;
  };
}

/**
 * 提交打卡
 * @param data 打卡数据
 */
export const submitCheckin = async (data: CheckinRequest): Promise<CheckinResponse> => {
  return apiClient.post('/checkins/', data);
};

/**
 * 查询打卡历史
 * @param userId 用户ID（可选，不传则查询当前用户）
 * @param limit 返回数量，默认20
 * @param offset 偏移量，默认0
 */
export const getCheckinHistory = async (
  userId?: number,
  limit?: number,
  offset?: number
): Promise<CheckinHistoryResponse> => {
  const params: any = {};
  if (userId !== undefined) params.user_id = userId;
  if (limit !== undefined) params.limit = limit;
  if (offset !== undefined) params.offset = offset;

  return apiClient.get('/checkins/history', { params });
};

export default {
  submitCheckin,
  getCheckinHistory,
};
