FROM python:3.12-alpine AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/app/deps -r requirements.txt

FROM python:3.12-alpine
ARG BUILD_TIMESTAMP
RUN addgroup -g 10001 appuser && \
    adduser -D -u 10001 -G appuser appuser
COPY --from=builder /app/deps /app/deps
COPY --chown=10001:10001 main.py /app/main.py
RUN echo "$BUILD_TIMESTAMP" > /app/build-timestamp
ENV PYTHONPATH=/app/deps
WORKDIR /app
USER 10001:10001
EXPOSE 8080
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]