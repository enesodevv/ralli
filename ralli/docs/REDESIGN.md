# Ralli — araştırma sonrası deneyim değişiklikleri

1 Kasım 2026. Araştırma belgesi: outputs/Ralli-UX-Arastirma-ve-Yeniden-Tasarim-Raporu.md (çalışma alanı kökünde).

## Uygulanan deneyim
- Today, kullanıcı odağı, zaman, solo/partner ortamı ve deneyim tercihlerinden açıklanabilir bir öneri üretir. Duvar gereksinimi ve zaman sınırı gerçek filtrelerdir; odak eşleşmediğinde bu açıkça söylenir.
- İlk açılış profil zorunluluğu getirmez; isteğe bağlı kısa tercih ekranı vardır. Tüm kütüphane ayrıca kullanılabilir.
- Ders notu aktif odak/ipucu yapılabilir; Today ve o ipucuyla başlayan seans bağlanır. Geçmiş kayıt ilgili ders notuna bağlantı tutar (dondurulmuş kopya değildir).
- Practice bilgi mimarisi: hızlı uygun seçim + tüm kütüphane. Ayrıntıda ön koşul ve ekipman; ikincil yönergeler açılır bölümde bulunur.
- Kişisel tercihler ve seans taslağı SwiftData arşivinde opsiyonel alanlardır. Önceki sürümlerde bu alanların olmaması veri kaybına yol açmamalıdır.
- Aktif seans her 10 saniyede, kontrol değişimlerinde ve uygulama sahnesi değişiminde kaydedilir. Yeniden açılışta son kayıt noktasından duraklatılmış olarak yüklenir; uygulama kapalıyken geçen saatler çalışma süresine eklenmez.
- Seans bir kez kaydedilir; aynı seans kimliğiyle yinelenen kayıt toplam sayıyı artırmaz. Tamamlama ve aktif taslağı temizleme aynı veritabanı kaydında yapılır.
- Sesli ipuçları isteğe bağlı yerel konuşma sentezidir. Mikrofon kullanılmaz; duraklatma, ekran terk etme ve arka plana geçişte ses durur.
- Yarım notlar cihazdaki taslak alanına kaydedilir; kaydetmeden çıkarken taslağı tutma veya silme seçilir.
- Progress katılımı ve test sonucunu ayırır. Aynı plan ve aynı ölçüm sürümündeki en az iki girilmiş sonuç karşılaştırılır. Eski sürümü bilinmeyen sonuçlar karşılaştırmaya katılmaz. Geçmişin tamamı ve seans ayrıntıları açılabilir.
- Saydam karşılaştırma metni sonuçların kendi girişine dayandığını ve farklı koşulların etkisini belirtir; otomatik teknik gelişim iddiası yoktur.
- Küçük metin için kontrast artırıldı: muted #5D675C, clay #9C432F. Sistem metinleri ScaledMetric ile, serif başlıklar relativeTo stiliyle ölçeklenir. Oturum kaydırmasında Reduce Motion dikkate alınır.

## Devam eden sınırlar
- Sekiz çalışmanın kaynakları vardır; nitelikli antrenör saha incelemesi ve gerçek oyuncu araştırması yapılmış sayılmaz.
- Lisanslı/antrenör çekimli hareket videoları eklenmedi; mevcut kort şemaları ve sesli yönergeler kullanılır.
- Bu sürümde 10 dakikalık solo ayak çalışması vardır; her vuruş ve her süre için içerik yoktur. Uygun eşleşme yoksa açık durum gösterilir.
- Aktif seans çökmeden en çok son kayıt aralığı kadar süre kaybedebilir. Canlı zaman, uygulama kapanması sonrası son checkpoint ile sınırlandırılır.
- Bulut eşitleme, abonelik, bildirim ve üçüncü taraf analitik servisi eklenmedi.
- Sesli ipuçları fiziksel cihaz ve kullanıcının ses ortamında ayrıca denenmelidir.

## Doğrulama sonucu
- Son Xcode derlemesi: başarılı, 0 hata, 0 uyarı (Build LogStoreManifest).
- Model/kalıcılık testleri: 9 geçti, 0 hata (2 Kasım 2026 son test sonucu).
- Simülatör: kişisel tercih seçme/kaydetme, öneri gerekçesinin güncellenmesi, ikinci adımda kaydet/çık, uygulamayı yeniden başlatma, checkpoint’ten duraklatılmış geri yükleme ve Journal ipucunun Today’e taşınması doğrulandı.
- Progress boş karşılaştırma durumu doğru gösterildi; önceki kayıtlar korundu. Karşılaştırma gruplarının ayrılması otomatik testte doğrulandı.
- EN/TR 359 anahtar ve format parametreleri kontrol edildi.
- En büyük Dynamic Type ve azaltılmış hareket simülatörde kontrol edildi. Tam işitsel VoiceOver turu, fiziksel cihazda sesli ipuçları ve saha araştırması henüz yapılmadı.

## Tamamlama turu — 2 Kasım 2026
- Sekiz çalışmanın kort gösterimi oynatılabilir/duraklatılabilir. Azaltılmış harekette beş konum elle ilerletilir. Gösterimler teknik video veya gerçek top fiziği iddiası taşımaz.
- Resmî LTA rehberleri uygulama içi Safari görünümünde açılır; internet ve yayıncı koşulları açıkça belirtilir.
- Seans içinde kort kurulumunu açmak çalışmayı duraklatır.
- En büyük yazıda başlık, odak, not eylemleri ve karşılaştırmaların yerleşimi uyarlandı; süre göstergesinin taşması düzeltildi.
- VoiceOver için süre, adım ve kayıt bildirimleri eklendi; VoiceOver açıkken ayrı sesli ipucu çakışması önlendi. İşitsel cihaz testi bekliyor.
- Ralli uygulama simgesi eklendi.
- Normal oynat/duraklat ve azaltılmış hareket konum ilerletme simülatörde doğrulandı. En büyük yazı ve sunulan seans/gösterim ekranları incelendi.
- Son Ralli derlemesi: 0 hata, 0 uyarı. Dokuz model/kalıcılık testi başarılı; EN/TR 359 anahtar ve format parametreleri eşleşiyor.
