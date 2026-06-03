# Desktop Login Revamp — Split Panel Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the desktop login screen a proper split-panel layout — emerald brand panel on the left, clean inline form on the right — without touching the mobile path at all.

**Architecture:** One new widget (`DesktopLoginBrandPanel`), desktop branches added to `LoginForm` and `LoginOtp`, and a desktop `Scaffold` branch in `LoginScreen`. All existing mobile code paths are wrapped in `else` blocks and remain identical. No BLoC changes.

**Tech Stack:** Flutter, flutter_bloc, flutter_animate, existing `AmanaPosLogoMark`, `AppButton`, `PhoneNumberField`, `OTPInputSquare`, `AppTextStyles`, `AppColors`

---

## File Map

| Action | File |
|---|---|
| Create | `lib/features/login/presentation/widgets/desktop_login_brand_panel.dart` |
| Modify | `lib/features/login/presentation/login_screen.dart` |
| Modify | `lib/features/login/presentation/widgets/login_form.dart` |
| Modify | `lib/features/login/presentation/widgets/login_otp.dart` |
| Create | `test/features/login/presentation/widgets/desktop_login_brand_panel_test.dart` |

---

### Task 1: `DesktopLoginBrandPanel`

**Files:**
- Create: `lib/features/login/presentation/widgets/desktop_login_brand_panel.dart`
- Create: `test/features/login/presentation/widgets/desktop_login_brand_panel_test.dart`

Static widget — no BLoC. Emerald gradient left panel with logo mark, headline, subline, and feature badges.

- [ ] **Step 1: Write the failing test**

Create `test/features/login/presentation/widgets/desktop_login_brand_panel_test.dart`:

```dart
import 'package:amana_pos/features/login/presentation/widgets/desktop_login_brand_panel.dart';
import 'package:amana_pos/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DesktopLoginBrandPanel renders without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: DesktopLoginBrandPanel()),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(DesktopLoginBrandPanel), findsOneWidget);
  });

  testWidgets('DesktopLoginBrandPanel shows feature badges', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Row(
            children: [
              Expanded(child: DesktopLoginBrandPanel()),
            ],
          ),
        ),
      ),
    );

    // Three feature badges must be present
    expect(find.text('Offline-ready'), findsOneWidget);
    expect(find.text('Multi-branch'), findsOneWidget);
    expect(find.text('Secure'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to confirm it fails**

```bash
flutter test test/features/login/presentation/widgets/desktop_login_brand_panel_test.dart
```

Expected: FAIL — file does not exist yet.

- [ ] **Step 3: Create `lib/features/login/presentation/widgets/desktop_login_brand_panel.dart`**

```dart
import 'package:amana_pos/theme/app_spacing.dart';
import 'package:amana_pos/theme/app_text_styles.dart';
import 'package:amana_pos/widgets/amana_logo.dart';
import 'package:flutter/material.dart';

class DesktopLoginBrandPanel extends StatelessWidget {
  const DesktopLoginBrandPanel({super.key});

  static const Color _gradientTop = Color(0xFF0F766E);
  static const Color _gradientBottom = Color(0xFF0a4f49);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientTop, _gradientBottom],
          stops: [0.0, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glow overlays
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, 0.9),
                  radius: 1.1,
                  colors: [
                    const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.8),
                  radius: 0.7,
                  colors: [
                    Colors.white.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDims.s8,
              vertical: AppDims.s8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo mark + wordmark
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AmanaPosLogoMark(size: 42, isInAppBar: true),
                    const SizedBox(width: AppDims.s3),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'AmanaPOS',
                          style: AppTextStyles.bs600(context).copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Point of Sale Platform',
                          style: AppTextStyles.sm100(context).copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Headline
                Text(
                  'The smarter way\nto run your shop.',
                  style: AppTextStyles.lg200(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.18,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: AppDims.s3),

                // Subline
                Text(
                  'Real-time inventory, multi-branch\nmanagement, and instant receipts.',
                  style: AppTextStyles.bs300(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.60),
                    height: 1.55,
                  ),
                ),

                const SizedBox(height: AppDims.s6),

                // Feature badges
                Wrap(
                  spacing: AppDims.s2,
                  runSpacing: AppDims.s2,
                  children: const [
                    _Badge(icon: '⚡', label: 'Offline-ready'),
                    _Badge(icon: '🌐', label: 'Multi-branch'),
                    _Badge(icon: '🔐', label: 'Secure'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDims.s3,
          vertical: AppDims.s1 + 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.sm100(context).copyWith(
                color: Colors.white.withValues(alpha: 0.80),
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Note:** `AppDims.s8` = 32px (confirmed in `app_spacing.dart`). The headline gap uses `const SizedBox(height: 40)` directly since `AppDims.s10` does not exist.

- [ ] **Step 4: Run test**

```bash
flutter test test/features/login/presentation/widgets/desktop_login_brand_panel_test.dart
```

Expected: PASS — both tests green. If `AppDims.s8`/`AppDims.s10` don't exist, replace with `const SizedBox(height: 32)` / `const SizedBox(height: 40)` and re-run.

- [ ] **Step 5: Commit**

```bash
git add lib/features/login/presentation/widgets/desktop_login_brand_panel.dart \
        test/features/login/presentation/widgets/desktop_login_brand_panel_test.dart
git commit -m "feat(desktop-login): add DesktopLoginBrandPanel — emerald split panel"
```

---

### Task 2: Desktop layout in `LoginForm`

**Files:**
- Modify: `lib/features/login/presentation/widgets/login_form.dart`

Add a `context.isDesktop` branch inside `_LoginFormState.build()`. The desktop branch renders an inline column (no Expanded/bottom-pinned button). Mobile branch is untouched.

- [ ] **Step 1: Add the import for `responsive.dart`**

Open `lib/features/login/presentation/widgets/login_form.dart`. Add after existing imports:

```dart
import 'package:amana_pos/core/responsive/responsive.dart';
```

- [ ] **Step 2: Add the desktop branch inside `BlocBuilder.builder`**

The current `return Column(children: [...])` in `_LoginFormState.build()` starts after `final hasError = state.mobileError != null;`. Wrap the existing `return Column(...)` in an `if (!context.isDesktop)` and add a desktop branch above it:

```dart
// ── Desktop: inline column, no bottom-pinned button ──────────────────────
if (context.isDesktop) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr.loginWelcomeTitle,
            style: AppTextStyles.lg100(context,
                weight: AppTextStyles.extraBold,
                color: colors.textPrimary),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            tr.loginSubtitle,
            style: AppTextStyles.bs400(context,
                color: colors.textSecondary),
          ),

          const SizedBox(height: AppSpacing.xxl),

          Text(
            tr.loginMobileLabel,
            style: AppTextStyles.bs600(context,
                weight: AppTextStyles.semibold,
                color: colors.textSecondary),
          ),

          const SizedBox(height: AppSpacing.xs),

          PhoneNumberField(
            controller: _phoneController,
            focusNode: _focus,
            error: hasError,
            onCompleted: (_) => context
                .read<LoginBloc>()
                .add(OnLoginSubmitEvent()),
          ),

          SizedBox(
            height: 28,
            child: hasError
                ? Row(
                    children: [
                      Icon(Icons.error_outline,
                          size: 14, color: colors.danger),
                      const SizedBox(width: 4),
                      Text(
                        state.mobileError!,
                        style: AppTextStyles.sm200(context,
                            weight: AppTextStyles.semibold,
                            color: colors.danger),
                      ),
                    ],
                  ).animate().shake(hz: 4, duration: 400.ms)
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.md),

          AppButton.wide(
            label: tr.loginContinue,
            onPressed: state.isMobileValid
                ? () => context
                    .read<LoginBloc>()
                    .add(OnLoginSubmitEvent())
                : null,
            isLoading: state.isLoading,
          ),

          const SizedBox(height: AppSpacing.sm),

          Text.rich(
            TextSpan(
              style: AppTextStyles.bs300(context,
                  color: colors.textHint),
              children: [
                TextSpan(text: tr.loginTermsPrefix),
                TextSpan(
                  text: tr.loginTermsLink,
                  style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600),
                ),
                TextSpan(text: tr.loginTermsSeparator),
                TextSpan(
                  text: tr.loginPrivacyLink,
                  style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
// ── Mobile: existing layout unchanged ────────────────────────────────────
return Column(
  children: [
    // ... existing code stays exactly as-is
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all 18 existing tests still pass. Fix any failures.

- [ ] **Step 4: Commit**

```bash
git add lib/features/login/presentation/widgets/login_form.dart
git commit -m "feat(desktop-login): add desktop inline layout to LoginForm"
```

---

### Task 3: Desktop layout in `LoginOtp`

**Files:**
- Modify: `lib/features/login/presentation/widgets/login_otp.dart`

Add a `context.isDesktop` branch inside the `BlocBuilder.builder`. Desktop: inline column, "← Change number" text link instead of the AppBar back button, no bottom-pinned button. Mobile untouched.

- [ ] **Step 1: Add the import**

Open `lib/features/login/presentation/widgets/login_otp.dart`. Add after existing imports:

```dart
import 'package:amana_pos/core/responsive/responsive.dart';
```

- [ ] **Step 2: Add the desktop branch**

After `final filled = (state.otp ?? '').length == 6;`, add the desktop branch before the existing `return Column(...)`:

```dart
// ── Desktop: inline column, no bottom-pinned button ──────────────────────
if (context.isDesktop) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: AppRadius.borderLg,
            ),
            child: Icon(
              Icons.shield_outlined,
              color: colors.primary,
              size: 24,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            tr.otpTitle,
            style: AppTextStyles.lg100(
              context,
              weight: AppTextStyles.extraBold,
              color: colors.textPrimary,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text.rich(
            TextSpan(
              style: AppTextStyles.bs400(context,
                  color: colors.textSecondary),
              children: [
                TextSpan(text: tr.otpSentPrefix),
                TextSpan(
                  text: '+249 ${state.phoneNumber ?? ''}  ',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: AppTextStyles.bold,
                    color: colors.textPrimary,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () => context
                        .read<LoginBloc>()
                        .add(const OnResetEvent(isPhoneChange: true)),
                    child: Text(
                      tr.otpChange,
                      style: AppTextStyles.bs400(
                        context,
                        weight: AppTextStyles.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          OTPInputSquare(
            state: state.otp ?? '',
            is6Digit: true,
            hasError: state.otpError != null,
            isLoading: state.isLoading,
            isOTPMatched: state.isPinMatched,
            onChanged: (code) => context
                .read<LoginBloc>()
                .add(OnChangeOtpEvent(otpCode: code)),
            onCompleted: () =>
                context.read<LoginBloc>().add(OnSubmitOtpEvent()),
          ),

          SizedBox(
            height: 36,
            child: state.otpError != null
                ? _StatusBanner(
                    message: state.otpError!,
                    isError: true,
                  ).animate().fadeIn(duration: 200.ms)
                : state.isPinMatched
                    ? _StatusBanner(
                        message: tr.otpVerifiedSigningIn,
                        isError: false,
                      )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.2, end: 0)
                    : const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.lg),

          Center(
            child: state.otpResendSeconds > 0
                ? Text.rich(
                    TextSpan(
                      style: AppTextStyles.sm300(
                          context,
                          color: colors.textSecondary),
                      children: [
                        TextSpan(text: tr.otpResendIn),
                        TextSpan(
                          text: '0:${state.otpResendSeconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontWeight: AppTextStyles.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                : TextButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context
                            .read<LoginBloc>()
                            .add(const OnResendOtpEvent()),
                    icon: Icon(Icons.refresh,
                        size: 16, color: colors.primary),
                    label: Text(
                      tr.otpResendButton,
                      style: AppTextStyles.sm300(
                        context,
                        weight: AppTextStyles.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: AppSpacing.xl),

          AppButton.wide(
            label: state.isPinMatched
                ? tr.otpVerifiedButton
                : tr.otpVerifyButton,
            onPressed: (filled && !state.isLoading && !state.isPinMatched)
                ? () => context
                    .read<LoginBloc>()
                    .add(OnSubmitOtpEvent())
                : null,
            isLoading: state.isLoading,
            suffixIcon: state.isPinMatched
                ? const Icon(Icons.check_rounded,
                    size: 20, color: Colors.white)
                : const Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}
// ── Mobile: existing layout unchanged ────────────────────────────────────
return Column(
  children: [
    // ... existing code stays exactly as-is
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all 18 tests pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/login/presentation/widgets/login_otp.dart
git commit -m "feat(desktop-login): add desktop inline layout to LoginOtp"
```

---

### Task 4: Desktop `Scaffold` branch in `LoginScreen`

**Files:**
- Modify: `lib/features/login/presentation/login_screen.dart`

Replace the entire `return Scaffold(...)` in `_LoginScreenState.build()` with a desktop-first branch that renders the split panel, falling back to the existing mobile `Scaffold`.

- [ ] **Step 1: Add imports**

Open `lib/features/login/presentation/login_screen.dart`. Add after existing imports:

```dart
import 'package:amana_pos/core/responsive/responsive.dart';
import 'package:amana_pos/features/login/presentation/widgets/desktop_login_brand_panel.dart';
```

- [ ] **Step 2: Replace `return Scaffold(...)` with the desktop branch**

Find the line `return Scaffold(` inside `_LoginScreenState.build()` (inside the `BlocConsumer.builder`). Replace the entire `return Scaffold(...)` block (everything from `return Scaffold(` through the matching `);`) with:

```dart
// ── Desktop: split-panel layout ──────────────────────────────────────────
if (context.isDesktop) {
  return Scaffold(
    backgroundColor: context.appColors.background,
    body: Row(
      children: [
        // Brand panel — 42% width
        Expanded(
          flex: 42,
          child: const DesktopLoginBrandPanel(),
        ),
        // Form panel — 58% width
        Expanded(
          flex: 58,
          child: ColoredBox(
            color: context.appColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pages.length,
                  itemBuilder: (_, i) => pages[i],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// ── Mobile: existing Scaffold unchanged ──────────────────────────────────
return Scaffold(
  extendBodyBehindAppBar: true,
  extendBody: true,
  resizeToAvoidBottomInset: true,
  appBar: AppBar(
    // ... rest of existing Scaffold as-is
```

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: all 18 tests still pass.

- [ ] **Step 4: Build for macOS to catch any compile errors**

```bash
flutter build macos --debug 2>&1 | tail -5
```

Expected: `✓ Built build/macos/Build/Products/Debug/amana_pos.app`

- [ ] **Step 5: Commit**

```bash
git add lib/features/login/presentation/login_screen.dart
git commit -m "feat(desktop-login): split-panel Scaffold on desktop, mobile unchanged"
```

---

### Task 5: Smoke test

- [ ] **Step 1: Run on macOS**

```bash
flutter run -d macos
```

Navigate to the login screen and verify:

- [ ] Left panel fills ~42% of width with emerald gradient, logo mark + "AmanaPOS" wordmark, headline, subline, and 3 feature badges
- [ ] Right panel is white/background, shows centered phone number form (max 400px wide), button is inline below the field (not pinned at bottom)
- [ ] Entering a valid phone number and tapping Continue transitions to OTP step — left panel stays fixed, right panel shows OTP form
- [ ] "Change number" link in OTP step navigates back to phone step
- [ ] No AppBar, no page dots visible on desktop

- [ ] **Step 2: Verify mobile is unchanged**

```bash
flutter run -d <ios-simulator-or-android>
```

- [ ] Login screen shows the original AppBar with page dots + grid background
- [ ] Form is full-width with logo at top, button pinned at bottom
- [ ] OTP step has back button in AppBar

- [ ] **Step 3: Commit any smoke-test fixes**

```bash
git add lib/features/login/presentation/login_screen.dart \
        lib/features/login/presentation/widgets/login_form.dart \
        lib/features/login/presentation/widgets/login_otp.dart \
        lib/features/login/presentation/widgets/desktop_login_brand_panel.dart
git commit -m "fix(desktop-login): smoke-test adjustments"
```
