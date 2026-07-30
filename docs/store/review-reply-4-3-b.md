# Reply to App Review — 4.3(b), submission ec20af61

**Status: SENT 2026-07-30 17:47** by Aimvalee Chanphen, as a Resolution Center
reply on the guideline 4.3(b) rejection of 1.0.0 (10). No resubmission was made;
"Resubmit to App Review" remains disabled, and that is deliberate.

Kept in the repo because every factual claim in it has to be true of the
committed code, and the cheapest way to keep it true is to review it in the same
diff as the code. The text below is what was actually sent, not a draft of it —
see the note on length.

## This is a question, not a resubmission

The reasoning is in the guideline text itself, which cuts both ways:

> Certain kinds of apps, such as dating, flashlight, sound effects, wallpaper,
> simple timers, and fortune telling, are well established on the App Store and
> we will not accept new submissions **unless they offer a meaningfully
> different or improved experience**. […] **Repeated submissions of this kind may
> lead to removal from the Apple Developer Program.**

The first clause is the opening — the bar is "meaningfully different", and it is
a bar about substance, which a sourced corpus can argue. The second is why not to
argue it by trial and error: the penalty for repeatedly submitting into a
saturated category is levied on the **developer account**, and นิมิต shares its
account with GrowSense. A wrong guess here is not paid for by this app alone.

A reply costs nothing and is explicitly invited ("Reply to this message in App
Store Connect and let us know"). It is not a submission, so it cannot be a
repeated one. Ask first; spend the submission once a human has answered.

## Rules this reply follows

- **No arguing with the finding.** The 4.3(b) message pre-empts "our app has
  distinguishing features" in its own text. Repeating that argument invites the
  same answer. What can change the outcome is a changed app.
- **No claiming a feature was removed unless it was.** ปฏิทินจันทรคติ and
  กระแสปีนี้ are still present, off the tab bar. Saying otherwise would be
  false, and a reviewer who opens the build will find them.
- **No past tense for work Apple cannot yet see.** The rebuild is committed but
  is not in a build on App Store Connect. The reply says built, not shipped.
- **Verifiable specifics only.** Tier badges, two-source corroboration and
  original-text display are things a reviewer can see in ninety seconds. That is
  the whole value of leading with them.

## The 4,000-character limit

The Resolution Center reply box caps at 4,000 characters. It does not advertise
this — `maxLength` on the textarea is `-1` — and it does not truncate. It
silently keeps the Reply button disabled and shows a negative counter. The first
version of this reply ran to 4,457 characters and simply would not send.

The sent version is 3,818. The cuts were redundancy, not substance: the tab bar
was described twice, and Thai terms that appear with an English gloss no longer
also appear in their own paragraph.

## Before resubmitting — only after a reply comes back

1. A new build with the repositioned navigation.
2. Name, subtitle, keywords and description updated per `listing.md`.
3. The 7 stale screenshots showing the `ดวง` / `กระแส` tab bar replaced.

Resubmitting while the product page still pictures the rejected structure argues
against itself.

---

## Sent text

> Thank you for the detailed review, and for naming the guideline clearly — it
> was the right call on what we submitted.
>
> We are not appealing and are deliberately not resubmitting yet. We want to ask
> one question first, because 4.3(b) says you will not accept new submissions in
> an established category "unless they offer a meaningfully different or improved
> experience". We would rather find out whether we clear that bar than keep
> submitting to discover it.
>
> We have rebuilt the app. Reading our submission back, we agree it presented
> itself as a fortune-telling app: the tab bar was Home / Dreams / Trends / ดวง
> (fortune) / Lottery, the first screen opened on a dream-entry prompt, and our
> keywords led with ทำนายฝัน (dream prediction), โหราศาสตร์ (astrology) and ราศี
> (zodiac). A reviewer had no reason to conclude anything else. The changes below
> are built and committed, but not yet in a build you can open — which is why we
> are asking before uploading one.
>
> What the app actually contains, and now leads with, is a sourced reference
> corpus of Thai textual tradition, principally ตำรา พรหมชาติ (Tamra
> Phrommachat), which we transcribe directly from the printed edition. It is not
> aggregated and not generated:
>
> 1. Every reading is attributed and tiered. Each entry carries a trust-tier
>    badge (A1 to D) naming the class of source, the title of the text, and the
>    original Thai passage, shown so a reader can compare our rendering against
>    it.
>
> 2. Corroboration is enforced in the database, not by editorial habit. A reading
>    found in only one text is marked as such and withheld from publication; two
>    independent witnesses are required before an entry is published. Of 108
>    Phrommachat items in the corpus, 106 are unpublished drafts on exactly this
>    rule.
>
> 3. The app refuses to answer when the corpus is silent. Searching a symbol the
>    library does not hold returns "not found, and we will not invent a meaning
>    without a text behind it" — not a generated reading.
>
> 4. Sources is now a primary tab, explaining what each tier means and linking to
>    the National Library of Thailand so readers can check the tradition at its
>    custodian. We claim no endorsement, and the screen says so.
>
> The tab bar is now Home / Library / Dreams / Lottery results / Sources.
>
> The lottery feature checks published สลากกินแบ่งรัฐบาล (Thai Government
> Lottery) results against numbers the user saved. It reports only what was
> officially announced, and refuses to declare a result while an announcement is
> incomplete. It does not predict outcomes, sell tickets, or take payment.
>
> Two things we would rather state than have you find:
>
> First, the app still has a lunar-calendar screen, previously titled ดวงของฉัน.
> The old title was inaccurate: it converts a birth date to the Thai lunar
> calendar and names the traditional ทักษา and นักษัตร classes for that date,
> each cited. It makes no prediction — an earlier version had one invented advice
> line and we deleted it before submitting. It is no longer a tab.
>
> Second, a screen showing which corpus symbols relate to draws that actually
> occurred over the past year: historical record joined to cited text, not
> forecasting. Also no longer a tab.
>
> Both are still reachable from the first screen. We did not want to claim a
> reduction we had not made.
>
> Our question: on the description above, would this app as a cited reference
> work be considered meaningfully different under 4.3(b), or do you consider the
> concept saturated regardless of how the sourcing is built?
>
> Either answer helps us. If no, we would rather stop than keep submitting into a
> category you have told us is closed. If yes, or yes with conditions, we will
> upload a build with the new structure and screenshots — and would value being
> told which screen still reads as fortune-telling, so we can fix it before you
> spend a second review.
