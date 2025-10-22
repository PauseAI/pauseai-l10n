OFFSET=0

# 1. Set up common prefix with timestamp first
TIMESTAMP=$(date +%Y%m%dT%H)
CHAT_NAME=$(sqlite3 ~/.config/Cursor/User/globalStorage/state.vscdb \
  "SELECT json_extract(value, '$.name') FROM cursorDiskKV 
   WHERE key LIKE 'composerData%' 
   ORDER BY json_extract(value, '$.createdAt') DESC LIMIT 1 OFFSET ${OFFSET};" | \
  tr ' ' '_' | tr -cd '[:alnum:]_-')
COMMON_PREFIX="${TIMESTAMP}.${CHAT_NAME}"

# 2. Extract chat JSON
sqlite3 ~/.config/Cursor/User/globalStorage/state.vscdb \
  "SELECT value FROM cursorDiskKV 
   WHERE key LIKE 'composerData%' 
   ORDER BY json_extract(value, '$.createdAt') DESC LIMIT 1 OFFSET ${OFFSET};" \
  | jq '.' > notes/raw_chat/${COMMON_PREFIX}.json

# 3. Extract message text
python3 notes/raw_chat/extract.py notes/raw_chat/${COMMON_PREFIX}.json \
  > notes/raw_chat/${COMMON_PREFIX}.txt

# 4. Create documentation files
touch notes/summary/${COMMON_PREFIX}.summary.md
touch notes/personal/${COMMON_PREFIX}.personal.md