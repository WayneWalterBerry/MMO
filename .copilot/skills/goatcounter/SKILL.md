# Skill: GoatCounter Analytics

**Confidence:** low
**Created by:** Coordinator
**Created:** 2026-03-21

## What

GoatCounter is the blog's privacy-friendly analytics tool. No cookies, no GDPR banner, free for non-commercial use.

## Configuration

- **Site code:** `waynewalterberry`
- **Dashboard:** https://waynewalterberry.goatcounter.com
- **Script location:** `_layouts/default.html` in the blog repo (`WayneWalterBerry.github.io`)
- **Blog repo:** `C:\Users\wayneb\source\repos\WayneWalterBerry.github.io`

## Accessing Data

### Web Dashboard
Visit https://waynewalterberry.goatcounter.com — shows page views, referrers, browsers, locations.

### API Access
GoatCounter has a REST API. To use it:

1. **Get an API token:** Dashboard → Settings → API tokens → Create
2. **Base URL:** `https://waynewalterberry.goatcounter.com/api/v0`
3. **Auth header:** `Authorization: Bearer {token}`

### Common API Queries

```bash
# Total pageviews for a date range
curl -H "Authorization: Bearer $TOKEN" \
  "https://waynewalterberry.goatcounter.com/api/v0/stats/total?start=2026-03-01&end=2026-03-31"

# Per-page hit counts
curl -H "Authorization: Bearer $TOKEN" \
  "https://waynewalterberry.goatcounter.com/api/v0/stats/hits?start=2026-03-01&end=2026-03-31"

# List all pages with view counts
curl -H "Authorization: Bearer $TOKEN" \
  "https://waynewalterberry.goatcounter.com/api/v0/paths"

# Export all data as CSV
curl -H "Authorization: Bearer $TOKEN" \
  "https://waynewalterberry.goatcounter.com/api/v0/export" -o analytics.csv
```

### PowerShell (Windows)

```powershell
$token = "YOUR_API_TOKEN"
$headers = @{ "Authorization" = "Bearer $token" }

# Get total views this month
Invoke-RestMethod -Uri "https://waynewalterberry.goatcounter.com/api/v0/stats/total?start=2026-03-01" -Headers $headers

# Get per-page stats
Invoke-RestMethod -Uri "https://waynewalterberry.goatcounter.com/api/v0/stats/hits?start=2026-03-01" -Headers $headers
```

## When to Use

- After publishing a blog post — check if it's getting traffic
- Before deciding which post to write next — see what readers care about
- When Wayne asks "how's the blog doing?" — pull stats from the API

## Notes

- Data takes a few minutes to appear after the script is added
- GoatCounter respects Do Not Track by default
- Wayne must create the account at goatcounter.com with site code `waynewalterberry`
- The script tag is in the Jekyll layout, so it automatically covers ALL pages including future posts
