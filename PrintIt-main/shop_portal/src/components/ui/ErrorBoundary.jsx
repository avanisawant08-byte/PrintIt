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
    console.error('ErrorBoundary caught error:', error, errorInfo);
  }

  handleReload = () => {
    window.location.reload();
  };

  handleReset = () => {
    this.setState({ hasError: false, error: null });
    window.location.href = '/dashboard/queue';
  };

  render() {
    if (this.state.hasError) {
      return (
        <div
          role="alert"
          className="min-h-screen bg-background text-on-background flex items-center justify-center p-6"
        >
          <div className="max-w-md w-full bg-surface-container border border-outline-variant/30 rounded-2xl p-8 text-center shadow-2xl">
            <div className="w-16 h-16 rounded-2xl bg-error/20 text-error flex items-center justify-center mx-auto mb-6">
              <span className="material-symbols-outlined text-4xl">dns</span>
            </div>
            <h1 className="text-2xl font-bold text-on-surface mb-2 font-display-lg">
              Application Error (500)
            </h1>
            <p className="text-sm text-on-surface-variant mb-6 leading-relaxed">
              We encountered an unexpected problem rendering this view. Your session and data are secure.
            </p>
            <div className="flex flex-col sm:flex-row gap-3 justify-center">
              <button
                onClick={this.handleReload}
                className="px-5 py-2.5 rounded-xl bg-primary text-on-primary font-medium text-sm hover:opacity-90 transition-opacity"
              >
                Reload Page
              </button>
              <button
                onClick={this.handleReset}
                className="px-5 py-2.5 rounded-xl bg-surface-container-highest border border-outline-variant text-on-surface text-sm font-medium hover:bg-surface-variant transition-colors"
              >
                Return to Queue
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
