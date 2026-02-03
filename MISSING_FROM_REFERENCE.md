# What’s Missing in Current SARAN App vs Reference (Saran_one-1)

Comparison of **Saran_one/SARAN** (current working app) with **Saran_one-1/SARAN** (reference on Desktop).

---

## 1. Flutter app – missing or different

### 1.1 **Hashtag Explore (Trending Hashtags) – MISSING**
- **Reference:** Has a dedicated **Hashtag Explore Screen** (`screens/explore/hashtag_explore_screen.dart`) that:
  - Calls `PostService.getTrendingHashtags()`
  - Shows a list of trending hashtags with post counts
  - Lets the user tap a hashtag to open `HashtagPostsScreen`
- **Reference router:** Has route `/hashtags` → `HashtagExploreScreen`.
- **Current app:** No `HashtagExploreScreen`, no `/hashtags` route. `getTrendingHashtags()` exists in `post_service.dart` but there is no UI to list trending hashtags or navigate to them.
- **Impact:** Users cannot discover or browse “Trending Hashtags” in the current app.

### 1.2 **Explore UI building blocks – MISSING (optional)**
- **Reference:** Reusable widgets under `widgets/explore/`:
  - `explore_tabs.dart` – horizontal tabs (All, People, Text, Photo, Video)
  - `explore_grid_item.dart` – grid cell for a post with “more” and type badge
  - `explore_people_tile.dart` – user row with avatar, name, follow, open profile
- **Current app:** Explore filters (All, People, Text, Photo, Vid) and grid/people UI are implemented **inline** in `explore_screen.dart`. Only `explore_search_bar.dart` exists under `widgets/explore/`.
- **Impact:** No functional gap; only structure differs (inline vs separate widgets). Refactor to these widgets is optional.

### 1.3 **User profile navigation – DIFFERENT**
- **Reference:** Uses GoRouter for user profile: route `/user-profile` with `state.extra as User` → `UserProfileScreen(user: user)`.
- **Current app:** Uses `Navigator.push` / `MaterialPageRoute` to `UserProfileScreen(user: user)` from explore and elsewhere. No `/user-profile` in `app_router.dart`.
- **Impact:** Same feature; current app does not use GoRouter for profile. Optional to add `/user-profile` and switch to `context.push('/user-profile', extra: user)` for consistency and deep linking.

### 1.4 **Dev / test screens – MISSING (optional)**
- **Reference:** Has `screens/dev/api_test_screen.dart` and `backend_test_screen.dart`.
- **Current app:** No dev/test screens under `screens/dev/`.
- **Impact:** Only affects development/debugging; not required for production.

### 1.5 **Menu sheet – MINOR UI**
- **Reference:** Logout row uses red icon and red text (`Icons.logout`, color: Colors.red).
- **Current app:** Logout row uses black icon and black text.
- **Impact:** Visual only; you can align to reference by making Logout red in `menu_sheet.dart` if desired.

### 1.6 **S-Frame widgets – REFERENCE PLACEHOLDERS**
- **Reference:** `features/sframe/widgets/sframe_progress.dart` and `sframe_reply_bar.dart` are **empty**.
- **Current app:** Has the same widget files with actual implementations (e.g. `sframe_progress.dart`, `sframe_reply_bar.dart` in `features/sframe/widgets/`).
- **Impact:** Nothing missing in current app; reference just has empty files.

---

## 2. Backend

- **Controllers and routes:** The same set exists in both (auth, block, closeFriend, content_mute, deleteAccount, event, eventReminder, feed, follow, hashtag, message, mute, notification, notificationSettings, post, report, save, scycle, search, settings, sframe, sos, space, upload, user, wellness, etc.).
- **Models:** Same models in both (Block, CloseFriend, Comment, ContentMute, Conversation, Event, Follow, Like, Message, Notification, Post, Report, Save, SFrame, User, wellness/cycle/mind journal, etc.).
- **Conclusion:** No backend features are missing relative to the reference; any gaps are in the Flutter app or routing.

---

## 3. Summary checklist

| Item | Status in current app |
|------|------------------------|
| Hashtag Explore Screen + `/hashtags` route | **Missing** – add screen and route to match reference |
| Explore tabs (as separate widget) | Optional – logic already inline in explore |
| ExploreGridItem / ExplorePeopleTile | Optional – UI inline in explore |
| `/user-profile` GoRouter route | Optional – profile works via Navigator |
| Dev screens (api_test, backend_test) | Optional – for dev only |
| Menu Logout in red | Optional – UI preference |
| Backend controllers/routes/models | Present – no gaps |
| S-Frame progress/reply bar | Present – reference had empty placeholders |

---

## 4. Recommended next step

- **Add Hashtag Explore:** Implement `hashtag_explore_screen.dart` (or equivalent) that uses `getTrendingHashtags()` and navigates to the existing `HashtagPostsScreen`, and add the `/hashtags` route in `app_router.dart`. Optionally add an entry point from Explore (e.g. “Trending hashtags” chip or header action) so users can open it.

All other items are either optional refactors, UI tweaks, or already present in the current app.
