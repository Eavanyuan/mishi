package service

import (
	"fmt"
	"strings"
)

type VideoPromptOptions struct {
	Seconds          int
	FPS              int
	VisualStyle      string
	SubtitleOnlyMode bool
}

func BuildPoetryVideoPrompt(title, author, dynasty string, content []string, opts VideoPromptOptions) string {
	seconds := opts.Seconds
	if seconds <= 0 {
		seconds = 10
	}
	fps := opts.FPS
	if fps <= 0 {
		fps = 24
	}
	style := strings.TrimSpace(opts.VisualStyle)
	if style == "" {
		style = "唯美动画"
	}

	lines := normalizePoemLines(content)
	if len(lines) == 0 {
		lines = []string{title}
	}

	shots := buildShotPlan(lines, seconds)

	subtitleMode := "仅字幕，无旁白，诗词逐句展开"
	if !opts.SubtitleOnlyMode {
		subtitleMode = "可选旁白，字幕逐句展开"
	}

	builder := &strings.Builder{}
	fmt.Fprintf(builder, "【项目】%s（%s·%s）\n", title, author, dynasty)
	fmt.Fprintf(builder, "【任务】生成 %ds 古诗词场景短视频，镜头连贯，情绪递进。\n", seconds)
	fmt.Fprintf(builder, "【参数】%dfps，统一风格，禁止现代元素。\n", fps)
	fmt.Fprintf(builder, "【风格】%s；东方诗意；柔和光影；慢镜头；电影构图。\n", style)
	fmt.Fprintf(builder, "【字幕】%s。\n\n", subtitleMode)

	builder.WriteString("【分镜与字幕时间轴】\n")
	for _, shot := range shots {
		fmt.Fprintf(
			builder,
			"- 镜头%d（%0.1fs-%0.1fs，帧%d-%d）：%s\n  字幕：%s\n  节奏：字幕与该镜头同步出现，禁止提前或延后。\n",
			shot.Index,
			shot.Start,
			shot.End,
			shot.StartFrame,
			shot.EndFrame,
			shot.Visual,
			shot.Subtitle,
		)
	}

	builder.WriteString("\n【负面约束】\n")
	builder.WriteString("- 不要现代建筑、现代服饰、现代标识、赛博特效。\n")
	builder.WriteString("- 不要快切和抖动运镜，避免字幕错字与遮挡主体。\n")
	builder.WriteString("- 不要出现与镜头无关的旁白文本，字幕必须与分镜内容一一对应。\n")

	return builder.String()
}

type shotPlan struct {
	Index      int
	Start      float64
	End        float64
	StartFrame int
	EndFrame   int
	Visual     string
	Subtitle   string
}

func normalizePoemLines(content []string) []string {
	out := make([]string, 0, len(content))
	for _, line := range content {
		txt := strings.TrimSpace(line)
		if txt == "" {
			continue
		}
		out = append(out, txt)
	}
	return out
}

func buildShotPlan(lines []string, seconds int) []shotPlan {
	n := len(lines)
	if n > 4 {
		n = 4
	}
	if n <= 0 {
		n = 1
	}

	shotDur := float64(seconds) / float64(n)
	totalFrames := seconds * 24
	plans := make([]shotPlan, 0, n)
	for i := 0; i < n; i++ {
		start := float64(i) * shotDur
		end := float64(i+1) * shotDur
		if i == n-1 {
			end = float64(seconds)
		}
		startFrame := int(float64(i) * float64(totalFrames) / float64(n))
		endFrame := int(float64(i+1)*float64(totalFrames)/float64(n)) - 1
		if i == n-1 {
			endFrame = totalFrames - 1
		}
		if endFrame < startFrame {
			endFrame = startFrame
		}

		line := lines[i]
		visual := fmt.Sprintf("围绕诗句“%s”构建可视化场景，镜头缓慢推进并保持意象连续。", line)
		plans = append(plans, shotPlan{
			Index:      i + 1,
			Start:      start,
			End:        end,
			StartFrame: startFrame,
			EndFrame:   endFrame,
			Visual:     visual,
			Subtitle:   line,
		})
	}
	return plans
}
