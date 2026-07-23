# FastAPI + React Frontend Compose Stack

## What this runs

- `fastapi-api` on `http://localhost:8000`
- `react-frontend` on `http://localhost:3000`

## Networking

Both containers share `app-net`.
React can call backend using service DNS name:

- `http://fastapi-api:8000`

## Run

```bash
cd compose/fastapi-react
docker compose up --build
```

## Stop

```bash
docker compose down
```
