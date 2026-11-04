# Ralli — Faz 0 yayın kontrol listesi

## Kodda tamamlananlar (4 Kasım 2026)
- [x] Gizlilik manifesti (`PrivacyInfo.xcprivacy`): izleme yok, veri toplama yok, UserDefaults gerekçesi CA92.1.
- [x] Sürüm 1.0.0 (build 1), şifreleme beyanı (`ITSAppUsesNonExemptEncryption = NO`), Spor kategorisi.
- [x] Konuşma tanıma, destekleyen cihazlarda yalnızca cihaz içinde çalışıyor.
- [x] 3B sahne Düşük Güç modunda ya da ısınmada 30 fps'ye ve efektsiz moda geçiyor; duraklatılınca çizim yapmıyor.
- [x] Analitik altyapısı: olaylar yalnızca cihaz günlüğüne yazılıyor. MetricKit çökme ve donma teşhisleri bağlı.
- [x] Sağlık uyarısı her çalışmanın detayında görünür.
- [x] Gizlilik politikası, App Store metinleri ve App Privacy cevapları taslak olarak hazır.
- [x] Uygulama içi Hakkında sayfası: gizlilik politikası (internetsiz okunabilir), izin ayarları, güvenlik, içerik kaynakları ve bağımsızlık beyanı, sürüm (Yönerge 5.1.1).
- [x] Solak oyuncu desteği (tercih + animasyonlar + kort şemaları).
- [x] 6 dil: İngilizce, Türkçe, İspanyolca, Almanca, Fransızca, İtalyanca (arayüz, 17 çalışma, animasyon metinleri, gizlilik, izin açıklamaları, App Store metinleri).
- [ ] Destek e-postası: gerçek bir adres olunca `AboutView.swift` içindeki `AppLinks.supportEmail` alanına yaz.

## Senin yapman gerekenler
1. **Apple Developer Program** üyeliği (yıllık 99 $). Bireysel ya da şirket olarak; şirket adı mağazada görünür.
2. **Alan adı ve web sitesi:** `/privacy` ve `/support` sayfaları. Taslaklar bu klasörde.
3. **Bundle ID:** sahip olduğun alan adına göre seç (ör. `app.ralli.ios`) ve `ralli/project.yml` içinde `DEVELOPMENT_TEAM` ile birlikte gir. Sonra `xcodegen generate` çalıştır.
4. **"Ralli" adının uygunluğu:** App Store'da ve marka tescilinde (TÜRKPATENT, gerekirse EUIPO/USPTO) aynı adda bir ürün var mı kontrol et.
5. **Vergi ve banka:** App Store Connect'te vergi formları (W-8BEN) ve banka bilgisi. Şahıs şirketi gerekip gerekmediğini mali müşavirle konuş.
6. **Hukuk kontrolü:** gizlilik politikası (KVKK, GDPR) ve kullanım koşulları.
7. **Gerçek iPhone testi:** pilot kabul kontrolündeki maddeler (ses, titreşim, bildirim, VoiceOver, sıcaklık ve pil).
8. **Antrenör içerik onayı:** 17 çalışma ve 6 animasyon.
9. **TestFlight:** Xcode › Product › Archive › Distribute › TestFlight. İlk 20-30 kişilik pilot grubu.

## Faz 0'dan sonra (Faz 1–2)
- Analitik servisi seçimi (gizlilik öncelikli; ör. TelemetryDeck) ve bunun App Privacy etiketine yansıtılması.
- iCloud yedekleme, karanlık mod.
- Abonelik (StoreKit 2), programlar, 40+ çalışma; sonra Japonca ve Brezilya Portekizcesi.
- Yeni dillerin ana dili konuşan, tenis bilen biri tarafından okunması.
