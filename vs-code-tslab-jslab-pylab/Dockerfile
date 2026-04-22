# Use Debian slim
FROM python:3.11-slim

# Install system deps (added git, which is very useful in VS Code)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

# Install Python tools (VS Code uses these under the hood to run notebooks)
RUN pip install --no-cache-dir jupyterlab ipykernel

# Install Deno
ENV DENO_INSTALL=/usr/local
RUN curl -fsSL https://deno.land/x/install/install.sh | sh
RUN deno jupyter --install

# Install code-server (VS Code in the browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Pre-install VS Code extensions for Python, Jupyter, and Deno
# This ensures syntax completion works instantly when you open the browser
RUN code-server --install-extension ms-python.python \
    && code-server --install-extension ms-toolsai.jupyter \
    && code-server --install-extension denoland.vscode-deno

# Set the working directory
WORKDIR /workspace

# Expose the internal port
EXPOSE 8888

# Start VS Code server on port 8888, password disabled
CMD ["code-server", "--bind-addr", "0.0.0.0:8888", "--auth", "none", "/workspace"]