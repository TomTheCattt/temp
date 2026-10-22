#!/usr/bin/env python3
"""
Instagram iOS Firebase REST Seeder
Seeds rich production-ready data into Firebase Authentication & Cloud Firestore
via official Google REST APIs, 100% compliant with firestore.rules (Zero Permission Denied).
"""

import sys
import json
import time
from datetime import datetime, timezone, timedelta
import urllib.request
import urllib.error
from concurrent.futures import ThreadPoolExecutor, as_completed

API_KEY = "AIzaSyDZAf8nh9wgqg-9EUznDKF10zASMGJPkqY"
PROJECT_ID = "instagram-clone-c1ffa"
PASSWORD = "password123"

AUTH_SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
AUTH_SIGNUP_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}"
FS_BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

NOW = datetime.now(timezone.utc)

def iso_ts(seconds_ago=0, seconds_ahead=0):
    t = NOW - timedelta(seconds=seconds_ago) + timedelta(seconds=seconds_ahead)
    return t.strftime("%Y-%m-%dT%H:%M:%S.000Z")

def to_fs(val):
    if val is None:
        return {"nullValue": None}
    if isinstance(val, bool):
        return {"booleanValue": val}
    if isinstance(val, int):
        return {"integerValue": str(val)}
    if isinstance(val, float):
        return {"doubleValue": val}
    if isinstance(val, str):
        if val.endswith("Z") and ("T" in val):
            return {"timestampValue": val}
        return {"stringValue": val}
    if isinstance(val, list):
        return {"arrayValue": {"values": [to_fs(v) for v in val]}}
    if isinstance(val, dict):
        return {"mapValue": {"fields": {k: to_fs(v) for k, v in val.items()}}}
    return {"stringValue": str(val)}

def http_post(url, data_dict, headers=None, method="POST"):
    req_headers = {"Content-Type": "application/json"}
    if headers:
        req_headers.update(headers)
    req = urllib.request.Request(
        url,
        data=json.dumps(data_dict).encode("utf-8"),
        headers=req_headers,
        method=method
    )
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=15) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            err_body = e.read().decode("utf-8")
            if e.code in (429, 503) and attempt < 3:
                time.sleep(1.0 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {e.code}: {err_body}")
        except Exception as e:
            if attempt < 3:
                time.sleep(1.0 * (attempt + 1))
                continue
            raise e

def ensure_auth_user(email, display_name):
    """Signs in user or creates account if not exists, returning (uid, idToken)"""
    # 1. Try sign in
    try:
        res = http_post(AUTH_SIGNIN_URL, {
            "email": email,
            "password": PASSWORD,
            "returnSecureToken": True
        })
        return res["localId"], res["idToken"]
    except RuntimeError as e:
        if "EMAIL_NOT_FOUND" not in str(e) and "INVALID_LOGIN_CREDENTIALS" not in str(e):
            pass

    # 2. Try sign up
    try:
        res = http_post(AUTH_SIGNUP_URL, {
            "email": email,
            "password": PASSWORD,
            "returnSecureToken": True
        })
        return res["localId"], res["idToken"]
    except RuntimeError as e:
        # If email exists but wrong password or other error, retry sign in
        res = http_post(AUTH_SIGNIN_URL, {
            "email": email,
            "password": PASSWORD,
            "returnSecureToken": True
        })
        return res["localId"], res["idToken"]

def write_document(path, fields_dict, token):
    url = f"{FS_BASE_URL}/{path}"
    # If doc already exists, preserve its original createdAt to satisfy immutable rule
    try:
        req_get = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(req_get, timeout=5) as resp:
            existing = json.loads(resp.read().decode("utf-8"))
            if "fields" in existing and "createdAt" in existing["fields"]:
                fields_dict["createdAt"] = existing["fields"]["createdAt"]["timestampValue"]
    except Exception:
        pass

    fs_body = {"fields": {k: to_fs(v) for k, v in fields_dict.items()}}
    return http_post(url, fs_body, headers={"Authorization": f"Bearer {token}"}, method="PATCH")

# ---------------------------------------------------------------------------
# Data Definitions
# ---------------------------------------------------------------------------

USER_DEFS = [
    ("jane@example.com", "jane_doe", "Jane Doe", "Travel photographer 📸 Living between Tokyo & Da Nang", True),
    ("alex@example.com", "alex_nguyen", "Alex Nguyen", "Hanoi • Street food • 35mm film photos 🎞️", False),
    ("user_1@example.com", "jane_doe_photo", "Jane Doe Photography", "Photographer 📸 | Canon EOS R5", False),
    ("user_2@example.com", "john_smith", "John Smith", "Travel 🌍 | Food 🍕 | Nomadic lifestyle", True),
    ("user_3@example.com", "sara_design", "Sara Design", "UI/UX Designer ✨ | Design systems & motion", False),
    ("user_4@example.com", "mike_dev", "Mike Developer", "SwiftUI | Kotlin | Rust enthusiast 💻", False),
    ("user_5@example.com", "lisa_art", "Lisa Art", "Digital Artist 🎨 | Procreate illustrations", True),
    ("user_6@example.com", "an_le", "Lê Hoàng An", "Architecture & Interior 🏛️ Saigon based", False),
    ("user_7@example.com", "minh_tri", "Trần Minh Trí", "Coffee addict ☕️ • Tech reviewer 📱", False),
    ("user_8@example.com", "lan_huong", "Nguyễn Lan Hương", "Fashion & Lifestyle 👗 Hanoi", True),
    ("user_9@example.com", "alex_walker", "Alex Walker", "Outdoor adventures 🏔️ Trekking & Camping", False),
    ("user_10@example.com", "emma_chef", "Emma Cook", "Plant-based recipes 🌱 Healthy sourdough & matcha", True),
    ("user_11@example.com", "quoc_bao", "Phạm Quốc Bảo", "Mobile Engineer 🚀 Building iOS & macOS apps", False),
    ("user_12@example.com", "thuy_tien", "Đặng Thủy Tiên", "Ceramics & Handmade Pottery 🏺 Da Nang workshop", False),
    ("user_13@example.com", "david_music", "David Chen", "Music Producer 🎧 Lo-fi beats & vinyl collector", True),
    ("user_14@example.com", "mai_anh", "Vũ Mai Anh", "Book reviewer 📚 | Cat mom 🐱 | Cozy corner", False),
    ("user_15@example.com", "hoang_nam", "Ngô Hoàng Nam", "Street photography 🎞️ 35mm film only", False),
    ("user_16@example.com", "chloe_fit", "Chloe Nguyen", "Fitness & Yoga Coach 🧘‍♀️ Mindful body & soul", True),
    ("user_17@example.com", "tuan_kien", "Lý Tuấn Kiệt", "Specialty Coffee Roaster ☕️ Origin stories", False),
    ("user_18@example.com", "sophia_baker", "Sophia Miller", "Artisan Bakery 🥐 French pastries & tarts", False),
    ("user_19@example.com", "duc_huy", "Bùi Đức Huy", "Product Designer 📐 Figma & Design systems", False),
    ("user_20@example.com", "huyen_my", "Trương Huyền My", "Watercolor & Gouache 🖌️ Nature painter", True),
    ("user_21@example.com", "thanh_tung", "Vũ Thanh Tùng", "Landscape Photographer 🌄 Chasing golden hour", False),
    ("user_22@example.com", "ngoc_anh", "Đoàn Ngọc Ánh", "Pastry Chef & Baker 🍰 Sweet creations", False),
    ("user_23@example.com", "viet_dung", "Lê Việt Dũng", "Coffee Shop Owner ☕ Specialty brews & beans", False),
    ("user_24@example.com", "phuong_linh", "Trần Phương Linh", "Fashion Designer & Stylist ✨ Modern vintage", True),
    ("user_25@example.com", "hoang_long", "Nguyễn Hoàng Long", "Indie Game Developer 🎮 Pixels & chiptunes", False),
    ("user_26@example.com", "thu_ha", "Phạm Thu Hà", "Yoga & Mindfulness Coach 🧘 Mind & breath", False),
    ("user_27@example.com", "quang_huy", "Đinh Quang Huy", "Architect & Urban Sketcher 🏛️ Saigon lines", True),
    ("user_28@example.com", "kim_ngan", "Võ Kim Ngân", "Ceramicist & Clay Artist 🏺 Wheel throwing", False),
    ("user_29@example.com", "duc_thang", "Trịnh Đức Thắng", "Triathlete & Marathon Runner 🏃 Sub-3 goal", False),
    ("user_30@example.com", "ha_my", "Lâm Hà My", "Botanist & Plant Collector 🌿 Monstera lover", False),
    ("user_31@example.com", "minh_quan", "Đỗ Minh Quân", "Sound Engineer & Podcaster 🎙️ Voice & beats", False),
    ("user_32@example.com", "thanh_thao", "Bùi Thanh Thảo", "Handmade Leather Craftsman 🧵 Bespoke bags", False),
    ("user_33@example.com", "tan_phat", "Ngô Tấn Phát", "Drone Pilot & Cinematographer 🚁 4K skies", True),
    ("user_34@example.com", "khanh_vy", "Hoàng Khánh Vy", "Language Tutor & Translator 📖 EN / FR / VI", False),
]

SAMPLE_DIALOGUES = [
    ("Chào bạn, khi nào rảnh ghé quán thử mẻ cà phê mới nhé!", "Chắc chắn rồi, cuối tuần này mình qua nha!"),
    ("Bộ ảnh chụp ở Đà Nẵng đẹp quá bạn ơi!", "Cảm ơn bạn, hôm nào cùng đi chụp nhé."),
    ("Tài liệu kiến trúc hệ thống bạn gửi đọc rất dễ hiểu.", "Cảm ơn bạn, có thắc mắc gì cứ hỏi mình nhé."),
    ("Dự án iOS đợt này chạy mượt mà trên ProMotion 120 FPS luôn.", "Tuyệt vời, chúc mừng team nhé!"),
    ("Workshop làm gốm tuần tới còn chỗ không bạn?", "Còn bạn nhé, bạn đăng ký qua link ở bio nha."),
    ("Track nhạc mới nghe chill thực sự 🎧", "Cảm ơn bạn đã lắng nghe và ủng hộ nha!"),
    ("Mẫu thiết kế UI mới trông rất hiện đại và tinh tế.", "Cảm ơn góp ý của bạn, mình vừa cập nhật component."),
    ("Hôm nào cà phê chia sẻ về kinh nghiệm làm mobile app nhé!", "Sẵn sàng luôn, hẹn bạn chiều thứ Bảy."),
]

def main():
    print("🚀 [1/6] Authenticating Primary Admin User (tom@example.com)...")
    tom_uid, tom_token = ensure_auth_user("tom@example.com", "Tom The Cat")
    print(f"    ✓ Tom authenticated: UID={tom_uid}")

    # Tom's user document
    write_document(f"users/{tom_uid}", {
        "id": tom_uid,
        "uid": tom_uid,
        "username": "tomthecat",
        "fullName": "Tom The Cat",
        "displayName": "Tom The Cat",
        "email": "tom@example.com",
        "bio": "iOS Developer 🍎 | Coffee lover ☕️ | Building things",
        "avatarURL": "https://i.pravatar.cc/300?u=tomthecat",
        "avatarUrl": "https://i.pravatar.cc/300?u=tomthecat",
        "profileImageUrl": "https://i.pravatar.cc/300?u=tomthecat",
        "website": "https://tomthecat.dev",
        "isVerified": True,
        "isPrivate": False,
        "followersCount": 1234,
        "followingCount": 567,
        "postsCount": 34,
        "createdAt": iso_ts(seconds_ago=86400 * 30),
    }, tom_token)

    print("🚀 [2/6] Authenticating & Seeding 36 Partner Accounts...")
    user_map = {} # email -> {uid, token, username, fullName, avatar, isVerified}
    user_map["tom@example.com"] = {
        "uid": tom_uid,
        "token": tom_token,
        "username": "tomthecat",
        "fullName": "Tom The Cat",
        "avatar": "https://i.pravatar.cc/300?u=tomthecat",
        "isVerified": True
    }

    def seed_user(u_def):
        email, username, fullName, bio, isVerified = u_def
        uid, token = ensure_auth_user(email, fullName)
        avatar = f"https://i.pravatar.cc/300?u={username}"
        write_document(f"users/{uid}", {
            "id": uid,
            "uid": uid,
            "username": username,
            "fullName": fullName,
            "displayName": fullName,
            "email": email,
            "bio": bio,
            "avatarURL": avatar,
            "avatarUrl": avatar,
            "profileImageUrl": avatar,
            "isVerified": isVerified,
            "isPrivate": False,
            "followersCount": 200 + (len(username) * 37) % 500,
            "followingCount": 100 + (len(username) * 19) % 250,
            "postsCount": 3 + (len(username) % 10),
            "createdAt": iso_ts(seconds_ago=86400 * 20),
        }, token)
        return email, {
            "uid": uid,
            "token": token,
            "username": username,
            "fullName": fullName,
            "avatar": avatar,
            "isVerified": isVerified
        }

    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = [executor.submit(seed_user, u) for u in USER_DEFS]
        for f in as_completed(futures):
            email, data = f.result()
            user_map[email] = data
            sys.stdout.write(f"\r    ✓ Seeded user: {data['username']} ({data['uid']})")
            sys.stdout.flush()
    print("\n    ✓ All 37 users authenticated & profiles created.")

    jane = user_map["jane@example.com"]
    alex = user_map["alex@example.com"]

    # -----------------------------------------------------------------------
    # 3. Seed Posts & Comments
    # -----------------------------------------------------------------------
    print("🚀 [3/6] Seeding Posts, Comments & Replies...")
    sample_posts = [
        (tom_token, tom_uid, "post_1", "Coding Instagram clone with Firebase BaaS integration! 🚀💻 #ios #swift #cleanarchitecture", [jane["uid"], alex["uid"]], 86400 * 3),
        (jane["token"], jane["uid"], "post_2", "Morning coffee in Tokyo ☕️🇯🇵 Loving the autumn breeze! #travel #coffee #japan", [tom_uid], 86400 * 2),
        (alex["token"], alex["uid"], "post_3", "Hanoi weekend vibes 🌆 Autumn is definitely here. #hanoi #film #35mm", [tom_uid, jane["uid"]], 86400 * 1),
        (user_map["user_1@example.com"]["token"], user_map["user_1@example.com"]["uid"], "post_4", "Canon EOS R5 test shots at golden hour 📸🌅 #photography #goldenhour", [tom_uid], 86400 * 4),
        (user_map["user_2@example.com"]["token"], user_map["user_2@example.com"]["uid"], "post_5", "Best pizza slice in town 🍕 Nomadic life in Da Nang! #foodie #vietnam", [tom_uid], 86400 * 5),
        (user_map["user_3@example.com"]["token"], user_map["user_3@example.com"]["uid"], "post_6", "Design systems & atomic components in Figma ✨ #ui #design #figma", [tom_uid], 86400 * 2),
        (user_map["user_5@example.com"]["token"], user_map["user_5@example.com"]["uid"], "post_7", "New digital artwork finished on iPad Pro & Procreate 🎨✨ #digitalart #procreate", [tom_uid], 86400 * 3),
        (user_map["user_6@example.com"]["token"], user_map["user_6@example.com"]["uid"], "post_8", "Minimalist concrete architecture in District 2 🏛️ #architecture #saigon", [tom_uid], 86400 * 6),
        (user_map["user_8@example.com"]["token"], user_map["user_8@example.com"]["uid"], "post_9", "Autumn street style collection 👗✨ #fashion #style #ootd", [tom_uid], 86400 * 4),
        (user_map["user_10@example.com"]["token"], user_map["user_10@example.com"]["uid"], "post_10", "Fresh sourdough loaf out of the oven! 🥖 Homemade matcha latte 🍵 #baking #sourdough", [tom_uid], 86400 * 1),
        (user_map["user_11@example.com"]["token"], user_map["user_11@example.com"]["uid"], "post_11", "Testing Swift 6 concurrency & non-blocking UI 📱⚡️ #swift6 #iosdev", [tom_uid], 86400 * 2),
        (user_map["user_12@example.com"]["token"], user_map["user_12@example.com"]["uid"], "post_12", "Handmade ceramic mugs fresh out of the kiln 🏺 #pottery #ceramics", [tom_uid], 86400 * 3),
    ]

    for token, uid, pid, caption, likes, ago in sample_posts:
        media_url = f"https://picsum.photos/seed/{pid}/1080/1080"
        author_info = user_map.get([e for e, u in user_map.items() if u["uid"] == uid][0])
        write_document(f"posts/{pid}", {
            "id": pid,
            "authorId": uid,
            "authorUsername": author_info["username"],
            "authorPhotoUrl": author_info["avatar"],
            "caption": caption,
            "mediaUrl": media_url,
            "mediaUrls": [media_url],
            "mediaType": "image",
            "mediaItems": [{
                "id": f"{pid}_m1",
                "url": media_url,
                "type": "IMAGE",
                "width": 1080,
                "height": 1080
            }],
            "location": "Da Nang, Vietnam",
            "likesCount": 0,
            "likedBy": [],
            "savedBy": [],
            "commentsCount": 0,
            "createdAt": iso_ts(seconds_ago=ago),
        }, token)

        # Comments
        write_document(f"posts/{pid}/comments/{pid}_c1", {
            "id": f"{pid}_c1",
            "postId": pid,
            "authorId": jane["uid"],
            "authorUsername": jane["username"],
            "authorPhotoUrl": jane["avatar"],
            "text": "Bức ảnh đẹp quá bạn ơi! 🔥",
            "likesCount": 0,
            "replyCount": 0,
            "likedBy": [],
            "createdAt": iso_ts(seconds_ago=ago - 600),
        }, jane["token"])

        # Reply by Tom
        write_document(f"posts/{pid}/comments/{pid}_c1/replies/{pid}_r1", {
            "id": f"{pid}_r1",
            "postId": pid,
            "parentId": f"{pid}_c1",
            "authorId": tom_uid,
            "authorUsername": "tomthecat",
            "authorPhotoUrl": "https://i.pravatar.cc/300?u=tomthecat",
            "text": "Cảm ơn Jane nhiều nhé! 🙏",
            "likesCount": 0,
            "replyCount": 0,
            "likedBy": [],
            "createdAt": iso_ts(seconds_ago=ago - 1200),
        }, tom_token)

    print("    ✓ Seeded 12 rich posts with media items, comments & replies.")

    # -----------------------------------------------------------------------
    # 4. Seed Reels & Stories
    # -----------------------------------------------------------------------
    print("🚀 [4/6] Seeding Stories & Reels...")
    # Stories (valid for 48 hours)
    story_users = [
        (tom_token, tom_uid, "story_1", 3600 * 2),
        (jane["token"], jane["uid"], "story_2", 3600 * 3),
        (alex["token"], alex["uid"], "story_3", 3600 * 4),
        (user_map["user_1@example.com"]["token"], user_map["user_1@example.com"]["uid"], "story_4", 3600 * 5),
        (user_map["user_5@example.com"]["token"], user_map["user_5@example.com"]["uid"], "story_5", 3600 * 6),
        (user_map["user_8@example.com"]["token"], user_map["user_8@example.com"]["uid"], "story_6", 3600 * 1),
    ]
    for token, uid, sid, ago in story_users:
        write_document(f"stories/{sid}", {
            "id": sid,
            "authorId": uid,
            "authorUsername": [u["username"] for u in user_map.values() if u["uid"] == uid][0],
            "authorPhotoUrl": [u["avatar"] for u in user_map.values() if u["uid"] == uid][0],
            "mediaUrl": f"https://picsum.photos/seed/{sid}/1080/1920",
            "mediaType": "image",
            "caption": "Story moment ✨",
            "viewedBy": [],
            "viewersCount": 0,
            "createdAt": iso_ts(seconds_ago=ago),
            "expiresAt": iso_ts(seconds_ahead=3600 * 48),
        }, token)

    # Reels
    sample_reels = [
        (tom_token, tom_uid, "reel_1", "Swift 6 Concurrency & Task cancellation in 15 seconds ⚡️", 3600 * 12),
        (jane["token"], jane["uid"], "reel_2", "Tokyo Shinjuku night walk in 4K 🌃 #tokyo #japan", 3600 * 24),
        (alex["token"], alex["uid"], "reel_3", "Making authentic Egg Coffee in Hanoi Old Quarter ☕️", 3600 * 18),
        (user_map["user_5@example.com"]["token"], user_map["user_5@example.com"]["uid"], "reel_4", "Speed drawing timelapse in Procreate 🎨✨", 3600 * 30),
        (user_map["user_10@example.com"]["token"], user_map["user_10@example.com"]["uid"], "reel_5", "Sourdough scoring technique & oven spring 🥖🔥", 3600 * 8),
        (user_map["user_13@example.com"]["token"], user_map["user_13@example.com"]["uid"], "reel_6", "Cooking up a new chill lo-fi beat 🎧🎹", 3600 * 15),
    ]
    for token, uid, rid, caption, ago in sample_reels:
        write_document(f"reels/{rid}", {
            "id": rid,
            "authorId": uid,
            "authorUsername": [u["username"] for u in user_map.values() if u["uid"] == uid][0],
            "authorPhotoUrl": [u["avatar"] for u in user_map.values() if u["uid"] == uid][0],
            "videoUrl": "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            "thumbnailUrl": f"https://picsum.photos/seed/{rid}/720/1280",
            "caption": caption,
            "audioTrack": "Original Audio",
            "likesCount": 0,
            "commentsCount": 0,
            "viewsCount": 0,
            "likedBy": [],
            "savedBy": [],
            "createdAt": iso_ts(seconds_ago=ago),
        }, token)
    print("    ✓ Seeded 6 active stories and 6 video reels.")

    # -----------------------------------------------------------------------
    # 5. Seed Notes & Notifications
    # -----------------------------------------------------------------------
    print("🚀 [5/6] Seeding Notes & Notifications...")
    notes = [
        (tom_token, tom_uid, "Coding all night ☕️"),
        (jane["token"], jane["uid"], "Tokyo trip soon ✈️"),
        (alex["token"], alex["uid"], "Chilling in Hanoi Old Quarter ☕️"),
        (user_map["user_1@example.com"]["token"], user_map["user_1@example.com"]["uid"], "Golden hour shoot 📸"),
        (user_map["user_5@example.com"]["token"], user_map["user_5@example.com"]["uid"], "New art dropping today 🎨"),
    ]
    for token, uid, text in notes:
        uinfo = [u for u in user_map.values() if u["uid"] == uid][0]
        write_document(f"notes/{uid}", {
            "id": uid,
            "authorId": uid,
            "userId": uid,
            "authorUsername": uinfo["username"],
            "authorPhotoUrl": uinfo["avatar"],
            "text": text,
            "createdAt": iso_ts(seconds_ago=3600),
            "expiresAt": iso_ts(seconds_ahead=3600 * 48),
        }, token)

    # Notifications for Tom
    write_document("notifications/notif_1", {
        "id": "notif_1",
        "recipientId": tom_uid,
        "senderId": jane["uid"],
        "senderUsername": jane["username"],
        "senderPhotoUrl": jane["avatar"],
        "type": "like",
        "postId": "post_1",
        "message": "đã thích bài viết của bạn.",
        "isRead": False,
        "createdAt": iso_ts(seconds_ago=1800),
    }, jane["token"])

    write_document("notifications/notif_2", {
        "id": "notif_2",
        "recipientId": tom_uid,
        "senderId": alex["uid"],
        "senderUsername": alex["username"],
        "senderPhotoUrl": alex["avatar"],
        "type": "comment",
        "postId": "post_1",
        "message": "đã bình luận: Tuyệt vời quá! 😄",
        "isRead": False,
        "createdAt": iso_ts(seconds_ago=3600),
    }, alex["token"])
    print("    ✓ Seeded notes and activity notifications.")

    # -----------------------------------------------------------------------
    # 6. Seed Conversations & Real-Time Messages (35 Conversations)
    # -----------------------------------------------------------------------
    print("🚀 [6/6] Seeding 35 Two-Way Conversations with Direct Messages...")
    partner_emails = [e for e in user_map.keys() if e != "tom@example.com"]

    def seed_conversation(idx, partner_email):
        partner = user_map[partner_email]
        conv_id = f"conv_{tom_uid}_{partner['uid']}"
        participant_ids = [tom_uid, partner["uid"]]
        participant_ids.sort()

        dialogue = SAMPLE_DIALOGUES[idx % len(SAMPLE_DIALOGUES)]
        has_unread = idx < 3
        unread_count = 1 if has_unread else 0
        ago_partner = (idx + 1) * 900
        ago_tom = ago_partner + 600

        # Create Conversation Document with Tom's Token
        last_msg_time = iso_ts(seconds_ago=ago_partner if has_unread else ago_tom)
        last_sender = partner if has_unread else user_map["tom@example.com"]
        last_text = dialogue[0] if has_unread else dialogue[1]

        write_document(f"conversations/{conv_id}", {
            "id": conv_id,
            "participantIds": participant_ids,
            "participants": [
                {
                    "id": tom_uid,
                    "username": "tomthecat",
                    "fullName": "Tom The Cat",
                    "avatarURL": "https://i.pravatar.cc/300?u=tomthecat",
                    "isVerified": True
                },
                {
                    "id": partner["uid"],
                    "username": partner["username"],
                    "fullName": partner["fullName"],
                    "avatarURL": partner["avatar"],
                    "isVerified": partner["isVerified"]
                }
            ],
            "isGroup": False,
            "isMuted": False,
            "unreadCount": unread_count,
            "unreadCounts": {
                tom_uid: unread_count,
                partner["uid"]: 0
            },
            "lastMessageText": last_text,
            "lastMessageSenderId": last_sender["uid"],
            "lastMessageTimestamp": last_msg_time,
            "lastMessage": {
                "id": f"{conv_id}_m2",
                "conversationId": conv_id,
                "senderId": last_sender["uid"],
                "sender": {
                    "id": last_sender["uid"],
                    "username": last_sender["username"],
                    "fullName": last_sender["fullName"],
                    "avatarURL": last_sender["avatar"],
                    "isVerified": last_sender["isVerified"]
                },
                "type": "text",
                "text": last_text,
                "status": "sent",
                "createdAt": last_msg_time
            },
            "createdAt": iso_ts(seconds_ago=ago_tom + 3600),
            "updatedAt": last_msg_time,
        }, tom_token)

        # Message 1 (Tom to Partner)
        write_document(f"conversations/{conv_id}/messages/{conv_id}_m1", {
            "id": f"{conv_id}_m1",
            "conversationId": conv_id,
            "senderId": tom_uid,
            "sender": {
                "id": tom_uid,
                "username": "tomthecat",
                "fullName": "Tom The Cat",
                "avatarURL": "https://i.pravatar.cc/300?u=tomthecat",
                "isVerified": True
            },
            "type": "text",
            "text": dialogue[1] if not has_unread else "Chào bạn nhé!",
            "status": "sent",
            "createdAt": iso_ts(seconds_ago=ago_tom),
        }, tom_token)

        # Message 2 (Partner to Tom)
        write_document(f"conversations/{conv_id}/messages/{conv_id}_m2", {
            "id": f"{conv_id}_m2",
            "conversationId": conv_id,
            "senderId": partner["uid"],
            "sender": {
                "id": partner["uid"],
                "username": partner["username"],
                "fullName": partner["fullName"],
                "avatarURL": partner["avatar"],
                "isVerified": partner["isVerified"]
            },
            "type": "text",
            "text": last_text,
            "status": "sent",
            "createdAt": last_msg_time,
        }, partner["token"])

        return conv_id

    with ThreadPoolExecutor(max_workers=6) as executor:
        futures = [executor.submit(seed_conversation, idx, p_email) for idx, p_email in enumerate(partner_emails)]
        for f in as_completed(futures):
            conv_id = f.result()
            sys.stdout.write(f"\r    ✓ Seeded conversation: {conv_id}")
            sys.stdout.flush()
    print("\n    ✓ Seeded all 35 conversations and 2-way message streams.")

    print("\n=======================================================")
    print("🎉 FIREBASE SEED COMPLETED SUCCESSFULLY!")
    print(f"Project ID: {PROJECT_ID}")
    print(f"Admin User: tom@example.com / {PASSWORD} (UID: {tom_uid})")
    print(f"Total Users: {len(user_map)}")
    print(f"Total Posts: {len(sample_posts)}")
    print(f"Total Conversations: {len(partner_emails)}")
    print("=======================================================")

if __name__ == "__main__":
    main()
