import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import api from '../../core/api';

const TicketList = () => {
  const [tickets, setTickets] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    fetchTickets();
  }, []);

  const fetchTickets = async () => {
    try {
      const res = await api.get('/support/tickets');
      setTickets(res.data);
    } catch (err) {
      setError(err.response?.data?.error || err.message);
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch(status) {
      case 'open': return 'bg-error-container text-on-error-container border-error/30';
      case 'in_progress': return 'bg-secondary-container text-on-secondary-container border-secondary/30';
      case 'resolved': return 'bg-green-500/20 text-green-400 border-green-500/30';
      case 'closed': return 'bg-surface-container-highest text-on-surface-variant border-outline-variant/50';
      default: return 'bg-surface-container text-on-surface';
    }
  };

  return (
    <div className="max-w-6xl mx-auto p-6 md:p-12 space-y-8">
      <div className="flex justify-between items-end">
        <div>
          <h2 className="text-3xl font-headline-lg font-bold text-primary mb-2">Support Tickets</h2>
          <p className="text-on-surface-variant font-body-md">Manage and resolve customer issues</p>
        </div>
      </div>

      {error && <div className="bg-error-container/20 text-error p-4 rounded-xl border border-error/30">{error}</div>}

      <div className="bg-surface-container-highest border border-outline-variant/30 rounded-2xl overflow-hidden shadow-xl">
        {isLoading ? (
          <div className="p-12 text-center text-on-surface-variant">Loading tickets...</div>
        ) : tickets.length === 0 ? (
          <div className="p-12 text-center text-on-surface-variant">No support tickets found.</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-surface-container-high border-b border-outline-variant/30 text-on-surface-variant text-sm uppercase tracking-wider">
                  <th className="p-4 font-semibold">Ticket ID</th>
                  <th className="p-4 font-semibold">Customer</th>
                  <th className="p-4 font-semibold">Subject</th>
                  <th className="p-4 font-semibold">Status</th>
                  <th className="p-4 font-semibold">Last Updated</th>
                  <th className="p-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-outline-variant/20">
                {tickets.map(ticket => (
                  <tr key={ticket.ticket_id} className="hover:bg-surface-container transition-colors group">
                    <td className="p-4 font-data-mono text-sm text-tertiary">#{ticket.ticket_id.toString().slice(-6)}</td>
                    <td className="p-4">
                      <div className="font-semibold text-on-surface">{ticket.customer_name}</div>
                      <div className="text-xs text-on-surface-variant">{ticket.customer_email}</div>
                    </td>
                    <td className="p-4">
                      <div className="font-medium text-on-surface">{ticket.subject}</div>
                      <div className="flex gap-2 items-center mt-1 flex-wrap">
                        {ticket.issue_type && (
                          <span className="text-[10px] bg-primary/10 text-primary border border-primary/20 px-2 py-0.5 rounded font-semibold">
                            {ticket.issue_type}
                          </span>
                        )}
                        {ticket.order_id && (
                          <span className="text-[10px] bg-surface-container-highest text-on-surface-variant border border-outline-variant/30 px-2 py-0.5 rounded font-mono">
                            Order: #{ticket.order_id}
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="p-4">
                      <span className={`px-3 py-1 rounded-full text-xs font-bold border ${getStatusColor(ticket.status)} uppercase tracking-wider`}>
                        {ticket.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td className="p-4 text-sm text-on-surface-variant">
                      {new Date(ticket.updated_at).toLocaleDateString()} {new Date(ticket.updated_at).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}
                    </td>
                    <td className="p-4 text-right">
                      <button 
                        onClick={() => navigate(`/dashboard/support/${ticket.ticket_id}`)}
                        className="text-primary hover:text-primary-fixed bg-primary/10 hover:bg-primary/20 px-4 py-2 rounded-lg text-sm font-semibold transition-colors"
                      >
                        View
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};

export default TicketList;
