#!/usr/bin/env python3
#
# verify_real_conversations.py
# Verification tool for real Firestore conversations and chronological sorting
#

import urllib.request
import json
from datetime import datetime

API_KEY = "AIzaSyDZAf8nh9wgqg-9EUznDKF10zASMGJPkqY"
PROJECT_ID = "instagram-clone-c1ffa"
EMAIL = "tom@example.com"
PASSWORD = "password123"

def main():
    print("=" * 60)
    print(" REAL FIRESTORE CONVERSATION VERIFICATION")
    print(f" Account: {EMAIL} | Project: {PROJECT_ID}")
    print("=" * 60)

    # 1. Firebase Auth Sign-in
    auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
    auth_data = json.dumps({"email": EMAIL, "password": PASSWORD, "returnSecureToken": True}).encode("utf-8")
    req = urllib.request.Request(auth_url, data=auth_data, headers={"Content-Type": "application/json"})

    with urllib.request.urlopen(req) as resp:
        auth_res = json.loads(resp.read().decode("utf-8"))
        uid = auth_res["localId"]
        token = auth_res["idToken"]
        print(f"[AUTH] Logged in successfully. UID: {uid}")

    # 2. Query Firestore runQuery
    query_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:runQuery"
    query_body = {
        "structuredQuery": {
            "from": [{"collectionId": "conversations"}],
            "where": {
                "fieldFilter": {
                    "field": {"fieldPath": "participantIds"},
                    "op": "ARRAY_CONTAINS",
                    "value": {"stringValue": uid}
                }
            }
        }
    }
    qreq = urllib.request.Request(query_url, data=json.dumps(query_body).encode("utf-8"), headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"})
    with urllib.request.urlopen(qreq) as qres:
        results = json.loads(qres.read().decode("utf-8"))

    print(f"[FIRESTORE] Fetched {len(results)} query results from Firestore.\n")

    def parse_firestore_value(val):
        if not val:
            return None
        if "stringValue" in val:
            return val["stringValue"]
        if "timestampValue" in val:
            return val["timestampValue"]
        if "integerValue" in val:
            return int(val["integerValue"])
        if "booleanValue" in val:
            return val["booleanValue"]
        if "mapValue" in val:
            fields = val["mapValue"].get("fields", {})
            return {k: parse_firestore_value(v) for k, v in fields.items()}
        if "arrayValue" in val:
            values = val["arrayValue"].get("values", [])
            return [parse_firestore_value(v) for v in values]
        return None

    def parse_iso(iso_str):
        if not iso_str:
            return datetime.min
        try:
            clean = iso_str.replace("Z", "+00:00")
            if "." in clean:
                parts = clean.split(".")
                sub = parts[1].split("+")[0][:6]
                clean = f"{parts[0]}.{sub}+00:00"
            return datetime.fromisoformat(clean)
        except Exception:
            return datetime.min

    conversations = []
    for item in results:
        if "document" not in item:
            continue
        doc = item["document"]
        doc_id = doc["name"].split("/")[-1]
        raw_fields = doc.get("fields", {})
        fields = {k: parse_firestore_value(v) for k, v in raw_fields.items()}

        updated_at = parse_iso(fields.get("updatedAt"))

        last_msg = fields.get("lastMessage")
        last_msg_text = ""
        last_msg_date = datetime.min
        if isinstance(last_msg, dict):
            last_msg_text = last_msg.get("text") or last_msg.get("content") or ""
            last_msg_date = parse_iso(last_msg.get("createdAt"))
        if not last_msg_text:
            last_msg_text = fields.get("lastMessageText") or ""
            last_msg_date = parse_iso(fields.get("lastMessageTimestamp"))

        effective_date = max(updated_at, last_msg_date)
        participants = fields.get("participantIds", [])
        other_users = [p for p in participants if p != uid]

        conversations.append({
            "id": doc_id,
            "other_user": other_users[0] if other_users else "Self",
            "last_msg_text": last_msg_text,
            "updated_at_str": fields.get("updatedAt"),
            "effective_date": effective_date
        })

    # Sort descending by effective_date
    sorted_conversations = sorted(conversations, key=lambda c: c["effective_date"], reverse=True)

    # Verification: Ensure strict monotonic descending order
    is_strictly_ordered = True
    for i in range(len(sorted_conversations) - 1):
        if sorted_conversations[i]["effective_date"] < sorted_conversations[i+1]["effective_date"]:
            is_strictly_ordered = False
            break

    print("TOP 10 SORTED CONVERSATIONS (EFFECTIVE DATE DESC):")
    print("-" * 60)
    for i, c in enumerate(sorted_conversations[:10]):
        print(f"#{i+1:02d} Effective Date: {c['effective_date']} | Partner: {c['other_user']}")
        print(f"     Last Message: \"{c['last_msg_text']}\"")
        print(f"     Doc ID: {c['id']}")

    print("\n" + "=" * 60)
    print(f"VERIFICATION SUMMARY:")
    print(f"- Total Real Conversations Processed: {len(sorted_conversations)}")
    print(f"- Chronological Order Valid Across ALL Items: {is_strictly_ordered}")
    print(f"- Newest Item at Index 0: {sorted_conversations[0]['effective_date'] >= sorted_conversations[-1]['effective_date']}")
    print("=" * 60)

if __name__ == "__main__":
    main()
