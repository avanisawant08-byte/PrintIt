import React from 'react';
import { Link } from 'react-router-dom';

const AccessibilityStatement = () => {
  return (
    <div className="min-h-screen bg-background text-on-background py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-10 shadow-xl">
        <div className="flex items-center justify-between border-b border-outline-variant/20 pb-6 mb-8">
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-primary font-label-md">
              Accessibility
            </span>
            <h1 className="text-3xl font-extrabold text-on-surface mt-1 font-display-lg">
              Accessibility Statement
            </h1>
            <p className="text-xs text-on-surface-variant mt-1 font-label-md">
              Effective Date: January 1, 2026 | Platform Version: 1.0.0
            </p>
          </div>
          <Link
            to="/"
            className="px-4 py-2 rounded-xl bg-surface-container-highest border border-outline-variant text-xs text-on-surface hover:bg-surface-variant transition-colors flex items-center gap-1.5"
          >
            <span className="material-symbols-outlined text-sm">arrow_back</span>
            <span>Back</span>
          </Link>
        </div>

        <div className="space-y-8 text-sm text-on-surface-variant leading-relaxed">
          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">1. Our Commitment</h2>
            <p>
              PrintIt is dedicated to ensuring digital accessibility for all users, including individuals with visual, auditory, motor, or cognitive disabilities. We continually refine the user experience of our partner web portal and mobile app, applying relevant modern accessibility standards and design principles.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">2. Standards & Implemented Features</h2>
            <ul className="list-disc list-inside space-y-1.5 ml-2 mt-2">
              <li><strong>Semantic HTML Structure:</strong> Logical heading hierarchies, landmarks (<code>main</code>, <code>nav</code>, <code>header</code>), and descriptive element structures.</li>
              <li><strong>Keyboard Navigation:</strong> Interactive buttons, form fields, and modal dialogs are navigable using tab, enter, and escape key controls with visible focus rings.</li>
              <li><strong>High Contrast & Readability:</strong> High contrast color pairings designed to exceed 4.5:1 ratio for body copy across dark and light palettes.</li>
              <li><strong>Screen Reader Accessibility:</strong> Semantic ARIA roles (<code>role="alert"</code>, <code>role="status"</code>, <code>aria-live="polite"</code>) for dynamic queue updates and notification banners.</li>
              <li><strong>Touch Target Sizing:</strong> Mobile interactive elements maintain minimum target sizes of 48×48 dp for reliable activation.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">3. Feedback & Accessibility Inquiries</h2>
            <p>
              If you encounter any difficulty navigating or accessing content within our portals, please contact our support team at <a href="mailto:support@printit.com" className="text-primary underline">support@printit.com</a>. We take feedback seriously and work actively to implement remediation.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
};

export default AccessibilityStatement;
