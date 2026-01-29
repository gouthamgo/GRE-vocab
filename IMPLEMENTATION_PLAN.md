# GRE Vocab App - Implementation Plan

## Executive Summary

This document outlines the complete UX overhaul to transform the GRE Vocab app into a competitive, monetizable product that rivals Magoosh and other premium GRE prep solutions.

**Goal:** Increase user retention, engagement, and convert free users to paid subscribers.

**Timeline:** 10 major features across 3 phases

---

## Current State vs. Target State

| Feature | Current | Target |
|---------|---------|--------|
| Onboarding | 4 screens, generic | 6 screens, personalized with GRE date & placement quiz |
| Home Screen | Basic CTA | Score predictor, countdown, learning path |
| Session Complete | Simple stats | Tomorrow preview, urgency creation |
| Monetization | None | Freemium with paywall at Day 3 |
| Notifications | None | Smart push notification system |
| Score Tracking | None | GRE Verbal score predictor |

---

## Phase 1: Core Experience Improvements

### 1.1 Enhanced Onboarding Flow

**Files to modify:**
- `Views/OnboardingView.swift`
- `Models/UserProgress.swift`

**New screens:**
```
Screen 1: Problem (existing)
Screen 2: Solution (existing)
Screen 3: GRE Test Date Picker [NEW]
Screen 4: 5-Word Placement Quiz [NEW]
Screen 5: Personalized Daily Goal (enhanced)
Screen 6: Notification Permission [NEW]
```

**Data model additions:**
```swift
// UserProgress.swift
var greTestDate: Date?
var placementScore: Int = 0
var notificationsEnabled: Bool = false
var estimatedVerbalScore: Int = 145  // Starting estimate
```

---

### 1.2 GRE Test Date & Countdown

**Purpose:** Create urgency and enable personalized recommendations

**Implementation:**
```swift
// New computed properties in UserProgress
var daysUntilGRE: Int? {
    guard let testDate = greTestDate else { return nil }
    return Calendar.current.dateComponents([.day], from: Date(), to: testDate).day
}

var greReadinessPercentage: Double {
    // Based on words mastered vs total needed
    let masteredCount = // fetch from words
    let targetWords = 500
    return Double(masteredCount) / Double(targetWords) * 100
}

var recommendedDailyWords: Int {
    guard let days = daysUntilGRE, days > 0 else { return 15 }
    let remainingWords = 500 - masteredWordsCount
    return max(5, min(50, remainingWords / days))
}
```

---

### 1.3 Score Predictor Algorithm

**Purpose:** Show users their estimated GRE Verbal score

**Algorithm:**
```swift
// New file: Services/ScorePredictorService.swift

class ScorePredictorService {

    /// GRE Verbal scores range from 130-170
    /// Base score: 145 (50th percentile)
    /// Each 100 mastered words ≈ +3 points
    /// Accuracy modifier: ±5 points based on quiz performance

    static func calculateEstimatedScore(
        masteredWords: Int,
        accuracy: Double,
        avgResponseTime: Double
    ) -> Int {
        let baseScore = 145

        // Word mastery contribution (0-15 points)
        let wordBonus = min(15, masteredWords / 33)

        // Accuracy contribution (-5 to +5 points)
        let accuracyBonus = Int((accuracy - 0.7) * 25)

        // Speed bonus (0-5 points for fast accurate responses)
        let speedBonus = avgResponseTime < 5.0 ? 3 : 0

        let estimatedScore = baseScore + wordBonus + accuracyBonus + speedBonus

        return min(170, max(130, estimatedScore))
    }

    static func getScoreChange(from oldScore: Int, to newScore: Int) -> String {
        let diff = newScore - oldScore
        if diff > 0 {
            return "+\(diff)"
        } else if diff < 0 {
            return "\(diff)"
        }
        return "—"
    }
}
```

---

### 1.4 Redesigned Home Screen

**Layout (top to bottom):**

1. **Header:** Greeting + streak badge
2. **GRE Countdown Banner:** Days remaining + readiness %
3. **Learning Path:** Visual progress (New → Quiz → Deep → Master)
4. **Main CTA:** "Today's Session" with phase breakdown
5. **Score Card:** Estimated Verbal + daily change
6. **Today's Progress:** Goal completion bar

**Key changes to HomeView.swift:**
- Add `greCountdownBanner` view
- Add `scoreEstimateCard` view
- Move `learningPathSection` above main CTA
- Update stats to show score, not just accuracy

---

### 1.5 Enhanced Session Completion

**New elements:**
- Tomorrow's preview (words due, new words coming)
- Score change indicator
- Streak celebration
- Share progress button
- "We'll remind you" with notification time

---

## Phase 2: Monetization

### 2.1 Paywall Screen

**Trigger conditions:**
- Day 3 of usage, OR
- 50 words learned, OR
- User tries to access locked content

**Paywall content:**
- Progress celebration
- Feature comparison (Free vs Premium)
- Pricing options ($4.99/mo, $29.99/yr)
- Social proof (testimonials)
- "Continue Free" option (always available)

**Files to create:**
- `Views/PaywallView.swift`
- `Services/SubscriptionService.swift`
- `Models/SubscriptionStatus.swift`

---

### 2.2 Subscription Tiers

**Free Tier:**
- Essential word pack (100 words)
- 10 words per day limit
- Basic stats
- 7-day streak max visible

**Premium Tier ($29.99/year or $4.99/month):**
- All 500+ words
- Unlimited daily sessions
- Score predictor
- Detailed analytics
- Cloud sync (future)
- Advanced & Expert word packs

---

### 2.3 Locked Content UI

**Words screen changes:**
- Show locked packs with "PRO" badge
- Dim locked content
- Tap to show paywall

---

## Phase 3: Retention & Engagement

### 3.1 Push Notification System

**Implementation:**
- Request permission in onboarding
- User selects preferred time
- Smart notification logic

**Notification types:**
```swift
enum NotificationType {
    case dailyReminder      // "12 words due today"
    case streakWarning      // "Don't lose your 7-day streak!"
    case achievement        // "You just hit 100 words!"
    case reEngagement       // "We miss you! 45 days to GRE"
    case weeklyReport       // "This week: 89 words, +4 score"
}
```

**Files to create:**
- `Services/NotificationService.swift`
- Update `AppDelegate` or `GREVocabApp.swift` for UNUserNotificationCenter

---

### 3.2 Placement Quiz

**5-word quick assessment:**
- Shows during onboarding
- Tests vocabulary level
- Results personalize starting difficulty
- Skip option available

**Implementation:**
- Random selection from different difficulty tiers
- Track correct/incorrect
- Set initial `placementScore` (0-5)
- Adjust which word packs to prioritize

---

### 3.3 Tomorrow Preview

**Session completion additions:**
- "Tomorrow: X words due for review"
- "Y new words to learn"
- Specific word teaser: "ubiquitous comes back!"
- Notification time confirmation

---

## File Changes Summary

### New Files to Create

| File | Purpose |
|------|---------|
| `Services/ScorePredictorService.swift` | GRE score estimation algorithm |
| `Services/NotificationService.swift` | Push notification management |
| `Services/SubscriptionService.swift` | StoreKit integration |
| `Views/PaywallView.swift` | Premium upsell screen |
| `Views/PlacementQuizView.swift` | Onboarding assessment |
| `Views/GREDatePickerView.swift` | Test date selection |
| `Views/NotificationPermissionView.swift` | Notification opt-in |
| `Models/SubscriptionStatus.swift` | Subscription state |

### Files to Modify

| File | Changes |
|------|---------|
| `Models/UserProgress.swift` | Add greTestDate, estimatedScore, notificationsEnabled |
| `Views/OnboardingView.swift` | Add 3 new screens, restructure flow |
| `Views/HomeView.swift` | Add countdown, score card, redesign layout |
| `Views/ContentView.swift` | Add paywall trigger logic |
| `Views/DailySessionView.swift` | Update completion screen |
| `Views/StatsProgressView.swift` | Add score predictor section |
| `Views/DeckListView.swift` | Add locked state for premium packs |
| `GREVocabApp.swift` | Add notification setup |

---

## Implementation Order

### Week 1: Foundation
1. ✅ Create implementation plan (this document)
2. Update UserProgress model with new fields
3. Create ScorePredictorService
4. Update HomeView with score card

### Week 2: Onboarding
5. Create GRE date picker screen
6. Create placement quiz
7. Create notification permission screen
8. Integrate new onboarding flow

### Week 3: Monetization
9. Create PaywallView
10. Add subscription service (StoreKit)
11. Add locked content UI
12. Implement paywall triggers

### Week 4: Retention
13. Create NotificationService
14. Update session completion with tomorrow preview
15. Add re-engagement notifications
16. Testing & polish

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Day 1 → Day 2 retention | Unknown | 60% |
| Day 7 retention | Unknown | 40% |
| Onboarding completion | Unknown | 80% |
| Free → Paid conversion | 0% | 5% |
| Notification opt-in | 0% | 60% |
| Daily session completion | Unknown | 70% |

---

## Appendix: UI Mockups

### Home Screen Layout
```
┌─────────────────────────────────┐
│  Good morning!           🔥 7   │
├─────────────────────────────────┤
│  ┌───────────────────────────┐  │
│  │  51 DAYS TO YOUR GRE      │  │
│  │  ████████░░░░ 68% ready   │  │
│  └───────────────────────────┘  │
│                                 │
│  YOUR LEARNING PATH             │
│  ○────●────○────○               │
│  New  Quiz  Deep  Master        │
│  234   12    3     51           │
│                                 │
│  ┌───────────────────────────┐  │
│  │  ▶  TODAY'S SESSION       │  │
│  │  12 words · 6 min         │  │
│  │  [👁️ 3] [❓ 6] [💡 1]      │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │Est.Verbal│  │ Accuracy │    │
│  │   155    │  │   87%    │    │
│  │  +3 pts  │  │          │    │
│  └──────────┘  └──────────┘    │
├─────────────────────────────────┤
│   🏠        📚        📊       │
└─────────────────────────────────┘
```

### Paywall Layout
```
┌─────────────────────────────────┐
│  ✕                              │
├─────────────────────────────────┤
│            🎉                   │
│     You've learned 50 words!    │
│                                 │
│  ┌───────────────────────────┐  │
│  │  UNLOCK FULL POTENTIAL    │  │
│  │                           │  │
│  │  ✓ All 500+ words         │  │
│  │  ✓ Score predictor        │  │
│  │  ✓ Unlimited sessions     │  │
│  │  ✓ Advanced analytics     │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │  $29.99/year - BEST VALUE │  │
│  │  [Get Premium →]          │  │
│  └───────────────────────────┘  │
│                                 │
│       $4.99/month               │
│                                 │
│  [Continue Free - Limited]      │
│                                 │
└─────────────────────────────────┘
```

---

## Notes

- All UI follows existing AppTheme design system
- Dark mode only (current app behavior)
- Haptic feedback on all interactions
- Accessibility labels for all elements
- SwiftData for persistence
- No backend required for Phase 1-2
