const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const { createClient } = require("@supabase/supabase-js");

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

// ==========================================
// GENIUSPAY INTEGRATION
// ==========================================
const GENIUSPAY_API_KEY = "sk_sandbox_C7BuIXV82NdoQyT6EtSTpSZXMaW04Ebu";
const GENIUSPAY_API_SECRET = "ss_sandbox_3TEVd5FYPPS7zdPiWDbI4sw8acDOjWdHKN00I6PwNWV68hlQ";
const GENIUSPAY_WEBHOOK_SECRET = process.env.GENIUSPAY_WEBHOOK_SECRET || "whsec_sandbox_placeholder";

const SUPABASE_URL = process.env.SUPABASE_URL || "https://placeholder.supabase.co";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || "placeholder_key";
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

exports.createGeniusPayCheckout = onCall(async (request) => {
  const { amount, propertyId, durationDays, planName, userId, userEmail, userName, type } = request.data;

  if (!userId) {
    throw new HttpsError("unauthenticated", "Vous devez être connecté pour effectuer un paiement.");
  }

  const isBoost = type !== "subscription";

  if (!amount || (isBoost && !propertyId)) {
    throw new HttpsError("invalid-argument", "Montant ou ID de propriété manquant.");
  }

  // 1. Générer l'ID et créer le document dans Supabase
  const transactionId = crypto.randomUUID();

  const transactionData = {
    id: transactionId,
    user_id: userId,
    property_id: propertyId || null,
    amount: amount,
    plan_name: planName,
    duration_days: durationDays,
    status: "created"
  };

  const { error: insertError } = await supabase
    .from("transactions")
    .insert(transactionData);

  if (insertError) {
    console.error("Supabase insert error:", insertError);
    throw new HttpsError("internal", "Impossible de créer la transaction.");
  }

  // 2. Appeler l'API GeniusPay
  const descriptionPrefix = isBoost ? "Boost" : "Abonnement";
  const payload = {
    amount: amount,
    description: `${descriptionPrefix} ${planName} - ${durationDays} jours`,
    customer: {
      name: userName || "Utilisateur Imobareld",
      email: userEmail || "user@imobareld.app",
    },
    metadata: {
      transaction_id: transactionId, // Transmettre l'ID pour le webhook
      property_id: propertyId || "",
      duration_days: durationDays,
      plan_name: planName,
      type: type || "boost",
      user_id: userId
    },
    return_url: "imobareldapp://payment/return",
    cancel_url: "imobareldapp://payment/cancel"
  };

  try {
    const response = await fetch("https://geniuspay.ci/api/v1/merchant/payments", {
      method: "POST",
      headers: {
        "X-API-Key": GENIUSPAY_API_KEY,
        "X-API-Secret": GENIUSPAY_API_SECRET,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const result = await response.json();

    if (!response.ok || !result.success) {
      console.error("GeniusPay API Error:", result);
      await supabase.from("transactions").update({ 
        status: "failed", 
        error_message: "Erreur API GeniusPay"
      }).eq("id", transactionId);
      throw new HttpsError("internal", "Impossible d'initialiser le paiement avec GeniusPay.");
    }

    // Mettre à jour le statut
    await supabase.from("transactions").update({ 
        status: "initiated",
        checkout_url: result.data.checkout_url,
        provider_reference: result.data.reference
    }).eq("id", transactionId);

    return { 
      checkoutUrl: result.data.checkout_url,
      transactionId: transactionId 
    };
  } catch (error) {
    console.error("Error creating checkout:", error);
    await supabase.from("transactions").update({ 
      status: "failed", 
      error_message: error.message
    }).eq("id", transactionId);
    throw new HttpsError("internal", error.message);
  }
});

exports.geniusPayWebhook = onRequest(async (req, res) => {
  const signature = req.headers["x-webhook-signature"];
  const timestamp = req.headers["x-webhook-timestamp"];
  const event = req.headers["x-webhook-event"];

  if (!signature || !timestamp || !event) {
    console.warn("GeniusPay Webhook: Headers manquants");
    return res.status(400).send("Missing headers");
  }

  // Use rawBody to calculate signature accurately
  const rawBody = req.rawBody ? req.rawBody.toString() : JSON.stringify(req.body);
  const dataToSign = timestamp + "." + rawBody;

  const expectedSignature = crypto
    .createHmac("sha256", GENIUSPAY_WEBHOOK_SECRET)
    .update(dataToSign)
    .digest("hex");

  // Bypass check if webhook secret is not configured
  if (GENIUSPAY_WEBHOOK_SECRET !== "whsec_sandbox_placeholder" && signature !== expectedSignature) {
    console.warn("GeniusPay Webhook: Signature invalide");
    return res.status(401).send("Invalid signature");
  }

  const data = req.body.data;
  const metadata = data?.metadata || {};
  const transactionId = metadata.transaction_id;

  if (transactionId) {
    let newStatus = "pending";

    switch (event) {
      case "payment.initiated": newStatus = "initiated"; break;
      case "payment.success": newStatus = "completed"; break;
      case "payment.failed": newStatus = "failed"; break;
      case "payment.cancelled": newStatus = "cancelled"; break;
      case "payment.refunded": newStatus = "refunded"; break;
      case "payment.expired": newStatus = "expired"; break;
    }

    try {
      await supabase.from("transactions").update({
        status: newStatus,
        provider_reference: data.reference,
        payment_method: data.payment_method
      }).eq("id", transactionId);

      // Valider le boost ou l'abonnement seulement si complété
      if (event === "payment.success") {
        const durationDays = metadata.duration_days;
        
        // Calculer la date de fin
        const endDate = new Date();
        endDate.setDate(endDate.getDate() + durationDays);

        if (metadata.type === "subscription" && metadata.user_id) {
          const userId = metadata.user_id;
          await supabase.from("users").update({
            subscription_status: "active",
            subscription_ends_at: endDate.toISOString()
          }).eq("id", userId);

          console.log(`User ${userId} subscribed successfully via GeniusPay Webhook.`);
        } else if (metadata.property_id) {
          const propertyId = metadata.property_id;
          await supabase.from("properties").update({
            is_boosted: true,
            boost_end_date: endDate.toISOString()
          }).eq("id", propertyId);

          console.log(`Property ${propertyId} boosted successfully via GeniusPay Webhook.`);
        }

        // ==========================================
        // ENVOI D'EMAIL AVEC RESEND
        // ==========================================
        try {
          const userId = metadata.user_id;
          if (userId) {
            // Récupérer l'email de l'utilisateur depuis Supabase (s'il est authentifié)
            const { data: userRecord } = await supabase
              .from("users")
              .select("email, name")
              .eq("id", userId)
              .single();
              
            const userEmail = userRecord?.email || data.customer?.email;
            const userName = userRecord?.name || data.customer?.name || "Client";

            if (userEmail) {
              const resendApiKey = process.env.RESEND_API_KEY;
              
              let subject = "Paiement réussi !";
              let title = "Paiement Validé";
              let message = "Votre paiement a été traité avec succès.";
              
              if (metadata.type === "subscription") {
                subject = "Abonnement activé ! 🎉";
                title = "Bienvenue en Premium !";
                message = `Votre abonnement a été activé pour <strong>${durationDays} jours</strong>.<br>Merci de votre confiance et profitez pleinement de toutes les fonctionnalités exclusives.`;
              } else {
                subject = "Propriété boostée ! 🚀";
                title = "Annonce Boostée !";
                message = `Votre annonce a bien été boostée pour <strong>${durationDays} jours</strong>.<br>Elle bénéficiera d'une visibilité maximale auprès de nos utilisateurs !`;
              }

              // Beau template HTML
              let htmlContent = `
              <!DOCTYPE html>
              <html>
              <head>
                <style>
                  body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #f4f7f6; margin: 0; padding: 40px 20px; }
                  .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.05); }
                  .header { background-color: #0A2540; padding: 30px 20px; text-align: center; }
                  .header h1 { color: #ffffff; margin: 0; font-size: 26px; letter-spacing: 2px; font-weight: bold; }
                  .content { padding: 40px 30px; color: #333333; line-height: 1.6; font-size: 16px; }
                  .content h2 { color: #0A2540; font-size: 22px; margin-top: 0; }
                  .box { background-color: #f8fafc; border-left: 4px solid #F97316; padding: 20px; margin: 25px 0; border-radius: 4px; color: #1e293b; }
                  .footer { background-color: #f1f5f9; padding: 20px; text-align: center; color: #64748b; font-size: 13px; border-top: 1px solid #e2e8f0; }
                  .button { display: inline-block; background-color: #F97316; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; margin-top: 15px; }
                  .button:hover { background-color: #ea580c; }
                </style>
              </head>
              <body>
                <div class="container">
                  <div class="header">
                    <h1>IMOBARELD</h1>
                  </div>
                  <div class="content">
                    <h2>${title}</h2>
                    <p>Bonjour <strong>${userName}</strong>,</p>
                    <p>Nous avons le plaisir de vous confirmer que votre transaction a été traitée avec succès sur notre plateforme.</p>
                    
                    <div class="box">
                      ${message}
                    </div>
                    
                    <p>Si vous avez la moindre question, notre équipe de support reste à votre entière disposition.</p>
                    
                    <center>
                      <a href="https://imobareld.app" class="button">Ouvrir l'application</a>
                    </center>
                  </div>
                  <div class="footer">
                    &copy; ${new Date().getFullYear()} Imobareld. Tous droits réservés.<br>
                    Ceci est un email automatique, merci de ne pas y répondre.
                  </div>
                </div>
              </body>
              </html>
              `;

              // Appel à l'API Resend
              const emailResponse = await fetch("https://api.resend.com/emails", {
                method: "POST",
                headers: {
                  "Authorization": `Bearer ${resendApiKey}`,
                  "Content-Type": "application/json"
                },
                body: JSON.stringify({
                  from: "IMOBARELD <contact@mail.imobareld.app>", // Utilisation de votre sous-domaine !
                  to: userEmail,
                  subject: subject,
                  html: htmlContent
                })
              });
              
              if (emailResponse.ok) {
                console.log(`Email de succès envoyé à ${userEmail}`);
              } else {
                console.error("Erreur API Resend:", await emailResponse.text());
              }
            }
          }
        } catch (emailError) {
          console.error("Erreur lors de l'envoi de l'email Resend:", emailError);
        }
      }
    } catch (e) {
      console.error("Error updating transaction:", e);
    }
  }

  res.status(200).send({ success: true });
});
