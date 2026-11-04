# Ralli — Kullanım memnuniyeti, devamlılık ve ürün değeri araştırması

**Tarih:** 1 Kasım 2026  
**Kapsam:** Global pazara yönelik iOS tenis uygulaması; İngilizce ve Türkçe.  
**Çıktı:** Araştırma bulguları, mevcut ürün denetimi, yeniden tasarım kararı ve uygulanabilir deneyim şartnamesi.

## 1. Yönetici kararı

**Ralli’nin görsel kimliği korunmalı; bilgi mimarisi ve tekrar kullanım döngüsü yeniden tasarlanmalı.** Kort yeşili, sıcak kâğıt, terracotta ve editoryal tipografi ayırt edici bir başlangıç. Ancak mevcut sürüm oyuncunun hedefine göre davranmıyor, ders notunu bir sonraki çalışmaya bağlamıyor ve gerçek ilerlemeyi anlaşılır biçimde karşılaştırmıyor. Estetik ile ücret ödemeye değer fayda arasındaki bağ henüz kurulmuş değil.

Önerilen ürün vaadi:

> **Know what to work on. See what changes.**  
> Ne çalışacağını bil. Nelerin değiştiğini gör.

Kullanıcının geri dönme gerekçesi, her açılışta yeni bir kart görmekten daha güçlü olmalı: “Bu uygulama benim oyunumda neye çalıştığımı hatırlıyor, uygun çalışmayı bulmamı kolaylaştırıyor ve tekrarlarımdan bir anlam çıkarıyor.”

Ana başarı ölçütü, uygulamada geçirilen toplam süre yerine **oyuncunun sonraki tenis seansında Ralli’den tekrar yararlanması** olmalı. Bu, ticari hedefi daraltmaz: Kalıcı ödeme gerekçesini, tekrarlanan gerçek kullanım üzerine kurar.

## 2. Yöntem ve kanıt sınırları

Bu çalışma; motivasyon ve dijital davranış değişikliği literatürü, UX araştırmaları, spor ürünlerinin resmî açıklamaları, abonelik sektör verileri ve mevcut SwiftUI kaynaklarının incelenmesine dayanır. Önceki simülatör görüntüleri ve akış doğrulamaları da değerlendirmeye alınmıştır.

Bu turda gerçek oyuncu görüşmesi, saha gözlemi, ödeme deneyi veya yeni kullanılabilirlik oturumu yapılmadı. Rakipler için ücretli hesap satın alınmadı; özellik karşılaştırması kamuya açık ürün ve yardım sayfalarına dayanıyor. Rakiplerin devamlılık oranlarını veya ürün özelliklerinin bunlara nedensel katkısını bilmiyoruz.

Raporda üç tür ifade ayrılır:

- **Araştırma bulgusu:** Kaynakta raporlanan bilgi.
- **Ürün gözlemi:** Mevcut Ralli kodunda veya önceki ekranlarda görülen durum.
- **Tasarım hipotezi:** Ralli’de sınanması gereken öneri.

Sağlık, fitness ve öğrenme araştırmaları tenis uygulamasına doğrudan başarı garantisi vermez. Bir özelliğin çok kullanılması, etkili olduğunun kanıtı değildir; kullanım ilişkisi, nedensellik anlamına gelmez.

## 3. İnsanların memnuniyetle geri dönmesini açıklayan bulgular

### 3.1. Kontrol ve yeterlilik hissi

Öz belirleme kuramı; özerklik, yeterlilik ve ilişki kurma ihtiyaçlarını motivasyon için temel kabul eder. Ralli’ye aktarımı bir tasarım hipotezidir: Oyuncunun kendi odağını seçebilmesi, yapabileceği zorlukta bir görev alması ve sonucunu anlayabilmesi deneyimi güçlendirebilir. [Ryan & Deci, 2000](https://selfdeterminationtheory.org/SDT/documents/2000_RyanDeci_SDT.pdf)

**Karar:** Öneri sun, nedenini açıkla ve değiştirmeyi kolaylaştır. “Bugün bunu yapmalısın” yerine “Servis yerleşimine odaklandığın ve yalnız çalıştığın için bu seans uygun” kullan. Bu açıklama gerçek tercihlere dayanmalı; sistemin bilmediği bir kişiselleştirmeyi ima etmemeli.

### 3.2. Geri bildirim ve kişisel kayıt

2023 tarihli sistematik derleme; hedef belirleme, kendini izleme, davranış geri bildirimi, hatırlatıcılar, ödüller ve sosyal desteğin uygulama etkileşimiyle tekrar eden ilişkilerini bildiriyor. Bulgular, tek bir mekanizmanın her kullanıcıda işe yaradığını göstermiyor. [Frontiers in Psychology](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2023.1227443/full)

**Karar:** Sayacı artırmakla yetinme. Oyuncunun belirli bir çalışmadaki kendi sonuçlarına geri dönmesini sağla. Oturum sayısı, zaman ayırmayı gösterir; teknik gelişimi tek başına göstermez.

### 3.3. Alışkanlık, uygun bağlama bağlı tekrar ister

2024 tarihli alışkanlık derlemesinde oluşum süreleri ve davranışlar arasında büyük farklılıklar bulunuyor. Bulgular sabit bir “21 günde alışkanlık” vaadini desteklemiyor; tenis uygulamasının ne kadar sürede alışkanlık oluşturacağını da belirlemiyor. [Healthcare sistematik derlemesi](https://www.mdpi.com/2227-9032/12/23/2488)

**Karar:** Günlük uygulama açılışını zorlamaktansa oyuncunun doğal anlarına yerleş: dersten sonra kısa not, kort öncesi seçim, kortta uygulama, seans sonrası tek kayıt. Günlük seri yerine geçmişe geri dönmenin kolaylığına yatırım yap.

### 3.4. Güzel görünmek önemlidir; işlevsel sorunları gizleyebilir

NN/g, çekici arayüzlerin daha kullanışlı algılanabildiğini; kullanıcıların görsel beğeni bildirirken görevlerde zorlanabildiğini anlatıyor. Bu yüzden “çok güzel olmuş” geri bildirimi tek başına yeterli değildir. [Aesthetic–Usability Effect](https://www.nngroup.com/articles/aesthetic-usability-effect/)

**Karar:** Tasarım değerlendirmesinde beğeni kadar görev başarısını izle. Örneğin kullanıcı 15 dakikalık, partnersiz uygulanabilir bir çalışmayı yardım almadan bulabiliyor mu? Başlık ve illüstrasyon ilk kullanımdan sonra tekrar eden bir engel oluyor mu?

### 3.5. İçerik zenginliği, ilk ekranda her şeyi göstermek değildir

Kademeli açıklama, temel seçenekleri görünür tutup daha seyrek kullanılan ayrıntıları ihtiyaç anında açmayı önerir. Hangi bilginin ilk seviyede gerektiği görev analiziyle belirlenmelidir. [NN/g — Progressive Disclosure](https://www.nngroup.com/articles/progressive-disclosure/)

**Karar:** Çalışma seçimi sırasında amaç, süre, seviye, ortam ve ekipman göster. Ayrıntılı teknik açıklama, varyasyon ve kaynak bilgisine çalışma içinde erişilsin. Zenginlik, kullanıcı aradığını kolayca bulduğunda değer kazanır.

### 3.6. İlk deneme ile devamlı kullanım aynı problem değildir

Fitness uygulamalarının devam eden kullanımını inceleyen 2025 derlemesi, ilk benimseme ile sürdürülen kullanımı ayrı değerlendiriyor. [Management Review Quarterly](https://link.springer.com/article/10.1007/s11301-025-00537-1)

**Karar:** İlk açılış için tasarlanan ilgi çekici ekranı, geri dönen kullanıcıya sürekli aynı biçimde gösterme. İlk gelişte ürünün faydasını tanıt; ikinci gelişte kaldığı yeri ve kişisel odağı öne çıkar.

## 4. Rakiplerden alınacak ürün dersleri

Bu tabloda resmî olarak açıklanan özellikler ile bizim çıkarımımız ayrıdır. Bunlar rakiplerin tasarımının başarılı olduğunu veya bizim kopyalayınca aynı sonucu alacağımızı kanıtlamaz.

| Ürün | Kaynaktan görülen yaklaşım | Ralli için çıkarım |
|---|---|---|
| Freeletics | Antrenman, performans ve seans sonrası geri bildirimle uyarlanıyor. | Kayıt, bir sonraki öneriyi gerçekten etkilemeli. [Resmî yardım](https://help.freeletics.com/hc/en-us/articles/115004675229-Get-started-with-Freeletics-Training) |
| Fitbod | Hedef, ekipman, deneyim ve geçmiş gibi girdiler öneriyi şekillendiriyor. | Mevcut ortamı bilmeden “sana uygun” seans önerme. [Resmî açıklama](https://help.fitbod.me/hc/en-us/articles/360004429814-How-Fitbod-Creates-Your-Workout) |
| Strava | Kişisel antrenman geçmişi ve ilerleme görünümü var. | Tekil oturumları oyuncunun kendi hikâyesine bağla. [Training Log](https://support.strava.com/en-us/articles/15402077-training-log) |
| Nike Training Club | Nike üyelerine ücretsiz uzman içerikleri sunuluyor. | Salt içerik kütüphanesi güçlü ücretsiz alternatiflerle yarışıyor. [Nike](https://www.nike.com/gb/ntc-app) |
| NextSet | Oyuncuya ücretsiz notlar, görevler ve antrenman araçları sunuyor. | “Not + zamanlayıcı” ücretli farklılaşma için yeterli olmayabilir. [Oyuncu sayfası](https://nextset.us/for-players) |
| SwingVision | Video analizi ve asenkron koçluk gibi somut çıktılar sunuyor. | Değerin görünür bir ürünü olmalı; uzun video kurulumu gerektirmeyen kullanım bizim hipotezimiz. [Resmî ürün](https://swing.vision/subscribe) |

**Ticari sonuç:** Kullanıcının ödemekten memnun olacağı şey, aynı videoların ücretli sürümü olmamalı. Daha güçlü değer paketi; kendi odağına uygun seçimi hızlandırma, güvenilir uygulama rehberliği ve zaman içinde anlamlı karşılaştırmadır. Bu paket için ödeme isteği henüz ölçülmedi. Abonelik ekranı ve fiyatlandırma bu araştırmanın uygulama kapsamı dışında bırakılmıştır.

RevenueCat’in 2026 raporu, kendi platformunu kullanan uygulamalardan topladığı verilerde AI ve AI olmayan ürünler arasında ilk gelir ve uzun vadeli abonelik tutma farkları bildiriyor. Bu gözlemsel kategori karşılaştırması, AI eklemenin başarı sağladığını veya başarısızlığa neden olduğunu göstermez. Ralli için çıkarım: “AI” etiketi yerine devam eden faydayı ispatlamalıyız. Raporun abonelik devamlılığı ölçüsü, uygulamayı açan kullanıcı oranıyla aynı değildir. [RevenueCat metodolojisi ve bulguları](https://www.revenuecat.com/state-of-subscription-apps)

## 5. Mevcut Ralli denetimi

### Güçlü taraflar

- Tenisle ilişkili, tutarlı ve farklılaşmaya elverişli bir görsel başlangıç var.
- Solo/partner ayrımı, kaynak bağlantıları ve isteğe bağlı sonuç kaydı doğru temeller.
- Kullanıcı girmediğinde başarı puanı üretilmiyor.
- Türkçe/İngilizce kaynaklar ve yerel kayıt sistemi mevcut.
- Çalışma seçimi, seans ve kayıt akışı çalışan bir prototip oluşturuyor.

### Değişmesi gerekenler

| Gözlem | Kullanıcıya etkisi | Tasarım kararı |
|---|---|---|
| Home herkese aynı slogan ve kütüphane çağrısını gösteriyor. | Kişisel fayda ilk bakışta görünmüyor. | Odağı ve uygun bir sonraki eylemi öne çıkar. |
| Featured çalışma sabit bir dizi elemanından seçiliyor. | Önerinin gerekçesi yok; kişiye uygunluk bilinmiyor. | Ortam, süre ve oyuncu odağıyla açıklanabilir seçim yap. |
| Practice’te arama, kategori, ortam ve favori seçenekleri birlikte sunuluyor. | Yeni kullanıcı nereden başlayacağını kestiremeyebilir. | Hızlı yönlendirme ile tüm kütüphaneyi iki giriş olarak düzenle. |
| Ders notları çalışma seçimine bağlanmıyor. | “Defter” ve “Practice” ayrı araçlar gibi kalıyor. | Notu bir odakla ve uygun çalışmayla ilişkilendir. |
| Progress büyük sayaçlar ve son kayıt listesinden oluşuyor. | “Geliştim mi?” sorusu yanıtsız kalıyor. | Aynı testin tekrarlı sonuçlarını, koşullarıyla göster. |
| Vuruş seviyesi ve hazır oluş gereksinimi içerik modelinde yok. | Aynı öneri farklı oyuncular için uygun olmayabilir. | Ön koşul, kolaylaştırma ve ilerletme bilgisi ekle. |
| Sesli/animasyonlu saha rehberliği yok. | Oyuncu ekrana tekrar tekrar bakmak zorunda. | İsteğe bağlı kısa sesli ipuçları ve açık duraklatma davranışı tasarla. |
| Aktif seans uygulama kapanınca geri yüklenmiyor. | Tek kesinti, verilen emeği boşa çıkarmış hissettirebilir. | Seans taslağını sakla; yeniden açılışta sürdür veya bitir seçeneği ver. |
| Kaydedilmiş sonuç, geçmişten ayrıntılı olarak açılamıyor. | Kişisel öğrenme arşivi sınırlı kalıyor. | Tam geçmiş, seans ayrıntısı ve düzeltme akışı ekle. |
| Yazı boyutlarının çoğu sabit puntoyla tanımlı. | Büyük yazı tercihinde güvenilir ölçekleme sağlanmış değil. | Dynamic Type temelli metin stilleri ve erişilebilirlik yerleşimleri kullan. |

Bunlar kod ve önceki ekran incelemesine dayanan bulgulardır; kullanıcıların yaşadığı sorunun sıklığı henüz ölçülmedi.

### Kontrast incelemesi

Kaynak dosyadaki sRGB renklerinden hesaplanan düz renk eşleşmeleri:

| Metin / zemin | Oran | Karar |
|---|---:|---|
| Koyu yeşil `#24382D` / kâğıt `#F5F1E8` | 11,10:1 | Ana metin için güçlü başlangıç. |
| İkincil metin `#73796D` / kâğıt | 3,98:1 | Küçük gövde metni için koyulaştırılmalı. |
| Kâğıt / terracotta `#B9573D` | 4,15:1 | Küçük kart yazıları için iyileştirilmeli. |

WCAG’nin normal metin için 4,5:1 ölçütü burada tasarım kontrolü olarak kullanıldı; bu tablo uygulamanın tamamı için erişilebilirlik uygunluk belgesi değildir. Gerçek bileşimler, saydamlıklar, metin boyutları ve cihaz koşulları ayrıca incelenmelidir. [W3C kontrast ölçütü](https://www.w3.org/WAI/WCAG21/Understanding/contrast-minimum.html)

Önerilen deneme renkleri: ikincil metin `#5D675C` ile kâğıtta yaklaşık 5,23:1; koyu terracotta `#9C432F` üzerinde kâğıt yazıyla yaklaşık 5,72:1. Açık terracotta dekoratif yüzeylerde korunabilir. “Yeşil bilinçaltında güven yaratır” gibi evrensel psikolojik bir iddiaya dayanmıyoruz.

## 6. Önerilen deneyim mimarisi

Dört ana alanı korumayı öneriyorum: **Today / Practice / Journal / Progress**. Court adı ilk kez gelen oyuncuya daha belirsiz; Today adı kişisel başlangıç ekranının işlevini daha doğrudan anlatabilir. İsim tercihi de test edilmelidir.

### Today — Kişisel başlangıç

İlk görünen alanlar:

1. Oyuncunun seçtiği aktif odak: “A more reliable second serve”.
2. Ortamına uygun tek ana öneri ve kısa gerekçesi.
3. Büyük bir “Start practice” eylemi; yanında kolay “Change” seçeneği.
4. Son çalışmadan bir gerçek hatırlatma.
5. Ders notunu hızla ekleme girişi.

İlk kullanıcıda odak seçimi ve örnek çalışma; geri dönen kullanıcıda devam eden hedef; yarım kalmış seansta sürdürme; uzun aradan sonra daha kolay dönüş seçenekleri gösterilir. Bu durumlar birbirinden farklı tasarlanır.

### Practice — Uygun çalışma bulma

İki giriş:

- **Help me choose:** Bugünkü süre, solo/partner, kort/duvar/boş alan ve vuruş odağı.
- **Explore all:** Mevcut arama, kategoriler ve favoriler.

Kullanıcı bu bilgileri her seferinde yeniden doldurmaz. Son tercih görünürdür; tek dokunuşla değiştirilebilir. Uygun çalışma yoksa süreyi sessizce aşan veya partner gerektiren bir içerik gösterilmez; hangi tercihin değiştirilmesi gerektiği açıklanır.

İlk öneri motoru şeffaf kurallarla çalışabilir. Gerekçesi olmayan “AI-selected” rozeti eklemek gerekmez.

### Çalışma ayrıntısı — Beklentiyi doğru kurma

İlk bakışta: amaç, süre, ortam, seviye/ön koşul ve gerekenler. Ardından küçük bir hareket şeması, izlenebilir kısa gösterim, kritik ipucu ve başlayacak düğme.

Kurulum ve ilk deneme anlaşılmadan zamanlayıcı başlamaz. Ayrıntılı kaynak ve alternatifler erişilebilir olur; başlatma eylemini sayfanın en altına gömmez.

### Court mode — Düşük dikkat yükü

Ekranın işi oyuncuyu uzun süre ekrana baktırmak değil, uygulamayı takip etmeyi kolaylaştırmaktır. Büyük süre/tekrar göstergesi, tek kısa ipucu, adım ilerlemesi ve erişilebilir duraklatma eylemi yeterlidir.

Sesli uyarı tercih edilebilir; ses kapalıyken görsel/haptik eşdeğeri bulunur. Uygulama kapanması, telefon kilidi ve arka plana geçiş açıkça ele alınır. Seansın geçen süresi ile gerçekten tamamlandığı beyan edilen çalışma ayrı kavramlar olarak saklanır.

### Seans sonu — Kısa ama anlamlı kapanış

Önce kaydedilen iş ve süre açıklanır. Sonuç girişi atlanabilir. Oyuncu isterse tek bir his veya kısa not ekler. Başarısız bir testte bile gösterilecek fayda vardır: neyin zor olduğu, sonraki denemede neyin aynı tutulacağı.

“Great job!” her zaman aynı şekilde görünmek yerine yapılan işi tarif eden geri bildirim kullanılır: “You recorded your first serve-placement check.” Ölçüm olmadan “Your serve improved” denmez.

### Journal — Tenis hafızası

Serbest notların yanında kısa bir yapı: “What my coach said”, “My cue”, “What I’ll try”. Kullanıcı bunları doldurmak zorunda değildir. Bir notu aktif odak yapma ve çalışmayla ilişkilendirme mümkün olur. Sesli giriş, düzenleme ve yanlışlıkla çıkıştan taslak kurtarma birlikte düşünülür.

### Progress — Anlaşılır kişisel kanıt

Üç ayrı katman:

- **Participation:** Oyuncunun kaydettiği çalışmalar ve ayırdığı süre.
- **Practice results:** Aynı çalışmanın aynı ölçüm sürümündeki sonuçları.
- **Reflections:** Kişisel ipuçları ve hisler.

İsabet testi, ralli uzunluğu ve denge sayısı tek bir “tenis puanına” çevrilmez. Örnek metin: “Your last two checks: 4/10 and 6/10.” Bu yalnızca iki kaydı betimler; koşullar değişmişse gelişim kanıtı sayılmaz. Kaynak sayısı, tarih, solo/partner ve test tanımı görünür olmalıdır.

## 7. Kullanıcıyı geri getiren ürün döngüsü

**Kişisel odak → uygun seçim → anlaşılır uygulama → gerçek kayıt → sonraki kullanımda hatırlama.**

| Aşama | Oyuncunun sorusu | Ürünün karşılığı | Geri dönüş gerekçesi |
|---|---|---|---|
| Kort öncesi | Bugün neye çalışayım? | Süreme ve ortamıma uygun öneri. | Karar yükünün azalması. |
| Kortta | Bunu nasıl yapacağım? | Kısa gösterim ve tek ipucu. | Daha akıcı uygulama. |
| Kort sonrası | Ne kaydetmeye değer? | İsteğe bağlı tek ölçüm veya not. | Kişisel hafıza. |
| Sonraki geliş | Nerede kalmıştım? | Geçmiş ipucu ve uygun tekrar. | Önceki emeğin işe yaraması. |

Kullanıcıyı geri çağıran mesajlar kendi tercih ettiği tenis bağlamına dayanmalı; otomatik günlük bildirim temel mekanizma olmamalı. Aradan sonra karşılayan ekran, suçluluk yerine kolay bir başlangıç sunmalı. Ödüller yapılan gerçek işi işaret etmeli; değişken ödül, sahte aciliyet ve kayıp korkusu temel ürün stratejisi yapılmamalı.

## 8. Görsel ve duygusal tasarım şartnamesi

**Yön:** Tenis kültürünü taşıyan, sıcak ve hassas işlenmiş bir araç. Dergi estetiğinin karakteri ile saha aracının netliği birleşmeli.

- Serif başlıklar tanıtıcı alanlarda korunur; aktif seans yönergelerinde okunaklı sistem yazısı öne çıkar.
- Sloganlar küçülür; kişisel odak ve eylem daha görünür olur.
- Tipografi, sabit punto yerine ölçeklenebilir stillerle tanımlanır.
- Yeşil ana eylem, koyu terracotta vurgu; lime dekoratif ve destekleyici işaret için kullanılır. Renk tek başına anlam taşımaz.
- Önemli dokunma hedefleri için 44 × 44 pt başlangıç alt sınırı benimsenir; tek elle ve hareket hâlinde ayrıca test edilir.
- Kısa, amaca bağlı geçişler kullanılır. Kaydetme ve adım değişimi hissedilir; sürekli hareket eden dekorasyon eklenmez.
- Reduce Motion, VoiceOver ve büyük yazı tercihleri tasarımın başından ele alınır. Bunlar Apple’ın erişilebilirlik yönlendirmeleriyle kontrol edilir. [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/)
- Fotoğraf veya video, yalnızca hareketi öğretmek veya bağlamı açıklamak için kullanılır. Rastgele stok tenis görseli içerik kalitesinin yerine geçmez.
- İngilizce başlıklara göre değil, iki dilde de doğal metin uzunluklarına göre yerleşim kurulur.

**Memnuniyet anları:** İlk doğru çalışma seçimi; uzun metin okumadan hareketin anlaşılması; ders ipucunun sonraki kortta karşıya çıkması; kaydın güvenle saklanması; gerçek bir önceki sonuçla kıyas yapabilme. Her birinin görsel karşılığı olmalı.

## 9. İçerik kalitesi ve teknik gereksinimler

Çalışma sayısını rastgele artırmak yerine temel bir içerik matrisi oluşturulmalı: vuruş × amaç × ortam × seviye. Yalnızca gerçekten farklı bir amaç veya koşulu karşılayan içerik eklenmeli.

Her çalışmanın standardı:

1. Uygun oyuncu ve ön koşul.
2. Amaç ve beklenen öğrenme odağı.
3. Kort/alan/partner/ekipman gereksinimi.
4. Açık kurulum ve kısa gösterim.
5. Tekrar, süre, dinlenme ve rol değişimi.
6. Bir ana ipucu ve yaygın hata.
7. Kolaylaştırma ve ilerletme seçeneği.
8. Değişmeyen tanıma sahip isteğe bağlı test.
9. Kaynak, editör/antrenör incelemesi ve içerik sürümü.

Kaynak bağlantısı, uygulamadaki tüm uyarlamanın uzman onayı aldığı anlamına gelmez. Mevcut sekiz içerik için antrenörün gerçek kortta kurulum ve uygulanabilirlik incelemesi hâlâ eksiktir.

Veri tarafında gerekenler: oyuncu odağı ve ortam tercihleri, ders notu–çalışma ilişkisi, sürümlü test tanımı, seans taslağı, seansın durumu, gerçek kullanıcı beyanı ve test/demo kayıtlarının ayrımı. AI zorunlu değildir; önce açıklanabilir kurallar ve güvenilir veri temeli gerekir.

## 10. Doğrulama ve ölçüm

Aşağıdakiler önerilen araştırma tasarımı ve ürün hedefleridir; sektör standardı veya mevcut başarı oranımız değildir.

### A. Kullanıcı ve saha araştırması

Düzenli ders alan, bağımsız çalışan ve partnerli oynayan yetişkinlerden 12–15 görüşme; farklı seviyelerden 3–5 antrenör içerik görüşmesi önerilir. Sayılar pazar genellemesi yapmak için yeterli kabul edilmez; ilk örüntüleri bulmaya yöneliktir.

Sorular geçmiş davranışa dayanmalı: Son kort seansında ne çalıştın? Nasıl seçtin? Telefonu ne zaman kullandın? Hangi uygulamayı neden bıraktın? Son ders ipucunu sonra nasıl hatırladın?

En az birkaç gerçek kort kullanımında tek elle erişim, güneş ışığı, ses, ekran kilidi ve partnerin beklemesi gözlemlenmeli. Bunları masa başında varsayamayız.

### B. Prototip kullanılabilirlik deneyi

İlk turda 5–8 uygun katılımcı, ardından bulunan sorunlara göre ikinci tur. Bu örneklem bir dönüşüm yüzdesini güvenilir biçimde tahmin etmek için kullanılmaz.

Görevler: 15 dakika ve partnersiz ortamda uygun içerik bulmak; duvarı olmayan kullanıcıya duvar çalışmasını önermemek; adımı açıklamasız uygulamak; seansı kesip sürdürmek; eski notu yeni çalışmaya taşımak; gerçek sonuç ile çalışma sayısını ayırt etmek.

Başlangıç kabul hedefleri: yardımsız uygun seçimde 30 saniye medyan, sonucu kaydetmede 15 saniye medyan ve veri kaybına yol açan kritik sorun bulunmaması. Bunlar önceki sürümle karşılaştırılacak ürün hedefleridir; henüz ölçülmüş sonuçlar değildir.

### C. Saha pilotu

20–30 oyuncunun birden fazla gerçek kort fırsatını kapsayan pilotu: ilk heyecan, gerçek kullanım ve tekrar geliş ayrı incelenir. Başlangıç hedefi olarak aktif oyuncu tanımı açıkça yazılır; yalnızca ekran açanlar “fayda aldı” sayılmaz.

Ana ölçümler:

| Ölçüm | Tanım |
|---|---|
| İlk değer anına ulaşma | Uygun çalışma seçip anlaşılır biçimde başlatabilenler. |
| Anlamlı seans kaydı | Gerçek kullanıcı seansı olduğunu beyan ederek tamamlanmış kayıt; test/demo hariç. |
| Tekrar fayda | Sonraki tenis fırsatında yeniden çalışma veya önceki ipucunu kullanma. |
| Kişisel bağ | Ders notundan çalışma seçimine geçenler. |
| Sonuç devamlılığı | Aynı test tanımıyla ikinci kayıt oluşturanlar. |
| Memnuniyet | Görev sonrası açıklık/çaba değerlendirmesi ve açık uçlu neden. |
| Ürün güveni | Kayıt kaybı, yanlış öneri, beklenmeyen ses/izin ve yeniden başlatma sorunları. |

Toplam ekran süresi yardımcı bir ölçümdür. Uzun süre, ilgi kadar kafa karışıklığını da gösterebilir. Telefon ekranının açık kalması gerçek tenis çalışmasını kanıtlamaz.

Davranış olayları: `focus_selected`, `recommendation_shown`, `session_selected`, `session_started`, `session_paused`, `session_resumed`, `session_saved`, `benchmark_added`, `note_linked_to_session`. Parametrelerde not metni veya ses içeriği taşımak gerekmez.

### D. Ticari değer doğrulaması

“Öder miydin?” sorusu yalnız başına yeterli değildir. Oyuncu gerçek faydayı yaşadıktan sonra neden devam etmek istediği ve ileride gerçek ücretli teklife verdiği karşılık ölçülmeli. Fiyat/abonelik geliştirmesi ayrı ele alınır.

Erken küçük örneklemde eşzamanlı çok sayıda A/B testiyle kesin sonuç çıkarılmamalı. Önce belirgin kullanılabilirlik sorunları çözülür; yeterli hacim oluşunca tek hipotez, önceden belirlenen ana ölçüm ve uygun örneklem hesabıyla karşılaştırma yapılır.

## 11. Yeniden tasarım kapsamı ve uygulama sırası

Takvim yerine bağımlılık sırası:

**Önce:** Today’in kişisel odağa dönüşmesi; Practice’in uygun seçim akışı; not–çalışma bağlantısı; renk ve yazı sistemi; aktif seansı kurtarma.

**Ardından:** Gerçek gösterim içerikleri, saha modu, sonuç ayrıntısı ve aynı testin tekrarlı karşılaştırması. Onboarding yalnızca öneriyi değiştiren bilgiyi toplamalı; uzun hesap/profil formu ilk faydanın önüne geçmemeli.

**Saha doğrulamasından sonra:** Açıklanabilir önerilerin ilerletilmesi, tercihli hatırlatmalar, paylaşılabilir gelişim çıktıları ve ticari teklifin doğrulanması.

Sekiz kartın yerini seksen kartın alması, bu bağlar kurulmadan temel problemi çözmez. Önerilen yeniden tasarımın kabul koşulu, oyuncunun “Bu bana bugün ne yapacağımı ve önceki çalışmamın neden önemli olduğunu gösteriyor” diyebilmesidir; bunu gözlenen kullanım desteklemelidir.

## 12. Son karar ve açık sorular

**Kozmetik yenileme yeterli değil. Home/Today, Practice seçimi, seans sonu ve Progress birlikte yeniden ele alınmalı.** Mevcut renk karakteri, modüler yapı, yerel veri ve iki dil temeli korunabilir. Bu araştırma turunda uygulama kodu değiştirilmedi.

Henüz bilmediklerimiz: En güçlü ilk müşteri alt grubu; gerçek kortta ne kadar ekran etkileşiminin kabul edildiği; sesli yönlendirmeye talep; not–çalışma bağının tekrar kullanıma etkisi; içeriklerin antrenör saha onayı; gerçek ödeme isteği.

Bu soruların cevaplarını araştırma makaleleri veya rakip ekranları bizim yerimize vermez. Rapor, profesyonel bir yeniden tasarım için kanıta dayalı başlangıç ve test edilebilir karar setidir; talep ve devamlılık garantisi değildir.
