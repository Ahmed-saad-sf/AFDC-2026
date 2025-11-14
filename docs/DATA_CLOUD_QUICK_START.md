# Data Cloud Configuration - Quick Start

## 🚀 5-Minute Setup (If Data Cloud Already Configured)

### Step 1: Open Agent Builder (2 min)
1. Setup → Agents → **AF_Decision_Maker** → Edit
2. Click **Topics** → **+ New Topic**
3. Name: **Data Operations**
4. Description: **Query and manage Salesforce data**

### Step 2: Add Search Action (2 min)
1. In Data Operations topic → **Actions** → **+ New Action**
2. Select: **Einstein Search** or **Search Records**
3. Progress message: "Searching Salesforce data..."
4. Save

### Step 3: Add Instructions (1 min)
Copy-paste these instructions into the topic:

```
You have access to query ALL Salesforce data with user permissions enforced.

EXAMPLES:
- "Show me all accounts in California"
- "Find opportunities over $100K"
- "What are John's open cases?"

FORMAT:
- List or table for multiple records
- Show key fields (Name, Amount, Status)
- Limit to 10-20 results
- Include record links
```

### Step 4: Activate
Click **Activate** → Test with query: "Show me all accounts"

---

## ✅ If Already Working

Your agent can now:
- Query any Salesforce object
- Search across all data user has access to
- Respect permissions automatically
- Mask PII fields
- Return formatted results

---

## ❌ If Not Working

**Check:**
1. Data Cloud enabled? (Setup → Data Cloud)
2. Data Streams active? (Data Cloud → Data Streams)
3. Data Space configured? (Data Cloud → Data Spaces)
4. Einstein Trust Layer on? (Setup → Einstein Trust Layer)

If any are missing → See [DATA_CLOUD_SETUP_GUIDE.md](./DATA_CLOUD_SETUP_GUIDE.md)

---

## 🧪 Test Queries

```
✅ "Show me all accounts"
✅ "Find opportunities closing this month"
✅ "What cases were created today?"
✅ "Show contacts at Acme Corp"
✅ "List my open tasks"
```

---

## 🔐 Security Verified?

- [ ] User only sees their data (sharing rules work)
- [ ] Sensitive fields masked (PII protection work)
- [ ] Cannot access restricted objects
- [ ] Audit logs showing queries

---

## 📞 Need Help?

See full guide: [DATA_CLOUD_SETUP_GUIDE.md](./DATA_CLOUD_SETUP_GUIDE.md)

