# Ralli — 3B vuruş animasyonları denetimi

4 Kasım 2026. Altı hareket (forehand, çift el backhand, servis, vole, smaç, split step) iki yoldan incelendi:

- **Sayısal denetim** (`ralli/Tests/MotionAuditTests.swift`): her hareket 600 karede ölçüldü. Ölçülenler: raket/el/top ile kafa ve gövde çakışması, ayak kayması, eklem ve top sıçramaları, diz yönü, çift el tutuş, temas anında topun tellerde ve raket yüzünün fileye dönük olması, gövde eğimi, omuz-kalça dönüş farkı.
- **Görsel denetim**: her hareket 12 kareye bölünüp üç kamera açısından incelendi (Debug kısayolu: `-ralli-contact-sheet <hareket> <side|behind|front>`).

## Tespit edilen sorunlar

| # | Sorun | Nerede | Ölçüm (ilk durum) |
|---|---|---|---|
| 1 | Yerdeki ayak kayıyor ("buz pateni") | Hepsi | 3,5 m/s'ye kadar |
| 2 | Raket kafanın / gövdenin içinden geçiyor | Forehand, backhand, servis | Gövdeye %92'ye kadar giriyor |
| 3 | Boştaki kol gövdenin içinden geçiyor | Forehand, backhand, servis, smaç | %99'a kadar |
| 4 | Diz geriye kırılıyor | Servis, smaç | 117–127 kare |
| 5 | Çift el backhand'de sol el raketten ayrık | Backhand | Karelerin %90'ı |
| 6 | Servis: raket düşüşü sırtın arkası yerine vücudun önünde | Servis | Koordinat yönü ters yazılmış |
| 7 | Kupa pozisyonunda kol ve raket "meşale gibi" dimdik | Servis, smaç | Teknik hata |
| 8 | Duruştan kupaya raket yüzün önünden kalkıyor; sarkaç evresi eksik | Servis | — |
| 9 | Geri çekişte kol dümdüz, raket kadraj dışında | Forehand | — |
| 10 | Bitişte raket kafanın yanından omuza "kısa yol" alıyor, takip evresi yok | Forehand, backhand | Raket ucu 170–260 m/s sıçrıyor |
| 11 | Serviste raket tek karede ters dönüyor ("kırbaç") | Servis | 73 m/s |
| 12 | Vole: raket dik, yüz kenardan görünüyor, vuruş okunmuyor | Vole | — |
| 13 | Yüzsüz kafa: oyuncunun nereye baktığı anlaşılmıyor | Hepsi | — |
| 14 | Backhand geri çekişi yandan kamerada gövdenin arkasında kalıyor | Backhand | — |

## Kök nedenler ve düzeltmeler

- **Ara kareler kortun sabit eksenlerinde hesaplanıyordu.** Oyuncu dönerken eller düz çizgide gidip gövdeyi kesiyordu. Kollar ve raket artık göğsün kendi eksenlerinde hesaplanıyor; gövde dönünce eller de onunla dönüyor (gerçek animasyon iskeletleri gibi).
- **Raket yönü düz ara değerlemeyle hesaplanıyordu.** Zıt yönler arasında sıfıra yakın bir değerden geçtiği için raket tek karede dönüyordu. Artık küresel ara değerleme (slerp) kullanılıyor; raket sabit açısal hızla dönüyor.
- **Fiziksel kurallar her karede uygulanıyor:**
  - Kollar ve bacaklar ters kinematikle gerçek kemik boyunda tutuluyor.
  - Dizler her zaman öne bükülüyor.
  - Eller, dirsekler ve raket kafa ile gövdenin dışında tutuluyor.
  - Backhand'de sol el raket sapında, hazır duruşta raket boğazında kilitli.
  - Top temas anında tellerin üstünde, atıştan önce sol elde.
- **Adım kuralı:** yerdeki ayak ya sabit kalıyor ya da önce kalkıp sonra yer değiştiriyor. Havadan inen ayak önce yerini bulup sonra yere basıyor.
- **Pozlar:**
  - Servis ve smaç doğru teknikle yeniden yazıldı. Servise "Top atışı" evresi eklendi; kupa pozisyonunda dirsek omuz hizasında ve raket başın arkasında.
  - Forehand ve backhand'e "Takip" evresi eklendi.
  - Forehand geri çekişi ve vole hazır duruşu düzeltildi.
- **Görünüm:**
  - Siperlikli beyaz şapka eklendi.
  - Backhand yandan kamerası oyuncunun sol tarafına alındı; vole varsayılan olarak önden gösteriliyor.
  - Yandan kadraj genişletildi, temas halkası küçültüldü, top uçuş mesafesi göz takibine uygun hâle getirildi.

## Sonuç

| Ölçüt | Önce | Sonra |
|---|---|---|
| Sayısal denetim bulgusu | 37 | 1 (izin verilen) |
| Ayak kayması (en kötü) | 3,5 m/s | 0 |
| Raket / kol gövde içinde | %99'a kadar | Yalnızca forehand takibinde önkol gömleğe %15 sürtünüyor |
| Raket ucu sıçraması | 264 m/s | Yok |

Denetim artık bir test: `testEveryMotionPassesThePhysicalAudit` bu sorunlardan biri geri gelirse başarısız olur. Toplam 15 test geçiyor, derleme uyarısız.

## Bilinen sınırlar

- Önden kamerada vole hazırlığına geçerken raket bir an yüzün önünden geçiyor. Bu çakışma değil, perspektiften kaynaklanan bir örtüşme.
- Model sade bir figür; parmak, bilek ve yüz ifadesi yok.
- Pozlar bir tenis antrenörü tarafından henüz onaylanmadı. Gerçek iPhone'da akıcılık ve pil etkisi ölçülmedi.
