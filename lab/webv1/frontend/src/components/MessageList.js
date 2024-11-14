import React, { useState, useEffect } from 'react';
// import axios from 'axios';
import api from '../api';


function MessageList() {
  const [messages, setMessages] = useState([]);

  useEffect(() => {
    api.get('/api/messages')
      .then((response) => {
        setMessages(response.data);
      })
      .catch((error) => {
        console.error('Error fetching messages:', error);
      });
  }, []);

  return (
    <div>
      <h2>Messages</h2>
      {messages.length > 0 ? (
        <ul>
          {messages.map((msg) => (
            <li key={msg.id}>{msg.content}</li>
          ))}
        </ul>
      ) : (
        <p>No messages found.</p>
      )}
    </div>
  );
}

export default MessageList;
