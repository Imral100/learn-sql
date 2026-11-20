# person-car: akılda kalacaklar

Bu serinin en önemli dersleri ve en çok zorlandığım noktalar.

## 1. JOIN koşulu iki tabloyu bağlamalı

- `ON` içinde **iki tablonun da** sütunu olmalı. `ON p.car_id IS DISTINCT FROM NULL` → 134.000 satır.
- `UPDATE … FROM`'da doldurmaya çalıştığın sütunla eşleştirme yapılmaz (`WHERE h.owner_id = k.id` → `UPDATE 0`).
- Sayı beklenmedik derecede büyükse, ilk şüpheli `ON` koşulu.

## 2. LEFT JOIN'in üç kuralı

- **Sağ tabloya filtre `ON` içine**, `WHERE`'e değil. Yoksa LEFT JOIN fiilen INNER olur.
- **Sayım:** `count(*)` değil, `count(sağ_tablo.id)`. Eşi olmayan satır `count(*)` ile 1 sayılır.
- **Toplam:** `SUM` boş grupta NULL döner → `COALESCE(SUM(…), 0)`.

## 3. Satır çoğalması: one mı, many mi?

- JOIN'den önce sor: "Bir satır karşıda **kaç** satırla eşleşir?"
- **One tarafını** sayıyorsan → `count(DISTINCT p.id)` ya da `EXISTS`.
- **Many → one** JOIN çoğaltmaz (`car` → `person`). **One → many** çoğaltır.

## 4. EXISTS: alt sorgu neye bağlı?

- Bağlantı, sorunun **kimin hakkında** olduğunu belirler: kişi mi (`p.id`), ülke mi (`p.country_of_birth`)?
- Bağlantı yoksa → **ya hepsi ya hiçbiri.**
- `c` / `c2`: bağlantı ikisini birleştirir, **aranan özellik `c2`'ye** aittir.
- Kendisiyle eşleşmeyi engellemek: satır listelerken `<>`, çift listelerken `<`.
- Anti-join: **NOT EXISTS**, asla `NOT IN (SELECT fk …)`.

## 5. Mantık çevirisi

- "**Hiç** X yok" → `NOT EXISTS (X)`
- "**Hepsi** X" → `EXISTS (herhangi) AND NOT EXISTS (X olmayan)`
- "Hiçbir vatandaşı araba sahibi değil" ≠ "her vatandaşı araba sahibi" ≠ "arabasız vatandaşı var"
- **Zorlanınca:** önce tersini ("en az bir") düz sorgu olarak yaz → tek bir değerle çalıştır → dış sorguya bağla.
- Her dönüşümü somut bir örnekle test et.

## 6. Constraint'ler

- **NOT NULL** `''` ve `'   '`'yi engellemez → `CHECK (trim(x) <> '')`.
- **CHECK sadece FALSE'u reddeder**, NULL geçer. Zorunluysa NOT NULL da ekle.
- **Dolu tabloya** NOT NULL sütun: ekle → gerçek değerlerle doldur → kısıtla. UNIQUE sütunda `DEFAULT` işe yaramaz.
- **Kurallar birbirini etkiler:** `ON DELETE SET NULL` + iki sütunlu CHECK → sahibi olan kişi silinemedi.
- Bir CHECK'le zorla tutarlı tuttuğun sütun, çoğu zaman **yanlış tablodadır** (→ `ownership` ara tablosu).

## 7. Sıra, id ve zaman

- `ORDER BY` olmadan sıra **yoktur.** Eşitlik varsa sona `id` ekle.
- Sequence geri gitmez. Boşluklar normaldir, geri alma.
- **TIMESTAMP + BETWEEN** son günü kaçırır → `>= başlangıç AND < sonraki_gün`.
- Yaş için `AGE`, yıl farkı değil. `EXTRACT` numeric döndürür → `::int`.
- "Bu ay", "toplam" gibi değerleri asla elle yazma.

## 8. Dikkat hataları

- Virgül, `;`, tip adı ve sütun adı yazımı → migration'dan sonra `\d tablo`.
- `>` mi `>=` mi? Gereksinimi kelimesi kelimesine oku.
- `UPDATE … SET`'te alias yok, `WHERE`'de var.
- Aggregate sütunlarına alias ver, çıktı formatını kontrol et.

## Sorgu çalıştırmadan önce 5 soru

1. **Sıfırlar** görünmeli mi? → LEFT JOIN
2. **Sınırlar** dahil mi? → `>` / `>=`
3. Saydığım şey **one** tarafında mı, **many** tarafında mı?
4. Alt sorgum dış sorguya **neyle** bağlı?
5. Sonuç sayısı **mantıklı** mı? Değilse, önce `ON`'a ve bağlantıya bak.
