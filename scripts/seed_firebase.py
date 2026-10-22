#!/usr/bin/env python3
"""
Instagram iOS Firebase REST Seeder - 1xx Scale Edition
Seeds 100+ documents per table on Cloud Firestore via official REST APIs.
Maintains 100% Relational Matrix Integrity and Zero Permission Denied compliance.
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
    try:
        res = http_post(AUTH_SIGNIN_URL, {
            "email": email,
            "password": PASSWORD,
            "returnSecureToken": True
        })
        return res["localId"], res["idToken"]
    except RuntimeError:
        pass

    try:
        res = http_post(AUTH_SIGNUP_URL, {
            "email": email,
            "password": PASSWORD,
            "returnSecureToken": True
        })
        return res["localId"], res["idToken"]
    except RuntimeError:
        res = http_post(AUTH_SIGNIN_URL, {
            "email": email,
            "password": PASSWORD,
            "returnSecureToken": True
        })
        return res["localId"], res["idToken"]

def write_document(path, fields_dict, token, skip_if_exists=True):
    url = f"{FS_BASE_URL}/{path}"
    if skip_if_exists:
        try:
            req_get = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
            with urllib.request.urlopen(req_get, timeout=5) as resp:
                if resp.status == 200:
                    return {"name": path, "skipped": True}
        except urllib.error.HTTPError as e:
            if e.code == 404:
                pass
        except Exception:
            pass

    fs_body = {"fields": {k: to_fs(v) for k, v in fields_dict.items()}}
    return http_post(url, fs_body, headers={"Authorization": f"Bearer {token}"}, method="PATCH")

# ---------------------------------------------------------------------------
# Dynamic 105 User Pool Generator
# ---------------------------------------------------------------------------

OCCUPATIONS = [
    ("Photographer 📸 | 35mm film & Canon EOS", "photography"),
    ("Specialty Coffee Roaster ☕️ | Origin stories", "coffee"),
    ("UI/UX Designer ✨ | Design systems & motion", "design"),
    ("Mobile Engineer 📱 | Swift 6 & iOS architecture", "tech"),
    ("Ceramics & Pottery Artist 🏺 | Wheel throwing", "craft"),
    ("Digital Artist 🎨 | Procreate & conceptual art", "art"),
    ("Travel Blogger 🌍 | Living between Da Nang & Tokyo", "travel"),
    ("Pastry Chef 🥐 | French patisserie & sourdough", "culinary"),
    ("Yoga & Mindfulness Coach 🧘‍♀️ | Breath & body", "fitness"),
    ("Sound Engineer & Producer 🎧 | Chill lo-fi beats", "music"),
    ("Fashion Stylist 👗 | Modern vintage aesthetics", "fashion"),
    ("Architecture & Urban Sketcher 🏛️ | Saigon lines", "architecture"),
    ("Botanist & Plant Collector 🌿 | Rare aroids", "nature"),
    ("Marathon Runner 🏃‍♂️ | Sub-3 training & endurance", "sports"),
    ("Drone Pilot & Cinematographer 🚁 | 4K aerials", "video"),
    ("Independent Book Reviewer 📚 | Literature addict", "books"),
    ("Indie Game Developer 🎮 | Pixel art & chiptunes", "gaming"),
]

FIRST_NAMES_ASCII = [
    "minh", "hoang", "quoc", "phuong", "thu", "lan", "thao", "huong",
    "bao", "tuan", "duc", "tri", "ngoc", "huyen", "khanh", "thanh",
    "viet", "anh", "quang", "duy", "huy", "nam", "mai", "tien"
]

FIRST_NAMES = [
    "Minh", "Hoàng", "Quốc", "Phương", "Thu", "Lan", "Thảo", "Hương",
    "Bảo", "Tuấn", "Đức", "Trí", "Ngọc", "Huyền", "Khánh", "Thanh",
    "Việt", "Anh", "Quang", "Duy", "Huy", "Nam", "Mai", "Tiên"
]

LAST_NAMES = [
    "Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ",
    "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương", "Lý"
]

VIDEO_URLS = [
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4",
    "https://storage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4",
]

LOCATIONS = [
    "Da Nang, Vietnam",
    "Hanoi Old Quarter, Vietnam",
    "District 1, Ho Chi Minh City",
    "Bà Nà Hills, Da Nang",
    "Hồ Hoàn Kiếm, Hanoi",
    "Phố cổ Hội An, Quang Nam",
    "Shinjuku, Tokyo, Japan",
    "Da Lat, Lam Dong",
    "Phú Quốc Island, Kien Giang",
    "Sa Pa, Lao Cai"
]

SAMPLE_DIALOGUES = [
    ("Chào bạn, khi nào rảnh ghé quán thử mẻ cà phê mới rang nhé!", "Chắc chắn rồi, cuối tuần này mình qua nha!"),
    ("Bộ ảnh chụp ở Đà Nẵng đẹp quá bạn ơi!", "Cảm ơn bạn, hôm nào cùng đi chụp ảnh nhé."),
    ("Tài liệu kiến trúc hệ thống bạn gửi đọc rất dễ hiểu.", "Cảm ơn bạn, có thắc mắc gì cứ hỏi mình nhé."),
    ("Dự án iOS đợt này chạy mượt mà trên ProMotion 120 FPS luôn.", "Tuyệt vời, chúc mừng team nhé!"),
    ("Workshop làm gốm tuần tới còn chỗ không bạn?", "Còn bạn nhé, bạn đăng ký qua link ở bio nha."),
    ("Track nhạc mới nghe chill thực sự 🎧", "Cảm ơn bạn đã lắng nghe và ủng hộ nha!"),
    ("Mẫu thiết kế UI mới trông rất hiện đại và tinh tế.", "Cảm ơn góp ý của bạn, mình vừa cập nhật component."),
    ("Hôm nào cà phê chia sẻ về kinh nghiệm làm mobile app nhé!", "Sẵn sàng luôn, hẹn bạn chiều thứ Bảy."),
    ("Bài viết mới của bạn trên feed hay lắm!", "Cảm ơn bạn nhiều, mình đang viết phần 2."),
    ("Góc chụp này ánh sáng tự nhiên đẹp tuyệt cú mèo!", "Đúng rồi, mình căn đúng khung giờ vàng golden hour đấy."),
]

def generate_user_definitions():
    users = [
        ("jane@example.com", "jane_doe", "Jane Doe", "Travel photographer 📸 Living between Tokyo & Da Nang", True),
        ("alex@example.com", "alex_nguyen", "Alex Nguyen", "Hanoi • Street food • 35mm film photos 🎞️", False),
    ]
    for i in range(1, 103):
        fn = FIRST_NAMES[i % len(FIRST_NAMES)]
        fn_ascii = FIRST_NAMES_ASCII[i % len(FIRST_NAMES_ASCII)]
        ln = LAST_NAMES[(i * 3) % len(LAST_NAMES)]
        occ, tag = OCCUPATIONS[i % len(OCCUPATIONS)]
        uname = f"{tag}_{fn_ascii}_{i}"
        full_name = f"{ln} {fn}"
        email = f"user_{i}@example.com"
        is_verified = (i % 7 == 0)
        users.append((email, uname, full_name, occ, is_verified))
    return users

# ---------------------------------------------------------------------------
# Main Execution
# ---------------------------------------------------------------------------

def main():
    print("=================================================================")
    print("🚀 INSTAGRAM FIREBASE SEEDER (1xx SCALE PRODUCTION DATA MATRIX)")
    print(f"Target: Project {PROJECT_ID} | 100+ documents per collection")
    print("=================================================================\n")

    # 1. Admin Authentication (Tom The Cat)
    print("📦 [1/7] Authenticating & Verifying Primary Admin User (tom@example.com)...")
    tom_uid, tom_token = ensure_auth_user("tom@example.com", "Tom The Cat")
    print(f"    ✓ Tom authenticated: UID={tom_uid}")

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
        "postsCount": 15,
        "createdAt": iso_ts(seconds_ago=86400 * 60),
    }, tom_token)

    # 2. 104 Partner Accounts Authentication & Seeding
    print("\n📦 [2/7] Authenticating & Seeding 104 Partner Accounts...")
    user_defs = generate_user_definitions()
    user_map = {
        "tom@example.com": {
            "uid": tom_uid,
            "token": tom_token,
            "username": "tomthecat",
            "fullName": "Tom The Cat",
            "avatar": "https://i.pravatar.cc/300?u=tomthecat",
            "isVerified": True
        }
    }

    def seed_single_user(u_def):
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
            "followersCount": 200 + (len(username) * 31) % 600,
            "followingCount": 100 + (len(username) * 17) % 300,
            "postsCount": 1 + (len(username) % 4),
            "createdAt": iso_ts(seconds_ago=86400 * 45),
        }, token)
        return email, {
            "uid": uid,
            "token": token,
            "username": username,
            "fullName": fullName,
            "avatar": avatar,
            "isVerified": isVerified
        }

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(seed_single_user, u) for u in user_defs]
        count = 0
        for f in as_completed(futures):
            email, data = f.result()
            user_map[email] = data
            count += 1
            if count % 15 == 0 or count == len(user_defs):
                sys.stdout.write(f"\r    ✓ Progress: {count}/{len(user_defs)} partner accounts seeded.")
                sys.stdout.flush()
    print(f"\n    ✓ User Pool Total: {len(user_map)} active authenticated profiles.")

    partners = sorted([u for u in user_map.values() if u["uid"] != tom_uid], key=lambda u: u["username"])
    all_users = [user_map["tom@example.com"]] + partners

    # 3. Posts Matrix (105 Posts)
    print("\n📦 [3/7] Seeding 105 Posts (Single Image, Carousel & Video) + Comments Matrix...")
    posts_data = []

    # 15 Posts for Tom
    tom_captions = [
        "Coding Instagram clone with Firebase BaaS integration! 🚀💻 #ios #swift #cleanarchitecture",
        "Coffee and Swift 6 concurrency on a rainy morning ☕️⚡️ #swift6 #coffeelover",
        "Exploring Da Nang coastal road with my vintage camera 📸🌊 #danang #vietnam",
        "New UI component library running smooth at 120 FPS ProMotion ✨📱 #swiftui",
        "Sunday afternoon reading Clean Architecture by Uncle Bob 📖☕️ #softwareengineering",
        "Testing AVAssetWriter and CVPixelBufferPool for 4K video rendering 🎬⚡️ #iosdev",
        "Sunset view from Ba Na Hills! Absolutely magical 🌄✨ #travel #sunset",
        "Specialty pour-over coffee: Ethiopia Yirgacheffe notes of jasmine & peach ☕️🍑",
        "Building offline-first realtime sync with Cloud Firestore ☁️🔥 #firebase",
        "Hanoi Old Quarter walk during autumn season 🍂🏮 #hanoi #autumn",
        "Zero memory leak achieved with strict autoreleasepool wrapping 🛡️🚀 #performance",
        "Figma design tokens transformed into type-safe Swift enums 🎨💻 #designsystem",
        "A peaceful morning in Hội An ancient town 🏮🛶 #hoian #vietnam",
        "Refactoring ViewModel state with Swift 6 actors for thread safety 🛡️⚡️",
        "Milestone reached: 100+ unit tests passing with zero compiler warnings! 🎯💯"
    ]
    for idx, caption in enumerate(tom_captions, 1):
        posts_data.append((tom_token, tom_uid, f"post_tom_{idx}", caption, LOCATIONS[idx % len(LOCATIONS)], 86400 * (idx * 2)))

    # 90 Posts for Partners
    partner_post_templates = [
        "Golden hour photography session at the beach 🌅📸 #photography #goldenhour",
        "Fresh batch of artisan sourdough bread out of the hearth oven 🥖🔥 #baking #artisan",
        "Morning yoga flow and mindful breathing practice 🧘‍♀️🌿 #yoga #mindfulness",
        "Ceramic mugs handmade on the pottery wheel 🏺✨ #ceramics #craft",
        "New UI layout design for our mobile application 📱🎨 #figma #uiux",
        "Weekend cycling trip across the countryside 🚴‍♂️🌾 #cycling #outdoors",
        "Pouring fresh latte art at our neighborhood cafe ☕️🎨 #latteart #barista",
        "A quiet evening sketching Saigon's historical architecture 🏛️✏️ #sketching",
        "Testing our new drone camera over the mountains 🚁🏔️ #drone #4k",
        "Reading a classic novel under the shade of a banyan tree 📚🌿 #bookworm",
    ]
    for idx in range(1, 91):
        partner = partners[(idx - 1) % len(partners)]
        caption = f"{partner_post_templates[idx % len(partner_post_templates)]} · Session #{idx}"
        pid = f"post_{partner['uid'][:8]}_{idx}"
        posts_data.append((partner["token"], partner["uid"], pid, caption, LOCATIONS[idx % len(LOCATIONS)], 86400 * (idx % 30 + 1)))

    def seed_single_post(item):
        token, uid, pid, caption, loc, ago = item
        uinfo = [u for u in all_users if u["uid"] == uid][0]
        media_url = f"https://picsum.photos/seed/{pid}/1080/1080"
        is_carousel = (hash(pid) % 5 == 0)

        media_items = [{
            "id": f"{pid}_m1",
            "url": media_url,
            "type": "IMAGE",
            "width": 1080,
            "height": 1080
        }]
        if is_carousel:
            media_items.append({
                "id": f"{pid}_m2",
                "url": f"https://picsum.photos/seed/{pid}_b/1080/1080",
                "type": "IMAGE",
                "width": 1080,
                "height": 1080
            })

        # Create post complying with isFreshInteractions
        write_document(f"posts/{pid}", {
            "id": pid,
            "authorId": uid,
            "authorUsername": uinfo["username"],
            "authorPhotoUrl": uinfo["avatar"],
            "caption": caption,
            "mediaUrl": media_url,
            "mediaUrls": [m["url"] for m in media_items],
            "mediaType": "carousel" if is_carousel else "image",
            "mediaItems": media_items,
            "location": loc,
            "likesCount": 0,
            "commentsCount": 0,
            "replyCount": 0,
            "likes": [],
            "likedBy": [],
            "savedBy": [],
            "createdAt": iso_ts(seconds_ago=ago),
        }, token)

        # Seed 1 comment from another user
        c_author = partners[(hash(pid) + 3) % len(partners)]
        cid = f"{pid}_c_{c_author['uid'][:8]}"
        write_document(f"posts/{pid}/comments/{cid}", {
            "id": cid,
            "postId": pid,
            "authorId": c_author["uid"],
            "authorUsername": c_author["username"],
            "authorPhotoUrl": c_author["avatar"],
            "text": "Bức ảnh này màu sắc và góc nhìn đẹp quá bạn ơi! 🔥✨",
            "likesCount": 0,
            "commentsCount": 0,
            "replyCount": 0,
            "likes": [],
            "likedBy": [],
            "savedBy": [],
            "createdAt": iso_ts(seconds_ago=ago - 600),
        }, c_author["token"])

        return pid

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(seed_single_post, p) for p in posts_data]
        count = 0
        for f in as_completed(futures):
            f.result()
            count += 1
            if count % 20 == 0 or count == len(posts_data):
                sys.stdout.write(f"\r    ✓ Progress: {count}/{len(posts_data)} posts + comments created.")
                sys.stdout.flush()
    print(f"\n    ✓ Posts Matrix Total: {len(posts_data)} posts (15 by Tom, 90 by partners).")

    # 4. Reels Matrix (100 Reels)
    print("\n📦 [4/7] Seeding 100 Video Reels (9:16 vertical stream)...")
    reels_data = []
    reel_captions = [
        "Swift 6 Concurrency & Task cancellation in 15 seconds ⚡️📱 #swift #ios",
        "Tokyo Shinjuku night walk in 4K HDR 🌃🇯🇵 #tokyo #travel",
        "Making authentic Vietnamese Egg Coffee step-by-step ☕️🥚 #eggcoffee",
        "Speed painting timelapse on iPad Pro with Procreate 🎨✨ #digitalart",
        "Artisan sourdough scoring technique & oven spring 🥖🔥 #baking",
        "Behind the scenes: Producing a chill lo-fi beat in Logic Pro 🎧🎹",
        "10-minute core workout routine for morning energy 🧘‍♀️💪 #fitness",
        "Handmade ceramic trimming on the pottery wheel 🏺✨ #ceramics",
        "Flying through misty mountain peaks at sunrise 🚁🌄 #drone #cinematography",
        "Street photography candid portrait tricks with 35mm lens 📸🎞️ #photography"
    ]
    for idx in range(1, 101):
        creator = partners[(idx * 2) % len(partners)]
        caption = f"{reel_captions[idx % len(reel_captions)]} · Reel #{idx}"
        rid = f"reel_{creator['uid'][:8]}_{idx}"
        reels_data.append((creator["token"], creator["uid"], rid, caption, idx))

    def seed_single_reel(item):
        token, uid, rid, caption, idx = item
        uinfo = [u for u in all_users if u["uid"] == uid][0]
        video_url = VIDEO_URLS[idx % len(VIDEO_URLS)]
        thumb_url = f"https://picsum.photos/seed/{rid}/720/1280"

        write_document(f"reels/{rid}", {
            "id": rid,
            "authorId": uid,
            "authorUsername": uinfo["username"],
            "authorPhotoUrl": uinfo["avatar"],
            "videoUrl": video_url,
            "thumbnailUrl": thumb_url,
            "caption": caption,
            "audioTrack": "Original Audio",
            "audioTitle": "Original Audio",
            "likesCount": 0,
            "commentsCount": 0,
            "replyCount": 0,
            "viewsCount": 0,
            "likes": [],
            "likedBy": [],
            "savedBy": [],
            "createdAt": iso_ts(seconds_ago=3600 * (idx * 2)),
        }, token)
        return rid

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(seed_single_reel, r) for r in reels_data]
        count = 0
        for f in as_completed(futures):
            f.result()
            count += 1
            if count % 20 == 0 or count == len(reels_data):
                sys.stdout.write(f"\r    ✓ Progress: {count}/{len(reels_data)} reels created.")
                sys.stdout.flush()
    print(f"\n    ✓ Reels Total: {len(reels_data)} vertical videos seeded.")

    # 5. Stories Matrix (100 Stories)
    print("\n📦 [5/7] Seeding 100 Active Stories (48h-120h validity)...")
    stories_data = []
    for idx in range(1, 101):
        creator = all_users[idx % len(all_users)]
        sid = f"story_{creator['uid'][:8]}_{idx}"
        stories_data.append((creator["token"], creator["uid"], sid, idx))

    def seed_single_story(item):
        token, uid, sid, idx = item
        uinfo = [u for u in all_users if u["uid"] == uid][0]
        write_document(f"stories/{sid}", {
            "id": sid,
            "authorId": uid,
            "authorUsername": uinfo["username"],
            "authorPhotoUrl": uinfo["avatar"],
            "mediaUrl": f"https://picsum.photos/seed/{sid}/1080/1920",
            "mediaType": "image",
            "caption": f"Story moment #{idx} ✨",
            "viewedBy": [],
            "viewerIds": [],
            "views": [],
            "viewersCount": 0,
            "createdAt": iso_ts(seconds_ago=1800 * idx),
            "expiresAt": iso_ts(seconds_ahead=3600 * 96), # 4 days ahead
        }, token)
        return sid

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(seed_single_story, s) for s in stories_data]
        count = 0
        for f in as_completed(futures):
            f.result()
            count += 1
            if count % 20 == 0 or count == len(stories_data):
                sys.stdout.write(f"\r    ✓ Progress: {count}/{len(stories_data)} stories created.")
                sys.stdout.flush()
    print(f"\n    ✓ Stories Total: {len(stories_data)} active stories seeded.")

    # 6. Notes Matrix (60 Notes)
    print("\n📦 [6/7] Seeding 60 Notes for Direct Messages top bar...")
    notes_data = [
        "Coding all night ☕️", "Chilling in Da Nang 🌊", "Tokyo trip soon ✈️",
        "New art dropping today 🎨", "Sourdough fresh out of oven 🥐",
        "Swift 6 rocks 🚀", "Golden hour photography 📸", "Film photo lab day 🎞️",
        "Morning yoga routine 🧘‍♀️", "Lo-fi beats in progress 🎧"
    ]
    active_note_users = all_users[:60]
    for idx, user in enumerate(active_note_users):
        note_text = notes_data[idx % len(notes_data)]
        write_document(f"notes/{user['uid']}", {
            "id": user["uid"],
            "authorId": user["uid"],
            "userId": user["uid"],
            "authorUsername": user["username"],
            "authorPhotoUrl": user["avatar"],
            "text": note_text,
            "createdAt": iso_ts(seconds_ago=1800),
            "expiresAt": iso_ts(seconds_ahead=3600 * 72),
        }, user["token"])
    print(f"    ✓ Notes Total: {len(active_note_users)} notes active.")

    # 7. Direct Messages & Notifications Matrix (100 Conversations & 100 Notifications)
    print("\n📦 [7/7] Seeding 100 Conversations (2-Way Dialogue) & 100 Notifications for Tom...")
    target_partners = partners[:100]

    def seed_single_conversation(idx, partner):
        conv_id = f"conv_{tom_uid}_{partner['uid']}"
        participant_ids = [tom_uid, partner["uid"]]
        participant_ids.sort()

        dialogue = SAMPLE_DIALOGUES[idx % len(SAMPLE_DIALOGUES)]
        has_unread = (idx < 10) # 10 first convs have unread badge
        unread_count = 1 if has_unread else 0
        ago_partner = (idx + 1) * 600
        ago_tom = ago_partner + 300

        last_msg_time = iso_ts(seconds_ago=ago_partner if has_unread else ago_tom)
        last_sender = partner if has_unread else user_map["tom@example.com"]
        last_text = dialogue[0] if has_unread else dialogue[1]

        # 1. Conversation Document
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

        # 2. Messages Subcollection
        # Message 1 from Tom
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

        # Message 2 from Partner
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

        # 3. Notification for Tom (from this partner)
        notif_id = f"notif_{partner['uid'][:8]}_{idx + 1}"
        notif_types = ["like", "comment", "follow"]
        n_type = notif_types[idx % 3]
        target_post = f"post_tom_{(idx % 15) + 1}"
        n_msg = "đã thích bài viết của bạn." if n_type == "like" else ("đã bình luận trên bài viết của bạn." if n_type == "comment" else "đã bắt đầu theo dõi bạn.")

        write_document(f"notifications/{notif_id}", {
            "id": notif_id,
            "recipientId": tom_uid,
            "senderId": partner["uid"],
            "senderUsername": partner["username"],
            "senderPhotoUrl": partner["avatar"],
            "type": n_type,
            "postId": target_post if n_type != "follow" else "",
            "message": n_msg,
            "isRead": False,
            "createdAt": iso_ts(seconds_ago=ago_partner),
        }, partner["token"])

        return conv_id

    with ThreadPoolExecutor(max_workers=10) as executor:
        futures = [executor.submit(seed_single_conversation, idx, p) for idx, p in enumerate(target_partners)]
        count = 0
        for f in as_completed(futures):
            f.result()
            count += 1
            if count % 20 == 0 or count == len(target_partners):
                sys.stdout.write(f"\r    ✓ Progress: {count}/{len(target_partners)} convs + messages + notifs seeded.")
                sys.stdout.flush()
    print(f"\n    ✓ Convs & Notifications Total: {len(target_partners)} convs and {len(target_partners)} notifications seeded.")

    print("\n=================================================================")
    print("🎉 ALL 1XX PRODUCTION DATA MATRIX SEEDED SUCCESSFULLY ON FIREBASE!")
    print(f"Project ID: {PROJECT_ID}")
    print(f"Admin User: tom@example.com / {PASSWORD} (UID: {tom_uid})")
    print(f"Total Users: {len(all_users)}")
    print(f"Total Posts: {len(posts_data)}")
    print(f"Total Reels: {len(reels_data)}")
    print(f"Total Stories: {len(stories_data)}")
    print(f"Total Notes: {len(active_note_users)}")
    print(f"Total Conversations: {len(target_partners)}")
    print(f"Total Notifications: {len(target_partners)}")
    print("=================================================================\n")

if __name__ == "__main__":
    main()
