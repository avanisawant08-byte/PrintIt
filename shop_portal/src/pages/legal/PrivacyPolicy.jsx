import React from 'react';
import { Link } from 'react-router-dom';

const PrivacyPolicy = () => {
  return (
    <div className="min-h-screen bg-background text-on-background py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-10 shadow-xl">
        <div className="flex items-center justify-between border-b border-outline-variant/20 pb-6 mb-8">
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-primary font-label-md">
              Legal Disclosure
            </span>
            <h1 className="text-3xl font-extrabold text-on-surface mt-1 font-display-lg">
              Privacy Policy
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
            <h2 className="text-lg font-bold text-on-surface mb-2">1. Overview</h2>
            <p>
              This Privacy Policy details how the <strong>PrintIt</strong> platform ("we", "our", or "the Platform") collects, processes, protects, and retains user personal data and uploaded digital documents when using the customer mobile app, web application, and vendor partner portals.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">2. Information We Collect</h2>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li><strong>Account Credentials:</strong> Full name, email address, mobile phone number, and encrypted password hash (Bcrypt).</li>
              <li><strong>Third-Party Authentication:</strong> Google account identifier (Firebase UID) and profile picture when authenticating via Google Sign-In.</li>
              <li><strong>Uploaded Documents:</strong> Digital PDF files, document page counts, print specifications (color, paper size, duplex, binding options).</li>
              <li><strong>Transaction Data:</strong> Razorpay payment identifiers, payment status, order references, and digital wallet balance ledger. We do not store raw debit/credit card numbers or CVVs on our servers.</li>
              <li><strong>Location Data:</strong> Device latitude and longitude coordinates submitted during shop discovery to calculate real-time distance to nearby print shops.</li>
              <li><strong>Device & Notifications:</strong> Firebase Cloud Messaging (FCM) push notification tokens to deliver live order status alerts.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">3. Document Storage & Automated 48-Hour Cleanup</h2>
            <p>
              Documents uploaded for printing are transmitted via TLS encryption and stored securely in Google Cloud Storage buckets with restricted access URLs.
            </p>
            <div className="mt-3 p-4 rounded-xl bg-surface-container-highest/60 border border-primary/20 text-on-surface">
              <strong>Automated File Deletion Protocol:</strong> To safeguard your privacy, our automated background cleanup job runs daily and permanently deletes all underlying uploaded files for completed orders older than 48 hours.
            </div>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">4. Browser Storage & Zero Tracking</h2>
            <p>
              We do not use advertising trackers, third-party analytics pixels, or profiling cookies. We strictly utilize standard browser <code>localStorage</code> to store your JSON Web Token (JWT) session and active shop identifiers to keep you authenticated.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">5. Third-Party Service Providers</h2>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li><strong>Google Cloud Platform (GCS):</strong> Secure document object storage.</li>
              <li><strong>Firebase (Google LLC):</strong> Identity authentication (Google OAuth, Phone OTP) and Cloud Messaging push alerts.</li>
              <li><strong>Razorpay:</strong> Secure payment gateway processing compliant with PCI-DSS.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">6. User Rights & Account Deletion</h2>
            <p>
              You have the right to access, edit, or permanently delete your account data at any time. Account deletion can be performed directly within the mobile application settings or partner portal settings, triggering complete purging and anonymization of personal identifiers.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">7. Contact & Support</h2>
            <p>
              For questions regarding privacy practices, contact our support team at <a href="mailto:support@printit.com" className="text-primary underline">support@printit.com</a> or raise an inquiry ticket through the in-app Support Center.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
};

export default PrivacyPolicy;
