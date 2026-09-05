import React from 'react';
import { Link } from 'react-router-dom';

const TermsOfService = () => {
  return (
    <div className="min-h-screen bg-background text-on-background py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto bg-surface-container border border-outline-variant/30 rounded-2xl p-6 sm:p-10 shadow-xl">
        <div className="flex items-center justify-between border-b border-outline-variant/20 pb-6 mb-8">
          <div>
            <span className="text-xs font-bold uppercase tracking-widest text-primary font-label-md">
              Legal Agreement
            </span>
            <h1 className="text-3xl font-extrabold text-on-surface mt-1 font-display-lg">
              Terms of Service
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
            <h2 className="text-lg font-bold text-on-surface mb-2">1. Acceptance of Terms</h2>
            <p>
              By accessing or using the <strong>PrintIt</strong> platform, whether as a customer placing print orders or as an affiliated shop partner operating a print vendor business, you agree to be bound by these Terms of Service.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">2. Services Provided</h2>
            <p>
              PrintIt provides a technology marketplace linking consumers with independent local print shops for document printing, binding, custom stationery sales, and in-person store collection. PrintIt acts as a digital intermediary facilitating ordering, live queue scheduling, payment capture, and fulfillment verification.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">3. User Responsibilities & Acceptable Use</h2>
            <p>
              You represent and warrant that you hold all necessary copyrights, authorizations, or legal rights to all documents and digital assets you upload. You agree not to upload:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mt-2">
              <li>Documents violating intellectual property, copyright, or trademark laws.</li>
              <li>Defamatory, obscene, unlawful, or sexually explicit materials.</li>
              <li>Files containing viruses, Trojan horses, ransomware, or malicious code.</li>
              <li>Forged identity documents, counterfeit securities, or fraudulent instruments.</li>
            </ul>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">4. Partner Vendor Obligations</h2>
            <p>
              Affiliated print shop owners agree to maintain accurate pricing matrices (black-and-white, color, binding options), observe operational opening and closing hours, and fulfill accepted print jobs diligently using standard commercial printing quality.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">5. Order Pickup & Verification</h2>
            <p>
              All print jobs are completed for in-store collection at the selected shop location. Customers verify order receipt by presenting their unique verification QR code to the shopkeeper upon collection. Orders not collected within 7 calendar days may be recycled by the vendor shop without refund liability.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">6. Limitation of Liability</h2>
            <p>
              PrintIt is not liable for typographical errors, formatting inconsistencies inherent to user-supplied source files, or machine breakdowns at independent vendor locations. Print errors caused by machine faults are resolved via the in-app support dispute mechanism.
            </p>
          </section>

          <section>
            <h2 className="text-lg font-bold text-on-surface mb-2">7. Governing Law</h2>
            <p>
              These Terms are governed by and construed in accordance with the laws of India. Any disputes arising out of platform transactions shall be subject to the exclusive jurisdiction of the competent courts in Maharashtra, India.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
};

export default TermsOfService;
