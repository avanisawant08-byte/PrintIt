import React from 'react';

const LoadingSkeleton = ({ count = 3 }) => {
  return (
    <div
      role="status"
      aria-live="polite"
      className="space-y-4 w-full animate-pulse my-4"
    >
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="p-5 rounded-2xl bg-surface-container/60 border border-outline-variant/20 flex flex-col gap-3"
        >
          <div className="flex items-center justify-between">
            <div className="h-5 bg-surface-container-highest rounded-md w-1/4"></div>
            <div className="h-6 bg-surface-container-highest rounded-full w-20"></div>
          </div>
          <div className="h-4 bg-surface-container-highest/60 rounded-md w-1/2"></div>
        </div>
      ))}
      <span className="sr-only">Loading administrative data...</span>
    </div>
  );
};

export default LoadingSkeleton;
