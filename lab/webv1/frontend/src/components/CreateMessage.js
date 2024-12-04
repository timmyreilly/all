import React, { useState } from 'react';
import api from '../api';

function CreateMessage() {
  const [content, setContent] = useState('');
  const [message, setMessage] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      const response = await api.post('/api/messages', { content });
      setMessage('Message created successfully!');
      setContent(response.data.content);
    } catch (error) {
      setMessage('Error creating message');
    }
  };

  return (
    <div>
      <h2>Create Message</h2>
      <form onSubmit={handleSubmit}>
        <div>
          <label>Content:&nbsp;</label>
          <input
            type="text"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            required
          />
        </div>
        <button type="submit">Create</button>
      </form>
      <p>{message}</p>
    </div>
  );
}

export default CreateMessage;
