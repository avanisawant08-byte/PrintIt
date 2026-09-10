import React from 'react';
import { useTheme } from '../../context/ThemeContext';

const ThemeToggle = ({ className = '' }) => {
  const { theme, toggleTheme, isDark } = useTheme();

  return (
    <button
      onClick={toggleTheme}
      type="button"
      title={`Switch to ${isDark ? 'light' : 'dark'} mode`}
      aria-label="Toggle theme"
      className={`relative inline-flex items-center justify-center w-9 h-9 rounded-lg text-on-surface-variant hover:text-on-surface hover:bg-surface-container-high transition-colors cursor-pointer border border-outline-variant/40 shrink-0 ${className}`}
    >
      {isDark ? (
        <span className="material-symbols-outlined text-[20px] text-amber-300">
          light_mode
        </span>
      ) : (
        <span className="material-symbols-outlined text-[20px] text-slate-700">
          dark_mode
        </span>
      )}
    </button>
  );
};

export default ThemeToggle;
