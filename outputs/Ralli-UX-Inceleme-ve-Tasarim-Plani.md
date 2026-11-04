# Ralli — bütün uygulama için UX incelemesi ve yeni tasarım

2 Kasım 2026 · Tasarım önerisi / uygulama şartnamesi

## Karar

Ralli’nin özelliklerini azaltmadan, kullanıcıya aynı anda sunulan kararları azaltacağız. Ana döngü: **uygun çalışma bul → ne yapacağını anla → çalış → kaydet → sonraki ziyaretinde kaldığın yerden devam et.** Not ve geçmiş bu döngüyü destekleyecek.

Mevcut görsel kimlik korunabilir: sıcak kâğıt, kort yeşili ve sınırlı kil rengi. Ancak büyük şiirsel başlıklar, küçük üst etiketler, kutu içinde kutular ve sürekli açıklama blokları azaltılmalı. Sanatsal karakteri boşluk, tipografi ve kort çizgisi taşımalı; her bileşenin dikkat istemesi gerekmiyor.

Bu belge mevcut SwiftUI ekranları, durumları, modelleri ve yerelleştirme metinlerinin uzman değerlendirmesidir. Kullanılabilirlik testi sonucu değildir. Bu turda açık simülatör iPhone 16 Pro/iOS 18.5 başlatma ekranında kaldığından güncel ekranların tamamının yeni canlı görsel turu yapılmış sayılmamalıdır. Önceki simülatör doğrulamaları, kod incelemesinin yerine kanıt olarak kullanılmadı. Tasarım prototipi üretim uygulamasından ayrı bir çıktıdır.

## İnceleme bulguları

Öncelik: P1 temel görevde belirgin yük/yanıltma, P2 tekrarlanan sürtünme, P3 görsel tutarlılık. Bunlar uzman değerlendirmesi; ölçülmüş hata oranları değildir.

| Alan | Mevcut somut durum | Kullanıcı açısından sorun | Karar | Öncelik |
|---|---|---|---|---|
| Today | Kurulum çağrısı, odak/değiştir, öneri veya taslak, aktif not, not ekleme, keşfet | İlk açılışta ana işin hangisi olduğu belirsizleşiyor | Tek baskın çalışma alanı; tercihler tek özet satırında; not kısa ve ikincil | P1 |
| Practice | Tercih kurma + önerilen çalışma + tüm kütüphane aynı ekranda | Today tekrarlanıyor; liste aşağı itiliyor; öneri kütüphanede tekrar görünebiliyor | Yalnızca arama, filtre girişi ve çalışma listesi | P1 |
| Filtre | Yatay vuruş şeritleri + ortam menüsü + favori kontrolü | Üç farklı kontrol biçimi; bazı vuruşlar yatay kaydırmada saklı | Tek filtre sayfası, dışarıda sonuç sayısı ve etkin filtre özeti | P2 |
| Çalışma kartı | Sembol, serif başlık, alt açıklama, süre, ortam, favori | Sekiz öğelik katalogda tarama zorlaşıyor | Ad, süre, ortam ve anlamlı tek satır tanım; favori ayrıntıda | P2 |
| Çalışma ayrıntısı | Gösterim, kaynak rehberi, amaç, ön koşul, ekipman, ipucu/hata, yapı, ölçüm, ses seçimi, uyarı, kaynak | Başlamak için okunması gerekenlerle başvuru içeriği karışıyor | Amaç + gerekli kurulum görünür; rehber ve ayrıntılar tek girişte | P1 |
| Aktif seans | Büyük plan başlığı, adım başlığı, yönerge, sayaç, iki eylem, ipucu, gösterim, ses anahtarı | Kortta hızlı bakışta fazla hiyerarşi | Küçük plan adı; büyük mevcut görev; sabit kontrol alanı; araçlar menüde | P1 |
| Erken adım geçişi | Süre dolmadan “Sonraki adım” normal ana düğme | Yanlışlıkla aşama atlama ihtimali | Süre dolmadan ikincil “Adımı erken bitir”; dolunca ana “Sonraki adım” | P2 |
| Seansı bitirme | Son adım ardından ölçüm anahtarı, açıklama, sonuç ve düşünce | Kaydetmek, form doldurma görevi gibi algılanabilir | Birincil “Seansı kaydet”; isteğe bağlı sonuç/not açılır | P1 |
| Journal liste | Her kartta odağa al, bu ipucuyla çalış, paylaş, düzenle, sil | Beş eylem tekrar ediyor; farkları anlaşılmıyor; silme gereğinden görünür | Kısa satırlar → not ayrıntısı; tek “Çalışmaya taşı” | P1 |
| Journal davranış | “Practise with this cue” aktif notu değiştirip Today’e götürüyor | Düğme vaadi ile sonuç farklı | Eylem adı “Bir sonraki çalışma için kullan”; uygun çalışma ve Başla görünür | P1 |
| Not düzenleyici | Kategori ve başlık, uzun ses açıklaması gövdeden önce | Kullanıcının asıl işi olan yazma alanı geri planda | Gövde önce; kısa mikrofon eylemi yanında; kategori isteğe bağlı | P2 |
| Not kaydı | Başlık ve gövde zorunlu | Tek cümlelik hızlı kayıt engelleniyor | Gövde yeterli; boş başlık ilk cümleden türetilir, sonra düzenlenebilir | P2 |
| Progress | Katılım toplamları ardından açıklamalar, yetersiz karşılaştırma, geçmiş | Değerli geçmiş aşağıda; az veri cezalandırıcı hissettirebilir | Özet → geçmiş; karşılaştırma yalnızca veri oluşunca giriş olarak görünür | P1 |
| Tercihler | Odak, ortam, duvar, süre, seviye ve canlı öneri aynı formda | Günlük koşullarla kalıcı beceri tercihi karışıyor | Süre/ortam/odak “Bu çalışma”; seviye ayrı “Oyuncu tercihleri” | P2 |
| Metinler | “Keep the feeling”, “See what changes”, “Your court, your way” gibi başlıklar | İlk kullanımda bölümün işini tanımlamak güçleşiyor | Notes, Progress, Session options gibi doğrudan başlıklar | P2 |
| Gezinme | Katalog ayrıntısı ve aktif seans aynı fullScreenCover içinde | İnceleme ile çalışma moduna girme ayrımı silik | Ayrıntı navigation push; aktif seans odaklı fullscreen | P2 |
| Durum/hata | Bazı kayıt hataları hem kök hem yerel görünümden sunulabiliyor | Aynı hatanın sunumu konusunda belirsizlik | Hata sahibi tek katman; işlem yanında tekrar dene; içerik korunur | P2 |
| Görsel dil | 10–13 pt mono üst etiketler, 36–45 pt serif başlıklar, çok sayıda renkli kart | Büyük farklar ve dekoratif etiketler yoğunluğu artırıyor | Daha sakin ölçek; normal metin varsayılan; renkli vurgu tek bölgede | P3 |

## Bilgi mimarisi

Dört sekme korunacak: **Today / Practice / Notes / Progress**; Türkçe **Bugün / Çalış / Notlar / Gelişim**. Sekme sayısını azaltmak için notları veya geçmişi gizlemek bu aşamada ek keşif yükü yaratır. Bu karar pilotta sekme bulma görevleriyle doğrulanacak.

- Today: tek öneri veya yarım seans; çalışma koşulları; varsa tek satırlık kişisel ipucu.
- Practice: bütün çalışmalar; arama; tek filtre girişi; ayrıntı.
- Notes: kısa not listesi; not ayrıntısı; yeni not.
- Progress: kısa katılım özeti; geçmiş; uygun veri olduğunda karşılaştırma ayrıntısı.
- Oyuncu tercihleri: Today başlığındaki etiketli araç düğmesi; ilk açılışta zorunlu değil.

**Modal kuralı:** filtre, günlük koşullar, not yazma ve kısa ayarlar sheet; kütüphane → çalışma ayrıntısı navigation push; aktif çalışma fullscreen. Geri dönüş, kullanıcının arama ve kaydırma konumunu korur. Not ayrıntısından gelen çalışma bitince not bağlamı korunur.

## Ekran tasarımları ve durum sözleşmeleri

### 1. Today

Üstte küçük marka ve “Today”. Altında “20 min · Solo · Serve” gibi düzenlenebilir tek koşul satırı. Ana bölgede çalışma adı, süre/ortam ve bir cümle amaç; **View session / Çalışmayı gör** düğmesi ayrıntıya götürür. Başlatma ayrıntıda gerçekleşir; kullanıcı kurulum/ekipmanı atlamaz. Yarım seans varsa önerinin yerini alır, ana düğme **Resume / Devam et** olur.

Aktif kişisel ipucu iki satırı aşmaz; dokununca nota gidilir. Not ekleme ve tüm kütüphane için ayrı büyük kartlar yok: sekmeler zaten bu işleri sunar. İlk kullanımda hesap/anket açılmaz. Kayıtlı tercihler “bugünkü fiziksel koşullar” olarak doğrulanmış sayılmaz; kullanıcı koşul satırından değiştirebilir.

Uygun öneri yoksa kısa neden + “Change options / Seçenekleri değiştir” ve ikincil “Browse all”. Daha uzun süre veya ekipman gerektiren çalışma sessizce önerilmez. Aktif taslak hiçbir tercihle örtük silinmez.

### 2. Practice

Başlık “Practice”. Arama alanı ve etiketli “Filters” düğmesi. Hemen altında sonuç listesi; öneri/kurulum kartı yok. Satırlar aynı yapıda: çalışma adı, bir satır amaç, süre ve ortam; belirgin ileri işareti. Ayrıntıya dokunmadan seans başlamaz.

Filtre sheet: ortam, vuruş ve kaydedilenler; duvar uygunluğu gerektiğinde açık seçeneğe dönüşür. Alt sabit eylem “Show 3 sessions / 3 çalışmayı göster”; görünür “Reset / Sıfırla”. Onaylanmamış değişiklikler kapatınca listeyi değiştirmez. Etkin filtreler dışarıda kısa özette görünür. Boş sonuçta aramayı silmek ile filtre sıfırlamak ayrı eylemler; kullanıcı hangi veriyi değiştirdiğini bilir.

### 3. Çalışma ayrıntısı

Üstte geri ve kaydet/favori. Başlık, süre ve ortam, tek cümle amaç. Ardından **Before you start / Başlamadan önce**: zorunlu ekipman, partner/duvar gereksinimi, seviye ve kort kurulumu. Ön koşullar keşfedilebilirliği azaltacak şekilde gizlenmez.

Kort kurulumunun küçük, hareketsiz önizlemesi ve “Court setup & guide / Kort kurulumu ve rehber” girişi. Ayrı rehberde animasyon ve kaynaklar. “Steps & tips / Adımlar ve ipuçları” açılır bölümünde seans yapısı, ana ipucu, yaygın hata ve ölçüm tanımı. Alt sabit **Start session / Seansa başla**. İlk görünümde rehberin bütün metni, ses seçimi ve kaynak açıklamaları yok.

Başka taslak varsa “You have a saved session” mesajı; “Resume saved session” veya “Keep browsing”. Yeni plan açmak taslağı kaybettirmez. Kullanıcı taslağı silmeyi ancak açık seans yönetiminden seçer.

### 4. Aktif çalışma

Üst araç çubuğu: “Close / Kapat”, küçük plan adı, etiketli “Tools / Araçlar”. Gövde: “Step 2 of 3”, mevcut görev başlığı, kısa yönerge, büyük süre. Ana kontrol **Pause / Duraklat**; durunca **Resume / Sürdür**. Sonraki adım aynı anda birincil görünmez.

Süre dolunca sayaç 00:00; otomatik adım atlama yok; ana eylem “Next step”. Son adımda “Finish session”. Erken geçiş ikincil “Finish step early” kontrolüdür; ilk kullanımda kaydedilen sürenin gerçek geçen süre olduğu kısa bağlamla anlatılır. Tek kişisel ipucu en çok iki satır; tamamı araçlardan açılır.

Araçlar: kort kurulumu, tam yönerge, sesli ipuçları. Kurulum açılınca süre durur; kapanınca “Paused / Duraklatıldı” korunur, açık sürdürme gerekir. Close → “Save & leave”, “Keep practising”, ikincil yıkıcı “Discard”. Geri yüklemede en üstte tek satır duraklatılmış durum; uzun açıklama tekrar etmez.

### 5. Seans bitirme

Başlık “Session complete / Seans tamamlandı”; gerçek kaydedilecek süre. Ana **Save session / Seansı kaydet** hiçbir ölçüm formunu zorunlu tutmaz. “Add a result” ve “Add a note” isteğe bağlı alan açar. Sonuç tanımı, payda ve aralık yanında görünür. Büyük aralıklar için yalnızca Stepper yerine sayısal alan + artır/azalt; boş, sıfır ve geçersiz değer farklı ele alınır.

Başarıdan sonra sade onay ve önceki bağlama dönüş. Başarı mesajı gerçek kalıcılık tamamlanınca gösterilir. Kayıt hatasında aynı ekranda girilenler korunur ve “Try again” bulunur; yanlış başarı geri bildirimi verilmez.

### 6. Notes listesi ve ayrıntısı

Başlık “Notes”, etiketli “New note”. Listenin ilk görünümünde başlık, gövdeden iki satır, kategori/tarih; etkin ipucu küçük bir işaretle gösterilir. Paylaş/düzenle/sil her satırda görünmez. Kategori filtresi tek kontrol; not sayısı çok azsa arama alanı zorunlu görsel yük oluşturmaz.

Ayrıntıda tam metin, düzenle ve daha fazla menüsü. Tek bağlama taşıma eylemi **Use for next session / Sonraki seans için kullan**. Ardından uygun çalışmayı gösteren durum; kendiliğinden seans başlatılmaz. Başarı için OK isteyen alert yerine görünür durum güncellenir. Odağı kaldırmak için “Remove as session cue” bulunur. Paylaş ve sil menüde; silme onayı korunur.

### 7. Not yazma

Gövde ve yazma odak noktası ilk sırada. Başlık isteğe bağlı; kaydederken ilk cümleden türetilir. Kategori ikinci planda. “Dictate / Konuşarak ekle” gövdenin yanında; veri/izin açıklaması ilk kullanım bağlamında ve tekrar açılabilir. Dinleme durumu ile durdur düğmesi açık kalır.

Kaydet düğmesinin pasifliği anlaşılır: boş gövde, sürmekte olan kayıt veya izin isteği. Kaydetmeden çıkınca taslağı koruma ve silme ayrımı açık. İzin reddinde yazı alanı kullanılabilir kalır. EN/TR kişisel metin çevrilmez.

### 8. Progress ve kayıt ayrıntısı

Başlık “Progress”. Kısa özet: seans sayısı ve toplam süre; teknik gelişim yüzdesi uydurulmaz. Ardından doğrudan geçmiş. İki uygun ölçüm oluşunca **Compare results / Sonuçları karşılaştır** girişi gösterilir; grafik ayrı ekranda. Henüz karşılaştırma yoksa büyük “veri yetersiz” kartı bulunmaz.

Kayıt ayrıntısında çalışma, tarih, gerçek süre, varsa sonuç ve kişisel not. Ölçüm yoksa değerli bir eksiklik gibi işaretlenmez. Karşılaştırma ekranında aynı plan/sürüm koşulu korunur; tarihler ve ölçüm tanımı açık olur. Erişilebilirlikte grafik yerine aynı bilgiyi taşıyan metin/tablo bulunur.

### 9. Çalışma seçenekleri ve oyuncu tercihleri

“Session options”: süre, solo/partner, odak; solo seçilince duvar. Günlük koşulun uygulama tercihi olarak saklandığı açıklanır. “Player preferences”: seviye; düz, anlaşılır ad ve kısa açıklama. İçerik uygunluğu değişince aktif kişisel ipucunun kaldırılması sessiz yapılmaz; kaydetmeden önce etkisi belirtilir. Öneri sonucu seçeneklerle aynı sayfada ikinci bir büyük kart olmaz; Today’de güncellenir.

### 10. Rehber ve sistem durumları

Rehberde önce kort kurulumu, sonra istenirse animasyon, sonra kaynak bağlantısı. Teknik video olmadığı tek açık cümleyle belirtilir. İnternet gerektiren kaynak dış eylem olarak etiketlenir. Çevrimdışı durumda yerel yönergeler kullanılabilir kalır. Azaltılmış harekette elle konum ilerletme korunur.

Tüm ekranlarda ilk kullanım, boş liste, filtre sonucu yok, kayıt hatası, taslak geri yükleme ve çok uzun kullanıcı metni ayrı durumlar olarak tasarlanır. Arka plandan dönüş süre davranışı mevcut checkpoint sözleşmesini korur; görünüm sadeleştirmesi veri modelini sessizce değiştirmez.

## Görsel sistem

- Zemin #F5F1E8, metin #24382D, ikincil #5D675C. Kil #9C432F yalnızca küçük vurgu/kurulum çizgisi; başarı ile yıkıcı eylem aynı renkle anlatılmaz.
- Tek baskın dolgu düğme; diğer eylemler anlamına göre metin veya ikincil çerçeve. Seansın durumuna göre baskın eylem değişebilir.
- Ekran başlığı serif 30–32 pt; çalışma başlığı 26–28; gövde sistem 17; açıklama 15; yardımcı metin 13. 10 pt mono üst etiketler temel bilgi taşımaz. Süre monospaced digit.
- 8 pt aralık sistemi; standart yatay boşluk 20; bölüm arası 24–32; ilgili metinler 6–8. Normal akışta gereksiz büyük boşluk yok.
- Liste satırlarını ayırıcıyla grupla; yalnızca öneri gibi seçkin alanda kart. Her bilgi için ayrı kutu yok.
- En az 44 pt dokunma alanı, görünür etiketler, renk dışı durum göstergeleri. Büyük yazıda yatay satırlar dikey olur; temel metin kırpılmaz. Sabit alt eylemler klavye ve güvenli alanı dikkate alır.
- EN/TR metinleri doğal uzunlukta; görsel şiir için elle satır kırma kaldırılır. “Başla” eylemi gerçekten başlatır, “Gör” ayrıntı açar.

## Uygulama sırası — takvim değil bağımlılık planı

1. Ortak satır, başlık, ana/ikincil düğme, boş/hata durumu bileşenleri; yeni metin anahtarları. Saklanan kategori/plan kimlikleri değiştirilmez.
2. Today ve Practice rollerini ayır; filtre taslağı/uygula modeli; ayrıntıyı navigation push yap. Kaydırma ve arama korunmalı.
3. PracticeSessionView’i Details / ActiveSession / Completion / Guide bileşenlerine ayır. Mevcut checkpoint, idempotent kayıt ve ölçüm sürümü modeli korunur.
4. Notes liste/ayrıntı ayrımı; birleştirilmiş ipucu eylemi; isteğe bağlı başlık. Eski notlar değişmeden yüklenir.
5. Progress geçmiş önceliği ve ayrı karşılaştırma; günlük koşullar/oyuncu tercihleri ayrımı.
6. Uçtan uca doğrulama: mevcut dokuz testin korunması; sadece değişen davranış için anlamlı ek testler. En küçük desteklenen iPhone, normal/en büyük yazı, EN/TR, VoiceOver ve azaltılmış hareket kontrolü.

## Kabul ölçütleri

Bunlar hedeflerdir; mevcut kullanıcı ölçümü değildir.

- Today’de aynı anda öneri ve yarım seans için iki ayrı ana düğme bulunmaz.
- Practice açıldığında arama/filtre ve ilk çalışma, öneri/kurulum bölümü arkasında kalmaz.
- Çalışma ayrıntısında zorunlu ön koşullar ve Başla kolayca bulunur; kaynak okuma zorunlu değildir.
- Aktif seansın adımı, durumu ve ana kontrolü normal yazıda temel görünümde; en büyük yazıda tamamı kaydırmayla erişilebilir.
- Ölçüm/not girmeden seans kaydedilebilir. Aynı seans iki kez kaydedilmez.
- Not listesindeki her öğe beş ayrı eylem taşımaz; düzenle/paylaş/sil ayrıntıdan bulunur.
- Arama, filtre, favori, not, aktif taslak ve geçmiş sadeleştirmede kaybolmaz.
- Pilot için 5–8 tenis oyuncusu: çalışma bulma/başlatma, duraklatıp çıkma/geri dönme, tek cümle not, ipucunu seansa taşıma, geçmişten sonuç bulma. Yardımsız tamamlama, yanlış dokunma, geri dönüş ve görev sonrası kolaylık puanı gözlenir. “İçeride geçirilen süre” başarı ölçütü yapılmaz; kort görevini az çabayla tamamlama esas alınır.

## Kaynaklar ve kullanım sınırı

[Apple — Navigation design](https://developer.apple.com/videos/play/wwdc2022/10001/): gezinme ve görev odaklı modal ayrımını değerlendirmek için.

[Apple — Modality](https://developer.apple.com/design/human-interface-guidelines/modality): ayrı moda geçişlerin bağlam maliyeti ve açık kapanış davranışı için.

[NN/g — Progressive disclosure](https://www.nngroup.com/articles/progressive-disclosure/): ikincil işlevleri gerektiğinde açma, ancak onları tek ve bulunabilir bir girişle sunma ilkesi için.

[NN/g — Usability heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/): sistem durumu, kontrol, tanıma ve sade bilgi sunumu üzerinden inceleme çerçevesi için.

Ralli’ye özgü ekran kararları bu kaynaklardan çıkarılan tasarım önerileridir; dönüşüm, ödeme isteği veya bağımlılık etkisinin kanıtı değildir. Eşlik eden HTML dosyası görsel ve etkileşimli tasarım prototipidir; SwiftUI uygulamasına henüz uygulanmamıştır.

## Prototip teslimi ve doğrulama

`Ralli-Yeni-UX-Prototip.html`: 12 ekran görünümü, Türkçe/İngilizce örnek metinler, sekme/ekran geçişleri, arama ve solo/partner filtreleme, geçici not ekleme ve örnek seans kaydı onayı. Kütüphanedeki kartlar temsilî servis ayrıntısını açar; seçenekler öneri motoruna bağlı değildir. Bunlar ürün davranışının tamamının kodlandığı anlamına gelmez.

JavaScript sözdizimi kontrol edildi. Basit DOM taklidiyle 24 ekran/dil üretimi, filtre, boş arama ve geçici not akışı geçti; gerçek tarayıcı testi değildir. Yerel sunucu sandbox tarafından engellendi, dosyanın tarayıcıda açılması da URL güvenlik politikası tarafından reddedildi. Bu nedenle görsel tarayıcı doğrulaması tamamlanamadı; dosya kullanıcı tarafından normal tarayıcıda açılıp incelenebilir. Bu tur SwiftUI üretim kodunu değiştirmedi; tasarım ve uygulama planını somutlaştırdı.
