# PingPal

PingPal is a location-sharing Proof of Concept (PoC) mobile application developed to demonstrate Adaptive Caching in Mobile Cloud Computing. It enables users (“Pingpals”) to share live locations during collaborative, time-bounded sessions called **Pingtrails**.

The project focuses on reducing latency and bandwidth usage while maintaining usability under varying network conditions.

---

## 🚀 Core Innovation: Adaptive Caching

PingPal dynamically adapts data update frequency based on a user’s network conditions.

The application detects the client’s connectivity type (Wi-Fi, 4G, or 3G), and the backend adjusts cache Time-To-Live (TTL) values accordingly:

- **Short TTL (~30 seconds):** High-bandwidth networks (Wi-Fi)
- **Long TTL (~5 minutes):** Low-bandwidth or unstable networks (3G)

This ensures that users on slower networks remain visible on the map even when updates are less frequent, while reducing unnecessary backend load.

---

## 🏗️ Hybrid Architecture

PingPal follows a hybrid cloud architecture to balance data persistence, scalability, and real-time performance.

### Control Plane – Firebase Firestore
Handles persistent and low-frequency data:
- User profiles and account metadata
- Pingpal (friend) relationships
- Friend requests and notifications
- Pingtrail session metadata
- Archived chat history

### Data Plane – Node.js + Redis
Optimised for high-frequency, real-time data:
- Live GPS location updates
- Active Pingtrail chat messages
- Adaptive TTL and caching logic

This separation prevents real-time data from overwhelming Firestore while ensuring durability for critical records.

---

## ✨ Key Features

### 📍 Pingtrails (Session-Based Location Sharing)
- Location sharing is only active during a Pingtrail session
- A host creates a trail, selects a destination, and invites Pingpals
- Participants must explicitly accept before joining
- Arrival is automatically detected within a 50-metre radius
- Trails are marked as completed once the session ends

---

### 🗺️ Live Map
- Displays all active participants on a shared map
- Marker updates respect backend adaptive caching rules
- Camera auto-adjusts to keep participants in view
- Distance to destination and participants is visible

---

### 💬 Pingtrail Chat
- Chat is scoped strictly to a Pingtrail session
- Adaptive polling:
    - Wi-Fi: ~1 second
    - Mobile data: ~5 seconds
- Chats become read-only once a trail ends
- Chat history is archived in Firestore
- SQLite is used for fast local caching and offline access

---

### 👥 Friend Management
- Users can search for Pingpals by email
- Friend requests require mutual acceptance
- Firestore transactions ensure consistency

---

### 👤 Profile & Privacy
- Users can manage profile details and images
- Full “Right to be Forgotten” implementation:
    - Firestore documents and sub-collections
    - Firebase Authentication account
    - Local SQLite storage

---

## 🛠️ Technology Stack

- **Frontend:** Flutter (iOS & Android)
- **Backend:** Node.js + Express (Google Cloud deployment)
- **Real-Time Cache:** Redis
- **Database & Auth:** Firebase Firestore & Firebase Authentication
- **Local Storage:** SQLite (sqflite)
- **Maps & Location:** Google Maps Flutter, Geolocator
- **Connectivity Detection:** connectivity_plus

Backend repository:  
https://github.com/Idadelveloper/pingpal-backend

---

## 🔒 Permissions Required

PingPal requires the following permissions:

- Location (Fine & Coarse) – live tracking during Pingtrails
- Internet – backend and Firebase communication
- Network state – adaptive caching logic
- Notifications – invites, arrivals, and friend requests

---
