# Contributing to EasyRec

Small, focused contributions are welcome. You can report a recording issue, improve accessibility or localization, refine the interface, or work on the capture pipeline.

## Get started

Use macOS with Xcode 26 or its Command Line Tools. Fork the repository, create a branch, then run:

```sh
zsh scripts/test.sh
zsh scripts/build-app.sh
open build/EasyRec.app
```

See [Architecture](docs/ARCHITECTURE.md) for the source layout and [Testing](docs/TESTING.md) for interactive checks.

## Make a change

- Keep one problem or feature per pull request.
- Preserve the compact recording flow and provide clear status while starting or saving.
- Keep capture lifecycle changes on the main actor and guard callbacks against stale sessions.
- Follow the surrounding Swift style. The repository includes a `.swift-format` configuration.
- Update documentation when behavior changes. Add tests when they exercise meaningful logic.

In the pull request, explain the problem, the resulting behavior, and how you checked it. For interface changes, include a screenshot. For capture changes, describe the audio sources and recording scenario you tested.

## Report an issue

Use [GitHub Issues](https://github.com/OHHHHHHei/EasyRec/issues). Include your macOS version, how you built the app, the steps to reproduce, and what you expected. Share screenshots or short samples only after removing personal content.

## License

Contributions are submitted under the repository's [MIT License](LICENSE). Only contribute code and assets you have permission to share.
