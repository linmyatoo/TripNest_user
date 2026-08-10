---
marp: true
paginate: true
---

# TripNest

**Flutter mobile app for discovering and booking travel events**

- Browse events, book tickets, chat with fellow travellers
- Talks to a REST backend at `tripnestbackend-v2.onrender.com/api`
- ~13k lines of Dart across 55 files
- Companion app to TripNest Admin (organizer side)

---

## What users can do

| Area | Capability |
|---|---|
| **Auth** | Sign up, log in, forgot/change password, biometric login |
| **Discover** | Home feed, search by place/keyword/mood, favorites |
| **Book** | Pick tickets, review, pay, see booking history |
| **Connect** | Per-event group chat, unlocked by booking |
| **Assist** | AI chatbot, air-quality alerts, notifications |
| **Profile** | Personal data, photo upload, security, settings |

---

## The core journey

```
Splash → Onboarding → Login
   ↓
Home / Search  →  Event Detail  →  Payment
   ↓                                  ↓
Favorites                       Booking created
                                      ↓
                          Chat room + notification
```

- Five tabs: Home · My Booking · Messages · Favorites · Profile
- A draggable AI chatbot button floats over every tab

---

## How it is built

- **UI**: Flutter + Material 3, one theme in `main.dart`
- **Layout**: `lib/src/features/<feature>/` screens,
  `lib/src/core/` shared services, widgets, theme
- **Navigation**: named routes in `app_router.dart`,
  iOS/Android page transitions chosen per platform
- **Data**: 11 static service classes wrapping `http`
- **State**: plain `setState` — no state-management package
- **Storage**: `shared_preferences` for prefs and caches,
  Keychain / Keystore for saved credentials

---

## What each function does — 1/2

**Accounts** — Sign up with email, log in, reset a forgotten
password, change it later. Optional Face ID / fingerprint
login. Saved passwords sit in the phone's secure vault.

**Discover** — Home feed shows popular and upcoming events.
Search by city, keyword, or mood. Tap the heart to save an
event; favorites stay on the device and sync to the account.

**Event details** — Photos, description, date, place, price,
and live ticket availability, so a sold-out event is visible
before the customer commits.

---

## What each function does — 2/2

**Book & pay** — Pick ticket count, review the total with
discount and tax, confirm. Booking lands in "My Booking".

**Group chat** — Each booked event opens a room with the
other attendees. Cancel the booking, lose the room.

**AI assistant** — Floating helper on every screen for
travel questions and app help.

**Alerts** — Daily air quality for the user's city, plus
booking and message notifications. All toggleable.

> Payments are validated in-app. Connecting a real payment
> provider is the remaining step.
