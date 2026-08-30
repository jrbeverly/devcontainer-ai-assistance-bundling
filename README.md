# Dev Container AI Assistance Bundling

> [!WARNING]
> **AI-authored:** This change was autonomously planned and implemented by an AI software factory from a human-authored specification, with possible subsequent human review or modification.

Compares a raw Markdown guidance corpus with the same corpus exposed through a local stdio MCP sidecar.

```sh
devcontainer up --workspace-folder . --config auxiliary/devcontainer.json
./context/build.sh
export CORPUS_SOURCE="$PWD/context/source"
```

## Notes

- initial idea; simple distribution of OpenAI configuration using container features
- ultimately decided against pursuing it
- distribution feels too involved for what is fundamentally just a set of files
- could ship a helper tool to pull/sync the files
- at that point though, starts becoming an AI system/orchestration problem rather than simple configuration distribution
- still some potentially useful sub-cases
- initialization/bootstrap flows
- orchestration of another tool
- storing/distributing precomputed knowledge bases
- overall; project effectively abandoned
