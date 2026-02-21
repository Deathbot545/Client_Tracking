# Client Tracking App (Meeting Minutes + Visits)

A cross-platform **Flutter** mobile app for logging **client meetings/visits**, capturing **meeting minutes**, tagging visits with **GPS location**, and triggering **email workflows**.  
The backend is built and automated using **n8n** (workflows + webhook/API endpoints), keeping the app lightweight while supporting flexible automation.

---

## ✨ Key Features

### ✅ Meeting Logging (Minutes)
- Create and manage **client meeting records**
- Capture structured notes:
  - Agreed actions
  - Responsibilities
  - Next steps
- View meetings in clean lists (**My Meetings** vs **All Meetings**)

### 📍 Location Capture (GPS)
- Optional “Use current location” toggle
- Stores coordinates for the meeting/visit (map tagging supported by your workflow/UI)

### 📧 Email Automation (n8n-powered)
- Trigger automated email flows for meeting summaries/follow-ups
- Send meeting details directly from the app (e.g., **Email** action)

### 🔐 Authentication
- Login-based access (internal usage)
- Role-aware UI (e.g., Admin / User views)

---

## 🧱 Tech Stack

**Frontend**
- Flutter + Dart
- Material UI / custom dark theme UI

**Backend / Automation**
- n8n workflows (webhooks + automation)
- Email workflow integration (SMTP/provider configured in n8n)
- Optional integrations (maps/geolocation depending on configuration)

---

## 📱 User Flow

1. **Login**
2. **Dashboard**
   - My Meetings / All Meetings
   - Create New Meeting
3. **New Meeting**
   - Optional location capture
   - Client details + structured minutes
4. **Meeting Details**
   - Update points
   - Email meeting summary
   - View location

---

## ⚙️ Setup (Frontend)

### 1) Install prerequisites
- Flutter SDK (must match the project's SDK constraints in `pubspec.yaml`)
- Android Studio / VS Code Flutter extensions

Check your Flutter version:
```bash
flutter --version
```

### 2) Install dependencies
From the project root:
```bash
flutter pub get
```

### 3) Run the app
```bash
flutter run
```

---

## 🔌 Backend Setup (n8n)

This app expects your **n8n** instance to expose webhook/API endpoints for:
- Authentication (login)
- CRUD for meetings
- Location capture storage
- Email trigger (send summary/follow-up)

### Recommended configuration
- Store your base API URL and secrets **outside git**
- Use HTTPS for n8n endpoints
- Validate inputs in workflows before writing data or sending emails

> Tip: If you use environment variables for API base URLs, document the required keys here (without committing secrets).

---

## 🔐 Security Notes (Recommended)
- Never commit API keys/tokens
- Use HTTPS endpoints for all webhooks
- Prefer per-user auth (JWT/session) where possible
- Sanitize/validate payloads before storage or email send
- Apply least-privilege credentials for mail providers

---

## 🗂️ Project Structure (high level)
- `lib/` → Flutter UI + app logic
- `assets/` → Images/icons
- Platform folders: `android/`, `ios/`, `web/`, `windows/`, etc.

---

## 📌 Roadmap / Improvements
- Offline-first caching (sync when online)
- Better error states (network/auth failures)
- Export meeting summaries as PDF
- Role-based permissions enforcement end-to-end

---

## 📄 License
Internal / private use (update as needed).
