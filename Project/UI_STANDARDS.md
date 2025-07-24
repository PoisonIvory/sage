# UI_STANDARDS.md — Vocal Trend Dashboard

**Purpose:**  
This document defines the UI/UX standards for the Sage vocal trend dashboard, drawing inspiration from Co–Star’s minimalist, content-centric design, Apple’s Human Interface Guidelines, and Sage’s unique brand ethos.  
**All design, code, and documentation must reference these standards.**

---

## 1. Visual Hierarchy & Layout

- **Content-Centric Layout:**  
  - Use clear sectioning for each data component (`SpeechChart`, `ProgressRing`, `InsightCard`).
  - Separate sections with consistent padding and a grid, not decorative dividers.
  - Use whitespace and simple card containers (rounded corners, Fog White background) for breathable separation.
- **Hierarchy:**  
  - Prioritize data visualizations and insights over navigation or controls.
  - Place navigation icons subtly in corners; keep data at center stage.
  - Most important metric/insight at the top; supportive data below in logical order.
- **Alignment & Flow:**  
  - Use left/system-aligned text and elements for legibility.
  - Follow a consistent alignment grid for all sections.
  - Each section: title, content/chart, caption.
- **Responsive Cards:**  
  - Present each major content piece as a SwiftUI card with generous margin.
  - Cards provide containment without heavy borders, aligning with Sage’s soft, circular aesthetic.

**AI Guidance:**  
When generating SwiftUI layouts, use card-based sections, consistent padding, and prioritize data visualizations. Reference this section for layout and hierarchy.

---

## 2. Typography & Whitespace

- **System Fonts & Dynamic Type:**  
  - Use iOS system font (San Francisco) for all body/UI text.
  - Custom fonts (if any) only for large titles or decorative use; must support accessibility.
  - All text must scale with Dynamic Type.
- **Hierarchy via Font Styles:**  
  - Use Title/Headline for section headers, Body/Callout for labels/insights.
  - Emphasize key data points with heavier weight or larger size.
  - Consistent text styles for immediate distinction between titles and details.
- **Whitespace & Line Spacing:**  
  - Generous whitespace around text and charts.
  - Comfortable line heights, especially for paragraphs.
  - No element should feel crowded.
- **Avoid Centered Body Text:**  
  - Left-align all body text and data labels.
  - Center only short titles or numbers within their containers.

**AI Guidance:**  
When generating text or SwiftUI views, use system font styles, left-align body text, and ensure Dynamic Type support. Reference this section for typography and spacing.

---

## 2. Design System Usage (Required)

All new SwiftUI Views **must** use the shared design system components in `Sage/DesignSystem/` for:
- Colors (`SageColors`)
- Typography (`SageTypography`)
- Spacing (`SageSpacing`)
- Buttons (`SageButton`)
- Cards (`SageCard`)
- Section headers (`SageSectionHeader`)
- Avatars (`SageAvatar`)
- Dividers (`SageDivider`)

**Do not hardcode colors, fonts, or spacing in View files.**  
**Always import and use the design system for consistency and maintainability.**

> **AI Guidance:**  
> When generating or refactoring any View, always use the components from `Sage/DesignSystem/`.  
> If a new UI pattern is needed, first extend the design system, then use it in your View.

**Example:**
```swift
SageCard {
    SageSectionHeader(title: "Profile")
    Text("Name: ...").font(SageTypography.body)
}
```

---

## 3. Color & Iconography

- **Brand Palette (Light Mode):**  
  - Fog White: primary background.
  - Sage Teal: primary accent (interactive elements, chart highlights).
  - Coral Blush: secondary accent (feedback, secondary highlights).
  - Earth Clay: neutrals (grid lines, icons).
  - All colors must meet WCAG AA contrast.
- **Semantic Color Use:**  
  - Use color for meaning, not decoration.
  - Each color must have a semantic role (e.g., Sage Teal = pitch, Coral Blush = shimmer).
  - Never rely on color alone for critical info—use labels, icons, or patterns as well.
- **Icons & Symbols:**  
  - Use SF Symbols for consistency.
  - Prefer circular, line-based icons.
  - Icons should be monochromatic (Sage Teal or Earth Clay) and supplement text.
- **Data Visualization Colors:**  
  - Use muted brand colors for chart lines/fills.
  - Grid lines/axes in Earth Clay or light gray.
  - Test all colors for clarity in various lighting.

**AI Guidance:**  
When generating color schemes or icons, use the brand palette and semantic roles. Ensure all color use is accessible and meaningful. Reference this section for color and iconography.

---

## 4. Motion & Micro-Interactions

- **Subtle Animations:**  
  - Use gentle, meaningful animations (e.g., line graph interpolation, progress ring fill).
  - Animations should be quick, consistent, and use easing curves (e.g., ease-out, 0.3s).
  - All motion must support Reduce Motion accessibility setting.
- **Avoid Flashy Effects:**  
  - No bouncy, long, or distracting animations.
  - Use fade-ins, crossfades, or subtle pulses for status/feedback.
- **Micro-Interactions:**  
  - Expandable cards use smooth spring animation.
  - Subtle haptic feedback for key actions (e.g., recording complete).
  - All micro-interactions must feel intentional and calm.

**AI Guidance:**  
When generating SwiftUI animations, keep them subtle, quick, and accessible. Reference this section for motion and micro-interaction standards.

---

## 5. Accessibility & Privacy

- **Dynamic Type:**  
  - All text must support Dynamic Type and adapt layout for large sizes.
- **Color Contrast:**  
  - All text and UI elements must meet at least WCAG AA contrast.
  - Support iOS “Increase Contrast” setting.
- **VoiceOver:**  
  - All charts and cards must have descriptive accessibility labels/hints.
  - All tappable elements must have accessible traits and labels.
- **HIPAA-Compliant UI:**  
  - No PII on dashboard.
  - Blur/hide sensitive data in app switcher.
  - Warn users before sharing/screenshotting sensitive data.
  - Use neutral, non-stigmatizing language and visuals.

**AI Guidance:**  
When generating UI code, always include accessibility modifiers, test for contrast, and ensure privacy by design. Reference this section for accessibility and privacy.

---

## 6. Emotional Tone & Brand Alignment

- **Calm, scientific, feminine, circular, and breathable.**
- **Minimal visuals, focus on content, respect for user exploration.**
- **Light color palette, spacious layout, rounded corners, and smooth animations.**
- **Objective and data-driven, but inviting and empathetic.**

**AI Guidance:**  
When generating UI/UX, always align with Sage’s brand ethos and emotional tone. Reference this section for brand alignment.

---

## 7. Sources & References

- Apple Human Interface Guidelines – Typography, Color, Animation, Accessibility
- Co–Star App Design Analysis – Minimalist aesthetic and layout choices
- IXD@Pratt Design Critique of Co–Star – Hierarchy, spacing, and typography
- Medium Article on Co–Star’s Design – Visual tone and metaphysical content
- Apple UI Design Do’s and Don’ts – Accent color and font usage in branding
- Apple vs Material Design – Use of white space and visual hierarchy

---

## 3. Cross-References
- See [CONTRIBUTING.md](./CONTRIBUTING.md) for developer checklist
- See [PROMPTS.md](./PROMPTS.md) for AI prompt examples
- See [AI_GENERATION_RULES.md](./AI_GENERATION_RULES.md) for automated enforcement

---

## 8. Compliance Checklist

- [ ] All layouts use card-based sections, consistent padding, and prioritize data.
- [ ] All text uses system font styles, left-aligned, and supports Dynamic Type.
- [ ] All color use is semantic, accessible, and brand-aligned.
- [ ] All icons are SF Symbols, circular/line-based, and supplement text.
- [ ] All animations are subtle, quick, and accessible.
- [ ] All UI is accessible (Dynamic Type, VoiceOver, color contrast).
- [ ] No PII is shown on dashboard; privacy is respected.
- [ ] All UI/UX aligns with Sage’s brand and emotional tone.

---

**AI Guidance:**  
When generating or updating UI/UX code, always reference this document, the Feedback Log in `DATA_STANDARDS.md`, and `CHANGELOG.md` for the latest standards and requirements.

---

**End of UI_STANDARDS.md**  
