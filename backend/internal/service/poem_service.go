package service

import (
	"context"

	"github.com/mishi-app/backend/internal/database"
	"github.com/mishi-app/backend/internal/model"
)

// PoemService 诗词服务
type PoemService struct {
	db *database.DB
}

// NewPoemService 创建诗词服务
func NewPoemService(db *database.DB) *PoemService {
	return &PoemService{db: db}
}

// GetPoemByID 根据ID获取诗词
func (s *PoemService) GetPoemByID(ctx context.Context, id int64) (*model.Poem, error) {
	// TODO: 实现数据库查询
	return &model.Poem{
		ID:      id,
		Title:   "示例诗词",
		Author:  "示例作者",
		Dynasty: "唐",
		Content: []string{"示例内容"},
		Status:  "published",
	}, nil
}

// RecommendPoems 推荐诗词
func (s *PoemService) RecommendPoems(ctx context.Context, lat, lon float64, limit int) ([]*model.PoemRecommendation, error) {
	// TODO: 实现推荐算法
	return []*model.PoemRecommendation{
		{
			Poem: &model.Poem{
				ID:      1,
				Title:   "示例推荐诗词",
				Author:  "示例作者",
				Dynasty: "唐",
				Content: []string{"示例内容"},
			},
			Distance: 100,
			Score:    0.95,
		},
	}, nil
}

// IncrementViewCount 增加诗词浏览次数
func (s *PoemService) IncrementViewCount(ctx context.Context, poemID int64) error {
	// TODO: 实现浏览次数递增
	return nil
}