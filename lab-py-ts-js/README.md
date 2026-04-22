# Jupyter Polyglot (Python + TS/JS)

## Run
```bash
docker compose up --build
```
Open http://localhost:8888/lab

## Kernels
- **Python 3** (ipykernel, JupyterLab visual debugger supported)
- **Deno** (TypeScript & JavaScript)

## Debugging

### Python (in notebook)
Pick the **Python 3** kernel, click the bug icon at the top-right of the
notebook toolbar, set breakpoints in the gutter, run the cell.

### TypeScript / JavaScript
Notebook (Deno kernel): use console.log; for full step-debug extract to a file:
```bash
deno run --inspect-brk --allow-all script.ts
# open chrome://inspect
```

### Bun scripts
```bash
bun --inspect-brk script.ts
# attach via chrome://inspect on port 9229
```

## Folders
- `notebooks/`  your notebooks
- `data/`       your local data (mounted into the container)
