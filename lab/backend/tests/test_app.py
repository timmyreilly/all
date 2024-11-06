

from fastapi.testclient import TestClient

def test_get_user():
    client = TestClient(app)
    with deps.override_for_test() as test_container:
        # Mock the DBConnection for testing
        test_container[DBConnection] = lambda: MockDBConnection()
        response = client.get("/users/1")
    assert response.status_code == 200
