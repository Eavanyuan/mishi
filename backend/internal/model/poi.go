package model

import (
	"time"
)

// POI 地点模型
type POI struct {
	ID          int64     `json:"id"`
	Name        string    `json:"name"`
	AncientName string    `json:"ancient_name,omitempty"`
	ModernName  string    `json:"modern_name,omitempty"`
	
	// 地理信息
	Latitude    float64   `json:"lat"`
	Longitude   float64   `json:"lon"`
	Radius      int       `json:"radius"`
	
	// 分类信息
	CityCode    string    `json:"city_code"`
	ProvinceCode string   `json:"province_code,omitempty"`
	Category    string    `json:"category,omitempty"`
	
	// 描述信息
	Description string    `json:"description,omitempty"`
	Address     string    `json:"address,omitempty"`
	
	// 统计信息
	VisitCount   int64     `json:"visit_count"`
	CheckinCount int64     `json:"checkin_count"`
	PoemsCount   int64     `json:"poems_count"`
	
	// 状态
	Status      int       `json:"status"`
	
	// 时间戳
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}

// POIResponse API响应格式
type POIResponse struct {
	POI *POI `json:"poi"`
}

// POIListResponse POI列表响应
type POIListResponse struct {
	POIs  []*POI `json:"pois"`
	Total int64  `json:"total"`
}

// POIWithDistance 带距离的POI
type POIWithDistance struct {
	POI      *POI   `json:"poi"`
	Distance int    `json:"distance"` // 距离（米）
}

// POINearbyResponse 附近POI响应
type POINearbyResponse struct {
	POIs  []*POIWithDistance `json:"pois"`
	Total int64              `json:"total"`
}

// GeofenceCheckResponse 地理围栏检查响应
type GeofenceCheckResponse struct {
	InGeofence bool   `json:"in_geofence"`
	Distance   int    `json:"distance"`
	MatchType  string `json:"match_type"`
	POIName    string `json:"poi_name"`
}