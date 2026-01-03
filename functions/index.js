const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

// Send Pingtrail Invite
exports.onPingtrailCreated = onDocumentCreated(
    {
      document: "pingtrails/{pingtrailId}",
      region: "us-central1",
    },
    async (event) => {
      if (!event.data) return;

      const data = event.data.data();
      if (!data) return;

      const hostId = data.hostId;
      const members = (data.members || []).filter((id) => id !== hostId);
      if (!members.length) return;

      // Get host's name
      const hostSnap = await admin
          .firestore()
          .collection("users")
          .doc(hostId)
          .get();

      const hostName = hostSnap.exists ?
        hostSnap.data().fullName || "A user" :
        "A user";

      // Get invited members' tokens
      const usersSnap = await admin
          .firestore()
          .collection("users")
          .where(admin.firestore.FieldPath.documentId(), "in", members)
          .get();

      const tokens = usersSnap.docs
          .map((doc) => doc.data().fcmToken)
          .filter(Boolean);

      if (!tokens.length) return;

      // Send notification
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: {
          title: "New Pingtrail Invite 🚶‍♂️",
          body: `${hostName} invited you to a Pingtrail`, // <- sender's name
        },
        android: {
          priority: "high",
          notification: {
            channelId: "default_notification_channel",
          },
        },
        data: {
          pingtrailId: event.params.pingtrailId,
          type: "pingtrail_invite",
        },
      });
    },
);


// Send Friend Request
exports.onFriendRequestCreated = onDocumentCreated(
    {
      document: "friend_requests/{requestId}",
      region: "us-central1",
    },
    async (event) => {
      if (!event.data) return;

      const requestData = event.data.data();
      if (!requestData) return;

      const receiverId = requestData.receiverId;
      const senderName = requestData.senderName;

      if (!receiverId) return;

      // Get receiver's FCM token
      const userSnap = await admin
          .firestore()
          .collection("users")
          .doc(receiverId)
          .get();

      const userData = userSnap.data();
      if (!userData) return;

      const receiverToken = userData.fcmToken;
      if (!receiverToken) return;

      // Send push notification
      await admin.messaging().send({
        token: receiverToken,
        notification: {
          title: "New Friend Request 🤝",
          body: `${senderName} sent you a friend request`,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "default_notification_channel",
          },
        },
        data: {
          type: "friend_request",
          senderId: requestData.senderId,
        },
      });

      console.log(`Friend request notification sent to ${receiverId}`);
    },
);


// Friend Request Accept/Reject
exports.onFriendRequestStatusChanged = onDocumentUpdated(
    {
      document: "friend_requests/{requestId}",
      region: "us-central1",
    },
    async (event) => {
      if (!event.data) return;

      const beforeData = event.data.before.data();
      const afterData = event.data.after.data();

      if (!beforeData || !afterData) return;

      // 🔹 Only trigger if status changed
      if (beforeData.status === afterData.status) return;

      const senderId = afterData.senderId;
      const receiverId = afterData.receiverId;

      if (!senderId || !receiverId) return;

      // 🔹 Fetch sender (notification receiver)
      const senderSnap = await admin
          .firestore()
          .collection("users")
          .doc(senderId)
          .get();

      if (!senderSnap.exists) return;

      const senderData = senderSnap.data();
      if (!senderData || !senderData.fcmToken) return;

      const senderToken = senderData.fcmToken;

      // 🔹 Fetch receiver (for name)
      const receiverSnap = await admin
          .firestore()
          .collection("users")
          .doc(receiverId)
          .get();

      let receiverName = "Someone";

      if (receiverSnap.exists) {
        const receiverData = receiverSnap.data();

        if (receiverData) {
          receiverName =
          receiverData.name ||
          receiverData.displayName ||
          receiverData.fullName ||
          receiverData.username ||
          "Someone";
        }
      }

      let title = "";
      let body = "";

      if (afterData.status === "accepted") {
        title = "You are now friends 🎉";
        body = receiverName + " accepted your friend request";
      } else if (afterData.status === "rejected") {
        title = "Friend request rejected ❌";
        body = receiverName + " rejected your friend request";
      } else {
        return;
      }

      await admin.messaging().send({
        token: senderToken,
        notification: {
          title: title,
          body: body,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "default_notification_channel",
          },
        },
        data: {
          type: "friend_request_" + afterData.status,
          receiverId: receiverId,
        },
      });

      console.log(
          "Friend request " +
        afterData.status +
        " notification sent to " +
        senderId,
      );
    },
);
