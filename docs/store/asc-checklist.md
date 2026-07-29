# App Store Connect — the answers, written before the form

Everything that has to be typed into App Store Connect for นิมิต v0.1.0, decided
here rather than improvised at 2 a.m. in a web form. Nothing in this file is
code; all of it is a claim about the app, and every claim is checkable against
the build.

---

## 1. App record

| Field | Value |
|---|---|
| Bundle ID | `app.nimit.nimit` |
| App name | นิมิต |
| Subtitle | ฝัน • ดวง • ความเชื่อ จากตำราที่อ้างอิงได้ |
| SKU | `nimit-ios` |
| Primary language | Thai |
| Primary category | Lifestyle |
| Secondary category | Reference |
| Devices | iPhone only, portrait only |
| Price | Free, no in-app purchases |

Category note: **Lifestyle**, not Entertainment and not Utilities. Reviewers use
the category to set expectations; a citation-first reference app filed under
Entertainment invites the "is this a game of chance" question this app spends
its whole design avoiding.

---

## 2. Age rating

Answer every question honestly. The honest answers are all *None* / *No*, which
gives **4+**:

- **Gambling — Simulated Gambling:** No. There is no wager, no stake, no payout,
  no simulated slot/card/roulette mechanic, and no purchase of anything.
- **Contests:** No.
- **Horror, violence, sexual content, profanity, drugs, alcohol:** None.
- **Unrestricted web access:** No. The app opens exactly two fixed URLs — the
  privacy policy and the support page — in the system browser.

If the rating is ever challenged, the argument is: the app neither takes money
nor pays it out, and shows official published lottery results so a user can
check a ticket bought elsewhere. Checking a result is not playing.

---

## 3. Privacy

**App Privacy label: "Data Not Collected"** — every category.

This is defensible, and here is the reasoning to give if asked. Apple defines
collection as transmitting data off the device and retaining it beyond real-time
servicing of the request. The dream text typed on the ความฝัน screen is sent to
the content server because matching runs in SQL, but:

- the request carries no account, device id, or advertising id;
- the server retains nothing — an unmatched dream is logged as a *length*, never
  as text (`supabase/migrations/20260729001000_no_raw_dream_text_in_logs.sql`,
  enforced by an assertion in `supabase/tests/rights_firewall_test.sql`);
- birth date, journal, saved numbers and budget never leave the device at all.

`app/ios/Runner/PrivacyInfo.xcprivacy` says the same thing in machine-readable
form. **If the server ever starts retaining dream text, this label becomes a
false statement** — change the label in the same change that changes the server.

- **Privacy Policy URL:** <https://sites.google.com/view/nimitluck/privacy>
- **Support URL:** <https://sites.google.com/view/nimitluck/support>

Both published on Google Sites 2026-07-29; wording lives in `docs/store/privacy.md`
and `docs/store/support.md`, rendered for pasting as the matching `-page.html`
files. Both are also in `app/lib/core/links.dart`, without which `flutter test`
fails and Codemagic refuses to build. That is deliberate.

**Export compliance:** already answered in `Info.plist` —
`ITSAppUsesNonExemptEncryption = false`. No questionnaire should appear. The app
uses only HTTPS, which is exempt.

**Sign in with Apple:** not applicable — there is no account of any kind, so
5.1.1(v) account deletion does not apply either.

---

## 4. App Review notes

Paste this into *App Review Information → Notes*. No demo account is needed —
say so, because an empty credentials field otherwise reads as an oversight.

> **No account is required. All features are available immediately on launch.**
>
> นิมิต is a Thai dream-interpretation and traditional-belief reference app.
>
> **This app does not offer gambling in any form.** It takes no wagers, sells no
> tickets, processes no payments, and has no in-app purchases. Nothing in the
> app can be bought, staked, or won.
>
> **Lottery results.** The ตรวจหวย screen displays the officially published
> results of the Thai Government Lottery (a state-operated lottery), so that a
> user can check a ticket they already hold. The app does not sell tickets and
> is not affiliated with the operator.
>
> **About the numbers shown with dream interpretations.** Thai dream manuals
> have associated symbols with numbers for over a century. Those numbers are
> transcribed from public-domain printed texts and are shown as cultural
> material, with the edition and page cited on screen. The app never claims a
> number will win, never presents a number as a prediction, and contains no
> accuracy or success claims. Every interpretation carries a visible source and
> a source-trust label (A1–D).
>
> **Responsible use.** The ตรวจหวย section includes a monthly entertainment
> budget the user sets for themselves, to encourage restraint.
>
> **Privacy.** No account, no analytics, no advertising, no tracking. Birth
> date, dream journal, saved numbers and budget are stored only on the device.
> The privacy policy is reachable inside the app from the แหล่งอ้างอิง screen
> (book icon in the navigation bar, on every screen).
>
> The interface is in Thai. Key screens: หน้าแรก (home), ความฝัน (dream lookup),
> กระแส (this year's trends), ดวง (personal reading from birth date, entered
> locally), ตรวจหวย (lottery result checking).

Thai version, for the same field if a Thai-speaking reviewer is assigned:

> **ไม่ต้องสมัครสมาชิก ใช้งานได้ทุกฟังก์ชันทันทีที่เปิดแอป**
>
> นิมิตเป็นแอปค้นคำทำนายฝันและความเชื่อไทยจากตำราที่อ้างอิงได้
>
> **แอปนี้ไม่มีการพนันในทุกรูปแบบ** ไม่รับพนัน ไม่ขายสลาก ไม่มีการชำระเงิน
> และไม่มีการซื้อในแอป
>
> **ผลรางวัล** หน้าตรวจหวยแสดงผลรางวัลอย่างเป็นทางการของสำนักงานสลากกินแบ่งรัฐบาล
> เพื่อให้ผู้ใช้ตรวจสลากที่ถืออยู่แล้ว แอปไม่ได้ขายสลากและไม่มีความเกี่ยวข้องกับผู้ออกสลาก
>
> **เรื่องตัวเลข** ตัวเลขที่แสดงคู่กับคำทำนายฝันคือเลขที่ตำราไทยโบราณผูกไว้กับสัญลักษณ์นั้น
> คัดมาจากหนังสือที่หมดลิขสิทธิ์แล้ว แสดงพร้อมชื่อฉบับและเลขหน้า เป็นการบันทึกความเชื่อ
> ไม่ใช่การทำนายผลรางวัล และแอปไม่มีคำกล่าวอ้างเรื่องความแม่นยำใด ๆ
>
> **ความเป็นส่วนตัว** ไม่มีบัญชีผู้ใช้ ไม่มีการติดตาม ไม่มีโฆษณา
> วันเกิด บันทึกความฝัน เลขที่บันทึกไว้ และงบประจำเดือน เก็บอยู่ในเครื่องเท่านั้น

---

## 5. Metadata rules

The store listing is held to the same standard as the app's own text. The
description, keywords, subtitle, promotional text and screenshots **must not**
contain:

- เลขเด็ด, หวยเด็ด, เลขแม่น, เลขที่จะออก, ถูกแน่, การันตี
- แม่นยำ, ความแม่นยำ, or any accuracy or success claim
- "predict", "prediction", "winning numbers", "lucky numbers that win"
- any implication that the app improves the odds of anything

This is the same rule the code already enforces on itself
(`lib/features/lottery/lottery_screen.dart` explains why a bare wall of numbers
is indistinguishable from a tip sheet). A store listing that claims what the app
refuses to claim is both a 2.3.1 misrepresentation and a lie.

Safe framing: "คำทำนายฝันจากตำราที่อ้างอิงได้", "ตรวจผลสลากกินแบ่งรัฐบาล",
"ความเชื่อไทยพร้อมที่มา", "cited Thai dream interpretation".

---

## 6. Still outstanding at submission time

- **Screenshots.** 6.9" and 6.5" iPhone sets are required for App Store review.
  TestFlight does not need them, so this does not block the first build. There
  is no Mac here; the options are to capture them from a device running the
  TestFlight build, or to render them at exact pixel sizes from a Flutter test.
- **Nothing else.** Everything above is decided.

---

## 7. Order of operations

1. Register bundle id `app.nimit.nimit` in the developer portal.
2. Create the ASC app record with the fields in §1.
3. Generate an ASC API key (App Manager role); add it to Codemagic as an
   integration named `nimit_asc`.
4. Create the Codemagic variable group `nimit_backend` with `NIMIT_REMOTE=true`,
   `SUPABASE_URL`, `SUPABASE_ANON_KEY`. The build refuses to run without it.
5. Publish the privacy and support pages; paste both URLs into
   `app/lib/core/links.dart`; confirm `flutter test` is green.
6. Tag `ios-v0.1.0-rc1` and watch the build. **Not** `ios-v0.1.0` — the tag
   pattern is `ios-v*`, so an rc exercises the whole pipeline without spending
   the release name on a first run that has never executed anywhere.
7. When that is green, tag `ios-v0.1.0`.
8. Fill in §2–§5 in App Store Connect. Submit when the screenshots exist.
