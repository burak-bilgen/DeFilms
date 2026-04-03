# DeFilms

DeFilms, TMDB API uzerinden film arama, favori liste yonetimi ve temel hesap/oturum akislari sunan SwiftUI tabanli bir iOS uygulamasidir. Proje iOS 16+ hedefler ve Swift Concurrency, MVVM, Core Data tabanli persistence ve route-coordinator yaklasimi kullanir.

## Kurulum

1. Xcode 16+ ile projeyi acin.
2. TMDB API anahtarini `DeFilms/Core/Network/APIConfig.swift` icin beklenen kaynakta tanimlayin.
3. `DeFilms` scheme'ini secip uygulamayi simulator veya cihazda calistirin.
4. Testler icin `DeFilmsTests` target'indaki testleri veya scheme uzerinden tum testleri kosun.

## Mimari

- UI katmani SwiftUI view'lar ile kuruldu.
- Is kurallari ve ekran durumlari ViewModel katmaninda tutulur.
- Navigation, tab bazli route coordinator yapisina tasindi:
  - `MovieRoute`
  - `FavoritesRoute`
  - `NavigationCoordinator<Route>`
- Ag katmani `NetworkServiceProtocol` ile soyutlandi.
- Veri saklama Core Data repository katmanlari ile yapiliyor:
  - `FavoritesRepository`
  - `RecentSearchRepository`
- Session ve yerel hesap yonetimi `AuthSessionManager` uzerinden ilerliyor.

## Uygulama Kapsami

- Filmler sekmesinde arama, validasyon, son 10 arama gecmisi, filtreleme, siralama ve detay gecisi bulunur.
- Favoriler sekmesinde liste olusturma, yeniden adlandirma, silme, film cikarimi ve listeler arasi tasima desteklenir.
- Ayarlar sekmesinde tema, dil, uygulama versiyonu ve yerel auth akislari bulunur.
- Hata durumlari toast/snackbar benzeri bildirimler ile kullaniciya gosterilir.

## Testler

Eklenen hedef testler:

- `MovieSearchViewModelTests.emptyQueryShowsValidationError()`
- `MovieSearchViewModelTests.successfulSearchStoresHistoryAndResults()`
- `FavoritesViewModelTests.createRenameAndDeleteListUpdatesPublishedLists()`

Ornek sonuc:

```text
3 tests: 3 passed, 0 failed
```

## Bilinen Noktalar

- Auth akisleri yerel keychain tabanli demo mantigi ile calisir; gercek backend entegrasyonu yoktur.
- UI testleri su an temel iskelet seviyesindedir, kritik kullanici akislari icin genisletilebilir.
- Asset catalog icinde eski iOS icon boyutlarina dair Xcode remark'lari vardir; davranissal hata olusturmaz ama temizlenebilir.

## Gelistirme Onerileri

- Settings/account formlarini da ayri ViewModel katmanlarina tasiyarak MVVM ayrimini daha da sertlestirin.
- Favori ve arama senaryolari icin repository seviyesinde daha fazla test ekleyin.
- Kritik akislara XCUI testleri ekleyin: arama, liste olusturma, film tasima, auth.
