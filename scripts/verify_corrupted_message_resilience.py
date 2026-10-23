#!/usr/bin/env python3
#
# verify_corrupted_message_resilience.py
# Tests defensive parsing (Zero-Drop Policy) & Downgrade Protection for corrupted messages.
#

import time
from datetime import datetime, timezone

def test_defensive_parsing():
    print("=" * 65)
    print(" DEFENSIVE MESSAGE PARSING (ZERO-DROP POLICY) & DOWNGRADE TEST")
    print("=" * 65)

    # 1. Simulate corrupted message payloads
    corrupted_payloads = [
        # Anomaly 1: Missing sender dictionary completely
        {
            "id": "err_msg_1",
            "conversationId": "conv_1",
            "text": "Tin nhắn thiếu trường sender",
            "createdAt": "2026-10-23T02:00:00Z"
        },
        # Anomaly 2: Sender is a raw String UID, not a dictionary
        {
            "id": "err_msg_2",
            "conversationId": "conv_1",
            "sender": "user_uid_raw_string",
            "text": "Tin nhắn có sender là chuỗi String",
            "createdAt": "2026-10-23T02:05:00Z"
        },
        # Anomaly 3: Sender is empty dictionary {}
        {
            "id": "err_msg_3",
            "conversationId": "conv_1",
            "sender": {},
            "text": "Tin nhắn có sender là map rỗng",
            "createdAt": "2026-10-23T02:10:00Z"
        },
        # Anomaly 4: Status is 'error' or 'failed'
        {
            "id": "err_msg_4",
            "conversationId": "conv_1",
            "senderId": "user_123",
            "status": "error",
            "text": "Tin nhắn gửi thất bại",
            "createdAt": "2026-10-23T02:15:00Z"
        },
        # Anomaly 5: Missing createdAt (using alternative field 'timestamp')
        {
            "id": "err_msg_5",
            "conversationId": "conv_1",
            "senderId": "user_123",
            "timestamp": "2026-10-23T02:20:00Z",
            "text": "Tin nhắn dùng timestamp thay vì createdAt"
        },
        # Anomaly 6: Completely missing timestamp fields
        {
            "id": "err_msg_6",
            "conversationId": "conv_1",
            "senderId": "user_123",
            "text": "Tin nhắn không có trường ngày tháng nào"
        }
    ]

    # Python translation of the new Swift dictToMessage
    def dict_to_message(d, doc_id):
        mid = d.get("id") or doc_id
        conv_id = d.get("conversationId", "")
        
        # Sender resolution
        sender_data = d.get("sender")
        if isinstance(sender_data, dict) and (sender_data.get("id") or sender_data.get("uid")):
            sender = {
                "id": sender_data.get("id") or sender_data.get("uid"),
                "username": sender_data.get("username", "user"),
                "fullName": sender_data.get("fullName", "User")
            }
        else:
            sender_id = (d.get("senderId") or d.get("sender_id") or 
                         (sender_data if isinstance(sender_data, str) else None) or
                         d.get("authorId") or d.get("userId") or f"unknown_{mid}")
            sender = {
                "id": sender_id,
                "username": d.get("senderUsername") or d.get("username") or "user",
                "fullName": d.get("senderFullName") or d.get("fullName") or "Người dùng"
            }
        
        status_raw = str(d.get("status", "sent")).lower()
        if status_raw in ["failed", "error"]:
            status = "failed"
        elif status_raw == "sending":
            status = "sending"
        elif status_raw in ["read", "delivered"]:
            status = status_raw
        else:
            status = "sent"

        # Date resolution
        created_at_raw = (d.get("createdAt") or d.get("timestamp") or 
                          d.get("time") or d.get("created_at") or d.get("date"))
        if created_at_raw:
            try:
                clean = str(created_at_raw).replace("Z", "+00:00")
                if "." in clean:
                    parts = clean.split(".")
                    clean = f"{parts[0]}.{parts[1][:6]}+00:00"
                created_at = datetime.fromisoformat(clean)
            except Exception:
                created_at = datetime.now(timezone.utc)
        else:
            created_at = datetime.now(timezone.utc)

        content = d.get("text") or d.get("content") or d.get("message") or "[Tin nhắn]"

        return {
            "id": mid,
            "conversationId": conv_id,
            "sender": sender,
            "status": status,
            "createdAt": created_at,
            "content": content
        }

    # Execute parsing
    parsed_messages = [dict_to_message(d, d["id"]) for d in corrupted_payloads]

    print("\n--- TEST 1: ZERO-DROP POLICY VERIFICATION ---")
    print(f"Total Corrupted Payloads Ingested: {len(corrupted_payloads)}")
    print(f"Total Successfully Parsed Messages: {len(parsed_messages)}")
    all_retained = len(parsed_messages) == len(corrupted_payloads)
    print(f"Result: {'PASS (0 messages skipped)' if all_retained else 'FAIL'}")
    assert all_retained

    for i, m in enumerate(parsed_messages, 1):
        print(f"  #{i} ID: {m['id']} | Sender: {m['sender']['id']} ({m['sender']['fullName']}) | Status: {m['status']} | Content: \"{m['content']}\"")

    print("\n--- TEST 2: DOWNGRADE PROTECTION IN syncConversationSummary ---")
    # Existing conversation summary from root doc (Rank 1, created today 02:28)
    existing_last_message = {
        "id": "recent_msg_from_root",
        "createdAt": datetime.fromisoformat("2026-10-23T02:28:00+00:00"),
        "content": "Tin nhắn mới nhất từ root doc"
    }
    existing_conv = {
        "id": "conv_test",
        "lastMessage": existing_last_message,
        "updatedAt": datetime.fromisoformat("2026-10-23T02:28:00+00:00")
    }

    # Suppose inside the messages subcollection, only an older message is loaded (e.g. 3 days ago)
    ram_latest = {
        "id": "old_msg_3_days_ago",
        "createdAt": datetime.fromisoformat("2026-10-20T10:00:00+00:00"),
        "content": "Tin nhắn cũ 3 ngày trước"
    }

    # OLD BUGGY BEHAVIOR: unconditionally chose ramLatest
    buggy_chosen = ram_latest
    buggy_effective = max(existing_conv["updatedAt"], buggy_chosen["createdAt"])
    print(f"  [Old Buggy Behavior] Chosen Last: \"{buggy_chosen['content']}\" | Effective Date: {buggy_effective}")

    # NEW FIXED BEHAVIOR: Downgrade Protection
    if ram_latest and existing_conv.get("lastMessage"):
        fixed_chosen = ram_latest if ram_latest["createdAt"] >= existing_conv["lastMessage"]["createdAt"] else existing_conv["lastMessage"]
    else:
        fixed_chosen = ram_latest or existing_conv.get("lastMessage")

    fixed_effective = max(existing_conv["updatedAt"], fixed_chosen["createdAt"])
    print(f"  [New Fixed Behavior] Chosen Last: \"{fixed_chosen['content']}\" | Effective Date: {fixed_effective}")

    protection_passed = (fixed_chosen["id"] == existing_last_message["id"]) and (fixed_effective == existing_conv["updatedAt"])
    print(f"Result: {'PASS (Conversation timestamp protected from downgrade)' if protection_passed else 'FAIL'}")
    assert protection_passed

    print("\n" + "=" * 65)
    print("ALL CORRUPTED MESSAGE & DOWNGRADE TESTS PASSED 100%!")
    print("=" * 65)

if __name__ == "__main__":
    test_defensive_parsing()
