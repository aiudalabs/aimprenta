> **LOCAL ADAPTATION (aimprenta install):** Upstream, this skill runs each
> per-entry reviewer call through the OpenAI Codex CLI (`mcp__codex__codex`, fresh
> thread per entry). That MCP is not part of this pipeline. Wherever the procedure
> below says to invoke `mcp__codex__codex` (or start a fresh Codex thread), instead
> spawn a FRESH Claude subagent via the Agent tool (subagent_type: general-purpose),
> one per entry or batch, passing the same reviewer prompt. Reviewer independence
> comes from the fresh context, not the vendor. `shared-references/` and `tools/`
> are bundled inside this skill directory (upstream keeps them at the repo root).
