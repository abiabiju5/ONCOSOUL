const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.cancelExpiredAppointments = functions.pubsub
    .schedule("every 5 minutes")
    .timeZone("Asia/Kolkata")
    .onRun(async () => {
      const db = admin.firestore();
      const now = new Date();

      // 1. Fetch admin slot duration
      let slotDurationMinutes = 30;
      try {
        const rulesDoc = await db
            .collection("settings")
            .doc("appointment_rules")
            .get();
        if (rulesDoc.exists) {
          slotDurationMinutes = rulesDoc.data().slotDurationMinutes || 30;
        }
      } catch (e) {
        console.log("Rules fetch failed, using default", e);
      }

      // 2. Query Pending appointments on today or earlier
      const endOfToday = new Date();
      endOfToday.setHours(23, 59, 59, 999);

      const snap = await db
          .collection("appointments")
          .where("status", "==", "Pending")
          .where("date", "<=", admin.firestore.Timestamp.fromDate(endOfToday))
          .get();

      if (snap.empty) return null;

      // 3. Determine which ones have actually expired
      const expired = [];
      snap.forEach((doc) => {
        const data = doc.data();
        const slotEnd = resolveSlotEnd(
            data.date.toDate(),
            data.slot,
            slotDurationMinutes,
        );
        if (slotEnd && slotEnd <= now) {
          expired.push({ref: doc.ref, data});
        }
      });

      if (expired.length === 0) return null;

      // 4. Batch-cancel all expired appointments
      const BATCH_LIMIT = 499;
      for (let i = 0; i < expired.length; i += BATCH_LIMIT) {
        const chunk = expired.slice(i, i + BATCH_LIMIT);
        const batch = db.batch();
        chunk.forEach(({ref}) => {
          batch.update(ref, {
            status: "Cancelled",
            cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
            cancelledBy: "System",
            cancelReason: "Appointment time passed without completion",
          });
        });
        await batch.commit();
      }

      // 5. Notify each affected patient
      const MONTHS = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun",
        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
      ];

      const notifyPromises = expired
          .filter(({data}) => data.patientId)
          .map(({data}) => {
            const d = data.date.toDate();
            const dateStr =
          `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}`;
            const doctor = data.doctorName || "your doctor";
            return db.collection("notifications").add({
              recipientId: data.patientId,
              type: "auto_cancelled",
              title: "Appointment Cancelled",
              message:
            `Your appointment with ${doctor} on ${dateStr} ` +
            `at ${data.slot} was automatically cancelled because ` +
            `the appointment time has passed.`,
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            });
          });

      await Promise.all(notifyPromises);
      console.log(`Auto-cancelled ${expired.length} expired appointment(s).`);
      return null;
    });

/**
 * Parses a slot string and returns the DateTime when the slot ends.
 * Handles formats: "9:30 AM", "12:00 PM", "09:30", "17:30"
 * @param {Date} date - The appointment date
 * @param {string} slot - The slot string
 * @param {number} durationMinutes - Slot duration in minutes
 * @return {Date|null} The slot end time, or null if parsing fails
 */
function resolveSlotEnd(date, slot, durationMinutes) {
  try {
    const trimmed = (slot || "").trim().toUpperCase();
    let hour;
    let minute;

    if (trimmed.includes("AM") || trimmed.includes("PM")) {
      const normalised = slot.trim().replace(/\s+/, " ");
      const [time, period] = normalised.split(" ");
      [hour, minute] = time.split(":").map(Number);
      if (period.toUpperCase() === "PM" && hour !== 12) hour += 12;
      if (period.toUpperCase() === "AM" && hour === 12) hour = 0;
    } else {
      [hour, minute] = slot.split(":").map(Number);
    }

    const slotStart = new Date(date);
    slotStart.setHours(hour, minute, 0, 0);
    return new Date(slotStart.getTime() + durationMinutes * 60 * 1000);
  } catch (e) {
    console.log("resolveSlotEnd failed", e);
    return null;
  }
}
