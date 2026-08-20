# 03 — Generate and open a source-faithful Brief

**What to build:** A queued Analysis Request is processed through a server-side Gemini adapter and becomes a completed immutable Brief that opens in the owner’s current workbench session.

**Blocked by:** 02 — Submit an Analysis Request.

**Status:** ready-for-agent

- [ ] Provider work remains server-side and uses one public YouTube URL per request; browser code never receives the Gemini key.
- [ ] A successful processing result records captured source metadata, selected output language, structured source-faithful content, and key conclusions in an immutable Brief.
- [ ] The owner sees the lifecycle progress from queued through processing to completed and can read the completed Brief in the workbench.
- [ ] A fake Gemini adapter drives deterministic successful application-boundary tests without calling the real provider.
