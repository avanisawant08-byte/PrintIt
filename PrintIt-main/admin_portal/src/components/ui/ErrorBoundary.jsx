import React, { Component } from 'react';

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Admin ErrorBoundary caught error:', error, errorInfo);
  }

  handleReload = () => {
    window.location.reload();
  };

  render() {
    if (this.state.hasError) {
      return (
        <div
          role="alert"
          className="min-h-screen bg-surface-dim text-on-surface flex items-center justify-center p-6 font-body-md"
        >
          <div className="max-w-md w-full bg-surface border border-outline-variant/30 rounded-2xl p-8 text-center shadow-2xl">
            <div className="w-16 h-16 rounded-2xl bg-error-container text-on-error-container flex items-center justify-center mx-auto mb-6">
              <span className="material-symbols-outlined text-4xl">admin_panel_settings</span>
            </div>
            <h1 className="text-2xl font-bold text-on-surface mb-2">
              Admin Console Error (500)
            </h1>
            <p className="text-sm text-on-surface-variant mb-6 leading-relaxed">
              An unhandled application exception occurred in the administrative workspace.
            </p>
            <div className="flex gap-3 justify-center">
              <button
                onClick={this.handleReload}
                className="px-5 py-2.5 rounded-xl bg-primary text-on-primary font-bold text-sm hover:opacity-90 transition-opacity"
              >
                Reload Console
              </button>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;
