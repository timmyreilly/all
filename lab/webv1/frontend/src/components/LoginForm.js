import React, { useState } from 'react';
import api from '../api';

function Login() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [message, setMessage] = useState('');

  const handleSubmit = async (event) => {
    event.preventDefault();
    try {
      // Prepare form data
      const params = new URLSearchParams();
      params.append('username', username);
      params.append('password', password);

      // Send POST request to /api/token
      const response = await api.post('/api/token', params, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      });

      if (response.status === 200) {
        // Store the access token (e.g., in local storage)
        const { access_token } = response.data;
        localStorage.setItem('access_token', access_token);
        setMessage('Login successful!');
        // You might want to redirect the user or update the app state here
      }
    } catch (error) {
      setMessage('Error logging in');
    }
  };

  return (
    <div>
      <h2>Login</h2>
      <form onSubmit={handleSubmit}>
        <div>
          <label>Username:&nbsp;</label>
          <input
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
          />
        </div>
        <div>
          <label>Password:&nbsp;</label>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>
        <button type="submit">Login</button>
      </form>
      <p>{message}</p>
    </div>
  );
}

export default Login;
