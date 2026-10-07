# Third-party sources — Task 1

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
dependency's actual APIs. Final distributable license bundling will be checked
in task 8; bundled third-party runtime code must retain its license notice.
