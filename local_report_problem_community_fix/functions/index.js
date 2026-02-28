const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Severity Multipliers
const SEVERITY = {
    'water': 3,
    'electricity': 3,
    'road': 2,
    'garbage': 2,
    'drainage': 2,
    'other': 1
};

/**
 * Calculate Priority Score
 * priorityScore = (voteCount × 5) + (categorySeverity × 10) - (ageWeight)
 */
function calculateScore(voteCount, category, createdAt) {
    const severityMultiplier = SEVERITY[category] || 1;
    const baseScore = (voteCount * 5) + (severityMultiplier * 10);

    // Simple age weight (decay)
    const ageInWeeks = Math.floor((Date.now() - createdAt.toMillis()) / (1000 * 60 * 60 * 24 * 7));
    const decayValue = ageInWeeks * 2; // Lose 2 points per week

    return Math.max(0, baseScore - decayValue);
}

// 1. On Problem Creation: Set initial priority score
exports.onProblemCreated = functions.firestore
    .document('problems/{problemId}')
    .onCreate(async (snapshot, context) => {
        const data = snapshot.data();
        const score = calculateScore(0, data.category, data.createdAt);

        return snapshot.ref.update({
            priorityScore: score,
            voteCount: 0,
            status: 'pending'
        });
    });

// 2. On Vote: Increment voteCount and recalculate priorityScore
exports.onVoteCreated = functions.firestore
    .document('votes/{voteId}')
    .onCreate(async (snapshot, context) => {
        const voteData = snapshot.data();
        const problemId = voteData.problemId;
        const userId = voteData.userId;

        // Check for duplicate vote (security)
        const existingVotes = await db.collection('votes')
            .where('problemId', '==', problemId)
            .where('userId', '==', userId)
            .get();

        if (existingVotes.size > 1) {
            console.log('Duplicate vote detected, deleting...');
            return snapshot.ref.delete();
        }

        const problemRef = db.collection('problems').doc(problemId);
        const problemDoc = await problemRef.get();

        if (!problemDoc.exists) return null;

        const pData = problemDoc.data();
        const newVoteCount = (pData.voteCount || 0) + 1;
        const newScore = calculateScore(newVoteCount, pData.category, pData.createdAt);

        return problemRef.update({
            voteCount: newVoteCount,
            priorityScore: newScore,
            lastUpdated: admin.firestore.FieldValue.serverTimestamp()
        });
    });

// 3. Status Change: Send Push Notification
exports.onStatusChanged = functions.firestore
    .document('problems/{problemId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        if (newData.status !== oldData.status) {
            const reporterId = newData.reportedBy;
            const userDoc = await db.collection('users').doc(reporterId).get();

            if (!userDoc.exists) return null;

            const userData = userDoc.data();
            const fcmToken = userData.fcmToken; // App should save this on login

            if (fcmToken) {
                const payload = {
                    notification: {
                        title: 'Problem Status Updated',
                        body: `Your report "${newData.title}" is now ${newData.status}.`,
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
                    }
                };
                return admin.messaging().sendToDevice(fcmToken, payload);
            }
        }
        return null;
    });

// 4. Scheduled Age Decay (Runs weekly)
exports.applyWeeklyDecay = functions.pubsub.schedule('every 7 days').onRun(async (context) => {
    const problems = await db.collection('problems')
        .where('status', 'in', ['pending', 'approved'])
        .get();

    const batch = db.batch();
    problems.forEach(doc => {
        const data = doc.data();
        const newScore = calculateScore(data.voteCount, data.category, data.createdAt);
        batch.update(doc.ref, { priorityScore: newScore });
    });

    return batch.commit();
});
