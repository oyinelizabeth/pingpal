# PingPal

PingPal is a location-sharing Proof of Concept (PoC) application developed to demonstrate **Adaptive Caching in Mobile Cloud Computing**. It allows users ("PingPals") to share real-time locations during specific collaborative sessions called **"Ping Trails."**

## 🚀 Core Innovation: Adaptive Caching

The app's primary research goal is to optimize data transmission based on network conditions. PingPal detects the user's network quality (Wi-Fi, 4G, or 3G) and the backend adjusts the data Time-To-Live (TTL) accordingly:
- **Short TTL (30s):** For users on high-speed networks (Wi-Fi).
- **Long TTL (5m):** For users on slower networks (3G), ensuring they remain visible on the map even with infrequent updates.

---

## 🏗️ Hybrid Architecture

PingPal uses a multi-layered "Hybrid" architecture to balance persistence and performance:

- **Control Plane (Firebase Firestore):** Manages persistent and slow-moving data:
  - User Profiles & Bios
  - Friend Lists (PingPals)
  - Friend Requests
  - Session Management (Ping Trail metadata)
  - Archived Chat History
- **Data Plane (Node.js/Express + Redis):** Dedicated to high-frequency, real-time data:
  - Live GPS Coordinates
  - Active Chat Messages
  - Adaptive TTL Logic

---

## ✨ Key Features

### 📍 Ping Trails (Location Sessions)
- **Session-Based Sharing:** Location sharing is only active during a "Ping Trail."
- **Host & Participants:** A host selects a destination and invites friends. Once accepted, participants' locations are visible to the group.
- **Auto-Arrival Detection:** The app calculates the distance to the destination and automatically notifies the group when a member arrives (within 50 meters).
- **Auto-Termination:** Trails are automatically marked as completed one hour after the expected arrival time.

### 🗺️ Live Map Screen
- **Real-time Tracking:** See yourself and your friends on a live map.
- **Adaptive Polling:** The map updates its markers based on the backend's adaptive logic.
- **Auto-Zoom:** The map automatically adjusts the camera to keep all active participants in view.
- **Distance Tracking:** Tap any marker to see the participant's profile and their exact distance from you.

### 💬 Active Chat
- **Session-Centric:** Chat is strictly tied to a Ping Trail session.
- **Mobile Cloud Optimization:** Adaptive polling intervals for messages:
  - **Wi-Fi:** 1-second polling.
  - **Mobile Data:** 5-second polling (bandwidth conservation).
- **Archiving:** Once a trail ends, the chat becomes a read-only archive stored in Firestore.
- **Local Persistence:** Uses SQLite for local caching, ensuring instant UI rendering and offline access to history.

### 👥 Friend Management
- **Search & Request:** Find friends by email and send "Ping Requests."
- **Secure Connections:** Friends are only added after mutual acceptance via a secure Firestore transaction.

### 👤 Profile & Privacy
- **Customization:** Upload profile images, add bios, and manage contact info.
- **Account Deletion:** A comprehensive "Right to be Forgotten" implementation that wipes all user data from Firestore, Authentication, and Local Storage.

---

## 🛠️ Technology Stack

- **Frontend:** Flutter (iOS & Android)
- **Backend:** [Node.js, Express (GKE Deployed)](https://github.com/Idadelveloper/pingpal-backend)
- **Real-time Data:** Redis
- **Database/Auth:** Firebase Firestore & Firebase Auth
- **Local Storage:** SQLite (sqflite)
- **Location:** Geolocator & Google Maps Flutter
- **Network:** Connectivity Plus

---

## 🔒 Permissions Required

To function correctly, PingPal requires the following permissions:
- **Location:** Fine & Coarse location access for real-time tracking.
- **Internet:** For backend and Firebase communication.
- **Network State:** For the Adaptive Caching logic.
- **Notifications:** For friend requests and arrival updates.