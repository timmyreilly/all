
```
poetry shell
poetry install
```

```
cd frontend 
npm run build
cd ..
```
Start fastpi to host static react app
```
uvicorn app.main:app --host 0.0.0.0 --port 8000
```