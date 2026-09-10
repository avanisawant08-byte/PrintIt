# PrintIt — Single Image Repeat Layout
## Product Requirements Document (PRD)

**Status:** Approved · **Owner:** Product & Engineering · **Version:** 1.0

---

## 1. Overview & Objective

When customers upload a single image (a photo, sticker design, ID/passport photo, graphic, or badge), they often want multiple copies of that same image printed together on a single sheet of paper (e.g., 2-in-1, 4-in-1, 6-in-1, or 8-in-1) rather than a single copy centered on a large blank page.

This document specifies the streamlined customer flow in the PrintIt Customer App for repeating a single photo across the chosen sheet layout.

---

## 2. Core User Experience

### 2.1 Placement in Existing Flow
- Located directly inside the **Document Configuration Screen** (`document_config_screen.dart`), right where the user selects **`PAGES / SHEET`** (`1`, `2`, `4`, `6`).
- When a single-image file is uploaded and a multi-up layout is selected (`pagesPerSheet > 1`), a simple toggle / checkbox appears:
  > **`[✓] Repeat photo across sheet`**
- Default state: **Ticked [✓]** when a single photo is selected with multi-up layout (or easily toggled off if the customer wants a single image in quadrant 1).

### 2.2 Live Visual Preview
- When the toggle is checked, the **`LiveFilePreview`** component dynamically repeats the single uploaded photo across all active grid cells:
  - **1 per sheet**: 1 single photo centered.
  - **2 per sheet**: 2 copies tiled side-by-side or stacked.
  - **4 per sheet**: 4 copies tiled in a 2×2 grid.
  - **6 per sheet**: 6 copies tiled in a 2×3 grid.
- Customer sees the exact sheet preview in real-time before placing the order.

---

## 3. Pricing Model

- **Standard Sheet Pricing**: Standard print-shop pricing applies per sheet of paper.
- There are **no complex per-photo or per-copy surcharge calculations**. The order price is simply based on the number of paper sheets printed, print color (B&W vs Color), and selected paper type.

---

## 4. Technical Requirements

### 4.1 Client-Side (Flutter App)
1. **Order State (`order_provider.dart`)**:
   - Add `repeatImageOnGrid: bool` (default: `true` for single images when `pagesPerPaper > 1`).
   - Expose `setRepeatImageOnGrid(bool)` notifier method.
2. **Document Configuration UI (`document_config_screen.dart`)**:
   - Display the repeat toggle directly adjacent to the `PAGES / SHEET` selection bar when the active file is a single image.
3. **Live File Preview (`live_file_preview.dart`)**:
   - For image files, if `repeatImageOnGrid == true` and `pagesPerPaper > 1`, render the image across all `pagesPerPaper` grid slots.

### 4.2 Backend & Shop Processing
- Pass `repeat_layout: true` in the order item print configuration metadata.
- When generating the final print PDF for the shop printer, repeat the source image into the PDF grid layout so the shop receives the exact tiled page ready for physical printing.

---

## 5. Summary of Key Decisions

| Requirement | Specification |
| :--- | :--- |
| **Trigger** | Single photo upload + selecting 2, 4, or 6 pages per sheet |
| **Control** | Simple toggle: `[✓] Repeat photo across sheet` |
| **Pricing** | Standard per-sheet paper charge (no extra fees) |
| **Cut Guides / Lines** | Off by default (clean, even padding between copies) |
| **Scope** | Any single image/photo file (PNG, JPG, WEBP) |
