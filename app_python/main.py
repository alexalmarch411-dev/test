import os
import time
from contextlib import asynccontextmanager

from fastapi import FastAPI
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo.errors import ConnectionFailure, OperationFailure
from fastapi.responses import JSONResponse, Response
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
MONGO_TIMEOUT_MS = int(os.getenv("MONGO_TIMEOUT_MS", "3000"))

client = AsyncIOMotorClient(
    MONGO_URI,
    serverSelectionTimeoutMS=MONGO_TIMEOUT_MS,
    connectTimeoutMS=MONGO_TIMEOUT_MS,
)

http_requests_total = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "path", "status"]
)
mongo_ping_duration = Histogram(
    "mongodb_ping_duration_seconds", "MongoDB ping latency"
)
mongo_up = Gauge(
    "mongodb_up", "Whether the last MongoDB ping succeeded (1) or not (0)"
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    client.close()


app = FastAPI(title="web", version="0.1.0", lifespan=lifespan)


@app.get("/")
async def root():
    http_requests_total.labels(method="GET", path="/", status="200").inc()
    return {"status": "ok"}


@app.get("/health")
async def health():
    start = time.perf_counter()
    try:
        await client.admin.command("ping")
        status, code = "ok", 200
        mongo_up.set(1)
    except (ConnectionFailure, OperationFailure):
        status, code = "error", 503
        mongo_up.set(0)
    finally:
        mongo_ping_duration.observe(time.perf_counter() - start)

    http_requests_total.labels(method="GET", path="/health", status=str(code)).inc()
    return JSONResponse(content={"mongodb": status}, status_code=code)


@app.get("/metrics")
async def metrics():
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)