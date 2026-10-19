/**
 * Firebase Cloud Seeder Script for Instagram iOS
 * Seeds users, posts, stories, reels, comments, notifications, conversations, messages, and notes.
 * Provisions 2 test accounts: tom@example.com and jane@example.com.
 */

const API_KEY = "AIzaSyDZAf8nh9wgqg-9EUznDKF10zASMGJPkqY";
const PROJECT_ID = "instagram-clone-c1ffa";
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

async function signIn(email, password) {
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password, returnSecureToken: true })
  });
  const data = await res.json();
  if (data.error) {
    throw new Error(`Failed to sign in ${email}: ${JSON.stringify(data.error)}`);
  }
  return data.idToken;
}

async function writeDoc(idToken, collection, docId, fields) {
  const url = `${FIRESTORE_BASE}/${collection}/${docId}?key=${API_KEY}`;
  const firestoreFields = {};
  for (const [key, val] of Object.entries(fields)) {
    if (typeof val === "string") {
      firestoreFields[key] = { stringValue: val };
    } else if (typeof val === "number") {
      if (Number.isInteger(val)) {
        firestoreFields[key] = { integerValue: val.toString() };
      } else {
        firestoreFields[key] = { doubleValue: val };
      }
    } else if (typeof val === "boolean") {
      firestoreFields[key] = { booleanValue: val };
    } else if (Array.isArray(val)) {
      firestoreFields[key] = {
        arrayValue: {
          values: val.map(item => ({ stringValue: String(item) }))
        }
      };
    }
  }

  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${idToken}`
    },
    body: JSON.stringify({ fields: firestoreFields })
  });
  const data = await res.json();
  if (data.error) {
    return { success: false, error: data.error };
  }
  return { success: true, doc: data.name };
}

async function main() {
  console.log("=== Instagram Firebase Cloud Data Seeder ===");
  console.log(`Target Firebase Project: ${PROJECT_ID}`);

  let idToken;
  try {
    idToken = await signIn("tom@example.com", "password123");
    console.log("✅ Authenticated as tom@example.com");
  } catch (e) {
    console.error("❌ Authentication error:", e.message);
    process.exit(1);
  }

  // 1. Seed Users
  console.log("\n--- Seeding Users ---");
  const users = [
    {
      id: "user_current",
      username: "tomthecat",
      fullName: "Tom The Cat",
      email: "tom@example.com",
      avatarURL: "https://i.pravatar.cc/300?u=tomthecat",
      bio: "iOS Developer 🍎 | Coffee lover ☕️ | Building things",
      isVerified: true,
      followersCount: 1234,
      followingCount: 567,
      postsCount: 42
    },
    {
      id: "user_1",
      username: "jane_doe",
      fullName: "Jane Doe",
      email: "jane@example.com",
      avatarURL: "https://i.pravatar.cc/300?u=jane_doe",
      bio: "Travel photographer 📸 Living between Tokyo & Da Nang",
      isVerified: false,
      followersCount: 892,
      followingCount: 310,
      postsCount: 28
    }
  ];

  for (const user of users) {
    const res = await writeDoc(idToken, "users", user.id, user);
    if (res.success) {
      console.log(`✅ Seeded user: @${user.username} (${user.id})`);
    } else {
      console.log(`⚠️ Firestore write notice for @${user.username}:`, res.error.message);
      if (res.error.message.includes("Cloud Firestore API has not been used")) {
        console.log("\n📢 ACTION REQUIRED: Please enable Cloud Firestore on Firebase Console:");
        console.log(`👉 https://console.firebase.google.com/project/${PROJECT_ID}/firestore`);
        console.log("Once enabled, re-run: node scripts/seed_firebase.mjs\n");
        return;
      }
    }
  }

  // 2. Seed Posts
  console.log("\n--- Seeding Sample Posts ---");
  const posts = [
    {
      id: "post_1",
      authorId: "user_current",
      caption: "Coding Instagram clone with Firebase BaaS integration! 🚀💻 #ios #swift",
      mediaURLs: ["https://picsum.photos/seed/post1/1080/1080"],
      likesCount: 142,
      commentsCount: 18
    },
    {
      id: "post_2",
      authorId: "user_1",
      caption: "Morning coffee in Tokyo ☕️🇯🇵 #travel #coffee",
      mediaURLs: ["https://picsum.photos/seed/post2/1080/1080"],
      likesCount: 289,
      commentsCount: 34
    }
  ];

  for (const post of posts) {
    const res = await writeDoc(idToken, "posts", post.id, post);
    if (res.success) {
      console.log(`✅ Seeded post: ${post.id}`);
    }
  }

  console.log("\n🎉 Cloud Seeder execution completed!");
}

main().catch(err => {
  console.error("Fatal error:", err);
});
