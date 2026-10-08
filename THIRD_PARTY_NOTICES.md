# Third-party sources and distribution notices

- `moonbitstack/moonjson 0.4.0`: Apache-2.0, Copyright 2026 Leo Cheng.
  Source: https://github.com/moonbitstack/moonjson ; downloaded through Mooncakes.
  License was inspected in `.mooncakes/moonbitstack/moonjson/LICENSE`.
  Registry archive SHA256: `d6c5a881ede691a3fd5ffdfcd748247323eafce8819161108bbf7c84542e7774`.
- `moonbitlang/core 0.10.14+7d59c7ec9`: Apache-2.0.
  Source: https://github.com/moonbitlang/core ; supplied by the official toolchain.
- `playwright-core 1.63.0`: Apache-2.0, Microsoft Corporation.
  Source: https://github.com/microsoft/playwright ; development verification only,
  not part of the browser runtime. Exact npm integrity is in `package-lock.json`.

Official API references used for implementation:
- https://www.moonbitlang.com/download/
- https://docs.moonbitlang.com/en/stable/language/ffi.html
- https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html
- https://mooncakes.io/docs/moonbitstack/moonjson

No parser source was copied or rewritten. The parser adapter calls the installed
dependency's actual APIs. Project-original code is MIT (root LICENSE); dependency
licenses retain their own terms. No upstream dependency source was modified.

## Included license texts, verified locally 2026-10-08

- licenses/moonjson-LICENSE.txt: verbatim installed 0.4.0 LICENSE, including Apache text and copyright.
  No upstream NOTICE was present in the installed moonjson package.
- licenses/moonbit-core-LICENSE.txt and licenses/moonbit-core-NOTICE.txt: verbatim pinned core texts.
  The full NOTICE conservatively retains its MIT, fdlibm/Sun and FreeBSD source notices,
  including routines that a JS release may omit.
- licenses/playwright-LICENSE.txt and licenses/playwright-NOTICE.txt: development dependency texts.

Generated JS includes required runtime/dependency code. Local runtime preparation copies licenses/,
root LICENSE and this file with both dist modules. Retain these in future source/runtime distributions;
MIT does not relicense bundled dependencies. Toolchain binaries, Node, Chrome, Playwright and FFmpeg
are not redistributed as runtime dependencies. Demo recording uses Playwright FFmpeg revision 1011,
downloaded by its official CLI solely as a development tool; no stock media or music was used.

RFC 6901 reference: https://www.rfc-editor.org/rfc/rfc6901 .
Existing source-diff project (comparison only, no code dependency):
https://mooncakes.io/docs/moonbit-community/moondiff .
