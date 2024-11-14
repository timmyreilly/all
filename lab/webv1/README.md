
```
poetry shell
poetry install

uvicorn chapp:app --reload
```

```
./build_frontend.sh
uvicorn app.main:app --host 0.0.0.0 --port 8000
```