
# Používateľská príručka – Drush príkaz `gallery:add-images`

Táto príručka vysvetľuje, ako používať vlastný Drush príkaz na hromadné pridanie obrázkov do existujúcej media galérie v Drupale 10.

---

## 📌 Účel
Príkaz umožňuje zaregistrovať existujúce obrázky v Drupale ako položky mediálnej galérie (media_gallery) bez potreby ich fyzického kopírovania – predpokladá sa, že súbory už existujú v adresári `public://` alebo na absolútnej ceste.

---

## 🛠 Použitie

### Základný formát:
```bash
drush gallery:add-images "Názov galérie" "cesta_k_adresáru"
```

### Príklady:
```bash
# Pridanie obrázkov do galérie s názvom "Plavecké preteky 2017"
drush gallery:add-images "Plavecké preteky 2017" public://gallery_import/202

# Použitie absolútnej cesty
drush gallery:add-images "Plavecké preteky 2017" /var/www/html/sites/default/files/gallery_import/202
```

---

## 🔍 Ako funguje príkaz

1. **Vyhľadanie galérie podľa názvu**  
   - Hľadá sa entita `media_gallery` (nie node typu article).  
   - Názov sa musí zhodovať s hodnotou uloženou v `media_field_data.name`.

2. **Iterácia cez súbory v adresári**  
   - Prechádzajú sa všetky súbory v zadanom adresári.
   - Filtrujú sa len obrázky (jpg, jpeg, png, gif).

3. **Registrácia ako media entity**  
   - Každý obrázok sa zaregistruje ako `media` entity typu `image`.
   - Media entita sa priradí k galérii cez referenčné pole.

4. **Žiadne kopírovanie súborov**  
   - Očakáva sa, že súbory sú už uložené v `public://` alebo absolútnej ceste prístupnej Drupalu.

---

## 📄 Zdrojový kód – `GalleryImportCommands.php`

```php
<?php

namespace Drupal\gallery_importer\Commands;

use Drush\Commands\DrushCommands;
use Drupal\media\Entity\Media;
use Drupal␌ile\Entity\File;
use Drupal\Core\Entity\EntityTypeManagerInterface;
use Symfony\Component\DependencyInjection\ContainerInterface;

class GalleryImportCommands extends DrushCommands {

  protected $entityTypeManager;

  public function __construct(EntityTypeManagerInterface $entityTypeManager) {
    $this->entityTypeManager = $entityTypeManager;
  }

  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('entity_type.manager')
    );
  }

  /**
   * Pridá obrázky z adresára do existujúcej media galérie.
   *
   * @command gallery:add-images
   * @param string $gallery_title
   *   Názov galérie.
   * @param string $source_dir
   *   Cesta k adresáru s obrázkami.
   * @usage drush gallery:add-images "Moja galéria" public://gallery_import/202
   */
  public function addImages($gallery_title, $source_dir) {
    $this->output()->writeln("🔎 Hľadám media galériu s názvom: {$gallery_title}");

    $galleries = $this->entityTypeManager->getStorage('media')->loadByProperties([
      'bundle' => 'media_gallery',
      'name' => $gallery_title,
    ]);

    if (empty($galleries)) {
      $this->output()->writeln("❌ Galéria s názvom '{$gallery_title}' nebola nájdená.");
      return;
    }

    $gallery = reset($galleries);

    if (strpos($source_dir, 'public://') === 0) {
      $real_path = \Drupal::service('file_system')->realpath($source_dir);
    } else {
      $real_path = $source_dir;
    }

    if (!is_dir($real_path)) {
      $this->output()->writeln("❌ Adresár '{$real_path}' neexistuje.");
      return;
    }

    $files = scandir($real_path);
    $count = 0;

    foreach ($files as $file_name) {
      if (in_array(strtolower(pathinfo($file_name, PATHINFO_EXTENSION)), ['jpg', 'jpeg', 'png', 'gif'])) {
        $uri = (strpos($source_dir, 'public://') === 0)
          ? $source_dir . '/' . $file_name
          : 'public://' . str_replace(\Drupal::service('file_system')->realpath('public://') . '/', '', $real_path . '/' . $file_name);

        $file = File::create([
          'uri' => $uri,
        ]);
        $file->save();

        $media = Media::create([
          'bundle' => 'image',
          'name' => $file_name,
          'field_media_image' => [
            'target_id' => $file->id(),
            'alt' => pathinfo($file_name, PATHINFO_FILENAME),
          ],
          'field_gallery' => [
            'target_id' => $gallery->id(),
          ],
        ]);
        $media->save();
        $count++;
      }
    }

    $this->output()->writeln("✅ Do galérie '{$gallery_title}' bolo pridaných {$count} obrázkov.");
  }
}
```

---

## ⚠️ Dôležité poznámky

- **Názov galérie** musí presne zodpovedať názvu v Drupale.  
- Skript neoveruje duplicitu – opakované spustenie môže vytvoriť duplicity obrázkov.  
- Pole `field_gallery` musí byť správne nastavené podľa schémy tvojej stránky.  
- Na veľké importy (stovky až tisíce súborov) odporúčam použiť Drush namiesto web UI, pretože to obíde PHP time limit.

---

## 🧹 Údržba

- Ak sa import pokazí, môžeš media položky vymazať priamo cez **Drupal UI** alebo Drush:  
```bash
drush entity:delete media --bundle=image
```

- Na vymazanie len položiek z jednej galérie budeš musieť pridať filter podľa ID galérie.

---


## Inštalácia modulu `gallery_importer`

1. **Skopírujte modul do správneho adresára**  
   Modul umiestnite do:
   ```
   web/modules/custom/gallery_importer
   ```
   alebo v tvojej inštalácii:
   ```
   modules/custom/gallery_importer
   ```

2. **Overte `composer.json` (len ak je potrebné)**  
   Ak modul využíva ďalšie knižnice, overte ich prítomnosť:
   ```
   composer install
   ```
   alebo
   ```
   ~/tools/composer_run.sh install
   ```

3. **Vyčistite cache**
   ```
   drush cr
   ```

4. **Zapnite modul**
   ```
   drush en gallery_importer
   ```

5. **Overte prítomnosť príkazu**
   ```
   drush list | grep gallery
   ```
   Malo by sa zobraziť:
   ```
   gallery:add-images
   ```

---

## Odinštalovanie modulu `gallery_importer`

1. **Zakážte modul**
   ```
   drush pm:uninstall gallery_importer
   ```

2. **Odstráňte súbory modulu**
   ```
   rm -rf modules/custom/gallery_importer
   ```

3. **Vyčistite cache**
   ```
   drush cr
   ```
