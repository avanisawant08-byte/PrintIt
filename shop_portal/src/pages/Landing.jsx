import React from 'react';
import { useNavigate } from 'react-router-dom';

const Landing = () => {
  const navigate = useNavigate();

  return (
    <div className="flex-1 flex items-center justify-center min-h-[70vh]">
      <div className="max-w-[600px] text-center p-8 bg-surface-container rounded-xl border border-outline-variant/30">
        <h1 className="font-display-lg text-[3rem] font-extrabold mb-4 text-transparent bg-clip-text bg-gradient-to-br from-tertiary to-primary">
          Partner Portal
        </h1>
        <p className="text-on-surface-variant text-[1.1rem] leading-relaxed mb-8">
          Manage your print queue, set your pricing rules, and track your revenue all in one place.
        </p>
        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <button 
            onClick={() => navigate('/login')}
            className="bg-primary text-on-primary font-label-md px-8 py-4 rounded-xl shadow-lg hover:-translate-y-1 transition-transform"
          >
            Sign In
          </button>
          <button 
            onClick={() => navigate('/register')}
            className="bg-surface-container-highest text-on-surface border border-outline-variant hover:bg-surface-variant font-label-md px-8 py-4 rounded-xl transition-colors"
          >
            Register New Shop
          </button>
        </div>
      </div>
    </div>
  );
};

export default Landing;
