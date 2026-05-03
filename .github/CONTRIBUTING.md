# Contributing

Thanks for your interest in CloudCart AI Toolkit.

## Where bugs go

This repo holds plugin manifests and skill content. The underlying tools live elsewhere:

- CLI bugs: [`cloudcart/cli`](https://github.com/cloudcart/cli)
- Dev MCP bugs: [`cloudcart/dev-mcp`](https://github.com/cloudcart/dev-mcp)

Please open issues in the right place. PRs against this repo are welcome for:

- Skill text fixes (typos, broken commands, outdated guidance)
- New per-host plugin manifests
- Documentation improvements

## Local testing

```bash
# Validate all JSON manifests
for f in $(find . -name '*.json' -not -path './node_modules/*' -not -path './.git/*'); do
  python3 -m json.tool "$f" > /dev/null && echo "OK $f" || echo "FAIL $f"
done

# Smoke-test the Dev MCP
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}
{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | npx -y @cloudcart/dev-mcp@latest
```
