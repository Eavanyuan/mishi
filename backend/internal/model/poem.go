package model

import (
	"time"
)

// Poem 诗词模型
type Poem struct {
	ID         int64     `json:"id"`
	Title      string    `json:"title"`
	Author     string    `json:"author"`
	Dynasty    string    `json:"dynasty"`
	Content    []string  `json:"content"`
	ContentText string   `json:"content_text,omitempty"`
	
	// 标注信息
	Tags          []string `json:"tags,omitempty"`
	BestSeasons   []string `json:"best_seasons,omitempty"`
	SolarTerms    []string `json:"solar_terms,omitempty"`
	TimePeriodTags []string `json:"time_period_tags,omitempty"`
	
	// 解读内容
	InterpretationBasic       string `json:"interpretation_basic,omitempty"`
	InterpretationTextbook    string `json:"interpretation_textbook,omitempty"`
	InterpretationTextbookSource string `json:"interpretation_textbook_source,omitempty"`
	InterpretationAcademic    string `json:"interpretation_academic,omitempty"`
	InterpretationAcademicSource string `json:"interpretation_academic_source,omitempty"`
	
	// 媒体资源
	HasAudio     bool   `json:"has_audio"`
	AudioURL     string `json:"audio_url,omitempty"`
	AudioDuration int    `json:"audio_duration,omitempty"`
	HasVideo     bool   `json:"has_video"`
	
	// 统计信息
	ViewCount    int64 `json:"view_count"`
	LikeCount    int64 `json:"like_count"`
	CheckinCount int64 `json:"checkin_count"`
	
	// 状态
	Status      string `json:"status"`
	
	// 时间戳
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// PoemResponse API响应格式
type PoemResponse struct {
	Poem *Poem `json:"poem"`
}

// PoemListResponse 诗词列表响应
type PoemListResponse struct {
	Poems []*Poem `json:"poems"`
	Total int64   `json:"total"`
	Limit int     `json:"limit"`
	Offset int    `json:"offset"`
	HasMore bool  `json:"has_more"`
}

// PoemRecommendation 诗词推荐结果
type PoemRecommendation struct {
	Poem           *Poem   `json:"poem"`
	Distance       int     `json:"distance"`
	SeasonTag      string  `json:"season_tag,omitempty"`
	SolarTerm      string  `json:"solar_term,omitempty"`
	Score          float64 `json:"score"`
	ScoreBreakdown map[string]float64 `json:"score_breakdown,omitempty"`
}

// PoemRecommendationResponse 诗词推荐响应
type PoemRecommendationResponse struct {
	Poems          []*PoemRecommendation `json:"poems"`
	CurrentSeason  string                `json:"current_season"`
	CurrentSolarTerm string              `json:"current_solar_term,omitempty"`
	CurrentHour    int                   `json:"current_hour"`
}