import React from 'react';

const EmptyState = ({
  icon = 'inbox',
  title = 'No items found',
  description = 'There are no records to display at this time.',
  actionText,
  onAction,
}) => {
  return (
    <div
      role="status"
      aria-live="polite"
      className="flex flex-col items-center justify-center p-8 sm:p-12 text-center rounded-2xl bg-surface-container/50 border border-outline-variant/30 max-w-lg mx-auto my-6"
    >
      <div className="w-16 h-16 rounded-2xl bg-surface-container-highest/80 flex items-center justify-center text-primary mb-4 shadow-inner">
        <span className="material-symbols-outlined text-3xl">{icon}</span>
      </div>
      <h3 className="text-xl font-bold text-on-surface mb-2">{title}</h3>
      <p className="text-sm text-on-surface-variant max-w-sm mb-6 leading-relaxed">
        {description}
      </p>
      {actionText && onAction && (
        <button
          onClick={onAction}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-on-primary font-medium text-sm hover:opacity-90 transition-opacity shadow-md"
        >
          <span>{actionText}</span>
          <span className="material-symbols-outlined text-base">arrow_forward</span>
        </button>
      )}
    </div>
  );
};

export default EmptyState;
