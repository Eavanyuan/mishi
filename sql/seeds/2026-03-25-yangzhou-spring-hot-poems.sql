-- 春季·扬州专题高热诗词种子数据（2026-03-25）
-- 说明：
-- 1) 作品按“扬州关联度 + 传播广度（名句/教材/检索可见度）”人工筛选
-- 2) 使用 ON CONFLICT 做幂等 upsert，可重复执行
-- 3) 与扬州高热专题重复的诗词条目已统一为同一份 canonical 文案，两个 seed 可任意顺序执行
--
-- 执行：
--   psql "$DATABASE_URL" -f sql/seeds/2026-03-25-yangzhou-spring-hot-poems.sql
--
-- 参考来源（互联网）：
-- - 黄鹤楼送孟浩然之广陵（李白）https://www.gushiwen.cn/shiwenv.aspx?id=d3f231047aef
-- - 赠别二首·其一（杜牧）https://www.gushiwen.cn/shiwenv.aspx?id=a1cf171da994
-- - 泊船瓜洲（王安石）https://www.gushiwen.cn/shiwenv_df14e6fd217b.aspx
-- - 扬州慢·淮左名都（姜夔）https://www.gushiwen.cn/shiwenv.aspx?id=a8062138a414
-- - 扬州慢·十里春风（赵以夫）https://www.gushiwen.cn/shiwenv_4b8528b27fc4.aspx

BEGIN;

INSERT INTO poems (
    title,
    author,
    dynasty,
    content,
    content_text,
    tags,
    best_seasons,
    solar_terms,
    time_period_tags,
    interpretation_basic,
    interpretation_textbook,
    interpretation_textbook_source,
    interpretation_academic,
    interpretation_academic_source,
    status
) VALUES
(
    '黄鹤楼送孟浩然之广陵',
    '李白',
    '唐',
    '[{"text":"故人西辞黄鹤楼"},{"text":"烟花三月下扬州"},{"text":"孤帆远影碧空尽"},{"text":"唯见长江天际流"}]',
    '故人西辞黄鹤楼 烟花三月下扬州 孤帆远影碧空尽 唯见长江天际流',
    '["扬州","春景","送别","友情","长江"]',
    '["春"]',
    '["清明"]',
    '["白天"]',
    '写李白在黄鹤楼送孟浩然赴广陵（扬州），以“烟花三月”点明春季繁盛景象，借江天远景寄托深厚友情。',
    '诗歌结构由“送别场景”递进到“目送远帆”，以景收情，情深而不直白，是送别诗中的高频经典。',
    '古诗文网·黄鹤楼送孟浩然之广陵',
    '该诗将“扬州”建构为盛唐文化流动与城市繁华的象征，后世相关城市意象传播广泛。',
    '古诗文网+诗歌传播研究概述',
    'published'
),
(
    '赠别二首·其一',
    '杜牧',
    '唐',
    '[{"text":"娉娉袅袅十三余"},{"text":"豆蔻梢头二月初"},{"text":"春风十里扬州路"},{"text":"卷上珠帘总不如"}]',
    '娉娉袅袅十三余 豆蔻梢头二月初 春风十里扬州路 卷上珠帘总不如',
    '["扬州","春季","豆蔻年华","赠别","都市风情"]',
    '["春"]',
    '["惊蛰"]',
    '["白天","夜晚"]',
    '杜牧离扬州赴任前所作，借“二月初”“春风十里”强化时令与城市风貌，写赠别对象之美与离情。',
    '常见教材解读强调“以城衬人”的写法：先写人物，再写扬州繁华，最终形成强对比与集中抒情。',
    '古诗文网·名句与作品页',
    '“春风十里扬州路”已成为扬州城市传播中最常见的古典语汇之一，具有持续文化影响力。',
    '古诗文网+城市文化传播观察',
    'published'
),
(
    '泊船瓜洲',
    '王安石',
    '宋',
    '[{"text":"京口瓜洲一水间"},{"text":"钟山只隔数重山"},{"text":"春风又绿江南岸"},{"text":"明月何时照我还"}]',
    '京口瓜洲一水间 钟山只隔数重山 春风又绿江南岸 明月何时照我还',
    '["扬州","瓜洲","春景","思乡","宋诗名篇"]',
    '["春"]',
    '["春分"]',
    '["夜晚"]',
    '王安石途经瓜洲（今扬州南部）时写下此诗，“春风又绿江南岸”成为最具传播度的春景名句之一。',
    '教材常以“绿”字锤炼为重点，突出炼字艺术与“景中有情”的表达方式，末句转入思归主题。',
    '古诗文网相关作品/名句页',
    '此诗将地理节点“瓜洲”与春季迁徙心理相结合，是“扬州区域意象+春景情绪”融合传播的代表文本。',
    '古诗文网+古典诗学常识',
    'published'
),
(
    '扬州慢·淮左名都',
    '姜夔',
    '宋',
    '[{"text":"淮左名都，竹西佳处，解鞍少驻初程。"},{"text":"过春风十里，尽荠麦青青。"},{"text":"自胡马窥江去后，废池乔木，犹厌言兵。"},{"text":"渐黄昏，清角吹寒，都在空城。"},{"text":"杜郎俊赏，算而今，重到须惊。"},{"text":"纵豆蔻词工，青楼梦好，难赋深情。"},{"text":"二十四桥仍在，波心荡，冷月无声。"},{"text":"念桥边红药，年年知为谁生？"}]',
    '淮左名都 竹西佳处 解鞍少驻初程 过春风十里 尽荠麦青青 自胡马窥江去后 废池乔木 犹厌言兵 渐黄昏 清角吹寒 都在空城 杜郎俊赏 算而今重到须惊 纵豆蔻词工 青楼梦好 难赋深情 二十四桥仍在 波心荡 冷月无声 念桥边红药 年年知为谁生',
    '["扬州","宋词","春风十里","今昔兴衰","黍离之悲","城市兴衰"]',
    '["春","冬"]',
    '["冬至","惊蛰"]',
    '["黄昏","夜晚"]',
    '姜夔过扬州时见战后萧条，借“春风十里”反衬昔日繁华，形成今昔强烈对照与历史悲慨。',
    '课堂解读常以“过春风十里，尽荠麦青青”“二十四桥仍在”两组意象，分析词人如何以景寄史。',
    '古诗文网·扬州慢名句页',
    '该词是扬州城市记忆叙事中的核心文本之一，在文学史与地方文化传播中长期高频出现。',
    '古诗文网+词史通行解读',
    'published'
),
(
    '扬州慢·十里春风',
    '赵以夫',
    '宋',
    '[{"text":"十里春风，二分明月，蕊仙飞下琼楼。"},{"text":"看冰花翦翦，拥碎玉成毬。"},{"text":"想长日、云阶伫立，太真肌骨，飞燕风流。"},{"text":"敛群芳、清丽精神，都付扬州。"},{"text":"雨窗数朵，梦惊回、天际香浮。"},{"text":"似阆苑花神，怜人冷落，骑鹤来游。"},{"text":"为问竹西风景，长空淡、烟水悠悠。"},{"text":"又黄昏，羌管孤城，吹起新愁。"}]',
    '十里春风 二分明月 蕊仙飞下琼楼 看冰花翦翦 拥碎玉成毬 想长日云阶伫立 太真肌骨 飞燕风流 敛群芳清丽精神 都付扬州 雨窗数朵 梦惊回天际香浮 似阆苑花神 怜人冷落 骑鹤来游 为问竹西风景 长空淡烟水悠悠 又黄昏 羌管孤城 吹起新愁',
    '["扬州","春季","词","竹西风景","城市咏怀"]',
    '["春"]',
    '["春分"]',
    '["黄昏","夜晚"]',
    '词中以“十里春风”“二分明月”等扬州传统意象起笔，兼具繁华想象与晚景新愁。',
    '常见赏析将其视作对杜牧扬州意象的再书写：先写春景绮丽，再转入羌管孤城的情绪回落。',
    '古诗文网·扬州慢·十里春风',
    '该词虽不及姜夔篇流传广，但在“扬州+春风”母题中具代表性，适合专题内容补全与时令推荐。',
    '古诗文网+母题对读整理',
    'published'
)
ON CONFLICT (title, author, dynasty) DO UPDATE
SET
    content = EXCLUDED.content,
    content_text = EXCLUDED.content_text,
    tags = EXCLUDED.tags,
    best_seasons = EXCLUDED.best_seasons,
    solar_terms = EXCLUDED.solar_terms,
    time_period_tags = EXCLUDED.time_period_tags,
    interpretation_basic = EXCLUDED.interpretation_basic,
    interpretation_textbook = EXCLUDED.interpretation_textbook,
    interpretation_textbook_source = EXCLUDED.interpretation_textbook_source,
    interpretation_academic = EXCLUDED.interpretation_academic,
    interpretation_academic_source = EXCLUDED.interpretation_academic_source,
    status = 'published',
    updated_at = CURRENT_TIMESTAMP;

-- 补充春季扬州地理点：瓜洲渡
INSERT INTO pois (
    name, ancient_name, modern_name, location, radius, city_code, category, description, status
) VALUES
(
    '瓜洲渡',
    '瓜洲',
    '扬州瓜洲古渡',
    ST_SetSRID(ST_MakePoint(119.3656, 32.2578), 4326),
    1200,
    '321000',
    '古渡口',
    '位于扬州南部，古代江运要津，与《泊船瓜洲》文化意象高度关联。',
    1
)
ON CONFLICT (name, city_code) DO UPDATE
SET
    ancient_name = EXCLUDED.ancient_name,
    modern_name = EXCLUDED.modern_name,
    location = EXCLUDED.location,
    radius = EXCLUDED.radius,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    status = 1,
    updated_at = CURRENT_TIMESTAMP;

WITH mapping AS (
    SELECT '黄鹤楼送孟浩然之广陵'::text AS poem_title, '瘦西湖'::text AS poi_name, 700::int AS distance, 0.88::float AS score
    UNION ALL SELECT '赠别二首·其一', '二十四桥', 120, 0.95
    UNION ALL SELECT '泊船瓜洲', '瓜洲渡', 50, 0.99
    UNION ALL SELECT '扬州慢·淮左名都', '二十四桥', 100, 0.96
    UNION ALL SELECT '扬州慢·淮左名都', '瘦西湖', 500, 0.83
    UNION ALL SELECT '扬州慢·十里春风', '瘦西湖', 300, 0.90
    UNION ALL SELECT '扬州慢·十里春风', '二十四桥', 250, 0.88
)
INSERT INTO poi_poems (poi_id, poem_id, distance, relevance_score, created_by)
SELECT
    p.id AS poi_id,
    m.id AS poem_id,
    mapping.distance,
    mapping.score,
    'manual'
FROM mapping
JOIN pois p ON p.name = mapping.poi_name AND p.city_code = '321000'
JOIN poems m ON m.title = mapping.poem_title
ON CONFLICT (poi_id, poem_id) DO UPDATE
SET
    distance = EXCLUDED.distance,
    relevance_score = EXCLUDED.relevance_score,
    created_by = 'manual';

COMMIT;
