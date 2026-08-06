# Codex for Open Source application: quicz

Snapshot: 2026-08-06, public repository commit `2f980e26d21170da748b5c00cd62c43d21a416c1`.

## Submission blocker

Do not submit until a valid open-source license file has been added to the public repository. The public HEAD contains no `LICENSE` or `COPYING`, and the GitHub repository API reports `license: null`. `README.md` says "MIT" and links to `LICENSE`, but that target does not exist. Therefore this draft does not describe quicz as MIT-licensed.

## Form fields and paste-ready answers

The limits below come from the visible form DOM, not the hidden Marketo form copy. Fields marked `*` are required.

### 1. Last name *

- Control: text, maximum 255 characters.
- Answer: `[YOUR LEGAL/FAMILY NAME]`

### 2. First name *

- Control: text, maximum 255 characters.
- Answer: `[YOUR GIVEN NAME]`

### 3. Email *

- Control: email, maximum 255 characters.
- Form note: use the email associated with the applicant's ChatGPT account.
- Answer: `[EMAIL ASSOCIATED WITH YOUR CHATGPT ACCOUNT]`

### 4. GitHub username *

- Control: text, maximum 255 characters. GitHub profile must be public.
- Answer: `venjiang`

### 5. GitHub repository URL *

- Control: URL, maximum 255 characters. Repository must be public.
- Answer: `https://github.com/venjiang/quicz`

### 6. Are you a primary maintainer or core maintainer? *

- Control: required radio; choices `Primary maintainer` and `Core maintainer`.
- Answer: `Primary maintainer`
- Evidence: the repository owner is `venjiang`; GitHub lists `venjiang` as the sole contributor, with 1,733 contributions.

### 7. Why does this repository qualify? *

- Control: textarea, maximum 500 characters.
- Paste:

> quicz is a public, actively maintained QUIC/HTTP/3 implementation in pure Zig for Zig 0.16. It covers QUIC v1/v2, TLS 1.3, recovery and congestion control, HTTP/3, QPACK, WebTransport, qlog, and cross-implementation interop. As of 2026-08-06 it has 10 GitHub stars, 1,733 commits, 1,822 passing tests, and a documented 7/7 bidirectional interop matrix. Adoption is early; its value is a native, standards-focused transport stack for Zig.

This intentionally does not claim monthly downloads or broad adoption: the repository has no public release/package download metric.

### 8. I am interested in

- Control: optional multi-select. Choices `Codex Security` and `API credits`.
- Answer: select both `Codex Security` and `API credits`.
- Rationale: quicz contains security-sensitive TLS, packet protection, protocol parsing, and interoperability paths; API credits also match the proposed maintainer workflow below.

### 9. OpenAI organization ID *

- Control: text, maximum 30 characters.
- Answer: `[OPENAI ORGANIZATION ID FROM PLATFORM SETTINGS]`
- Lookup: <https://platform.openai.com/settings/organization/general>

### 10. How will you use API credits for your project? *

- Control: textarea, maximum 500 characters.
- Paste:

> Use API credits only for quicz maintenance: triage issues; review pull requests against QUIC, TLS, and HTTP/3 requirements; propose targeted regression and fuzz tests for packet parsing, recovery, congestion control, and TLS; analyze interoperability and benchmark failures; and maintain release notes and documentation. A human maintainer will review every proposed change. The workflow will not merge or release autonomously or inspect repositories I do not control.

### 11. Is there anything else you would like us to know?

- Control: optional textarea, maximum 500 characters.
- Paste:

> I own and maintain the repository and am its sole listed GitHub contributor. quicz is early-stage: it has no public release/package download metric, and I am not claiming broad adoption. I can provide repository-control verification, current test output, and interoperability evidence on request.

## Sources

### Official program sources

- [Chinese application form](https://openai.com/zh-Hans-CN/form/codex-for-oss/): all 11 visible fields, required markers, choices, helper text, and visible character limits; checked through the live DOM on 2026-08-06 without filling or submitting.
- [Codex for Open Source program page](https://developers.openai.com/community/codex-for-oss): eligibility, benefits, and the instruction to apply even when a project's case rests on ecosystem importance rather than broad use.
- [Program terms](https://learn.chatgpt.com/docs/codex-for-oss-terms): accurate application information, maintainer/repository-control verification, and authorization limits for Codex Security/API credits.

### quicz primary sources

- [GitHub repository API](https://api.github.com/repos/venjiang/quicz): public visibility, owner `venjiang`, Zig as the primary language, 10 stars, 0 forks, timestamps, and `license: null` as of 2026-08-06.
- [GitHub contributors API](https://api.github.com/repos/venjiang/quicz/contributors?per_page=100): sole contributor `venjiang`, 1,733 contributions.
- [GitHub releases API](https://api.github.com/repos/venjiang/quicz/releases?per_page=100) and [tags API](https://api.github.com/repos/venjiang/quicz/tags?per_page=100): no public releases or tags, so no public release-download metric.
- [`README.md` project scope and feature list](https://github.com/venjiang/quicz/blob/2f980e26d21170da748b5c00cd62c43d21a416c1/README.md#L10-L26): pure-Zig QUIC/HTTP/3 scope and implemented protocol areas.
- [`README.md` interop matrix](https://github.com/venjiang/quicz/blob/2f980e26d21170da748b5c00cd62c43d21a416c1/README.md#L174-L187): documented 7/7 bidirectional matrix.
- [`build.zig.zon`](https://github.com/venjiang/quicz/blob/2f980e26d21170da748b5c00cd62c43d21a416c1/build.zig.zon#L1-L14): package version and Zig 0.16 minimum.
- [`src/lib.zig`](https://github.com/venjiang/quicz/blob/2f980e26d21170da748b5c00cd62c43d21a416c1/src/lib.zig#L3-L52): exported runtime, TLS, packet protection, HTTP/3, QPACK, WebTransport, qlog, congestion-control, and interop-related modules.
- Clean public HEAD verification: `zig build test --summary all` at commit `2f980e2` passed `1,822/1,822` tests. The README's `1,820` count is stale and should be corrected before submission.
- License check: `git ls-tree -r --name-only HEAD` contains no `LICENSE` or `COPYING`; GitHub reports `license: null`, while [`README.md` lines 223-225](https://github.com/venjiang/quicz/blob/2f980e26d21170da748b5c00cd62c43d21a416c1/README.md#L223-L225) links to a missing `LICENSE` file.

## Final submission checklist

1. Add the intended open-source license file and verify GitHub detects it.
2. Replace the four personal placeholders: last name, first name, ChatGPT-account email, and OpenAI organization ID.
3. Update the stale README test count from 1,820 to 1,822 or rerun the clean-HEAD test command if the public commit changes.
4. Recheck stars, contribution/commit count, releases, form fields, and all 500-character answers immediately before submission.
5. Submit only after reviewing and accepting the linked program terms; this research did not submit the form.
