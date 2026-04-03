# DeFilms

DeFilms, TMDB API uzerinden film arama, detay goruntuleme ve coklu favori listesi yonetimi sunan SwiftUI tabanli bir iOS uygulamasidir. Proje iOS 16+ hedefler ve MVVM, Swift Concurrency, protokol tabanli servis/repository katmani ve tekrar kullanilabilir coordinator yapisi kullanir.

## Kurulum

1. Xcode 16 veya daha guncel bir surumle projeyi acin.
2. `DeFilms/Info.plist` icine `TMDBApiKey` anahtariyla gecerli bir TMDB API key ekleyin.
3. `DeFilms` scheme'ini secin ve uygulamayi simulator ya da cihazda calistirin.
4. Test dogrulamasi icin test navigator veya aktif scheme uzerinden testleri calistirin.

## Mimari

- UI katmani `SwiftUI` ile kuruludur.
- Durum yonetimi `ObservableObject`, `@StateObject` ve `@ObservedObject` ile MVVM uzerinden ilerler.
- Ag istekleri `URLSession`, `Codable` ve `async/await` ile yonetilir.
- Navigasyon `NavigationCoordinator<Route>` ile route bazli, tekrar kullanilabilir bir coordinator yapisi kullanir.
- Favoriler ve arama gecmisi repository/store katmanlari ile yerel olarak saklanir.
- Tema, dil ve oturum bilgisi environment object yapisi ile uygulama geneline yayilir.

## Ozellikler

- Film arama, bos sorgu validasyonu ve iki sutunlu sonuc listesi
- Trend, populer, vizyondaki, yakinda ve en cok oy alan browse bolumleri
- Yil, puan ve tur filtreleri ile siralama secenekleri
- Son 10 aramanin cihazda tutulmasi
- Film detay, oyuncu, yonetmen ve fragman akislari
- Coklu favori listesi olusturma, yeniden adlandirma, silme ve tasima
- Light/Dark mode ile Ingilizce, Turkce ve Arapca lokalizasyon
- Yerel hesap olusturma, giris, sifre degistirme ve oturum yonetimi

## Testler

Projede `Testing` tabanli ViewModel testleri bulunur:

- `MovieSearchViewModelTests.emptyQueryShowsValidationError`
- `MovieSearchViewModelTests.successfulSearchStoresHistoryAndResults`
- `FavoritesViewModelTests.createRenameAndDeleteListUpdatesPublishedLists`
- `FavoritesViewModelTests.storeAdoptsLegacyGuestListsIntoSignedInAccountScope`
- `AuthFormViewModelTests.signInViewModelPublishesLocalizedErrorOnFailure`
- `AuthFormViewModelTests.changePasswordViewModelClearsFieldsOnSuccess`

Ornek test ozeti:

```text
MovieSearchViewModelTests: validation, history persistence, loaded state
FavoritesViewModelTests: list CRUD, guest-to-account adoption
AuthFormViewModelTests: sign-in failure and password-change success
```

## Bilinen Noktalar ve Gelistirme Onerileri

- `TMDBApiKey` tanimli degilse uygulama bilincli olarak kullaniciya hata mesaji gosterir.
- Kimlik dogrulama su an cihaz ici keychain tabanlidir; gercek backend entegrasyonu sonraki mantikli adimdir.
- UI test kapsami temel launch smoke testlerinin otesine tasinabilir.
- Teslimata 2-3 ekran goruntusu veya kisa demo videosu eklenmesi faydali olur.
