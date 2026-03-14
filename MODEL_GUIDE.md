# AI Model Selection

Your AI model is selected automatically during installation. The installer will discover available models and ask you to choose.

## How It Works

1. Run `./install.sh`
2. Installer runs `kilo models` to discover available models
3. Shows you a numbered list of free models
4. You enter the number to select
5. Config is automatically created

## Available Free Models

| # | Model |
|---|-------|
| 1 | kilo/kilo-auto/free |
| 2 | kilo/minimax/minimax-m2.5:free |
| 3 | kilo/x-ai/grok-code-fast-1:optimized:free |
| 4 | kilo/nvidia/nemotron-3-super-120b-a12b:free |

## Changing Model Later

Edit `~/.config/kilo/kilo.json`:

```json
{
  "skills": {
    "security-review": {
      "path": "~/.config/kilo/skills/security-review",
      "model": "kilo/minimax/minimax-m2.5:free"
    }
  }
}
```

Then restart Kilo CLI.

## Recommended Models

- **For speed**: `kilo/stepfun/step-3.5-flash:free`
- **For reasoning**: `kilo/kilo-auto/free`
- **For code analysis**: `kilo/x-ai/grok-code-fast-1:optimized:free`
