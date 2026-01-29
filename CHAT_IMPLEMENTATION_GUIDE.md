# Chat Implementation Guide: Flutter + Firebase + Laravel Integration

## Overview

This document explains how the chat system integrates Flutter with Firebase Firestore (for real-time messaging) and Laravel API (for message persistence and business logic).

## Architecture

```
┌─────────────────┐
│   Flutter App   │
└────────┬────────┘
         │
         ├──────────────────┬──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────────┐  ┌──────────────┐  ┌──────────────┐
│ Firebase        │  │ Laravel API  │  │ Local Storage│
│ Firestore       │  │ (Sanctum)    │  │ (SharedPrefs)│
└─────────────────┘  └──────────────┘  └──────────────┘
```

## How Flutter and Firebase are Linked

### 1. **Firebase Initialization** (`lib/main.dart`)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

- Firebase is initialized **before** the app starts
- `DefaultFirebaseOptions` contains platform-specific configuration (Android, iOS, Web, etc.)
- This connects your Flutter app to your Firebase project

### 2. **Firebase Configuration** (`lib/firebase_options.dart`)

This file contains:
- **API Keys**: Authentication credentials for Firebase
- **Project ID**: Your Firebase project identifier
- **App IDs**: Platform-specific application IDs
- **Storage Bucket**: For file storage (if needed)

**To generate this file:**
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### 3. **Firestore Connection** (`lib/services/chat_service.dart`)

```dart
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
```

- Creates a connection to Firestore database
- All Firestore operations use this instance
- Automatically handles reconnection and offline support

## Data Flow: How Chat Works

### **Step 1: User Clicks "Inquire" Button**

1. User clicks "Inquire" on institution details screen
2. App checks if user is logged in
3. If not logged in → redirects to login screen
4. If logged in → proceeds to create/get conversation

### **Step 2: Create/Get Conversation** (Laravel API)

```dart
// In institution_details_screen.dart
final conversationData = await ApiService.createOrGetConversation(
  institutionId: institutionId,
  token: token,
);
```

**Laravel API Endpoint:** `POST /api/conversations/create`

**What Laravel does:**
1. Checks if conversation already exists
2. If exists → returns existing conversation ID
3. If not → creates new conversation in database
4. Creates corresponding Firestore document
5. Returns conversation ID and Firebase conversation ID

**Response:**
```json
{
  "status": true,
  "data": {
    "conversation_id": "123",
    "firebase_conversation_id": "conv_abc123",
    "institution_id": 456,
    "user_id": 789
  }
}
```

### **Step 3: Navigate to Chat Screen**

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ChatDetailScreen(
      conversationId: conversationId, // Firebase conversation ID
      institutionName: institutionName,
      institutionAvatar: institutionAvatar,
    ),
  ),
);
```

### **Step 4: Listen to Real-time Messages** (Firebase Firestore)

```dart
// In chat_detail_screen.dart
StreamBuilder<List<Map<String, dynamic>>>(
  stream: _chatService.listenToMessages(widget.conversationId),
  builder: (context, snapshot) {
    // Updates UI automatically when new messages arrive
  },
)
```

**Firestore Structure:**
```
conversations/
  └── {conversationId}/
      ├── last_message: "Hello"
      ├── last_message_timestamp: Timestamp
      └── messages/
          ├── {messageId1}/
          │   ├── text: "Hello"
          │   ├── sender_id: "user123"
          │   ├── sender_type: "user"
          │   └── timestamp: Timestamp
          └── {messageId2}/
              ├── text: "Hi there!"
              ├── sender_id: "institution456"
              ├── sender_type: "institution"
              └── timestamp: Timestamp
```

**How it works:**
- `StreamBuilder` listens to Firestore changes
- When Laravel saves a message to Firestore, Flutter automatically receives it
- No polling needed - it's real-time!

### **Step 5: Send Message** (Hybrid: Laravel + Firebase)

```dart
// 1. Send to Laravel API
await ApiService.sendMessage(
  conversationId: conversationId,
  message: messageText,
  senderType: 'user',
  token: token,
);
```

**Laravel API Endpoint:** `POST /api/conversations/{conversationId}/messages`

**What Laravel does:**
1. Validates the message
2. Saves message to database (for persistence)
3. **Saves message to Firestore** (for real-time delivery)
4. Updates conversation last_message
5. Returns success response

**Laravel Code (Example):**
```php
// In Laravel Controller
public function sendMessage(Request $request, $conversationId) {
    // Save to database
    $message = Message::create([
        'conversation_id' => $conversationId,
        'text' => $request->message,
        'sender_type' => $request->sender_type,
    ]);
    
    // Save to Firestore (for real-time)
    $firestore = app('firebase.firestore');
    $conversationRef = $firestore->collection('conversations')
        ->document($conversationId);
    
    $conversationRef->collection('messages')
        ->add([
            'text' => $request->message,
            'sender_id' => auth()->id(),
            'sender_type' => $request->sender_type,
            'timestamp' => FieldValue::serverTimestamp(),
        ]);
    
    return response()->json(['status' => true]);
}
```

**After Laravel saves to Firestore:**
- Flutter's `StreamBuilder` automatically detects the new message
- UI updates instantly without refresh
- Other devices (if user is logged in on multiple devices) also receive the message

## Key Components

### 1. **ChatService** (`lib/services/chat_service.dart`)

**Responsibilities:**
- Listen to real-time messages from Firestore
- Mark messages as read
- Update conversation metadata

**Key Methods:**
- `listenToMessages()`: Stream of messages (real-time)
- `markMessagesAsRead()`: Update read status
- `updateConversationLastMessage()`: Update conversation metadata

### 2. **ApiService** (`lib/api/api_service.dart`)

**Responsibilities:**
- Create/get conversations (Laravel API)
- Send messages (Laravel API)

**Key Methods:**
- `createOrGetConversation()`: Create or retrieve conversation
- `sendMessage()`: Send message via Laravel

### 3. **ChatDetailScreen** (`lib/screens/chat_detail_screen.dart`)

**Responsibilities:**
- Display messages in real-time
- Handle message sending
- Manage UI state

**Key Features:**
- Real-time message updates via `StreamBuilder`
- Auto-scroll to latest message
- Loading states
- Error handling

## Firebase Security Rules

**Important:** Set up Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /conversations/{conversationId} {
      // Users can only read conversations they're part of
      allow read: if request.auth != null && 
        (resource.data.user_id == request.auth.uid || 
         resource.data.institution_id in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.institution_ids);
      
      // Only Laravel backend can write (via Admin SDK)
      allow write: if false;
      
      match /messages/{messageId} {
        // Users can read messages in their conversations
        allow read: if request.auth != null;
        
        // Only Laravel backend can write
        allow write: if false;
      }
    }
  }
}
```

## Why This Architecture?

### **Laravel API (Backend):**
- ✅ **Persistence**: Messages stored in database
- ✅ **Business Logic**: Validation, notifications, analytics
- ✅ **Security**: Authentication, authorization, rate limiting
- ✅ **Integration**: Connect with other services (email, SMS, etc.)

### **Firebase Firestore (Real-time):**
- ✅ **Real-time Updates**: Instant message delivery
- ✅ **Offline Support**: Works without internet
- ✅ **Scalability**: Handles millions of concurrent connections
- ✅ **Cross-platform**: Works on all devices simultaneously

### **Hybrid Approach Benefits:**
1. **Best of Both Worlds**: Laravel for business logic, Firebase for real-time
2. **Reliability**: If Firebase is down, messages are still in database
3. **Scalability**: Firebase handles real-time, Laravel handles business logic
4. **Security**: Laravel controls access, Firebase provides real-time delivery

## Setup Instructions

### 1. **Install Dependencies**

```bash
flutter pub get
```

### 2. **Configure Firebase**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase
flutterfire configure
```

### 3. **Laravel Backend Setup**

Your Laravel backend needs:
- Firebase Admin SDK installed
- Service account JSON file
- Endpoints:
  - `POST /api/conversations/create`
  - `POST /api/conversations/{id}/messages`

### 4. **Test the Flow**

1. Login to the app
2. Go to institution details
3. Click "Inquire" button
4. Chat screen opens
5. Send a message
6. Message appears instantly (real-time!)

## Troubleshooting

### **Messages not appearing:**
- Check Firebase connection
- Verify Firestore security rules
- Check Laravel is writing to Firestore
- Verify conversation ID is correct

### **"Please login" error:**
- User must be authenticated
- Token must be valid
- Check `AuthService.getToken()`

### **Firebase initialization error:**
- Run `flutterfire configure`
- Check `firebase_options.dart` has correct values
- Verify Firebase project is active

## Summary

**Flutter ↔ Firebase Connection:**
- Initialized in `main.dart` before app starts
- Connected via `firebase_options.dart` configuration
- Firestore accessed through `FirebaseFirestore.instance`

**Message Flow:**
1. User sends message → Laravel API
2. Laravel saves to database + Firestore
3. Firestore triggers real-time update
4. Flutter receives update via StreamBuilder
5. UI updates automatically

**Key Point:** Laravel writes to Firestore, Flutter reads from Firestore in real-time. This gives you both persistence (Laravel) and real-time delivery (Firebase).
