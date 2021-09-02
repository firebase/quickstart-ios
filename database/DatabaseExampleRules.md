```
{
    "rules": {
        // User profiles are only readable/writable by the user who owns it
        "users": {
            "$UID": {
                ".read": "auth.uid == $UID",
                ".write": "auth.uid == $UID"
            }
        },
        // Posts can be read by anyone but only written by logged-in users.
        "posts": {
            ".read": true,
            ".write": "auth.uid != null",
            "$POSTID": {
                // UID must match logged in user and is fixed once set
                "uid": {
                    ".validate": "(data.exists() && data.val() == newData.val()) || newData.val() == auth.uid"
                },
                // User can only update own stars
                "stars": {
                    "$UID": {
                        ".validate": "auth.uid == $UID"
                    }
                }
            }
        },
        // User posts can be read by anyone but only written by the user that owns it,
        // and with a matching UID
        "user-posts": {
            ".read": true,
            "$UID": {
                "$POSTID": {
                    ".write": "auth.uid == $UID",
                    ".validate": "data.exists() || newData.child('uid').val() == auth.uid"
                }
            }
        },
        // Comments can be read by anyone but only written by a logged in user
        "post-comments": {
            ".read": true,
            ".write": "auth.uid != null",
            "$POSTID": {
                "$COMMENTID": {
                    // UID must match logged in user and is fixed once set
                    "uid": {
                        ".validate": "(data.exists() && data.val() == newData.val()) || newData.val() == auth.uid"
                    }
                }
            }
        }
    }
}
```