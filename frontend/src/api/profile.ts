import { apiClient } from './client';

export interface UserProfile {
  id: number;
  nickname: string;
  avatar_url?: string;
  user_type: string;
  checkin_count: number;
  poem_view_count: number;
  audio_play_count: number;
  status: number;
}

interface ProfileResponse {
  user: UserProfile;
}

export async function getProfile(userId: number): Promise<ProfileResponse> {
  return apiClient.get(`/profile/${userId}`);
}
