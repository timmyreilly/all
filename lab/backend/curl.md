curl -X GET "http://localhost:8000/messages"


curl -X POST "http://localhost:8000/messages" \
     -H "Content-Type: application/json" \
     -d '{"content": "Hello, World!"}'


curl -X GET "http://localhost:8000/users/1"


curl -X POST "http://localhost:8000/users" \
     -H "Content-Type: application/json" \
     -d '{"username": "alice", "password": "securepassword123"}'
