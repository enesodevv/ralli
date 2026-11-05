# Ralli

SwiftUI ile iOS 17+ tenis uygulaması arayüz prototipi.

## Açılış
`Ralli.xcodeproj` dosyasını Xcode ile açın, Signing & Capabilities altında kendi takımınızı seçin ve bir iPhone simülatöründe çalıştırın.

Xcode projesini yeniden üretmek için proje klasöründe `xcodegen generate` çalıştırın. Proje tanımı `project.yml` içindedir. Harici paket bağımlılığı yoktur.

Çalışan akışlar: dört sekmeli gezinme, üç adımlı örnek çalışma ve tamamlanma kaydı, ders notu oluşturma / yerel saklama / paylaşma / silme, gerçek kayıt sayılarından gelişim görünümü.

Tasarım ve kapsam: `docs/DESIGN.md`.

Doğrulama: Xcode 26.6 ile iOS Simulator Debug derlemesi başarılı. iPhone 17 Pro / iOS 26.2 simülatöründe dört ekran görsel olarak incelendi; partner seçimi, çalışma adımları, tamamlanma, not oluşturma/kaydetme ve sayaç güncellemeleri doğrulandı. Xcode LLDB bağlantısı hata verdiği için kurulu uygulama simülatörden doğrudan açıldı. Test için bir örnek not ve bir tamamlanmış çalışma cihazda bırakıldı. Paylaşım, silme ve yeniden başlatma sonrası kalıcılık ayrıca doğrulanmadı.

## İkinci geliştirme adımı
Backhand, forehand ve servis örnekleri; solo/partnerli yönergeler; tarihe dayalı, duraklatılabilen adım zamanlayıcısı; erken adım geçişi; çıkış onayı; tarih/odak/süre içeren çalışma geçmişi eklendi. Notlar kategorilenebilir, filtrelenebilir ve düzenlenebilir; silme onay ister. Eski kategorisiz notlar Genel olarak görünür.

Zamanlayıcı uygulama açık kaldığı sürece sekmeler arasında sürer; arka plandan dönüşte son tarihle güncellenir. Güncel sürümde devam eden seans son kayıt noktasından duraklatılmış olarak geri yüklenir. Tamamlanan seanslar ve notlar cihazda saklanır. Bulut eşitleme henüz yoktur.

## Sesli not ve SwiftData
Notlar ve tamamlanan çalışmalar SwiftData ile cihazda saklanır. Eski UserDefaults kayıtları ilk açılışta taşınır; kaynak veriler korunur ve sonraki açılışlarda yeniden içe aktarılmaz. Kaydetme başarısız olduğunda düzenleyici kapanmaz ve hata gösterilir.

Ders notu düzenleyicisindeki Konuşarak ekle, Türkçe konuşma tanımayı kullanır. Mikrofon ve konuşma tanıma izinleri yalnızca bu düğmeye basıldığında istenir. Metin mevcut nota eklenir ve dinleme bittikten sonra düzenlenebilir. Oturum 55 saniyede durur; arka plana geçişte ve düzenleyiciden çıkışta mikrofon kapatılır. Ses dosyası saklanmaz; tanıma Apple hizmetleriyle işlenebilir ve bağlantı gerektirebilir.

Doğrulama: Xcode ile iOS derlemesi başarılı. RalliPersistenceTests şemasında 3 test, 0 hata: eski veriyi taşıma/tekrar içe aktarmama, düzenleme-silme-seans kaydını yeniden yükleme, bozuk kaynak veriyi koruma. Simülatörde mevcut örnek not ve seans sayısının taşındığı, sesli not ekranı ve izin reddinde yazılı nota dönüş doğrulandı. Simülatörde konuşma tanıma izni test amacıyla reddedildi. Canlı mikrofon ve Türkçe tanıma doğruluğu fiziksel iPhone üzerinde ayrıca doğrulanmalıdır.

Apple belgeleri: https://developer.apple.com/documentation/Speech/SFSpeechRecognizer ve https://developer.apple.com/documentation/swiftdata/modelcontainer

## Diller
İngilizce ve Türkçe desteklenir. Uygulama iOS dil tercihini izler; desteklenmeyen diller için geliştirme/fallback dili İngilizcedir. Zorunlu Türkçe locale kaldırılmıştır. Arayüz, çalışma yönergeleri, uyarılar, erişilebilirlik süre metni ve sistem izin açıklamaları yerelleştirilmiştir. Ses tanıma İngilizce için en-US, Türkçe için tr-TR kullanır. Kullanıcının not metni çevrilmez; kaydedilmiş kategori anahtarları değiştirilmeden gösterimde çevrilir.

Kaynaklar `Resources/en.lproj` ve `Resources/tr.lproj` altındadır. 124 anahtarın iki dilde eşleşmesi, süre/adım format parametreleri ve strings dosyalarının geçerliliği kontrol edildi. Xcode derleme/çalıştırma başarılı; İngilizce ana ekran, çalışma içeriği, defter, kategori etiketleri ve izin reddi mesajı simülatörde doğrulandı. Türkçe ses tanıma gibi İngilizce canlı tanıma da fiziksel cihazda ayrıca test edilmelidir.

## Practice kütüphanesi
Practice artık 8 kaynak bağlantılı çalışma içerir: backhand, forehand derinlik, servis yerleşimi, duvar, karşılama, vole, ralli ve ayak çalışması. Arama, vuruş/solo/partner filtreleri ve kalıcı favoriler; amaç, ekipman, kort şeması, ipucu, yaygın hata ve adımlı seans ayrıntısı eklendi. Sonuç girişinde isabet/ralli/dengeli dönüş ve kişisel düşünce isteğe bağlıdır. Kaydedilenler Progress içinde görünür.

Doğrulama: Xcode iOS derlemesi ve simülatörde kütüphane → servis filtresi → favori → ayrıntı → başlat → duraklat/sürdür → adımlar → değerlendirme → sonuç/not kaydı → gelişim geçmişi akışı başarılı. Güncellenen 3 kalıcılık testi geçti (0 hata): eski alanları olmayan seansların taşınması, yeni plan kimliği/sonuç/not alanlarının korunması ve bozuk kaynak verinin koruması. EN/TR 267 çeviri anahtarı kontrol edildi. Sonuç içeren bir simülatör kaydı açıkça “Interface test — not a real practice session.” olarak etiketlidir.

İçerik kaynakları ve kapsam sınırları: `docs/PRACTICE.md`. Antrenör saha incelemesi henüz yapılmadı.

## Araştırma sonrası yeniden tasarım (1 Kasım 2026)
Güncel deneyim şartnamesi `docs/REDESIGN.md` içindedir. Home artık Today: kısa ve isteğe bağlı kişisel tercihler, gerçek ortam/zaman/seviye filtreleriyle açıklanabilir öneri, aktif ders ipucu ve yarım seansı sürdürme. Ders notları odağa/sonraki seansa bağlanır; taslaklar korunur. Saha modu sesli ipuçları ve kayıt noktasından kurtarma sunar. Progress katılımı ve aynı sürümdeki test sonuçlarını ayırır, tüm geçmişi ve seans ayrıntısını açar.

Son doğrulama: Xcode ile iOS derlemesi başarılı; 7 macOS model/kalıcılık testi geçti (0 hata). Testler eski veri geçişini, tercih ve not bağlantısını, ortam/zaman/seviye filtrelerini, seans taslağını, yinelenen tamamlamanın önlenmesini ve karşılaştırma gruplarının doğruluğunu kapsar. Dil kaynaklarında 337 EN/TR anahtarı eşleşiyor. Arayüzde tercih seçimi ve kaydet/çık akışı simülatörde kontrol edildi.

Metin kontrastları güçlendirildi; sistem yazıları ve serif başlıklar Dynamic Type ile ölçeklenir. Sesli ipuçları ve çok büyük yazı boyutlarının fiziksel cihazdaki saha kontrolü henüz yapılmadı. Hareket videoları, gerçek kullanıcı araştırması ve antrenör saha onayı bu kod değişikliğinin tamamlanmış çıktıları değildir.

Simülatör ek doğrulaması: tercihler kaydedildikten sonra Today önerisi değişti; seans ikinci adımda kaydedilip çıkıldı, uygulama yeniden başlatıldı ve aynı adımdan duraklatılmış halde geri yüklendi. Journal → Practise with this cue, Today odağını ve ipucunu güncelledi. Progress boş karşılaştırma durumunu geçmişten ayrı gösterdi; mevcut kayıt ayrıntıları korundu. Karşılaştırma grafiğinin çok büyük Dynamic Type ve gerçek saha koşulu kontrolleri henüz tamamlanmadı.

## Güncel doğrulama — 2 Kasım 2026
Önceki bölümlerdeki sayılar geliştirme tarihçesidir. Güncel sonuç: Ralli iOS derlemesi 0 hata/0 uyarı; 9 model ve kalıcılık testi başarılı; 359 EN/TR anahtarı ve format parametreleri eşleşiyor. Kort gösteriminde oynat/duraklat, azaltılmış harekette elle konum ilerletme ve en büyük yazıdaki seans/gösterim akışı simülatörde kontrol edildi. Normal Ralli şeması yeniden çalıştırıldı.

Şematik kort animasyonları, resmî LTA rehberine erişim, seans sırasında kurulum görüntüleme, büyük yazı düzenleri, erişilebilirlik bildirimleri ve uygulama simgesi eklendi. İnsan tekniği çekimleri üretilmedi. Fiziksel cihazda ses/VoiceOver, oyuncu pilotu ve antrenör incelemesi bekliyor. Kabul kontrolü çalışma alanındaki `outputs/Ralli-Pilot-Kabul-Kontrolu.md` belgesinde.

## Arayüz düzeltmeleri ve genişletilmiş kütüphane — 2 Kasım 2026 (akşam)
- Kort modu: seans sürerken koyu, yüksek kontrastlı ekran; büyük yeşil sayaç; ana düğme Duraklat/Sürdür, Sonraki adım ikincil. Süre bitince yalnızca Sonraki adım gösterilir.
- Adım sonu artık duyulur ve hissedilir: titreşim, sistem sesi, sesli ipucu açıksa konuşma. Uygulama arka plandayken adım bitişi için yerel bildirim planlanır (izin ilk seans başlarken istenir). Seans sırasında ekran kilitlenmez.
- Today: büyük başlık yalnızca ilk kullanımda; devam et/öneri kartı en üstte; sesli not kısayolu öne alındı.
- Practice: kütüphane doğrudan görünür, yarım seans için devam bandı, tekrar eden öneri kartları kaldırıldı, tercihler filtre satırında.
- Çalışma ayrıntısı: adımlar her zaman açık; seviye etiketi; kaynak ve güvenlik notu en altta.
- Journal: not başına tek ana eylem + "…" menüsü, kategori çipleri; editör mikrofonla başlar, başlık isteğe bağlı (boşsa ilk satır).
- Progress: son 7 gün şeridi.
- Tasarım değişkenleri: `RalliTheme.radius` (20), `smallRadius` (14), `surface`.
- Kütüphane 8 → 17 çalışma: gölge vuruş, kendi beslemenle forehand/backhand, top atışı, ikinci servis, duvara vole, split step, fileye çıkış, lob/smaç. Yeni metinler EN/TR; antrenör saha incelemesi hâlâ bekliyor.
- Doğrulama: iOS derlemesi başarılı, 9 test geçti, 488 EN/TR anahtarı ve format parametreleri eşleşiyor. Simülatörde Today, kort modu (sürdür/duraklat/kaydet-çık), Practice, Journal ve Progress kontrol edildi. Ses, titreşim ve bildirim fiziksel iPhone'da denenmedi.

## İlk açılış tanıtımı — 2 Kasım 2026
- Yeni kullanıcı ilk açılışta 3 sayfalık tanıtım görür: dersteki ipucunu kaydet → korta taşı → neyin değiştiğini gör. Son sayfada "Bana göre ayarla" (tercih ekranını açar) ya da "Önce bir bakayım" seçilir; her sayfada "Geç" vardır.
- Notu, seansı veya yarım seansı olan mevcut kullanıcılar tanıtımı görmez. Durum `hasSeenIntro` ile saklanır.
- Geliştirme sırasında tanıtımı zorla açmak için uygulamayı `-ralli-show-intro` argümanıyla başlatın (yalnızca Debug).
- Sayfalar düğmeyle ve yatay kaydırmayla değişir; azaltılmış harekette yalnızca solma geçişi kullanılır. Dosya: `Features/Onboarding/IntroView.swift`.
- Doğrulama: derleme başarılı, 9 test geçti. Simülatörde İngilizce üç sayfa, "Bana göre ayarla" → tercih ekranı ve Türkçe ilk sayfa kontrol edildi.

## 3B vuruş animasyonları — 4 Kasım 2026
- Çalışma gösteriminde iki sekme var: **Vuruş hareketi** ve **Kort yönü** (önceki şema).
- Vuruş hareketi SceneKit ile çizilen 3B bir sahnedir: gerçek ölçülerde kort ve file, kıyafetli oyuncu, telli raket, gölge düşüren ışık, ufukta yumuşak sis. Kamera açısı Yandan / Arkadan / Önden seçilebilir; geçişler yumuşaktır.
- Hareketler: forehand, çift el backhand, servis, vole, smaç, split step. Her biri 4–5 anahtar pozdan oluşur; aradaki kareler Catmull-Rom eğrisiyle hesaplanır. Hazırlık yavaş, vuruş hızlıdır (anahtar poz başına süre). Dirsek ve dizler ters kinematikle her karede gerçek kemik uzunluğunda tutulur.
- Efektler: raket başının savrulma izi, temas anında genişleyen halka, top tellerin üstünde. Yavaş çekim hızı %35'e düşürür.
- Azaltılmış harekette sahne kendi kendine oynamaz, efektler kapanır; evreler düğmeyle ilerletilir.
- Dosyalar: `Core/Models/StrokeMotion.swift` (pozlar, zamanlama, IK), `Features/Practice/StrokeScene.swift` (sahne), `Features/Practice/StrokeMotionView.swift` (oynatıcı).
- Geliştirme kısayolu (yalnızca Debug): uygulamayı `-ralli-demo <çalışma kimliği>` ile açmak o çalışmanın gösterimini doğrudan açar, ör. `-ralli-demo serve`.
- Figür teknik analiz değildir; uygulamada bu yazılıdır. Pozların bir antrenör tarafından gözden geçirilmesi gerekir.
- Doğrulama: derleme 0 uyarı, 13 test geçti (kemik oranları anahtar pozlarda ve ara karelerde, ayak/raket zemin üstünde, zamanlama, EN/TR metinler). Altı hareket simülatörde Türkçe olarak kare kare incelendi. Gerçek iPhone'da akıcılık ve pil etkisi henüz ölçülmedi.

## Hareket denetimi ve düzeltmeler — 4 Kasım 2026
- Altı hareket 600 karede sayısal ve 3 kamerada görsel olarak denetlendi. 37 bulgunun tamamı giderildi; ayrıntılı rapor: `outputs/Ralli-Hareket-Denetimi.md`.
- Kollar ve raket göğsün kendi ekseninde, raket yönü küresel ara değerlemeyle hesaplanır. Her karede şu kurallar uygulanır: kemik boyları sabit, dizler öne, eller/raket kafa ve gövde dışında, backhand'de sol el sapta, ayak ya sabit ya da adım atarak hareket eder.
- Servis ve smaç doğru teknikle yeniden yazıldı (Top atışı ve Kupa pozisyonu evreleri). Forehand ve backhand'e Takip evresi eklendi. Oyuncuya siperlikli şapka eklendi.
- Denetim artık test kapısıdır: `MotionAuditTests.testEveryMotionPassesThePhysicalAudit`.
- Debug kısayolu: `-ralli-contact-sheet <hareket> <side|behind|front>` bir hareketin 12 karesini tek ekranda gösterir.

## Faz 0 — yayın hazırlığı (4 Kasım 2026)
- `PrivacyInfo.xcprivacy`: izleme yok, veri toplama yok, UserDefaults gerekçesi CA92.1. Analitik servisi eklenirse güncellenmeli.
- Sürüm 1.0.0 (1), `ITSAppUsesNonExemptEncryption = NO`, Spor kategorisi, tam ekran (yalnızca dikey). `DEVELOPMENT_TEAM` ve kalıcı bundle ID `project.yml` içinde girilmeli.
- Konuşma tanıma, destekleyen cihazlarda yalnızca cihaz içinde çalışıyor.
- `RenderQuality`: Düşük Güç modunda ya da cihaz ısınınca 3B sahne 30 fps ve efektsiz moda geçer; duraklatılınca çizim yapmaz.
- `Analytics`: huni olayları (açılış, tanıtım, tercih, not, seans, hareket gösterimi). Kişisel içerik yok; şimdilik yalnızca cihaz günlüğüne yazılıyor. MetricKit çökme ve donma teşhisleri bağlı.
- Sağlık uyarısı her çalışmanın detayında görünür.
- Yayın belgeleri (gizlilik politikası EN/TR, App Store metinleri, App Privacy cevapları, kontrol listesi): `outputs/yayin/`.
- Doğrulama: Release (iphoneos) derlemesi uyarısız; Debug kısayolları sürümde yok; 15 test geçti.

## Solak desteği, App Review hazırlığı ve 6 dil — 4 Kasım 2026
- **Solak:** tercihlerde "Hangi elinle oynuyorsun?". 3B hareketler tam ayna görüntüsü olarak hesaplanır (`StrokeMotion.mirrored()`); kamera ve kort şemaları da aynalanır. Oynatıcıda "Solak" kısayolu var. Solak hareketler de fiziksel denetim testinden geçer.
- **App Review:** Bugün ekranındaki (i) düğmesi Hakkında sayfasını açar: uygulama içinde okunabilen gizlilik politikası (Yönerge 5.1.1), izin ayarlarına kısayol, güvenlik notu, LTA/USTA ile bağlantısızlık beyanı, sürüm. Destek e-postası `AppLinks.supportEmail` boşken gösterilmez (ölü bağlantı riski olmasın diye).
- **Diller:** en, tr, es, de, fr, it. 500 metin; arayüz, 17 çalışma, animasyon metinleri, gizlilik ve izin açıklamaları. Konuşma tanıma ve sesli ipuçları uygulama dilinin bölgesel sesini kullanır. Kullanılmayan 76 eski metin silindi. `testEveryLanguageMatchesEnglish` eksik anahtar ve biçim hatasını yakalar.
- App Store metinleri dört yeni dilde de `outputs/yayin/app-store-metinleri.md` içinde.
- Doğrulama: 18 test geçti; Release (iphoneos) derlemesi uyarısız ve 6 dili içeriyor. Almanca Bugün ve Hakkında ekranları ile solak forehand simülatörde kontrol edildi.

## Kullanıcı testleri — 5 Kasım 2026
- `RalliUITests` (XCUITest, 13 test) uygulamayı gerçek bir oyuncu gibi kullanır: tanıtım ve tercihler, tanıtımı geçme, arama/filtre/favori, tam seans ve Gelişim kaydı, kaydet-çık ve yeniden açınca geri yükleme, kayıtlı seans varken başka çalışmaya bakma, seansı silme, not yazma/odak yapma/düzenleme/silme, not taslağı, Hakkında ve gizlilik, en büyük yazı boyutu, solak tercihinin hatırlanması, 6 dilde tüm sekmeler.
- Çalıştırma: `RalliUITests` şeması, bir iPhone simülatöründe (yaklaşık 10 dakika). Testler kendi ayrı veri dosyasını kullanır; gerçek veriye dokunmaz (`-ralli-ui-testing`, `-ralli-reset`, `-ralli-skip-intro`, yalnızca Debug).
- Testlerin bulduğu ve düzeltilen sorunlar: kayıtlı bir seans varken başka çalışmaların detayı açılmıyordu (artık açılıyor; yalnızca başlatırken "Onu sil ve bunu başlat" sorulur); İngilizcede "1 sessions recorded" dilbilgisi hatası; Bugün ekranındaki "Kendine göre ayarla" iki satıra taşıyordu ("Ayarla"); animasyondaki "Solak" kontrolü kapalıyken düğme olduğu anlaşılmıyordu (açık/kapalı hâli belli bir düğme oldu).
