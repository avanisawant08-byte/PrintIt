import React from 'react';
import { Link } from 'react-router-dom';

const SecurityPolicy = () => {
  return (
    <div className="min-h-screen bg-background text-on-background py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-10 shadow-xl">
        <div className="flex items-center justify-between border-b border-outline-variant/20 pb-6 mb-8">
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-primary font-label-md">
              Platform Security
            </span>
            <h1 className="text-3xl font-extrabold text-on-surface mt-1 font-display-lg">
              Security & Responsible Disclosure
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
            <h2 className="text-lg font-bold text-on-surface mb-2">1. Security Architecture</h2>
            <p>
              The PrintIt platform is built on modern security practices to protect user data and documents:
            </p>
            <ul className="list-disc list-inside space-y-1.5 ml-2 mt-2">
              <li><strong>Encryption in Transit:</strong> All communications between clients, web portals, and API gateways are protected with modern TLS encryption (HTTPS/WSS).</li>
              <li><strong>Secure Credential Storage:</strong> Passwords are encrypted with Bcrypt cryptographic hashing using 10 salt rounds; plaintext passwords are never stored or logged.</li>
              <li><strong>Stateless Authentication:</strong> User sessions are managed via digitally signed JSON Web Tokens (JWT) with strict validity windows and role-based access checks (RBAC).</li>
              <li><strong>Security Headers:</strong> API responses are hardened using Helmet middleware to enforce Content Security Policies, clickjacking prevention, and MIME-type sniffing defense.</li>
              <li><strong>Short-lived Document Lifecycle:</strong> Automated daily cleanup purges all completed order document files older than 48 hours to minimize sensitive file exposure.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">2. Payment Security</h2>
            <p>
              All card, netbanking, and UPI transactions are executed via Razorpay's PCI-DSS Level 1 certified infrastructure. Razorpay webhook payloads and signatures are cryptographically verified using HMAC SHA-256 before crediting user wallets or processing print jobs.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">3. Responsible Vulnerability Disclosure</h2>
            <p>
              We welcome reports from independent security researchers and developers to help keep our platform safe. If you believe you have discovered a vulnerability:
            </p>
            <ul className="list-disc list-inside space-y-1.5 ml-2 mt-2">
              <li>Submit a detailed description of the vulnerability, including steps to reproduce, to <a href="mailto:security@printit.com" className="text-primary underline">security@printit.com</a> or <a href="mailto:printitsupport@gmail.com" className="text-primary underline">printitsupport@gmail.com</a>.</li>
              <li>Allow our engineering team reasonable time to investigate and remediate the issue before public disclosure.</li>
              <li>Do not attempt to access, modify, or destroy user data, or degrade platform availability (DoS/DDoS attacks are strictly prohibited).</li>
            </ul>
          </section>
        </div>
      </div>
    </div>
  );
};

export default SecurityPolicy;
