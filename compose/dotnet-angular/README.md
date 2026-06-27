# .NET API + Angular Frontend Compose Stack

## What this runs

- `dotnet-api` on `http://localhost:5000`
- `angular-frontend` on `http://localhost:4200`

## Networking

Both containers share `app-net`.
Angular can call backend using service DNS name:

- `http://dotnet-api:8080`

## Run

```bash
cd compose/dotnet-angular
docker compose up --build
```

## Stop

```bash
docker compose down
```
