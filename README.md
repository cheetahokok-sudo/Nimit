# นิมิต (Nimit)

**ฝัน • ดวง • ความเชื่อ** — Thai dream-interpretation, belief, and lottery companion.

แอปสำหรับคนไทยที่อยากเข้าใจความฝัน ความเชื่อ และดวงของตัวเอง — เช็กผลหวยอย่างเป็นทางการ เข้าใจที่มาของความเชื่อ พร้อมเลขเชิงสัญลักษณ์ (**ไม่ใช่คำทำนายผล และไม่รับแทงหวย**)

## โครงสร้าง (Repo layout)

| Path | คำอธิบาย |
|---|---|
| `app/` | Flutter app (Android / iOS / Web) |

เอกสารวิจัยตลาด กลยุทธ์ และ UI board อยู่ใน repo แยกต่างหาก (private): [`cheetahokok-sudo/Nimit-docs`](https://github.com/cheetahokok-sudo/Nimit-docs)

## หลักการสำคัญจากงานวิจัย (Product guardrails)

1. **ไม่รับแทง ไม่มีธุรกรรมพนัน** — เป็น content + utility + astrology เท่านั้น
2. **Trust labels** — ทุกคำแปลระบุที่มาเป็นระดับ A1/A2/B1/B2/C/D (ข้อเท็จจริง / ความเชื่อ / ความเห็น แยกชัด)
3. **เลขเชิงสัญลักษณ์เท่านั้น** — ห้ามใช้คำว่า "เลขเด็ด" "เลขที่จะออก" หรือเคลมความแม่น
4. **Responsible use** — งบความบันเทิง, พักการแจ้งเตือน, อธิบายความน่าจะเป็นตามจริง
5. **ภาษาไทยเป็นหลัก** — ผู้ใช้ที่อ่านได้แต่ภาษาไทยต้องใช้งานได้ครบทุกฟีเจอร์

## เริ่มต้น (Getting started)

```bash
cd app
flutter pub get
flutter run
```

รันเทสต์และตรวจโค้ด:

```bash
cd app
flutter analyze
flutter test
```

## สถาปัตยกรรม (Architecture)

- **State**: [flutter_riverpod](https://riverpod.dev) — providers ใน `app/lib/data/providers.dart`
- **Navigation**: go_router (`StatefulShellRoute` 5 แท็บ: หน้าแรก / ความฝัน / กระแส / ดวง / ตรวจหวย)
- **Data**: repository interfaces (`app/lib/data/repositories/`) → ตอนนี้ใช้ mock (`data/mock/`) + local persistence ผ่าน shared_preferences (`data/local/`) — พร้อมสลับเป็น Supabase ภายหลังด้วย provider override โดยไม่แตะ UI
- **Theme**: design tokens จาก UI board ใน `app/lib/core/theme/nimit_theme.dart` (cream / aubergine / gold)

## สถานะ (Status)

Scaffold v0.1 — ครบ 8 หน้าจอตาม UI board v2 (ดู repo `Nimit-docs`) ด้วย mock data; dream journal, เลขที่บันทึก, และงบความบันเทิงเก็บลงเครื่องจริง ยังไม่เชื่อม API ผลหวย/AI วิเคราะห์ฝัน/การแชร์
