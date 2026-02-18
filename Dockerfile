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

WORKDIR /app

COPY --from=builder /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=builder /app /app

RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

CMD [ "python", "./app.py" ]