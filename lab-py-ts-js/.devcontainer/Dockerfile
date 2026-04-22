FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_LINK_MODE=copy \
    DENO_INSTALL=/usr/local \
    BUN_INSTALL=/usr/local

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl ca-certificates unzip git build-essential \
    && rm -rf /var/lib/apt/lists/*

# uv (fast Python package manager)
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Deno (built-in Jupyter kernel for TS/JS)
RUN curl -fsSL https://deno.land/install.sh | sh -s -- -y \
    && ln -sf /usr/local/bin/deno /usr/bin/deno

# Bun (TS/JS runtime + package manager)
RUN curl -fsSL https://bun.sh/install | bash \
    && ln -sf /usr/local/bin/bun /usr/bin/bun

WORKDIR /workspace

RUN uv venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}" VIRTUAL_ENV=/opt/venv

COPY pyproject.toml /workspace/pyproject.toml
RUN uv pip install --python /opt/venv/bin/python \
    "jupyterlab>=4.2" "notebook>=7.2" "ipykernel>=6.29" "debugpy>=1.8" ipywidgets

# Register Deno kernel
RUN deno jupyter --install || true

EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", \
     "--allow-root", "--ServerApp.token=", "--ServerApp.password="]
