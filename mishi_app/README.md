# mishi_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AI Features (MVP)

Poem detail page now supports three async AI actions backed by backend `ai_jobs`:

1. `AI解读` - generate interpretation text
2. `AI诵读` - generate reading audio URL and play it
3. `故事动画` - generate story video URL

The app creates a job with `POST /v1/ai/jobs` and polls `GET /v1/ai/jobs/{job_id}`.
