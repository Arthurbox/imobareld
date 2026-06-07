const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendChatPush = onRequest(async (req, res) => {
  // Configurer CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");

  // Si c'est une requête de preflight, on s'arrête là et on retourne un petit 204
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  // Vérifier qu'on a bien un payload
  const { fcm_token, title, body, payload_data } = req.body;

  if (!fcm_token || !title || !body) {
    res.status(400).send({
      success: false,
      message: "Missing 'fcm_token', 'title' or 'body' in the request body."
    });
    return;
  }

  try {
    const message = {
      token: fcm_token,
      notification: {
        title: title,
        body: body,
      },
      data: payload_data || {},
      android: {
        priority: "high",
        notification: {
          channelId: "general_alerts",
          sound: "default"
        }
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1
          }
        }
      }
    };

    const response = await admin.messaging().send(message);
    
    res.status(200).send({
      success: true,
      message: "Notification sent successfully",
      messageId: response
    });
  } catch (error) {
    console.error("Error sending push notification:", error);
    res.status(500).send({
      success: false,
      message: error.message
    });
  }
});
