/**
 * Firebase Admin Seeder cho Instagram iOS (bỏ qua Security Rules).
 *
 * Chuẩn bị:
 *   npm i firebase-admin
 *   Firebase Console > Project settings > Service accounts > Generate new private key
 *   export GOOGLE_APPLICATION_CREDENTIALS=/duong/dan/serviceAccount.json   (KHÔNG commit file này)
 *
 * Chạy:
 *   node scripts/seed_firebase_admin.mjs
 */
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const PROJECT_ID = "instagram-clone-c1ffa";

initializeApp({
  credential: applicationDefault(),
  projectId: PROJECT_ID,
});

const auth = getAuth();
const db = getFirestore();

async function ensureAuthUser(email, password, displayName) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    return auth.createUser({ email, password, displayName });
  }
}

async function main() {
  console.log("=== Instagram Firebase Admin Seeder ===");
  console.log(`Target Firebase Project: ${PROJECT_ID}`);

  // 1. Auth accounts -> lấy UID thật (ID doc users/{uid} phải trùng UID này)
  const tom = await ensureAuthUser("tom@example.com", "password123", "Tom The Cat");
  const jane = await ensureAuthUser("jane@example.com", "password123", "Jane Doe");
  console.log(`✅ Auth: tom=${tom.uid}, jane=${jane.uid}`);

  const now = Timestamp.now();
  const batch = db.batch();

  // 2. Users
  const users = [
    {
      uid: tom.uid,
      username: "tomthecat",
      fullName: "Tom The Cat",
      email: "tom@example.com",
      avatarURL: "https://i.pravatar.cc/300?u=tomthecat",
      bio: "iOS Developer 🍎 | Coffee lover ☕️ | Building things",
      isVerified: true,
      followersCount: 1234,
      followingCount: 567,
      postsCount: 42,
    },
    {
      uid: jane.uid,
      username: "jane_doe",
      fullName: "Jane Doe",
      email: "jane@example.com",
      avatarURL: "https://i.pravatar.cc/300?u=jane_doe",
      bio: "Travel photographer 📸 Living between Tokyo & Da Nang",
      isVerified: false,
      followersCount: 892,
      followingCount: 310,
      postsCount: 28,
    },
  ];

  for (const { uid, ...rest } of users) {
    batch.set(db.collection("users").doc(uid), { id: uid, uid, ...rest, createdAt: now });
  }

  // 3. Posts (authorId = UID thật)
  const posts = [
    {
      id: "post_1",
      authorId: tom.uid,
      caption: "Coding Instagram clone with Firebase BaaS integration! 🚀💻 #ios #swift",
      mediaURLs: ["https://picsum.photos/seed/post1/1080/1080"],
      likesCount: 142,
      commentsCount: 18,
    },
    {
      id: "post_2",
      authorId: jane.uid,
      caption: "Morning coffee in Tokyo ☕️🇯🇵 #travel #coffee",
      mediaURLs: ["https://picsum.photos/seed/post2/1080/1080"],
      likesCount: 289,
      commentsCount: 34,
    },
  ];

  for (const { id, ...rest } of posts) {
    batch.set(db.collection("posts").doc(id), { id, ...rest, createdAt: now });
  }

  // 4. Cờ trạng thái seed (collection metadata chỉ Admin ghi được)
  batch.set(db.collection("metadata").doc("seed_status"), { seeded: true, seededAt: now });

  await batch.commit();
  console.log("🎉 Seed hoàn tất (2 users, 2 posts, metadata/seed_status).");
}

main().catch((err) => {
  console.error("❌ Seed thất bại:", err);
  process.exit(1);
});
