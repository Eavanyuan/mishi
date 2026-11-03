import { useEffect, useMemo, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { Calendar, LoaderCircle, MapPin, Sparkles, Volume2 } from 'lucide-react';
import {
  createAIJob,
  extractAIJobResult,
  getAIJob,
  getLatestAIInterpretation,
  normalizeAIJobFailureKind,
  type AIJobFailureKind,
  type AIJobType,
} from '../../api/ai';
import { getApiErrorCode, getErrorMessage } from '../../api/client';
import { getPoemDetail, type PoemDetail as PoemDetailData } from '../../api/poems';

const wait = (ms: number) => new Promise<void>((resolve) => {
  setTimeout(resolve, ms);
});

type AIJobDisplayStatus = 'idle' | 'pending' | 'success' | 'failed' | 'unsupported' | 'provider_not_configured';

interface AIJobDisplayState {
  status: AIJobDisplayStatus;
  message: string;
  detail?: string;
}

const AI_JOB_LABELS: Record<AIJobType, string> = {
  interpretation: 'AI 解读',
  tts_reading: 'AI 诵读',
  story_video: '故事动画',
};

const AI_JOB_IDLE_MESSAGES: Record<AIJobType, string> = {
  interpretation: '点击“生成 AI 解读”后，会在左侧解读区同步展示。',
  tts_reading: '点击“生成 AI 诵读”后，会在下方播放音频。',
  story_video: '点击“生成故事动画”后，会在下方生成视频链接。',
};

const AI_JOB_PENDING_MESSAGES: Record<AIJobType, string> = {
  interpretation: '正在生成 AI 解读，请稍候。',
  tts_reading: '正在生成 AI 诵读，请稍候。',
  story_video: '正在生成故事动画，请稍候。',
};

const createIdleAIJobState = (jobType: AIJobType): AIJobDisplayState => ({
  status: 'idle',
  message: AI_JOB_IDLE_MESSAGES[jobType],
});

const getAIJobFailureState = (
  jobType: AIJobType,
  failureKind: AIJobFailureKind | undefined,
  errorMessage?: string
): AIJobDisplayState => {
  switch (failureKind) {
    case 'unsupported':
      return {
        status: 'unsupported',
        message: `${AI_JOB_LABELS[jobType]}当前 provider 不支持，换一个支持该能力的 provider 后再试。`,
      };
    case 'provider_not_configured':
      return {
        status: 'provider_not_configured',
        message: `${AI_JOB_LABELS[jobType]}的 provider 还没配置好，先补齐 API Key 再生成。`,
      };
    case 'empty_result':
      return {
        status: 'failed',
        message: `${AI_JOB_LABELS[jobType]}已完成，但没有返回可展示结果。`,
      };
    default:
      return {
        status: 'failed',
        message: errorMessage || `${AI_JOB_LABELS[jobType]}生成失败，请稍后重试。`,
      };
  }
};

const getAIJobStateTone = (status: AIJobDisplayStatus) => {
  switch (status) {
    case 'success':
      return 'border-emerald-200 bg-emerald-50 text-emerald-900';
    case 'pending':
      return 'border-blue-200 bg-blue-50 text-blue-900';
    case 'unsupported':
      return 'border-amber-200 bg-amber-50 text-amber-900';
    case 'provider_not_configured':
    case 'failed':
      return 'border-rose-200 bg-rose-50 text-rose-900';
    default:
      return 'border-slate-200 bg-slate-50 text-slate-700';
  }
};

const getAIJobStateLabel = (status: AIJobDisplayStatus) => {
  switch (status) {
    case 'idle':
      return '未生成';
    case 'pending':
      return '生成中';
    case 'success':
      return '已成功';
    case 'failed':
      return '已失败';
    case 'unsupported':
      return '能力不支持';
    case 'provider_not_configured':
      return '未配置';
    default:
      return status;
  }
};

const PoemDetail = () => {
  const { id } = useParams<{ id: string }>();
  const poemId = Number(id);

  const [detail, setDetail] = useState<PoemDetailData | null>(null);
  const [loading, setLoading] = useState(true);
  const [errorText, setErrorText] = useState('');
  const [aiLoadingType, setAiLoadingType] = useState<AIJobType | null>(null);
  const [aiInterpretation, setAiInterpretation] = useState('');
  const [aiAudioUrl, setAiAudioUrl] = useState('');
  const [aiAudioDuration, setAiAudioDuration] = useState('');
  const [aiVideoUrl, setAiVideoUrl] = useState('');
  const [aiVideoThumbnailUrl, setAiVideoThumbnailUrl] = useState('');
  const [aiJobStates, setAIJobStates] = useState<Record<AIJobType, AIJobDisplayState>>({
    interpretation: createIdleAIJobState('interpretation'),
    tts_reading: createIdleAIJobState('tts_reading'),
    story_video: createIdleAIJobState('story_video'),
  });

  const primaryPoi = useMemo(() => detail?.related_pois?.[0], [detail]);
  const contentLines = detail?.content ?? [];
  const tagList = detail?.tags ?? [];
  const relatedPoiList = detail?.related_pois ?? [];
  const bestSeasonList = detail?.best_seasons ?? [];
  const solarTermList = detail?.solar_terms ?? [];

  useEffect(() => {
    const fetchData = async () => {
      if (!poemId || Number.isNaN(poemId)) {
        setErrorText('诗词 ID 无效');
        setLoading(false);
        return;
      }

      setLoading(true);
      setErrorText('');
      try {
        const poemData = await getPoemDetail(poemId);
        setDetail(poemData);

        try {
          const latest = await getLatestAIInterpretation(poemId);
          const latestInterpretation = latest.interpretation?.trim() ?? '';
          if (latestInterpretation) {
            setAiInterpretation(latestInterpretation);
            setAIJobStates((prev) => ({
              ...prev,
              interpretation: {
                status: 'success',
                message: `${AI_JOB_LABELS.interpretation}已同步，最近一次由 ${latest.provider} 生成。`,
                detail: latest.finished_at ? `更新时间：${new Date(latest.finished_at).toLocaleString('zh-CN')}` : undefined,
              },
            }));
          }
        } catch {
          // 没有历史 AI 解读不影响页面展示
        }
      } catch (error) {
        setErrorText(getErrorMessage(error, '加载诗词详情失败'));
      } finally {
        setLoading(false);
      }
    };

    void fetchData();
  }, [poemId]);

  const runAIJob = async (jobType: AIJobType) => {
    if (!detail) {
      return;
    }

    setAiLoadingType(jobType);
    setErrorText('');
    if (jobType === 'interpretation') {
      setAiInterpretation('');
    }
    if (jobType === 'tts_reading') {
      setAiAudioUrl('');
      setAiAudioDuration('');
    }
    if (jobType === 'story_video') {
      setAiVideoUrl('');
      setAiVideoThumbnailUrl('');
    }
    setAIJobStates((prev) => ({
      ...prev,
      [jobType]: {
        status: 'pending',
        message: AI_JOB_PENDING_MESSAGES[jobType],
      },
    }));

    try {
      const created = await createAIJob({
        poem_id: detail.poem_id,
        job_type: jobType,
        style: jobType === 'story_video' ? 'ink' : 'modern',
        voice: jobType === 'tts_reading' ? 'warm_female' : undefined,
      });

      let finalJob = null as Awaited<ReturnType<typeof getAIJob>> | null;
      for (let attempt = 0; attempt < 30; attempt += 1) {
        const current = await getAIJob(created.job_id);
        if (current.status === 'success' || current.status === 'succeeded' || current.status === 'failed') {
          finalJob = current;
          break;
        }
        await wait(1500);
      }

      if (!finalJob) {
        throw new Error('AI 任务执行超时，请稍后查看结果');
      }
      if (finalJob.status === 'failed') {
        const failureKind = normalizeAIJobFailureKind(finalJob.error_code, finalJob.error_message);
        const nextState = getAIJobFailureState(jobType, failureKind, finalJob.error_message);
        setAIJobStates((prev) => ({
          ...prev,
          [jobType]: nextState,
        }));
        setErrorText(nextState.message);
        return;
      }

      const normalized = extractAIJobResult(finalJob);

      if (jobType === 'interpretation') {
        if (!normalized.text) {
          const nextState = getAIJobFailureState(jobType, 'empty_result');
          setAIJobStates((prev) => ({
            ...prev,
            [jobType]: nextState,
          }));
          setErrorText(nextState.message);
          return;
        }
        setAiInterpretation(normalized.text);
      }
      if (jobType === 'tts_reading') {
        if (!normalized.audioUrl) {
          const nextState = getAIJobFailureState(jobType, 'empty_result');
          setAIJobStates((prev) => ({
            ...prev,
            [jobType]: nextState,
          }));
          setErrorText(nextState.message);
          return;
        }
        setAiAudioUrl(normalized.audioUrl);
        setAiAudioDuration(typeof normalized.durationSeconds === 'number' ? `${normalized.durationSeconds}s` : '');
      }
      if (jobType === 'story_video') {
        if (!normalized.videoUrl) {
          const nextState = getAIJobFailureState(jobType, 'empty_result');
          setAIJobStates((prev) => ({
            ...prev,
            [jobType]: nextState,
          }));
          setErrorText(nextState.message);
          return;
        }
        setAiVideoUrl(normalized.videoUrl);
        setAiVideoThumbnailUrl(normalized.thumbnailUrl);
      }

      setAIJobStates((prev) => ({
        ...prev,
        [jobType]: {
          status: 'success',
          message: `${AI_JOB_LABELS[jobType]}已生成，来源：${normalized.provider || finalJob.provider}。`,
          detail:
            finalJob.job_type === 'tts_reading' && normalized.durationSeconds
              ? `音频时长：${normalized.durationSeconds} 秒`
              : undefined,
        },
      }));
    } catch (error) {
      const apiCode = getApiErrorCode(error);
      const failureKind = apiCode === 50101 || apiCode === 50102 ? normalizeAIJobFailureKind(apiCode) : undefined;
      const nextState = getAIJobFailureState(jobType, failureKind, getErrorMessage(error, 'AI 功能调用失败，请确认已登录且后端 AI 已配置'));
      setAIJobStates((prev) => ({
        ...prev,
        [jobType]: nextState,
      }));
      setErrorText(nextState.message);
    } finally {
      setAiLoadingType(null);
    }
  };

  if (loading) {
    return (
      <div className="rounded-2xl border border-slate-200 bg-white p-8 text-slate-600">
        <LoaderCircle className="inline-block animate-spin" size={18} />
        <span className="ml-2">加载诗词详情中...</span>
      </div>
    );
  }

  if (!detail) {
    return <div className="rounded-2xl bg-rose-50 p-6 text-rose-700">{errorText || '未找到诗词内容'}</div>;
  }

  return (
    <div className="mx-auto max-w-5xl space-y-6">
      <section className="rounded-3xl border border-slate-200 bg-white p-6 md:p-8">
        <h1 className="text-3xl font-semibold text-slate-900 md:text-4xl">{detail.title}</h1>
        <p className="mt-2 text-slate-600">
          {detail.author} · {detail.dynasty}
        </p>
      </section>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <section className="space-y-6 lg:col-span-2">
          <article className="rounded-3xl border border-slate-200 bg-white p-6 md:p-8">
            <div className="space-y-3 text-center text-2xl leading-loose text-slate-900">
              {contentLines.map((line, index) => (
                <p key={`${line}-${index}`}>{line}</p>
              ))}
            </div>

            <div className="mt-8 border-t border-slate-200 pt-6">
              <h3 className="text-lg font-semibold">标签</h3>
              <div className="mt-3 flex flex-wrap gap-2">
                {tagList.map((tag) => (
                  <span key={tag} className="rounded-full bg-slate-100 px-3 py-1 text-sm text-slate-700">
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          </article>

          <article className="rounded-3xl border border-slate-200 bg-white p-6 md:p-8">
            <h3 className="text-xl font-semibold text-slate-900">诗词解读</h3>
            <div className="mt-5 space-y-5 text-sm leading-7 text-slate-700">
              <div>
                <p className="font-semibold text-slate-900">教科书解读</p>
                <p className="mt-2">{detail.interpretations.textbook.content || '暂无'}</p>
              </div>
              <div>
                <p className="font-semibold text-slate-900">通俗解读</p>
                <p className="mt-2">{detail.interpretations.basic.content || '暂无'}</p>
              </div>
              {aiInterpretation || aiJobStates.interpretation.status !== 'idle' ? (
                <div className={`rounded-2xl border p-4 ${getAIJobStateTone(aiJobStates.interpretation.status)}`}>
                  <div className="flex items-center justify-between gap-3">
                    <p className="font-semibold">AI 解读</p>
                    <span className="rounded-full border border-current/20 px-2 py-0.5 text-xs font-medium">
                      {aiJobStates.interpretation.status === 'idle' ? '未生成' : aiJobStates.interpretation.status}
                    </span>
                  </div>
                  <p className="mt-2 whitespace-pre-wrap">{aiInterpretation || aiJobStates.interpretation.message}</p>
                  {aiJobStates.interpretation.detail ? (
                    <p className="mt-2 text-xs opacity-80">{aiJobStates.interpretation.detail}</p>
                  ) : null}
                </div>
              ) : null}
            </div>
          </article>
        </section>

        <aside className="space-y-4">
          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <MapPin className="mr-2" size={18} />
              相关地点
            </h3>
            <div className="mt-4 space-y-3">
              {relatedPoiList.map((poi) => (
                <div key={poi.poi_id} className="rounded-xl border border-slate-200 p-3">
                  <p className="font-medium text-slate-900">{poi.name}</p>
                  <p className="mt-1 text-xs text-slate-500">关联分 {poi.relevance_score.toFixed(2)}</p>
                </div>
              ))}
            </div>

            <Link
              to={`/checkin?poem_id=${detail.poem_id}${primaryPoi ? `&poi_id=${primaryPoi.poi_id}` : ''}`}
              className="mt-4 inline-flex w-full items-center justify-center rounded-xl bg-slate-900 px-4 py-2.5 text-sm text-white transition hover:bg-slate-700"
            >
              前往打卡
            </Link>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <Calendar className="mr-2" size={18} />
              季节信息
            </h3>
            <p className="mt-3 text-sm text-slate-600">最佳季节：{bestSeasonList.join('、') || '未标注'}</p>
            <p className="mt-1 text-sm text-slate-600">节气：{solarTermList.join('、') || '未标注'}</p>
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="flex items-center text-lg font-semibold text-slate-900">
              <Sparkles className="mr-2" size={18} />
              AI 能力
            </h3>
            <div className="mt-3 grid grid-cols-1 gap-2">
              <button
                type="button"
                onClick={() => void runAIJob('interpretation')}
                disabled={aiLoadingType !== null}
                className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 disabled:bg-slate-100"
              >
                {aiLoadingType === 'interpretation' ? '生成中...' : '生成 AI 解读'}
              </button>
              <button
                type="button"
                onClick={() => void runAIJob('tts_reading')}
                disabled={aiLoadingType !== null}
                className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 disabled:bg-slate-100"
              >
                {aiLoadingType === 'tts_reading' ? '生成中...' : '生成 AI 诵读'}
              </button>
              <button
                type="button"
                onClick={() => void runAIJob('story_video')}
                disabled={aiLoadingType !== null}
                className="rounded-lg border border-slate-300 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-100 disabled:bg-slate-100"
              >
                {aiLoadingType === 'story_video' ? '生成中...' : '生成故事动画'}
              </button>
            </div>

            <div className="mt-4 space-y-2">
              {(['interpretation', 'tts_reading', 'story_video'] as AIJobType[]).map((jobType) => (
                <div key={jobType} className={`rounded-xl border px-3 py-2 ${getAIJobStateTone(aiJobStates[jobType].status)}`}>
                  <div className="flex items-center justify-between gap-3">
                    <p className="text-sm font-medium">{AI_JOB_LABELS[jobType]}</p>
                    <span className="rounded-full border border-current/20 px-2 py-0.5 text-[11px] font-medium uppercase">
                      {getAIJobStateLabel(aiJobStates[jobType].status)}
                    </span>
                  </div>
                  <p className="mt-1 text-xs leading-5 opacity-90">{aiJobStates[jobType].message}</p>
                  {aiJobStates[jobType].detail ? <p className="mt-1 text-[11px] opacity-70">{aiJobStates[jobType].detail}</p> : null}
                </div>
              ))}
            </div>

            {aiAudioUrl ? (
              <div className="mt-4 rounded-xl bg-slate-100 p-3">
                <p className="mb-2 flex items-center text-sm font-medium text-slate-700">
                  <Volume2 className="mr-1" size={16} />
                  AI 诵读音频{aiAudioDuration ? ` · ${aiAudioDuration}` : ''}
                </p>
                <audio controls className="w-full" src={aiAudioUrl} />
              </div>
            ) : null}

            {aiVideoUrl ? (
              <div className="mt-4 space-y-2">
                <a
                  href={aiVideoUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="block rounded-xl bg-amber-50 px-3 py-2 text-sm text-amber-800 transition hover:bg-amber-100"
                >
                  查看故事动画链接
                </a>
                {aiVideoThumbnailUrl ? (
                  <a
                    href={aiVideoThumbnailUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="block rounded-xl bg-slate-100 px-3 py-2 text-sm text-slate-700 transition hover:bg-slate-200"
                  >
                    查看故事动画封面
                  </a>
                ) : null}
              </div>
            ) : null}
          </div>

          <div className="rounded-2xl border border-slate-200 bg-white p-5">
            <h3 className="text-lg font-semibold text-slate-900">统计</h3>
            <div className="mt-3 grid grid-cols-3 gap-2 text-center">
              <div className="rounded-lg bg-slate-100 p-2">
                <p className="text-lg font-semibold">{detail.stats.view_count}</p>
                <p className="text-xs text-slate-500">浏览</p>
              </div>
              <div className="rounded-lg bg-slate-100 p-2">
                <p className="text-lg font-semibold">{detail.stats.like_count}</p>
                <p className="text-xs text-slate-500">点赞</p>
              </div>
              <div className="rounded-lg bg-slate-100 p-2">
                <p className="text-lg font-semibold">{detail.stats.checkin_count}</p>
                <p className="text-xs text-slate-500">打卡</p>
              </div>
            </div>
          </div>
        </aside>
      </div>

      {errorText ? <p className="rounded-xl bg-rose-50 px-4 py-3 text-sm text-rose-700">{errorText}</p> : null}
    </div>
  );
};

export default PoemDetail;
