from fastapi import FastAPI

app = FastAPI()


@app.get("/healthz")
def read_health() -> dict[str, str]:
    return {"status": "ok"}
