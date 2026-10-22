/**
 * Firebase Admin Seeder cho Instagram iOS (bỏ qua Security Rules).
 *
 * Seed: 3 Auth user + users, posts, comments + replies, stories, reels,
 *       notes, notifications, conversations + messages, metadata/seed_status.
 *
 * Chuẩn bị:
 *   npm i firebase-admin
 *   Firebase Console > Project settings > Service accounts > Generate new private key
 *   export GOOGLE_APPLICATION_CREDENTIALS=/duong/dan/serviceAccount.json   (KHÔNG commit file này)
 *
 * Chạy:
 *   node scripts/seed_firebase_admin.mjs
 *
 * Chạy lại nhiều lần an toàn: mọi doc dùng ID cố định và ghi đè (set).
 * Dùng với emulator: FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 node ...
 */
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const PROJECT_ID = "instagram-clone-c1ffa";
const PASSWORD = process.env.SEED_PASSWORD ?? "password123";

initializeApp({ credential: applicationDefault(), projectId: PROJECT_ID });

const auth = getAuth();
const db = getFirestore();

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
const ts = (msAgo = 0) => Timestamp.fromMillis(Date.now() - msAgo);
const MIN = 60 * 1000;
const HOUR = 60 * MIN;
const DAY = 24 * HOUR;

async function ensureAuthUser(email, displayName) {
  try {
    return await auth.getUserByEmail(email);
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
    return auth.createUser({ email, password: PASSWORD, displayName });
  }
}

// Gom write vào các batch <= 400 op (giới hạn Firestore là 500)
class Writer {
  constructor() {
    this.ops = [];
  }
  set(ref, data) {
    this.ops.push({ ref, data });
  }
  async commit() {
    for (let i = 0; i < this.ops.length; i += 400) {
      const batch = db.batch();
      for (const { ref, data } of this.ops.slice(i, i + 400)) batch.set(ref, data);
      await batch.commit();
    }
    return this.ops.length;
  }
}

// Conversation ID deterministic: 2 uid sort tăng dần, nối bằng "_".
// PHẢI khớp cách app tạo ID, nếu khác thì sửa hàm này.
const convIdOf = (a, b) => [a, b].sort().join("_");

// ---------------------------------------------------------------------------
async function main() {
  console.log("=== Instagram Firebase Admin Seeder ===");
  console.log(`Project: ${PROJECT_ID}`);

  // 1. Auth accounts (UID thật, doc users/{uid} phải trùng UID này)
  const tom = await ensureAuthUser("tom@example.com", "Tom The Cat");
  const jane = await ensureAuthUser("jane@example.com", "Jane Doe");
  const alex = await ensureAuthUser("alex@example.com", "Alex Nguyen");
  console.log(`Auth: tom=${tom.uid}\n      jane=${jane.uid}\n      alex=${alex.uid}`);

  const w = new Writer();

  // 2. Users
  // Profiles cho Tom, Jane, Alex và 32 người dùng mẫu (khớp bio/nghề nghiệp)
  const extraUsers = [
    { id: "user_1", username: "jane_doe_photo", fullName: "Jane Doe Photography", bio: "Photographer 📸 | Canon EOS R5", isVerified: false },
    { id: "user_2", username: "john_smith", fullName: "John Smith", bio: "Travel 🌍 | Food 🍕 | Nomadic lifestyle", isVerified: true },
    { id: "user_3", username: "sara_design", fullName: "Sara Design", bio: "UI/UX Designer ✨ | Design systems & motion", isVerified: false },
    { id: "user_4", username: "mike_dev", fullName: "Mike Developer", bio: "SwiftUI | Kotlin | Rust enthusiast 💻", isVerified: false },
    { id: "user_5", username: "lisa_art", fullName: "Lisa Art", bio: "Digital Artist 🎨 | Procreate illustrations", isVerified: true },
    { id: "user_6", username: "an_le", fullName: "Lê Hoàng An", bio: "Architecture & Interior 🏛️ Saigon based", isVerified: false },
    { id: "user_7", username: "minh_tri", fullName: "Trần Minh Trí", bio: "Coffee addict ☕️ • Tech reviewer 📱", isVerified: false },
    { id: "user_8", username: "lan_huong", fullName: "Nguyễn Lan Hương", bio: "Fashion & Lifestyle 👗 Hanoi", isVerified: true },
    { id: "user_9", username: "alex_walker", fullName: "Alex Walker", bio: "Outdoor adventures 🏔️ Trekking & Camping", isVerified: false },
    { id: "user_10", username: "emma_chef", fullName: "Emma Cook", bio: "Plant-based recipes 🌱 Healthy sourdough & matcha", isVerified: true },
    { id: "user_11", username: "quoc_bao", fullName: "Phạm Quốc Bảo", bio: "Mobile Engineer 🚀 Building iOS & macOS apps", isVerified: false },
    { id: "user_12", username: "thuy_tien", fullName: "Đặng Thủy Tiên", bio: "Ceramics & Handmade Pottery 🏺 Da Nang workshop", isVerified: false },
    { id: "user_13", username: "david_music", fullName: "David Chen", bio: "Music Producer 🎧 Lo-fi beats & vinyl collector", isVerified: true },
    { id: "user_14", username: "mai_anh", fullName: "Vũ Mai Anh", bio: "Book reviewer 📚 | Cat mom 🐱 | Cozy corner", isVerified: false },
    { id: "user_15", username: "hoang_nam", fullName: "Ngô Hoàng Nam", bio: "Street photography 🎞️ 35mm film only", isVerified: false },
    { id: "user_16", username: "chloe_fit", fullName: "Chloe Nguyen", bio: "Fitness & Yoga Coach 🧘‍♀️ Mindful body & soul", isVerified: true },
    { id: "user_17", username: "tuan_kien", fullName: "Lý Tuấn Kiệt", bio: "Specialty Coffee Roaster ☕️ Origin stories", isVerified: false },
    { id: "user_18", username: "sophia_baker", fullName: "Sophia Miller", bio: "Artisan Bakery 🥐 French pastries & tarts", isVerified: false },
    { id: "user_19", username: "duc_huy", fullName: "Bùi Đức Huy", bio: "Product Designer 📐 Figma & Design systems", isVerified: false },
    { id: "user_20", username: "huyen_my", fullName: "Trương Huyền My", bio: "Watercolor & Gouache 🖌️ Nature painter", isVerified: true },
    { id: "user_21", username: "thanh_tung", fullName: "Vũ Thanh Tùng", bio: "Landscape Photographer 🌄 Chasing golden hour", isVerified: false },
    { id: "user_22", username: "ngoc_anh", fullName: "Đoàn Ngọc Ánh", bio: "Pastry Chef & Baker 🍰 Sweet creations", isVerified: false },
    { id: "user_23", username: "viet_dung", fullName: "Lê Việt Dũng", bio: "Coffee Shop Owner ☕ Specialty brews & beans", isVerified: false },
    { id: "user_24", username: "phuong_linh", fullName: "Trần Phương Linh", bio: "Fashion Designer & Stylist ✨ Modern vintage", isVerified: true },
    { id: "user_25", username: "hoang_long", fullName: "Nguyễn Hoàng Long", bio: "Indie Game Developer 🎮 Pixels & chiptunes", isVerified: false },
    { id: "user_26", username: "thu_ha", fullName: "Phạm Thu Hà", bio: "Yoga & Mindfulness Coach 🧘 Mind & breath", isVerified: false },
    { id: "user_27", username: "quang_huy", fullName: "Đinh Quang Huy", bio: "Architect & Urban Sketcher 🏛️ Saigon lines", isVerified: true },
    { id: "user_28", username: "kim_ngan", fullName: "Võ Kim Ngân", bio: "Ceramicist & Clay Artist 🏺 Wheel throwing", isVerified: false },
    { id: "user_29", username: "duc_thang", fullName: "Trịnh Đức Thắng", bio: "Triathlete & Marathon Runner 🏃 Sub-3 goal", isVerified: false },
    { id: "user_30", username: "ha_my", fullName: "Lâm Hà My", bio: "Botanist & Plant Collector 🌿 Monstera lover", isVerified: false },
    { id: "user_31", username: "minh_quan", fullName: "Đỗ Minh Quân", bio: "Sound Engineer & Podcaster 🎙️ Voice & beats", isVerified: false },
    { id: "user_32", username: "thanh_thao", fullName: "Bùi Thanh Thảo", bio: "Handmade Leather Craftsman 🧵 Bespoke bags", isVerified: false },
    { id: "user_33", username: "tan_phat", fullName: "Ngô Tấn Phát", bio: "Drone Pilot & Cinematographer 🚁 4K skies", isVerified: true },
    { id: "user_34", username: "khanh_vy", fullName: "Hoàng Khánh Vy", bio: "Language Tutor & Translator 📖 EN / FR / VI", isVerified: false },
  ];

  const profiles = [
    {
      uid: tom.uid,
      username: "tomthecat",
      fullName: "Tom The Cat",
      bio: "iOS Developer 🍎 | Coffee lover ☕️ | Building things",
      isVerified: true,
      isPrivate: false,
      followers: [jane.uid, alex.uid],
      following: [jane.uid],
      postsCount: 2,
    },
    {
      uid: jane.uid,
      username: "jane_doe",
      fullName: "Jane Doe",
      bio: "Travel photographer 📸 Living between Tokyo & Da Nang",
      isVerified: false,
      isPrivate: false,
      followers: [tom.uid],
      following: [tom.uid, alex.uid],
      postsCount: 1,
    },
    {
      uid: alex.uid,
      username: "alex_nguyen",
      fullName: "Alex Nguyen",
      bio: "Hanoi • Street food • Film photos",
      isVerified: false,
      isPrivate: false,
      followers: [jane.uid],
      following: [tom.uid],
      postsCount: 0,
    },
    ...extraUsers.map((u, i) => ({
      uid: u.id,
      username: u.username,
      fullName: u.fullName,
      bio: u.bio,
      isVerified: u.isVerified,
      isPrivate: false,
      followers: [tom.uid],
      following: [tom.uid],
      postsCount: (i % 5) + 1,
    }))
  ];

  const byUid = {};
  for (const p of profiles) {
    const avatar = `https://i.pravatar.cc/300?u=${p.username}`;
    byUid[p.uid] = { username: p.username, avatar, fullName: p.fullName, isVerified: p.isVerified };
    w.set(db.collection("users").doc(p.uid), {
      id: p.uid,
      uid: p.uid,
      username: p.username,
      fullName: p.fullName,
      displayName: p.fullName,
      email: `${p.username}@example.com`,
      bio: p.bio,
      avatarURL: avatar,
      avatarUrl: avatar,
      profileImageUrl: avatar,
      isVerified: p.isVerified,
      isPrivate: p.isPrivate,
      followers: p.followers,
      following: p.following,
      followersCount: p.followers.length,
      followingCount: p.following.length,
      postsCount: p.postsCount,
      createdAt: ts(30 * DAY),
    });
  }

  const A = (uid) => ({
    authorId: uid,
    authorUsername: byUid[uid].username,
    authorPhotoUrl: byUid[uid].avatar,
  });

  // 3. Posts (+ comments + replies)
  const posts = [
    {
      id: "post_1",
      by: tom.uid,
      caption: "Coding Instagram clone with Firebase BaaS integration! 🚀💻 #ios #swift",
      likedBy: [jane.uid, alex.uid],
      savedBy: [jane.uid],
      ago: 3 * DAY,
    },
    {
      id: "post_2",
      by: jane.uid,
      caption: "Morning coffee in Tokyo ☕️🇯🇵 #travel #coffee",
      likedBy: [tom.uid],
      savedBy: [],
      ago: 2 * DAY,
    },
    {
      id: "post_3",
      by: tom.uid,
      caption: "Hanoi weekend vibes 🌆 #hanoi",
      likedBy: [alex.uid],
      savedBy: [],
      ago: 1 * DAY,
    },
  ];

  const comments = {
    post_1: [
      {
        id: "c1",
        by: jane.uid,
        text: "Looks awesome! 🔥",
        likedBy: [tom.uid],
        replies: [{ id: "r1", by: tom.uid, text: "Thanks Jane! 🙏" }],
      },
      { id: "c2", by: alex.uid, text: "Open-source it please 😄", likedBy: [], replies: [] },
    ],
    post_2: [{ id: "c1", by: tom.uid, text: "Great shot ☕️", likedBy: [], replies: [] }],
  };

  for (const p of posts) {
    const mediaUrl = `https://picsum.photos/seed/${p.id}/1080/1080`;
    const cs = comments[p.id] ?? [];
    const commentsCount = cs.reduce((n, c) => n + 1 + c.replies.length, 0);
    w.set(db.collection("posts").doc(p.id), {
      id: p.id,
      ...A(p.by),
      caption: p.caption,
      mediaUrl,
      mediaUrls: [mediaUrl],
      mediaURLs: [mediaUrl],
      mediaType: "image",
      location: "Da Nang, Vietnam",
      likedBy: p.likedBy,
      savedBy: p.savedBy,
      likesCount: p.likedBy.length,
      commentsCount,
      createdAt: ts(p.ago),
    });

    for (const c of cs) {
      const cRef = db.collection("posts").doc(p.id).collection("comments").doc(c.id);
      w.set(cRef, {
        id: c.id,
        postId: p.id,
        ...A(c.by),
        text: c.text,
        parentId: "",
        likedBy: c.likedBy,
        likesCount: c.likedBy.length,
        replyCount: c.replies.length,
        createdAt: ts(p.ago - 10 * MIN),
      });
      for (const r of c.replies) {
        w.set(cRef.collection("replies").doc(r.id), {
          id: r.id,
          postId: p.id,
          ...A(r.by),
          text: r.text,
          parentId: c.id,
          likedBy: [],
          likesCount: 0,
          replyCount: 0,
          createdAt: ts(p.ago - 20 * MIN),
        });
      }
    }
  }

  // 4. Stories (hết hạn sau 24h tính từ lúc seed)
  const storyAuthors = [tom.uid, jane.uid, alex.uid];
  storyAuthors.forEach((uid, i) => {
    const id = `story_${i + 1}`;
    const viewers = storyAuthors.filter((x) => x !== uid).slice(0, i);
    w.set(db.collection("stories").doc(id), {
      id,
      ...A(uid),
      mediaUrl: `https://picsum.photos/seed/${id}/1080/1920`,
      mediaType: "image",
      caption: "",
      viewedBy: viewers,
      viewersCount: viewers.length,
      createdAt: ts(2 * HOUR),
      expiresAt: Timestamp.fromMillis(Date.now() + 22 * HOUR),
    });
  });

  // 5. Reels
  [
    { id: "reel_1", by: tom.uid, caption: "Swift tips in 15s ⚡️", likedBy: [jane.uid] },
    { id: "reel_2", by: jane.uid, caption: "Tokyo night walk 🌃", likedBy: [tom.uid, alex.uid] },
  ].forEach((r, i) => {
    w.set(db.collection("reels").doc(r.id), {
      id: r.id,
      ...A(r.by),
      videoUrl: "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      thumbnailUrl: `https://picsum.photos/seed/${r.id}/720/1280`,
      caption: r.caption,
      audioTrack: "Original Audio",
      audioTitle: "Original Audio",
      likedBy: r.likedBy,
      savedBy: [],
      likesCount: r.likedBy.length,
      commentsCount: 0,
      viewsCount: 100 + i * 50,
      createdAt: ts((i + 1) * 6 * HOUR),
    });
  });

  // 6. Notes (docId = uid => mỗi user 1 note)
  for (const [uid, text] of [
    [tom.uid, "Coding all night ☕️"],
    [jane.uid, "Tokyo trip soon ✈️"],
  ]) {
    w.set(db.collection("notes").doc(uid), {
      id: uid,
      authorId: uid,
      userId: uid,
      authorUsername: byUid[uid].username,
      authorPhotoUrl: byUid[uid].avatar,
      text,
      createdAt: ts(HOUR),
      expiresAt: Timestamp.fromMillis(Date.now() + 23 * HOUR),
    });
  }

  // 7. Notifications
  [
    { id: "n1", to: tom.uid, from: jane.uid, type: "like", postId: "post_1", message: "liked your post" },
    { id: "n2", to: tom.uid, from: alex.uid, type: "comment", postId: "post_1", message: "commented: Open-source it please 😄" },
    { id: "n3", to: tom.uid, from: jane.uid, type: "follow", postId: "", message: "started following you" },
    { id: "n4", to: jane.uid, from: tom.uid, type: "like", postId: "post_2", message: "liked your post" },
  ].forEach((n, i) => {
    w.set(db.collection("notifications").doc(n.id), {
      id: n.id,
      recipientId: n.to,
      senderId: n.from,
      senderUsername: byUid[n.from].username,
      senderPhotoUrl: byUid[n.from].avatar,
      type: n.type,
      postId: n.postId,
      message: n.message,
      isRead: false,
      createdAt: ts((i + 1) * 15 * MIN),
    });
  });

  // 8. Conversations + messages
  const sampleDialogues = [
    ["Chào bạn, khi nào rảnh ghé quán thử mẻ cà phê mới nhé!", "Chắc chắn rồi, cuối tuần này mình qua nha!"],
    ["Bộ ảnh chụp ở Đà Nẵng đẹp quá bạn ơi!", "Cảm ơn bạn, hôm nào cùng đi chụp nhé."],
    ["Tài liệu kiến trúc hệ thống bạn gửi đọc rất dễ hiểu.", "Cảm ơn bạn, có thắc mắc gì cứ hỏi mình nhé."],
    ["Dự án iOS đợt này chạy mượt mà trên ProMotion 120 FPS luôn.", "Tuyệt vời, chúc mừng team nhé!"],
    ["Workshop làm gốm tuần tới còn chỗ không bạn?", "Còn bạn nhé, bạn đăng ký qua link ở bio nha."],
    ["Track nhạc mới nghe chill thực sự 🎧", "Cảm ơn bạn đã lắng nghe và ủng hộ nha!"],
    ["Mẫu thiết kế UI mới trông rất hiện đại và tinh tế.", "Cảm ơn góp ý của bạn, mình vừa cập nhật component."],
    ["Hôm nào cà phê chia sẻ về kinh nghiệm làm mobile app nhé!", "Sẵn sàng luôn, hẹn bạn chiều thứ Bảy."],
  ];

  const convs = [
    {
      a: tom.uid,
      b: jane.uid,
      msgs: [
        { from: jane.uid, text: "Hey Tom, loved your new post!", ago: 50 * MIN },
        { from: tom.uid, text: "Thanks! Still polishing the Firestore rules 😅", ago: 40 * MIN },
        { from: jane.uid, text: "Send me the repo when it's ready", ago: 30 * MIN },
      ],
    },
    {
      a: tom.uid,
      b: alex.uid,
      msgs: [
        { from: alex.uid, text: "Coffee this weekend?", ago: 3 * HOUR },
        { from: tom.uid, text: "Sure, Saturday morning", ago: 2 * HOUR },
      ],
    },
    ...extraUsers.map((u, i) => {
      const dialogue = sampleDialogues[i % sampleDialogues.length];
      const unread = i < 3; // 3 hội thoại đầu có tin mới chưa đọc
      const agoPartner = (i + 1) * 20 * MIN;
      const agoTom = agoPartner + 10 * MIN;
      return {
        a: tom.uid,
        b: u.id,
        unread,
        msgs: [
          { from: tom.uid, text: dialogue[1], ago: agoTom },
          { from: u.id, text: dialogue[0], ago: agoPartner },
        ]
      };
    })
  ];

  for (const c of convs) {
    const convId = convIdOf(c.a, c.b);
    const participantIds = [c.a, c.b].sort();
    const last = c.msgs[c.msgs.length - 1];
    const lastTs = ts(last.ago);
    const slim = (uid) => ({
      id: uid,
      username: byUid[uid].username,
      avatarURL: byUid[uid].avatar,
    });

    // unread của người nhận tin cuối (map uid -> count), giữ thêm unreadCount cho client
    const unreadTom = c.unread ? 1 : 0;
    w.set(db.collection("conversations").doc(convId), {
      id: convId,
      participantIds,
      participants: participantIds.map(slim),
      isGroup: false,
      isMuted: false,
      unreadCount: unreadTom,
      unreadCounts: { [tom.uid]: unreadTom, [c.b]: 0 },
      lastMessageText: last.text,
      lastMessageSenderId: last.from,
      lastMessageTimestamp: lastTs,
      lastMessage: {
        id: `${convId}_m${c.msgs.length}`,
        conversationId: convId,
        senderId: last.from,
        sender: slim(last.from),
        type: "text",
        text: last.text,
        status: "sent",
        reactions: {},
        createdAt: lastTs,
      },
      createdAt: ts(c.msgs[0].ago),
      updatedAt: lastTs,
    });

    c.msgs.forEach((m, i) => {
      const mid = `${convId}_m${i + 1}`;
      w.set(db.collection("conversations").doc(convId).collection("messages").doc(mid), {
        id: mid,
        conversationId: convId,
        senderId: m.from,
        sender: slim(m.from),
        type: "text",
        text: m.text,
        status: "sent",
        isRead: false,
        readBy: [m.from],
        reactions: {},
        createdAt: ts(m.ago),
      });
    });
  }

  // 9. Cờ seed (collection top-level `metadata`: chỉ Admin ghi được vì rules không match)
  w.set(db.collection("metadata").doc("seed_status"), {
    seeded: true,
    seededAt: ts(),
    environment: "dev",
  });

  const n = await w.commit();
  console.log(`\nSeed hoàn tất: ${n} document.`);
  console.log(`Đăng nhập thử: tom@example.com / jane@example.com / alex@example.com  (mật khẩu: ${PASSWORD})`);
}

main().catch((err) => {
  console.error("Seed thất bại:", err);
  process.exit(1);
});
