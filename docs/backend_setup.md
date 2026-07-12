# Mediverse AI Backend Setup

This MVP uses Firebase Authentication and Firebase Realtime Database only.

Do not create Firebase Storage yet. Do not upload prescription images, profile photos, PDFs, medicine images, or documents in the MVP.

## 1. Firebase Packages

The app now uses:

```yaml
firebase_core
firebase_auth
firebase_database
```

Firestore has been removed from the active Flutter data layer.

## 2. Authentication

Enable in Firebase Console:

```text
Authentication -> Sign-in method -> Email/Password
```

The app uses Firebase Auth for:

```text
register
login
logout
reset password
current user ID
```

After registration, the app writes a simple user profile to Realtime Database:

```text
users/{uid}
- name
- email
- role
- createdAt
```

## 3. Realtime Database Structure

Use this MVP data shape:

```text
users/{uid}
users/{uid}/profile/health
medicines/{medicineId}
interactions/{drugA_drugB}
checks/{uid}/{checkId}
reminders/{uid}/{reminderId}
chatHistory/{uid}/{chatId}
scans/{uid}/{scanId}
```

Prescription scanner records are text/data only:

```text
scans/{uid}/{scanId}
- prescriptionText
- detectedMedicines
- createdAt
```

AI chat records are text/data only:

```text
chatHistory/{uid}/{chatId}
- title
- preview
- userMessage
- assistantMessage
- messages
- createdAt
```

Check history records:

```text
checks/{uid}/{checkId}
- drugA
- drugB
- result
- message
- createdAt
```

## 4. Seed Medicine Data

In Firebase Console:

```text
Realtime Database -> Data
```

Add starter data:

```json
{
  "medicines": {
    "ibuprofen": {
      "name": "Ibuprofen",
      "category": "NSAID",
      "description": "Used for pain, fever, and inflammation",
      "warnings": "May irritate the stomach and affect kidneys in some people."
    },
    "warfarin": {
      "name": "Warfarin",
      "category": "Blood thinner",
      "description": "Used to prevent blood clots",
      "warnings": "Can increase bleeding risk."
    },
    "paracetamol": {
      "name": "Paracetamol",
      "category": "Pain reliever",
      "description": "Used for pain and fever",
      "warnings": "Overdose may damage the liver."
    }
  },
  "interactions": {
    "ibuprofen_warfarin": {
      "drugA": "ibuprofen",
      "drugB": "warfarin",
      "severity": "high",
      "message": "Ibuprofen and warfarin may increase the risk of bleeding.",
      "recommendation": "Avoid using them together unless a healthcare professional advises it."
    },
    "ibuprofen_paracetamol": {
      "drugA": "ibuprofen",
      "drugB": "paracetamol",
      "severity": "low",
      "message": "No serious interaction is commonly expected, but dosage and patient condition matter.",
      "recommendation": "Use correct doses and ask a pharmacist if symptoms continue."
    }
  }
}
```

Drug order does not matter in the app. It sorts the two medicine keys before reading `interactions/{drugA_drugB}`.

## 5. Realtime Database Rules

Rules live in:

```text
database.rules.json
```

Deploy them with:

```bash
firebase deploy --only database --project mediverse-ai-86
```

## 6. MVP Without Storage

Continue using text/data only:

```text
Profile
Medical profile
Allergies
Current medicines
Reminders
Drug checker
Interaction history
AI chat history
Learning progress
Prescription scanner text
```

Add Firebase Storage later only for:

```text
Profile photos
Prescription images
Medicine images
PDF reports
Documents
```
