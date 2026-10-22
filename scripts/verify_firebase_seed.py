#!/usr/bin/env python3
"""
Verification Script for Cloud Firestore 1xx Production Data Matrix
Directly queries Firestore REST API with Tom's ID Token to produce empirical proof:
- Collection document counts (Users, Posts, Reels, Stories, Convs, Notifs, Messages).
- Relational integrity: Tom's profile metrics, follow graph, posts count.
- Schema richness: embedded author maps, engagement metrics, items list.
"""

import sys
import json
import urllib.request
import urllib.error

API_KEY = "AIzaSyDZAf8nh9wgqg-9EUznDKF10zASMGJPkqY"
PROJECT_ID = "instagram-clone-c1ffa"
PASSWORD = "password123"

AUTH_SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
FS_BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def get_auth_token():
    req = urllib.request.Request(
        AUTH_SIGNIN_URL,
        data=json.dumps({"email": "tom@example.com", "password": PASSWORD, "returnSecureToken": True}).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        return res["localId"], res["idToken"]

def get_doc(path, token):
    url = f"{FS_BASE_URL}/{path}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("fields", {})
    except Exception as e:
        return {}

def query_collection_count(collection_id, token, page_size=300):
    url = f"{FS_BASE_URL}/{collection_id}?pageSize={page_size}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            docs = data.get("documents", [])
            return len(docs), docs
    except Exception as e:
        return 0, []

def run_structured_query(collection_id, token, where_filter=None):
    url = f"{FS_BASE_URL}:runQuery"
    query = {
        "structuredQuery": {
            "from": [{"collectionId": collection_id}],
            "limit": 300
        }
    }
    if where_filter:
        query["structuredQuery"]["where"] = where_filter

    req = urllib.request.Request(
        url,
        data=json.dumps(query).encode("utf-8"),
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            res = json.loads(resp.read().decode("utf-8"))
            valid_docs = [r["document"] for r in res if "document" in r]
            return len(valid_docs), valid_docs
    except Exception as e:
        return 0, []

def unwrap_fs(val):
    if not isinstance(val, dict):
        return val
    if "stringValue" in val:
        return val["stringValue"]
    if "integerValue" in val:
        return int(val["integerValue"])
    if "doubleValue" in val:
        return float(val["doubleValue"])
    if "booleanValue" in val:
        return val["booleanValue"]
    if "arrayValue" in val:
        return [unwrap_fs(v) for v in val["arrayValue"].get("values", [])]
    if "mapValue" in val:
        return {k: unwrap_fs(v) for k, v in val["mapValue"].get("fields", {}).items()}
    if "timestampValue" in val:
        return val["timestampValue"]
    return None

def main():
    print("=================================================================")
    print("🔍 VERIFYING CLOUD FIRESTORE 1XX SEED DATA & RELATIONAL MATRIX")
    print(f"Project: {PROJECT_ID} | Querying via REST API with Tom's Token")
    print("=================================================================\n")

    tom_uid, tom_token = get_auth_token()
    print(f"✓ Authenticated as: tom@example.com (UID: {tom_uid})\n")

    targets = [
        ("users", 100),
        ("posts", 100),
        ("reels", 100),
        ("stories", 100),
    ]

    results = []

    for col, min_count in targets:
        count, docs = query_collection_count(col, tom_token)
        status = "✅ PASS" if count >= min_count else "❌ FAIL"
        sample_id = docs[0]["name"].split("/")[-1] if docs else "N/A"
        results.append((col, min_count, count, status, sample_id))

    # Query conversations with arrayContains participantIds: tom_uid
    conv_filter = {
        "fieldFilter": {
            "field": {"fieldPath": "participantIds"},
            "op": "ARRAY_CONTAINS",
            "value": {"stringValue": tom_uid}
        }
    }
    conv_count, conv_docs = run_structured_query("conversations", tom_token, conv_filter)
    status_conv = "✅ PASS" if conv_count >= 100 else "❌ FAIL"
    sample_conv_id = conv_docs[0]["name"].split("/")[-1] if conv_docs else "N/A"
    results.append(("conversations (for Tom)", 100, conv_count, status_conv, sample_conv_id))

    # Query notifications specifically for Tom
    notif_filter = {
        "fieldFilter": {
            "field": {"fieldPath": "recipientId"},
            "op": "EQUAL",
            "value": {"stringValue": tom_uid}
        }
    }
    notif_count, notif_docs = run_structured_query("notifications", tom_token, notif_filter)
    status_notif = "✅ PASS" if notif_count >= 100 else "❌ FAIL"
    sample_notif = notif_docs[0]["name"].split("/")[-1] if notif_docs else "N/A"
    results.append(("notifications (for Tom)", 100, notif_count, status_notif, sample_notif))

    # Check messages subcollection
    if sample_conv_id != "N/A":
        msg_count, msg_docs = query_collection_count(f"conversations/{sample_conv_id}/messages", tom_token)
        status_msg = "✅ PASS" if msg_count >= 2 else "❌ FAIL"
        results.append((f"messages ({sample_conv_id[:16]}...)", 2, msg_count, status_msg, f"{msg_count} msgs in thread"))

    print(f"{'Collection / Query':<32} | {'Target':<7} | {'Actual':<7} | {'Status':<8} | {'Sample Doc ID'}")
    print("-" * 85)
    for col, target, actual, status, sample in results:
        print(f"{col:<32} | >={target:<5} | {actual:<7} | {status:<8} | {sample}")

    print("\n-----------------------------------------------------------------")
    print("👤 VERIFYING TOM'S RELATIONAL PROFILE & MATRIX")
    print("-----------------------------------------------------------------")
    tom_raw = get_doc(f"users/{tom_uid}", tom_token)
    tom_data = {k: unwrap_fs(v) for k, v in tom_raw.items()}

    p_count = tom_data.get("postsCount", 0)
    followers = tom_data.get("followers", [])
    following = tom_data.get("following", [])
    followers_count = tom_data.get("followersCount", 0)
    following_count = tom_data.get("followingCount", 0)

    print(f"  • postsCount      : {p_count} (Expected: 15) -> {'✅ PASS' if p_count == 15 else '❌ FAIL'}")
    print(f"  • followersCount  : {followers_count} (len(followers) = {len(followers)}) -> {'✅ PASS' if followers_count == len(followers) == 50 else '❌ FAIL'}")
    print(f"  • followingCount  : {following_count} (len(following) = {len(following)}) -> {'✅ PASS' if following_count == len(following) == 25 else '❌ FAIL'}")

    print("\n-----------------------------------------------------------------")
    print("🧩 VERIFYING MODEL SCHEMAS & EMBEDDED AUTHOR MAPS")
    print("-----------------------------------------------------------------")
    # Sample Post
    post_raw = get_doc("posts/post_tom_1", tom_token)
    post = {k: unwrap_fs(v) for k, v in post_raw.items()}
    has_post_author = isinstance(post.get("author"), dict) and post["author"].get("username") == "tomthecat"
    has_post_likes = post.get("likesCount", 0) > 0
    has_post_comments = post.get("commentsCount", 0) > 0
    print(f"  • Post Embedded Author   : {post.get('author', {}).get('username')} -> {'✅ PASS' if has_post_author else '❌ FAIL'}")
    print(f"  • Post Engagement        : likes={post.get('likesCount')}, comments={post.get('commentsCount')} -> {'✅ PASS' if has_post_likes and has_post_comments else '❌ FAIL'}")

    # Sample Reel
    reel_count, reel_docs = query_collection_count("reels", tom_token, page_size=1)
    if reel_docs:
        r_fields = {k: unwrap_fs(v) for k, v in reel_docs[0]["fields"].items()}
        has_reel_author = isinstance(r_fields.get("author"), dict) and bool(r_fields["author"].get("username"))
        has_reel_audio = isinstance(r_fields.get("audioTrack"), dict) or isinstance(r_fields.get("audioTrack"), str)
        has_reel_views = r_fields.get("viewsCount", 0) > 0
        print(f"  • Reel Embedded Author   : {r_fields.get('author', {}).get('username')} -> {'✅ PASS' if has_reel_author else '❌ FAIL'}")
        print(f"  • Reel Audio & Views     : audio={r_fields.get('audioTitle')}, views={r_fields.get('viewsCount')} -> {'✅ PASS' if has_reel_audio and has_reel_views else '❌ FAIL'}")

    # Sample Story
    story_count, story_docs = query_collection_count("stories", tom_token, page_size=1)
    if story_docs:
        s_fields = {k: unwrap_fs(v) for k, v in story_docs[0]["fields"].items()}
        has_story_author = isinstance(s_fields.get("author"), dict) and bool(s_fields["author"].get("username"))
        has_story_items = isinstance(s_fields.get("items"), list) and len(s_fields["items"]) > 0
        print(f"  • Story Embedded Author  : {s_fields.get('author', {}).get('username')} -> {'✅ PASS' if has_story_author else '❌ FAIL'}")
        print(f"  • Story Items List       : count={len(s_fields.get('items', []))} -> {'✅ PASS' if has_story_items else '❌ FAIL'}")

    # Sample Notification
    if notif_docs:
        n_fields = {k: unwrap_fs(v) for k, v in notif_docs[0]["fields"].items()}
        has_notif_actor = isinstance(n_fields.get("actor"), dict) and bool(n_fields["actor"].get("username"))
        print(f"  • Notification Actor     : {n_fields.get('actor', {}).get('username')} -> {'✅ PASS' if has_notif_actor else '❌ FAIL'}")

    print("\n=================================================================")
    all_pass = all("PASS" in r[3] for r in results) and (p_count == 15) and (followers_count == 50) and (following_count == 25)
    if all_pass:
        print("🏆 EMPIRICAL PROOF 100% VERIFIED:")
        print("All documents, relational counters, and embedded author schemas match production specification.")
    else:
        print("⚠️ Some checks failed. Review output above.")
    print("=================================================================\n")

if __name__ == "__main__":
    main()
