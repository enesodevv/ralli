# Ralli — Kortun dışında da senin oyunun

Görsel yön: bağımsız tenis dergisi. Sıcak kâğıt, koyu kort yeşili, terracotta ve tenis topunu çağrıştıran açık yeşil. Sistem serif başlıklar, monospaced küçük etiketler, okunaklı sistem gövde yazıları. Fotoğraf yerine SwiftUI ile çizilen kort illüstrasyonu.

## Modüller
- App: uygulama girişi, sekmeli gezinme.
- Core/DesignSystem: renkler, tipografi, ortak bileşenler, kort çizimi.
- Core/Models: yerel oyuncu durumu ve not modeli.
- Features/Home: kort ana ekranı.
- Features/Practice: arama/filtre/favori kütüphanesi, içerik ayrıntısı, çalışma şemaları, zamanlayıcılı seans ve isteğe bağlı sonuç kaydı.
- Features/Journal: not oluşturma, kaydetme, paylaşma ve silme.
- Features/Progress: yalnızca gerçek yerel kullanım sayıları.

## UX ilkeleri
Bir ekranda bir ana eylem. Suçluluk uyandıran seri kaybı bildirimleri ve sahte istatistikler yok. Simgelerin yanında metin etiketleri var. Notlar cihazda tutulur. CourtArt dekoratiftir, VoiceOver ağacından çıkarılmıştır. Ekranlar kaydırılabilir; büyük erişilebilirlik yazı boyutları ve küçük cihazlar simülatörde ayrıca kontrol edilmelidir.

## Mevcut sınırlar
Bu ilk arayüz prototipidir. Supabase, video kaydı ve yapay zekâ henüz bağlı değildir. Notlar ve çalışma geçmişi SwiftData içinde yerel olarak saklanır; eski UserDefaults verileri korunarak taşınır. Sesli not Türkçe konuşmayı metne dönüştürür; ses dosyası saklanmaz. Çalışma içeriği açıkça örnek olarak etiketlenir. Gerçek adım zamanlayıcısı ve yerel çalışma geçmişi vardır; teknik analiz yoktur. Notlar kategorilenebilir ve düzenlenebilir.

## Yerelleştirme
Global sürümde İngilizce ve Türkçe arayüz kaynakları ayrı tutulur. Serif başlıkların satır kırımları her dil için yazılmıştır. Kişisel notlar özgün dilinde kalır. Kategori tanımlayıcıları veri katmanında sabit, görünür etiketler yerelleştirilmiştir. Yeni ekranların kullanıcıya görünen tüm metinleri ve izin açıklamaları her iki dile eklenmelidir.

## Güncel araştırma sonrası tasarım
Home → Today. Ayrıntılı kararlar ve teknik sınırlar REDESIGN.md içindedir. Renkler: paper #F5F1E8, ink #24382D, muted #5D675C, clay #9C432F, lime #D9E896. Renkli kart etiketleri zemine uygun açık yazı kullanır. Serif başlıklar ölçeklenebilir Georgia; sistem yazıları ScaledMetric kullanır. Tasarımın gerçek saha testinin yerine geçmez.
