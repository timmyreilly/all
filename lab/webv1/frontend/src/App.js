import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import Register from './components/Register';
import MessageList from './components/MessageList';
import CreateMessage from './components/CreateMessage';

function App() {
  return (
    <Router>
      <nav>
        <Link to="/">Messages</Link> | <Link to="/create">Create Message</Link> | <Link to="/register">Register</Link>
      </nav>
      <Routes>
        <Route path="/" element={<MessageList />} />
        <Route path="/create" element={<CreateMessage />} />
        <Route path="/register" element={<Register />} />
      </Routes>
    </Router>
  );
}

export default App;
