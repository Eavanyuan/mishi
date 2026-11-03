import { apiClient } from './client';

export interface PoemContent {
  poem_id: number;
  title: string;
  author: string;
  dynasty: string;
  content: string[];
  preview_line: string;
  distance: number;
  season_tag: string;
  solar_term: string;
  score: number;
  score_breakdown: {
    distance: number;
    popularity: number;
    season: number;
    time_period: number;
  };
  related_poi: {
    poi_id: number;
    name: string;
    distance: number;
  };
}

export interface RecommendResponse {
  poems: PoemContent[];
  current_season: string;
  current_solar_term: string;
  current_hour: number;
}

export interface SearchPoemsResponse {
  poems: Array<Pick<PoemContent, 'poem_id' | 'title' | 'author' | 'dynasty' | 'content' | 'preview_line'>>;
  total: number;
  limit: number;
  offset: number;
  has_more: boolean;
  keyword: string;
  returned: number;
}

export interface PoemDetail {
  poem_id: number;
  title: string;
  author: string;
  dynasty: string;
  content: string[];
  preview_line: string;
  tags: string[];
  best_seasons: string[];
  solar_terms: string[];
  time_period_tags: string[];
  interpretations: {
    textbook: {
      source: string;
      content: string;
    };
    academic: {
      source: string;
      content: string;
    };
    basic: {
      source: string;
      content: string;
    };
  };
  related_pois: Array<{
    poi_id: number;
    name: string;
    relevance_score: number;
  }>;
  media: {
    has_audio: boolean;
    audio_duration: number;
    has_video: boolean;
  };
  stats: {
    view_count: number;
    like_count: number;
    checkin_count: number;
  };
}

export const getRecommendedPoems = async (
  lat: number,
  lon: number,
  limit?: number,
  season?: string
): Promise<RecommendResponse> => {
  const params: Record<string, number | string> = { lat, lon };
  if (limit !== undefined) params.limit = limit;
  if (season !== undefined) params.season = season;

  return apiClient.get('/poems/recommend', { params });
};

export const searchPoems = async (
  keyword: string,
  limit = 10,
  offset = 0
): Promise<SearchPoemsResponse> => {
  return apiClient.get('/poems/search', {
    params: {
      q: keyword,
      limit,
      offset,
    },
  });
};

export const getPoemDetail = async (poemId: number): Promise<PoemDetail> => {
  return apiClient.get(`/poems/${poemId}`);
};

export default {
  getRecommendedPoems,
  searchPoems,
  getPoemDetail,
};
