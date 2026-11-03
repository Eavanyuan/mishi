-- 扬州高热诗词专题种子数据（2026-03-25）
-- 目标：补充 5 首与扬州强相关且传播度高的经典作品，并完成标签、解读与 POI 关联。
-- 执行方式：
--   psql "$DATABASE_URL" -f sql/seeds/2026-03-25-yangzhou-hot-poems.sql
--
-- 互联网来源（人工筛选）：
-- 1) 黄鹤楼送孟浩然之广陵（李白）https://www.gushiwen.cn/shiwenv.aspx?id=d3f231047aef
-- 2) 寄扬州韩绰判官（杜牧）https://www.gushiwen.cn/shiwenv.aspx?id=24dacc9084c8
-- 3) 赠别二首·其一（杜牧）https://www.gushiwen.cn/shiwenv_a1cf171da994.aspx
-- 4) 遣怀（杜牧）https://www.gushiwen.cn/mingju/juv.aspx?id=3524ac281b2e
-- 5) 扬州慢·淮左名都（姜夔）https://www.gushiwen.cn/shiwenv.aspx?id=a8062138a414
-- 说明：与春季专题重复的诗词条目已统一为同一份 canonical 文案，两个 seed 可任意顺序执行。

BEGIN;

-- 1) 诗词主表：幂等入库（按 title+author+dynasty 唯一键 upsert）
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
    '寄扬州韩绰判官',
    '杜牧',
    '唐',
    '[{"text":"青山隐隐水迢迢"},{"text":"秋尽江南草未凋"},{"text":"二十四桥明月夜"},{"text":"玉人何处教吹箫"}]',
    '青山隐隐水迢迢 秋尽江南草未凋 二十四桥明月夜 玉人何处教吹箫',
    '["扬州","二十四桥","怀友","月夜","唐诗"]',
    '["秋"]',
    '["霜降"]',
    '["夜晚"]',
    '杜牧离开扬州后写给旧友韩绰。诗以江南秋景起笔，结于“二十四桥明月夜”的名句，将怀人情绪与扬州夜色风物融合。',
    '常见解读认为本诗兼具调侃与怀旧：表层写景轻快，深层含离别后的人事追忆，折射中晚唐士人在幕府流动中的情感结构。',
    '古诗文网·寄扬州韩绰判官',
    '该诗推动了“二十四桥”作为扬州文化地标的文学再生产，后世城市记忆与旅游意象多沿此诗句展开。',
    '古诗文网+城市文学研究概述',
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
    '["夜晚","白天"]',
    '杜牧离扬州赴任前所作，借“二月初”“春风十里”强化时令与城市风貌，写赠别对象之美与离情。',
    '常见教材解读强调“以城衬人”的写法：先写人物，再写扬州繁华，最终形成强对比与集中抒情。',
    '古诗文网·名句与作品页',
    '“春风十里扬州路”已成为扬州城市传播中最常见的古典语汇之一，具有持续文化影响力。',
    '古诗文网+城市文化传播观察',
    'published'
),
(
    '遣怀',
    '杜牧',
    '唐',
    '[{"text":"落魄江湖载酒行"},{"text":"楚腰纤细掌中轻"},{"text":"十年一觉扬州梦"},{"text":"赢得青楼薄幸名"}]',
    '落魄江湖载酒行 楚腰纤细掌中轻 十年一觉扬州梦 赢得青楼薄幸名',
    '["扬州","自省","人生感慨","幕府经历","唐诗三百首"]',
    '["秋"]',
    '["寒露"]',
    '["夜晚"]',
    '杜牧回望在扬州任幕府期间的放浪岁月，以“十年一觉扬州梦”概括繁华如梦、醒后自嘲的复杂心态。',
    '常见解读强调本诗并非单纯艳情，而是夹带仕途受挫后的自我反思：前半写旧游，后半急转为“梦醒”后的价值判断。',
    '古诗文网·遣怀名句页',
    '“扬州梦”已成为中国古典诗学中的文化母题，常用于讨论城市繁华、士人流寓与自我叙事的张力关系。',
    '古诗文网+诗学主题整理',
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

-- 2) 扬州 POI：用于地理推荐/打卡
INSERT INTO pois (
    name, ancient_name, modern_name, location, radius, city_code, category, description, status
) VALUES
(
    '瘦西湖',
    '保障湖',
    '瘦西湖风景区',
    ST_SetSRID(ST_MakePoint(119.4210, 32.4123), 4326),
    2500,
    '321000',
    '自然景点',
    '扬州代表性水景园林，清代以来为文人游赏重地。',
    1
),
(
    '二十四桥',
    '廿四桥',
    '二十四桥景区',
    ST_SetSRID(ST_MakePoint(119.4255, 32.4142), 4326),
    800,
    '321000',
    '桥梁古迹',
    '与杜牧“二十四桥明月夜”相关的扬州文化地标。',
    1
),
(
    '大明寺',
    '栖灵寺',
    '扬州大明寺',
    ST_SetSRID(ST_MakePoint(119.4242, 32.4190), 4326),
    1200,
    '321000',
    '寺观古建',
    '扬州历史名刹，唐宋以来与城市文脉关系密切。',
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

-- 3) 诗词-POI 关联：用于 nearby/recommend
WITH mapping AS (
    SELECT '黄鹤楼送孟浩然之广陵'::text AS poem_title, '瘦西湖'::text AS poi_name, 600::int AS distance, 0.86::float AS score
    UNION ALL SELECT '寄扬州韩绰判官', '二十四桥', 80, 0.98
    UNION ALL SELECT '赠别二首·其一', '二十四桥', 120, 0.93
    UNION ALL SELECT '遣怀', '二十四桥', 200, 0.88
    UNION ALL SELECT '扬州慢·淮左名都', '二十四桥', 100, 0.95
    UNION ALL SELECT '扬州慢·淮左名都', '瘦西湖', 500, 0.82
    UNION ALL SELECT '扬州慢·淮左名都', '大明寺', 900, 0.78
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
