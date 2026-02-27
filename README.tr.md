# Sayfa

[![Hex Surumu](https://img.shields.io/hexpm/v/sayfa.svg)](https://hex.pm/packages/sayfa)
[![Lisans: MIT](https://img.shields.io/badge/Lisans-MIT-blue.svg)](LICENSE)
[![Elixir](https://img.shields.io/badge/elixir-~%3E%201.18-purple.svg)](https://elixir-lang.org/)

Elixir ile yazilmis basit ve genisletilebilir bir statik site ureteci. **Sayfa** — adini Turkce'den aliyor.

[English README](README.md)

---

## Icindekiler

- [Sayfa Nedir?](#sayfa-nedir)
- [Ozellikler](#ozellikler)
- [Gereksinimler](#gereksinimler)
- [Hizli Baslangic](#hizli-baslangic)
- [Icerik Turleri](#icerik-turleri)
- [On Bilgi (Front Matter)](#on-bilgi-front-matter)
- [Sablonlar ve Duzenler](#sablonlar-ve-duzenler)
- [Bloklar](#bloklar)
- [Temalar](#temalar)
- [Cok Dilli Destek](#cok-dilli-destek)
- [Beslemeler ve SEO](#beslemeler-ve-seo)
- [Yapilandirma](#yapilandirma)
- [CLI Komutlari](#cli-komutlari)
- [Proje Yapisi](#proje-yapisi)
- [Genisletilebilirlik](#genisletilebilirlik)
- [Yol Haritasi](#yol-haritasi)
- [Katki Saglama](#katki-saglama)
- [Lisans](#lisans)

---

## Sayfa Nedir?

Sayfa **iki katmanli bir mimari** kullanir:

1. **Sayfa** (bu paket) — Temel statik site uretim motoru: Markdown ayristirma, sablon olusturma, besleme uretimi, blok sistemi ve dahasi.
2. **Siteniz** — `{:sayfa, "~> 0.1"}` ile Sayfa'ya bagli bir proje. Siz icerigi, temayi ve yapilandirmayi saglarsiniz; Sayfa derlemeyi halleder.

```
┌──────────────────────────────────────────────────────┐
│                    SITENIZ                            │
│   content/     themes/     lib/blocks/    config/    │
└──────────────────────────┬───────────────────────────┘
                           │ {:sayfa, "~> 0.1"}
                           ▼
┌──────────────────────────────────────────────────────┐
│                 SAYFA (Hex Paketi)                    │
│  Builder, Content, Markdown, Feed, Sitemap, Blocks   │
└──────────────────────────────────────────────────────┘
```

### Tasarim Felsefesi

- **Basit** — Yapilandirma yerine gelenekler. Mantikli varsayilanlar, minimum sablonlama.
- **Genisletilebilir** — Bloklar, hook'lar, icerik turleri ve temalar behaviour'lar ile takilan modeller.
- **Hizli** — MDEx (Rust NIF) ile Markdown ayristirma. Onbellekleme ile artirimli derlemeler.
- **Node.js Gerektirmez** — TailwindCSS `tailwind` hex paketi ile otomatik indirilir. Saf Elixir + Rust.

---

## Ozellikler

### Temel
- Sozdizimi vurgulama ile Markdown (MDEx, Rust NIF)
- Tipli alanlar + `meta` haritasi ile YAML on bilgi
- Maksimum esneklik icin iki yapilik icerik hatti (`Raw` -> `Content`)

### Icerik Organizasyonu
- 5 yerlesik icerik turu (yazilar, notlar, projeler, konusmalar, sayfalar)
- Otomatik arsiv sayfalari ile kategoriler ve etiketler
- Yapilandirilabilir sayfa boyutu ile sayfalama
- Koleksiyonlar API'si (filtreleme, siralama, gruplama, son eklenenler)

### Sablonlar ve Tema
- Uc katmanli sablon bilesimi (icerik -> duzen -> temel)
- 17 yerlesik blok (hero, baslik, altbilgi, sosyal baglantilar, icerik tablosu, son yazilar, etiket bulutu, kategori bulutu, okuma suresi, kod kopyalama, baglanti kopyalama, breadcrumb, son icerikler, dil degistirici, ilgili yazilar, ilgili icerikler, analitik) ve 24 platform ikonu (GitHub, X/Twitter, Mastodon, LinkedIn, Bluesky, YouTube, Instagram ve daha fazlasi)
- Tema mirasi (ozel -> ust -> varsayilan)
- `@block` yardimcisi ile EEx sablonlari
- Yapilandirilabilir sozdizimi vurgulama temasi (`highlight_theme`)
- Sayfa gecisleri icin View Transitions API destegi (`view_transitions: true`)
- Yerlesik baski stilleri (`@media print`)

### Uluslararasilastirma
- Dizin tabanli cok dilli destek
- Dil bazli URL on ekleri (`/tr/posts/...`)
- 14 yerlesik UI cevirisi (en, tr, de, es, fr, it, pt, ja, ko, zh, ar, ru, nl, pl)
- Mevcut cevirileri otomatik algilayan dil degistirici bloku
- RTL dil destegi (Arapca, Ibranice, Farsca, Urduca)
- Icerik dosyalari arasinda otomatik ceviri baglantisi
- Sablonlarda `@t.("anahtar")` ceviri fonksiyonu

### SEO ve Beslemeler
- Atom besleme üretimi
- Sitemap XML
- SEO meta etiketleri (Open Graph, aciklama)

### Gelistirici Deneyimi
- `mix sayfa.new` proje ureticisi
- Dosya izleme ve canli yeniden yukleme ile gelistirme sunucusu
- Taslak onizleme modu
- Artirimli derlemeler icin onbellekleme
- Asama bazli zamanlama ile ayrintili loglama

---

## Gereksinimler

| Gereksinim | Surum | Notlar |
|------------|-------|--------|
| Elixir | 1.19.5+ | OTP 27+ |
| Rust | En son kararli | MDEx NIF derlemesi icin gerekli |

Rust **zorunlu bir gereksinimdir** — MDEx hizli Markdown ayristirma icin yerel bir uzanti derler.

---

## Hizli Baslangic

```bash
# Sayfa arsivini yukleyin (mix sayfa.new icin)
mix archive.install hex sayfa

# Yeni bir site olusturun
mix sayfa.new blogum
cd blogum
mix deps.get

# Siteyi derleyin
mix sayfa.build

# Veya gelistirme sunucusunu baslattn
mix sayfa.serve
```

Siteniz `dist/` dizininde olusturulacaktir. Gelistirme sunucusu canli yeniden yukleme ile `http://localhost:4000` adresinde calisir.

---

## Icerik Turleri

Sayfa 5 yerlesik icerik turu ile gelir. Her biri `content/` altinda bir dizine ve bir URL on ekine karsilik gelir:

| Tur | Dizin | URL Deseni | Varsayilan Duzen |
|-----|-------|------------|------------------|
| Yazi | `content/posts/` | `/posts/{slug}/` | `post` |
| Not | `content/notes/` | `/notes/{slug}/` | `post` |
| Proje | `content/projects/` | `/projects/{slug}/` | `page` |
| Konusma | `content/talks/` | `/talks/{slug}/` | `page` |
| Sayfa | `content/pages/` | `/{slug}/` | `page` |

URL'lerde tarih yok — temiz ve kalici kalir.

### Dosya Adi Kurali

```
# Tarihli icerik (yazilar, notlar)
2024-01-15-elixir-ile-ssg.md  →  /posts/elixir-ile-ssg/

# Tarihsiz icerik (projeler, sayfalar)
projem.md                      →  /projects/projem/
hakkimda.md                    →  /hakkimda/
```

### Ozel Icerik Turleri

Yeni bir icerik turu iskelet olusturmak icin:

```bash
mix sayfa.gen.content_type Tarif  # → lib/content_types/tarif.ex
```

Ya da `Sayfa.Behaviours.ContentType` behaviour'unu elle uygulayabilirsiniz:

```elixir
defmodule Uygulamam.ContentTypes.Tarif do
  @behaviour Sayfa.Behaviours.ContentType

  @impl true
  def name, do: :tarif

  @impl true
  def directory, do: "tarifler"

  @impl true
  def url_prefix, do: "tarifler"

  @impl true
  def default_layout, do: "page"

  @impl true
  def required_fields, do: [:title]
end
```

---

## On Bilgi (Front Matter)

Icerik dosyalari `---` ile ayrilmis YAML on bilgi kullanir:

```yaml
---
title: "Statik Site Ureteci Yapmak"         # Zorunlu
date: 2024-01-15                             # Yazilar/notlar icin zorunlu
slug: ozel-slug                              # Istege bagli (varsayilan: dosya adindan)
lang: tr                                     # Istege bagli (varsayilan: site varsayilani)
description: "Kisa bir aciklama"             # Istege bagli, SEO icin
categories: [elixir, rehber]                 # Istege bagli
tags: [statik-site, baslangic]              # Istege bagli
draft: false                                 # Istege bagli (varsayilan: false)
layout: ozel_duzen                           # Istege bagli
---

Markdown iceriginiz burada.
```

### Alan Referansi

| Alan | Tip | Varsayilan | Aciklama |
|------|-----|------------|----------|
| `title` | String | *zorunlu* | Sayfa basligi |
| `date` | Date | `nil` | Yayin tarihi (YYYY-MM-DD) |
| `slug` | String | dosya adindan | URL slug |
| `lang` | Atom | site varsayilani | Icerik dili |
| `description` | String | `""` | SEO aciklamasi |
| `categories` | List | `[]` | Kategori adlari |
| `tags` | List | `[]` | Etiket adlari |
| `draft` | Boolean | `false` | Uretim derlemelerinden haric tut |
| `layout` | String | tur varsayilani | Duzen sablonu adi |

Taninmayan alanlar `meta` haritasinda saklanir ve sablonlarda `@content.meta["alan_adi"]` ile erisilebilir.

---

## Sablonlar ve Duzenler

Sayfa **uc katmanli bir bilesim** modeli kullanir:

1. **Icerik govdesi** — Markdown'dan HTML'e donusturulur
2. **Duzen sablonu** — Icerigi sarar, bloklari yerlestirir (ornegin `post.html.eex`)
3. **Temel sablon** — HTML kabuGu (`<html>`, `<head>`, vb.), `@inner_content` ekler

### Duzen Secimi

Bir sayfa duzenini on bilgi ile secer:

```yaml
---
title: "Hos Geldiniz"
layout: home
---
```

Cozumleme sirasi:
1. On bilgideki `layout` alani
2. Icerik turunun `default_layout` degeri
3. `page` (geri donus)

### Varsayilan Duzenler

| Duzen | Kullanim | Tipik Bloklar |
|-------|----------|---------------|
| `home.html.eex` | Ana sayfa | hero, recent_posts, tag_cloud |
| `post.html.eex` | Tekil yazi | reading_time, toc, social_links |
| `note.html.eex` | Tekil not | reading_time, copy_link |
| `page.html.eex` | Statik sayfalar | yalnizca icerik |
| `list.html.eex` | Icerik listeleri | sayfalama |
| `base.html.eex` | HTML sarmalayici | header, footer |

### Sablon Degiskenleri

Tum sablonlar su degiskenleri alir:

| Degisken | Tur | Aciklama |
|----------|-----|----------|
| `@content` | `Sayfa.Content.t()` | Mevcut icerik (liste sayfalarinda nil) |
| `@contents` | `[Sayfa.Content.t()]` | Tum site icerikleri |
| `@site` | `map()` | Cozumlenms site yapilandirmasi |
| `@block` | `function` | Blok render yardimcisi |
| `@t` | `function` | Ceviri fonksiyonu (`@t.("anahtar")`) |
| `@lang` | `atom()` | Mevcut icerik dili |
| `@dir` | `String.t()` | Metin yonu (`"ltr"` veya `"rtl"`) |
| `@inner_content` | `String.t()` | Render edilmis ic HTML (yalnizca base layout) |

---

## Bloklar

Bloklar, `@block` yardimcisi ile cagirilan yeniden kullanilabilir EEx bilesenleridir:

```eex
<%= @block.(:hero, title: "Hos Geldiniz", subtitle: "Elixir Blogum") %>
<%= @block.(:recent_posts, limit: 5) %>
<%= @block.(:tag_cloud) %>
```

### Yerlesik Bloklar

| Blok | Atom | Aciklama |
|------|------|----------|
| Hero | `:hero` | Baslik ve alt baslikli hero bolumu |
| Baslik | `:header` | Navigasyonlu site basligi; yapilandirmada `logo:` ayarlandiginda logo gorseli render eder |
| Altbilgi | `:footer` | Site altbilgisi |
| Sosyal Baglantilar | `:social_links` | Sosyal medya baglanti ikonlari |
| Icerik Tablosu | `:toc` | Basliklardan otomatik uretilen icerik tablosu |
| Son Yazilar | `:recent_posts` | Son yazilarin listesi |
| Etiket Bulutu | `:tag_cloud` | Sayili etiket bulutu |
| Kategori Bulutu | `:category_cloud` | Sayili kategori bulutu |
| Okuma Suresi | `:reading_time` | Tahmini okuma suresi |
| Kod Kopyalama | `:code_copy` | Kod bloklari icin kopyalama dugmesi |
| Baglanti Kopyalama | `:copy_link` | Sayfa URL'sini panoya kopyala |
| Icerik Yolu | `:breadcrumb` | Icerik yolu navigasyonu |
| Son Icerikler | `:recent_content` | Herhangi bir icerik turunun son ogeler |
| Dil Degistirici | `:language_switcher` | Icerik cevirileri arasinda gecis |
| Ilgili Yazilar | `:related_posts` | Etiket/kategoriye gore ilgili yazilar |
| Ilgili Icerikler | `:related_content` | Etiket/kategoriye gore ilgili icerikler (turu otomatik algilar; `type:` atamasini kabul eder) |

### Ozel Bloklar

Yeni bir blok iskelet olusturmak icin:

```bash
mix sayfa.gen.block AfisBlok          # → lib/blocks/afis_blok.ex
mix sayfa.gen.block Uygulamam.Blocks.Hero # → lib/blocks/hero.ex
```

Ya da `Sayfa.Behaviours.Block` behaviour'unu elle uygulayabilirsiniz:

```elixir
defmodule Uygulamam.Blocks.Afis do
  @behaviour Sayfa.Behaviours.Block

  @impl true
  def name, do: :afis

  @impl true
  def render(assigns) do
    metin = Map.get(assigns, :metin, "Hos Geldiniz!")
    ~s(<div class="afis">#{metin}</div>)
  end
end
```

Ozel bloklari site yapilandirmaniza kaydedin:

```elixir
config :sayfa, :blocks, [Uygulamam.Blocks.Afis | Sayfa.Block.default_blocks()]
```

---

## Temalar

### Varsayilan Tema

Sayfa, minimal ve dokumantasyon tarzi bir varsayilan tema ile gelir. 5 duzen ve temel CSS icerir.

### Ozel Temalar

Projenizde bir tema dizini olusturun:

```
themes/
  benim_temam/
    layouts/
      post.html.eex    # Belirli duzenleri gecersiz kilin
    assets/
      css/
        ozel.css
```

Yapilandirmada ayarlayin:

```elixir
config :sayfa, :site,
  theme: "benim_temam"
```

### Tema Mirasi

Ozel temalar bir ust temadan miras alir. Gecersiz kilinmayan duzenler ust temaya geri doner:

```elixir
config :sayfa, :site,
  theme: "benim_temam",
  theme_parent: "default"
```

---

## Cok Dilli Destek

Sayfa, cok dilli icerik icin dizin tabanli bir yaklasim kullanir:

```
content/
  posts/
    hello-world.md          # Ingilizce (varsayilan)
  tr/
    posts/
      merhaba-dunya.md      # Turkce
```

### Yapilandirma

```elixir
config :sayfa, :site,
  default_lang: :en,
  languages: [
    en: [name: "English"],
    tr: [name: "Türkçe"]
  ]
```

### URL Desenleri

```
Ingilizce (varsayilan):  /posts/hello-world/
Turkce:                  /tr/posts/merhaba-dunya/
```

### Cevirileri Baglama

Diller arasi icerikleri baglamak icin `translations` on bilgi anahtarini kullanin. Derleyici ayrica slug eslestirmesiyle cevirileri otomatik baglar.

```yaml
---
title: "Merhaba Dunya"
lang: tr
translations:
  en: hello-world
---
```

Tek komutla cok dilli icerik olusturun:

```bash
mix sayfa.gen.content post "Hello World" --lang=en,tr
```

### Ceviri Fonksiyonu

Sablonlar, UI dizelerini cevirmek icin bir `@t` fonksiyonu alir:

```eex
<%= @t.("recent_posts") %>   <%# Ingilizce'de "Recent Posts", Turkce'de "Son Yazilar" %>
<%= @t.("min_read") %>       <%# "min read" / "dk okuma" %>
```

Sayfa, yaygin UI dizeleri icin 14 yerlesik ceviri dosyasiyla gelir:

`en`, `tr`, `de`, `es`, `fr`, `it`, `pt`, `ja`, `ko`, `zh`, `ar`, `ru`, `nl`, `pl`

Ceviri arama zinciri:
1. Yapilandirmadaki dil bazli gecersiz kilmalar (`languages: [tr: [translations: %{"anahtar" => "deger"}]]`)
2. Icerik dili icin YAML dosyasi (`priv/translations/{dil}.yml`)
3. Varsayilan dil icin YAML dosyasi (geri donus)
4. Anahtarin kendisi

### Dil Bazli Yapilandirma Gecersiz Kilma

Her dil icin site yapilandirmasini gecersiz kilin:

```elixir
config :sayfa, :site,
  title: "My Blog",
  default_lang: :en,
  languages: [
    en: [name: "English"],
    tr: [name: "Türkçe", title: "Blogum", description: "Kisisel blogum"]
  ]
```

### RTL Destegi

Sayfa, sagdan sola diller icin `<html>` etiketinde otomatik olarak `dir="rtl"` ayarlar: Arapca (`ar`), Ibranice (`he`), Farsca (`fa`) ve Urduca (`ur`).

---

## Beslemeler ve SEO

### Atom Beslemeleri

Sayfa otomatik olarak Atom XML beslemeleri uretir:

```
/feed.xml              # Tum icerik
/feed/posts.xml        # Yalnizca yazilar
/feed/notes.xml        # Yalnizca notlar
```

### Sitemap

Tum yayinlanmis sayfalari iceren bir `sitemap.xml`, `dist/` dizininin kokunde uretilir.

### SEO Meta Etiketleri

Sablonlar, on bilgi alanlarina dayali Open Graph ve aciklama meta etiketlerini otomatik olarak icerir.

---

## Yapilandirma

Site yapilandirmasi `config/config.exs` dosyasinda bulunur:

```elixir
import Config

config :sayfa, :site,
  # Temel
  title: "Sitem",
  description: "Sayfa ile olusturulmus bir site",
  author: "Adiniz",
  base_url: "https://example.com",

  # Icerik
  content_dir: "content",
  output_dir: "dist",
  posts_per_page: 10,
  drafts: false,

  # Dil
  default_lang: :tr,
  languages: [
    tr: [name: "Turkce"],
    en: [name: "English", path: "/en"]
  ],

  # Tema
  theme: "default",
  theme_parent: "default",

  # Logo (istege bagli — baslikta yazi basliginin yerine gosterilir)
  # logo: "/images/logo.svg",
  # logo_dark: "/images/logo-dark.svg",  # karanlik modda logo yerine gosterilir

  # Kod bloklari icin sozdizimi vurgulama temasi
  # highlight_theme: "github_light",

  # Sayfa gecisleri icin View Transitions API
  # view_transitions: false,

  # Gelistirme sunucusu
  port: 4000,
  verbose: false
```

### Yapilandirma Referansi

| Anahtar | Tip | Varsayilan | Aciklama |
|---------|-----|------------|----------|
| `title` | String | `"My Site"` | Site basligi |
| `description` | String | `""` | Site aciklamasi |
| `author` | String | `nil` | Site yazari |
| `base_url` | String | `"http://localhost:4000"` | Uretim URL'si |
| `content_dir` | String | `"content"` | Icerik kaynak dizini |
| `output_dir` | String | `"dist"` | Derleme cikis dizini |
| `posts_per_page` | Integer | `10` | Sayfalama boyutu |
| `drafts` | Boolean | `false` | Taslaklari derlemeye dahil et |
| `default_lang` | Atom | `:en` | Varsayilan icerik dili |
| `languages` | Keyword | `[en: [name: "English"]]` | Kullanilabilir diller |
| `theme` | String | `"default"` | Aktif tema adi |
| `theme_parent` | String | `"default"` | Miras icin ust tema |
| `static_dir` | String | `"static"` | Statik varliklar dizini |
| `tailwind_version` | String | `"4.1.12"` | Kullanilacak TailwindCSS surumu |
| `logo` | String | `nil` | Logo gorsel yolu (baslikta yazi basliginin yerine goster) |
| `logo_dark` | String | `nil` | Karanlik mod logosu yolu (karanlik modda `logo` yerine gosterilir) |
| `social_links` | Map | `%{}` | Sosyal medya baglantilari (github, twitter, vb.) |
| `highlight_theme` | String | `"github_light"` | Kod bloklari icin sozdizimi vurgulama temasi |
| `view_transitions` | Boolean | `false` | Sayfa gecisleri icin View Transitions API'yi etkinlestir |
| `port` | Integer | `4000` | Gelistirme sunucusu portu |
| `verbose` | Boolean | `false` | Ayrintili derleme loglama |

---

## CLI Komutlari

### `mix sayfa.new`

Yeni bir Sayfa sitesi olusturun:

```bash
mix sayfa.new blogum
mix sayfa.new blogum --theme minimal --lang tr,en
```

### `mix sayfa.build`

Siteyi derleyin:

```bash
mix sayfa.build
mix sayfa.build --drafts              # Taslak icerigi dahil et
mix sayfa.build --verbose             # Ayrintili loglama
mix sayfa.build --output _site        # Ozel cikis dizini
mix sayfa.build --source ./sitem      # Ozel kaynak dizini
```

### `mix sayfa.gen.content`

Yeni bir icerik dosyasi olusturun:

```bash
mix sayfa.gen.content post "Ilk Yazim"
mix sayfa.gen.content note "Hizli Ipucu" --tags=elixir,ipuclari
mix sayfa.gen.content post "Merhaba Dunya" --lang=en,tr    # Cok dilli
mix sayfa.gen.content --list                                # Icerik turlerini listele
```

Secenekler: `--date`, `--tags`, `--categories`, `--draft`, `--lang`, `--slug`.

### `mix sayfa.gen.block`

Ozel bir blok modulu iskelet olusturun:

```bash
mix sayfa.gen.block AfisBlok          # → lib/blocks/afis_blok.ex
mix sayfa.gen.block Uygulamam.Blocks.Hero # → lib/blocks/hero.ex
```

`Sayfa.Behaviours.Block` davranisini uygulayan bir modul olusturur ve `config/config.exs` icin kayit satirini yazdirir.

### `mix sayfa.gen.content_type`

Ozel bir icerik turu modulu iskelet olusturun:

```bash
mix sayfa.gen.content_type Tarif                       # → lib/content_types/tarif.ex
mix sayfa.gen.content_type Uygulamam.ContentTypes.Video # → lib/content_types/video.ex
```

`Sayfa.Behaviours.ContentType` davranisini uygulayan bir modul olusturur ve kayit ile `mkdir` talimatlarini yazdirir.

### `mix sayfa.serve`

Gelistirme sunucusunu baslatin:

```bash
mix sayfa.serve
mix sayfa.serve --port 3000           # Ozel port
mix sayfa.serve --drafts              # Taslaklari onizle
```

Gelistirme sunucusu dosya degisikliklerini izler ve otomatik olarak yeniden derler.

---

## Proje Yapisi

Olusturulan bir Sayfa sitesi su sekilde gorunur:

```
sitem/
├── config/
│   ├── config.exs
│   └── site.exs                # Site yapilandirmasi
│
├── content/
│   ├── posts/                  # Blog yazilari
│   │   └── 2024-01-15-merhaba-dunya.md
│   ├── notes/                  # Hizli notlar
│   ├── projects/               # Portfolyo projeleri
│   ├── talks/                  # Konusmalar/sunumlar
│   ├── pages/                  # Statik sayfalar
│   │   └── hakkimda.md
│   └── en/                     # Ingilizce ceviriler
│       └── posts/
│
├── themes/
│   └── benim_temam/            # Ozel tema (istege bagli)
│       └── layouts/
│
├── static/                     # dist/ dizinine oldugu gibi kopyalanir
│   ├── images/
│   └── favicon.ico
│
├── lib/                        # Ozel bloklar, hook'lar, icerik turleri
│
├── dist/                       # Olusturulan site (git-ignored)
│
└── mix.exs
```

---

## Dagitim

`mix sayfa.new` bir **nixpacks.toml** ve **GitHub Actions is akisi** olusturur, boylece hemen dagitim yapabilirsiniz.

### GitHub Pages

Olusturulan projeniz `.github/workflows/deploy.yml` dosyasini icerir. Depo ayarlarinizda GitHub Pages'i etkinlestirin (Kaynak olarak **GitHub Actions**'i secin), `main`'e yapilan her push sitenizi otomatik olarak derleyip dagitacaktir.

### Nixpacks (Railway / Coolify)

`nixpacks.toml` dosyasi dahildir ve sitenizi [Nixpacks](https://nixpacks.com/) ile derler. [Railway](https://railway.app/) ve [Coolify](https://coolify.io/) gibi platformlarla kutudan ciktiginda calisir.

- **Railway**: Deponuzu baglayin; Railway `nixpacks.toml` dosyasini otomatik algilar. Statik site sunumu icin yayim dizinini `dist/` olarak ayarlayin.
- **Coolify**: **Nixpacks** derleme paketini secin ve deponuzu gosterin.

### VPS (rsync)

Yerel olarak derleyin ve sunucunuza senkronize edin:

```bash
mix sayfa.build
rsync -avz --delete dist/ kullanici@sunucu:/var/www/sitem/
```

---

## Genisletilebilirlik

Sayfa, uc behaviour ile genisletilmek uzere tasarlanmistir:

### Bloklar

Yeniden kullanilabilir sablon bilesenleri. [Bloklar](#bloklar) bolumune bakin.

### Hook'lar

Derleme hattina 4 asamada ozel mantik enjekte edin:

```elixir
defmodule Uygulamam.Hooks.AnalizEkle do
  @behaviour Sayfa.Behaviours.Hook

  @impl true
  def stage, do: :after_render

  @impl true
  def run({content, html}, _opts) do
    {:ok, {content, html <> "<script>/* analiz */</script>"}}
  end
end
```

Hook'lari yapilandirmada kaydedin:

```elixir
config :sayfa, :hooks, [Uygulamam.Hooks.AnalizEkle]
```

**Hook asamalari:**

| Asama | Girdi | Aciklama |
|-------|-------|----------|
| `:before_parse` | `Content.Raw` | Markdown olusturmadan once |
| `:after_parse` | `Content` | Ayristirmadan sonra, sablondan once |
| `:before_render` | `Content` | Sablon olusturmadan once |
| `:after_render` | `{Content, html}` | Sablon olusturmadan sonra |

### Icerik Turleri

Icerigin nasil organize edildigini tanimlayin. [Ozel Icerik Turleri](#ozel-icerik-turleri) bolumune bakin.

---

## Yol Haritasi

Sayfa icin gelecek planlari:

- Arama islevselligi (istemci tarafli arama ve dizinleme)
- Ucuncu parti uzantilar icin eklenti sistemi
- Varlik parmak izi

---

## Katki Saglama

Katkilar memnuniyetle karsilanir! Yonergeler icin [CONTRIBUTING.md](CONTRIBUTING.md) dosyasina bakin.

```bash
git clone https://github.com/furkanural/sayfa.git
cd sayfa
mix deps.get
mix test
```

---

## Lisans

MIT Lisansi. Detaylar icin [LICENSE](LICENSE) dosyasina bakin.
