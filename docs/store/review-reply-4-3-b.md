# Reply to App Review — 4.3(b), submission ec20af61

Draft for the Resolution Center reply on the guideline 4.3(b) rejection of
1.0.0 (10). Kept in the repo because every factual claim in it has to be true of
the committed code, and the cheapest way to keep it true is to review it in the
same diff as the code.

## Rules this draft follows

- **No arguing with the finding.** The 4.3(b) message pre-empts "our app has
  distinguishing features" in its own text. Repeating that argument invites the
  same answer. What can change the outcome is a changed app.
- **No claiming a feature was removed unless it was.** ปฏิทินจันทรคติ and
  กระแสปีนี้ are still present, off the tab bar. Saying otherwise would be
  false, and a reviewer who opens the build will find them.
- **Verifiable specifics only.** Tier badges, two-source corroboration and
  original-text display are things a reviewer can see in ninety seconds. That is
  the whole value of leading with them.

## Do not send before

1. A new build is on App Store Connect with the repositioned navigation.
2. Name, subtitle, keywords and description are updated per `listing.md`.
3. The 7 stale screenshots showing the `ดวง` / `กระแส` tab bar are replaced.

Sending the reply while the product page still shows the rejected structure
argues against itself.

---

## Draft

> Thank you for the detailed review, and for naming the guideline clearly — it
> was the right call on what we submitted.
>
> We have not appealed. We rebuilt the app's structure, because reading the
> submission back we agree it presented itself as a fortune-telling app. The
> tab bar was หน้าแรก · ความฝัน · กระแส · ดวง · ตรวจหวย, the first screen opened
> on a dream-entry prompt, and our keywords led with ทำนายฝัน, โหราศาสตร์ and
> ราศี. A reviewer had no reason to conclude anything else.
>
> What the app actually contains, and what it now leads with, is a sourced
> reference corpus of Thai textual tradition — principally ตำรา พรหมชาติ, which
> we are transcribing directly from the printed edition. It is not a content
> aggregation and it is not generated. Specifically:
>
> - **Every reading is attributed and tiered.** Each entry carries a trust-tier
>   badge (A1 through D) naming the class of source it came from, the title of
>   the text it is drawn from, and the original Thai passage, displayed so a
>   reader can compare our rendering against it.
> - **Corroboration is enforced in the database, not by editorial habit.** A
>   reading found in only one text is marked as such and is withheld from
>   publication; agreement between two independent witnesses is required before
>   an entry is published. Of the 108 พรหมชาติ items in the current corpus, 106
>   are held as unpublished drafts on exactly this rule.
> - **The app refuses to answer when the corpus is silent.** Searching a symbol
>   the library does not hold returns an explicit "not found, and we will not
>   invent a meaning without a text behind it" — not a generated reading.
> - **แหล่งอ้างอิง is now a primary tab**, explaining what each tier means and
>   linking to the National Library of Thailand for readers who want to check
>   the tradition at its custodian. We claim no endorsement from them and the
>   screen says so.
>
> The new tab bar is หน้าแรก · คลังตำรา · ความฝัน · ตรวจหวย · แหล่งอ้างอิง. The
> library and the sources are destinations rather than items behind an icon, and
> the first screen now states what the app is and what is checkable about it.
>
> ตรวจหวย checks published สลากกินแบ่งรัฐบาล (Thai Government Lottery) results
> against numbers the user saved. It reports what was officially announced,
> including refusing to declare a result while an announcement is incomplete. It
> does not predict outcomes, sell tickets, or take payment of any kind.
>
> Two things we want to be straightforward about rather than have you find them:
>
> 1. The app still contains a **ปฏิทินจันทรคติ** screen, previously titled
>    ดวงของฉัน. We renamed it because the old title was inaccurate: it converts
>    a birth date into the Thai lunar calendar and names the ทักษา and นักษัตร
>    classes that tradition assigns to that date, each with its citation. It
>    makes no prediction — an earlier version contained one invented advice line
>    and we deleted it before this submission. It is no longer a tab.
> 2. A **กระแสปีนี้** screen shows which symbols in the corpus relate to draws
>    that actually occurred over the past year. It is historical record joined to
>    cited text, not forecasting. It is also no longer a tab.
>
> Both remain reachable from the first screen. We did not want to claim a
> reduction we had not made.
>
> We understand that a repositioned product page is not by itself sufficient,
> and that you may still consider the category saturated. If the app is
> acceptable in principle as a cited reference work but something specific still
> reads as fortune-telling to you, we would genuinely value being told which
> screen, and we will change it.
