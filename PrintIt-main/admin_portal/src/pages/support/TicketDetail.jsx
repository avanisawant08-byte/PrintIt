import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import api from '../../core/api';
import { useAuth } from '../../context/AuthContext';

const TicketDetail = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [ticket, setTicket] = useState(null);
  const [newMessage, setNewMessage] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState(null);
  const messagesEndRef = useRef(null);

  useEffect(() => {
    fetchTicket();
  }, [id]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [ticket?.messages]);

  const fetchTicket = async () => {
    try {
      const res = await api.get(`/support/tickets/${id}`);
      setTicket(res.data);
    } catch (err) {
      setError(err.response?.data?.error || err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSendMessage = async (e) => {
    e.preventDefault();
    if (!newMessage.trim()) return;
    
    setIsSending(true);
    try {
      const res = await api.post(`/support/tickets/${id}/messages`, { message: newMessage });
      setTicket(prev => ({
        ...prev,
        messages: [...prev.messages, {
          ...res.data.ticket_message,
          sender_name: user.full_name
        }]
      }));
      setNewMessage('');
    } catch (err) {
      alert(err.response?.data?.error || 'Failed to send message');
    } finally {
      setIsSending(false);
    }
  };

  const updateStatus = async (status) => {
    try {
      await api.patch(`/support/tickets/${id}/status`, { status });
      setTicket(prev => ({ ...prev, status }));
    } catch (err) {
      alert('Failed to update status');
    }
  };

  if (isLoading) return <div className="p-12 text-center text-on-surface-variant">Loading ticket details...</div>;
  if (error) return <div className="p-12 text-center text-error">{error}</div>;
  if (!ticket) return null;

  return (
    <div className="max-w-5xl mx-auto p-6 md:p-12 h-full flex flex-col">
      {/* Header */}
      <div className="bg-surface-container-highest border border-outline-variant/30 rounded-2xl p-6 shadow-lg mb-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <button onClick={() => navigate('/dashboard/support')} className="text-on-surface-variant hover:text-primary flex items-center gap-2 text-sm font-semibold mb-4 transition-colors">
            ← Back to Tickets
          </button>
          <div className="flex items-center gap-2 mb-2 flex-wrap">
            <h2 className="text-2xl font-bold text-on-surface">{ticket.subject}</h2>
            {ticket.issue_type && (
              <span className="text-xs bg-primary/15 text-primary border border-primary/30 px-2.5 py-0.5 rounded-full font-bold">
                {ticket.issue_type}
              </span>
            )}
            {ticket.order_id && (
              <span className="text-xs bg-surface-container-highest text-tertiary border border-outline-variant/40 px-2.5 py-0.5 rounded-full font-mono font-bold">
                Order #{ticket.order_id}
              </span>
            )}
          </div>
          <p className="text-on-surface-variant text-sm">
            Ticket <span className="font-data-mono text-tertiary">#{ticket.ticket_id}</span> • Customer: <span className="font-semibold text-primary">{ticket.customer_name}</span>
          </p>
        </div>
        
        <div className="flex items-center gap-3">
          <select 
            value={ticket.status}
            onChange={(e) => updateStatus(e.target.value)}
            className="bg-surface-container border border-outline-variant/50 rounded-xl px-4 py-2 text-sm font-bold text-on-surface focus:outline-none focus:border-primary uppercase tracking-wider"
          >
            <option value="open">Open</option>
            <option value="in_progress">In Progress</option>
            <option value="resolved">Resolved</option>
            <option value="closed">Closed</option>
          </select>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 bg-surface-container border border-outline-variant/30 rounded-2xl shadow-xl flex flex-col overflow-hidden">
        
        {/* Original Description */}
        <div className="p-6 bg-surface-container-low border-b border-outline-variant/20">
          <div className="flex justify-between items-center mb-2 flex-wrap gap-2">
            <h3 className="text-xs font-bold text-on-surface-variant uppercase tracking-wider">Original Description</h3>
            {ticket.order_id && (
              <span className="text-xs font-mono font-bold text-tertiary bg-surface-container-highest px-2 py-0.5 rounded">
                Linked Order: #{ticket.order_id}
              </span>
            )}
          </div>
          <p className="text-on-surface whitespace-pre-wrap">{ticket.description}</p>
        </div>

        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {ticket.messages.length === 0 ? (
            <div className="text-center text-on-surface-variant text-sm">No replies yet.</div>
          ) : (
            ticket.messages.map((msg) => {
              const isAdmin = msg.sender_role === 'admin';
              return (
                <div key={msg.message_id} className={`flex flex-col ${isAdmin ? 'items-end' : 'items-start'}`}>
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-xs font-bold text-on-surface-variant">{isAdmin ? 'Admin' : msg.sender_name}</span>
                    <span className="text-[10px] text-on-surface-variant/70">
                      {new Date(msg.created_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                    </span>
                  </div>
                  <div className={`max-w-[80%] rounded-2xl px-5 py-3 ${isAdmin ? 'bg-primary text-on-primary rounded-tr-sm' : 'bg-surface-container-highest text-on-surface rounded-tl-sm border border-outline-variant/20'}`}>
                    <p className="whitespace-pre-wrap">{msg.message}</p>
                  </div>
                </div>
              );
            })
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Reply Box */}
        {ticket.status !== 'closed' && ticket.status !== 'resolved' ? (
          <form onSubmit={handleSendMessage} className="p-4 bg-surface-container-lowest border-t border-outline-variant/30 flex gap-4">
            <input 
              type="text" 
              value={newMessage}
              onChange={(e) => setNewMessage(e.target.value)}
              placeholder="Type your reply..."
              className="flex-1 bg-surface-container-highest border border-outline-variant/50 rounded-xl px-4 py-3 text-on-surface focus:outline-none focus:border-primary transition-colors"
            />
            <button 
              type="submit" 
              disabled={isSending || !newMessage.trim()}
              className="bg-primary text-on-primary px-6 py-3 rounded-xl font-bold shadow-lg hover:-translate-y-0.5 transition-transform disabled:opacity-50 disabled:hover:translate-y-0"
            >
              Send
            </button>
          </form>
        ) : (
          <div className="p-4 bg-surface-container-lowest border-t border-outline-variant/30 text-center text-sm text-on-surface-variant font-semibold">
            This ticket is {ticket.status.replace('_', ' ')}. Replies are disabled.
          </div>
        )}
      </div>
    </div>
  );
};

export default TicketDetail;
