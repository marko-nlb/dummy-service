# builder
FROM python:3.14.3-slim-trixie@sha256:486b8092bfb12997e10d4920897213a06563449c951c5506c2a2cfaf591c599f AS builder

WORKDIR /app

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt ./
RUN pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

COPY app.py .

# runtime
FROM python:3.14.3-slim-trixie@sha256:486b8092bfb12997e10d4920897213a06563449c951c5506c2a2cfaf591c599f AS runtime

EXPOSE 8080/tcp

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends tini \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 appuser \
    && useradd -u 10001 -g 10001 -m -s /usr/sbin/nologin appuser

#RUN useradd -m appuser && chown -R appuser:appuser /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY --from=builder --chown=10001:10001 /app /app

USER 10001:10001

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health').read()" || exit 1

ENTRYPOINT ["tini", "--"]
CMD [ "python", "./app.py" ]