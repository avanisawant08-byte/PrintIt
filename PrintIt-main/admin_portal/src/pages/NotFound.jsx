import React from 'react';
import { useNavigate, Link } from 'react-router-dom';

const NotFound = () => {
  const navigate = useNavigate();

  return (
    <main
      role="main"
      className="min-h-screen bg-surface-dim text-on-surface flex items-center justify-center p-6 font-body-md"
    >
      <div className="max-w-lg w-full bg-surface border border-outline-variant/30 rounded-2xl p-8 sm:p-12 text-center shadow-2xl">
        <div className="w-20 h-20 rounded-3xl bg-surface-container-highest text-primary flex items-center justify-center mx-auto mb-6">
          <span className="material-symbols-outlined text-5xl">manage_search</span>
        </div>
        <span className="text-xs uppercase tracking-widest font-bold text-primary mb-2 block font-label-md">
          Error 404
        </span>
        <h1 className="text-3xl font-extrabold text-on-surface mb-3">
          Admin Route Not Found
        </h1>
        <p className="text-sm text-on-surface-variant mb-8 leading-relaxed max-w-sm mx-auto">
          The administrative view you are looking for does not exist or has been relocated.
        </p>
        <div className="flex flex-col sm:flex-row gap-3 justify-center">
          <button
            onClick={() => navigate(-1)}
            className="px-6 py-3 rounded-xl bg-surface-container-highest border border-outline-variant text-on-surface text-sm font-medium hover:bg-surface-variant transition-colors flex items-center justify-center gap-2"
          >
            <span className="material-symbols-outlined text-base">arrow_back</span>
            <span>Go Back</span>
          </button>
          <Link
            to="/dashboard/payouts"
            className="px-6 py-3 rounded-xl bg-primary text-on-primary text-sm font-bold hover:opacity-90 transition-opacity flex items-center justify-center gap-2 shadow-lg"
          >
            <span className="material-symbols-outlined text-base">dashboard</span>
            <span>Admin Console</span>
          </Link>
        </div>
      </div>
    </main>
  );
};

export default NotFound;
