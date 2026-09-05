import React from 'react';

const ErrorState = ({
  title = 'Failed to load administrative data',
  message = 'An unexpected server error occurred.',
  onRetry,
}) => {
  return (
    <div
      role="alert"
      className="flex flex-col items-center justify-center p-8 text-center rounded-2xl bg-error-container/20 border border-error/30 max-w-lg mx-auto my-6"
    >
      <div className="w-14 h-14 rounded-2xl bg-error/20 flex items-center justify-center text-error mb-4">
        <span className="material-symbols-outlined text-3xl">error_outline</span>
      </div>
      <h3 className="text-lg font-bold text-on-surface mb-2">{title}</h3>
      <p className="text-sm text-on-surface-variant max-w-sm mb-6 leading-relaxed">
        {message}
      </p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-surface-container-highest border border-outline-variant hover:bg-surface-variant text-on-surface text-sm font-medium transition-colors"
        >
          <span className="material-symbols-outlined text-base">refresh</span>
          <span>Retry Operation</span>
        </button>
      )}
    </div>
  );
};

export default ErrorState;
