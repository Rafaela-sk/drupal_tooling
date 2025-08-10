<?php

namespace Drupal\gallery_importer\Commands;

use Drush\Attributes as CLI;
use Drush\Commands\DrushCommands;
use Drupal\Core\File\FileSystemInterface;
use Drupal\file\Entity\File;
use Drupal\media\Entity\Media;

final class GalleryImportCommands extends DrushCommands {

  #[CLI\Command(name: 'gallery:add-images', description: 'Pridá všetky obrázky z adresára do existujúcej media galérie (vyhľadanej podľa názvu).')]
  #[CLI\Argument(name: 'gallery_title', description: 'Názov existujúcej galérie (Media: media_gallery.title).')]
  #[CLI\Argument(name: 'directory', description: 'Cesta k adresáru s obrázkami. Môže byť public://..., private://... alebo absolútna cesta. Ak je mimo public://, súbory sa skopírujú do public://gallery_import/<basename>.')]
  public function addImages(string $gallery_title, string $directory): int {
    $this->output()->writeln("🔎 Hľadám media galériu s názvom: {$gallery_title}");
    $storage = \Drupal::entityTypeManager()->getStorage('media_gallery');

    $ids = $storage->getQuery()
      ->accessCheck(FALSE)
      ->condition('title', $gallery_title)
      ->range(0, 1)
      ->execute();

    if (empty($ids)) {
      $this->io()->error("❌ Galéria s názvom '{$gallery_title}' nebola nájdená (ide o MEDIA entity, nie node).");
      return DrushCommands::EXIT_FAILURE;
    }

    $gallery = $storage->load(reset($ids));

    $field_name = 'images';
    if (!$gallery->hasField($field_name)) {
      $this->io()->error("❌ Galéria má neznáme pole pre referencie médií. Očakávané pole '{$field_name}' neexistuje.");
      return DrushCommands::EXIT_FAILURE;
    }

    /** @var \Drupal\Core\File\FileSystemInterface $fs */
    $fs = \Drupal::service('file_system');

    $is_stream = str_contains($directory, '://');
    $needs_copy = FALSE;

    if ($is_stream) {
      // public:// -> nekopíruj, private:// -> kopíruj do public://
      $needs_copy = !str_starts_with($directory, 'public://');
    }
    else {
      // Absolútna cesta -> kopíruj do public://
      $needs_copy = TRUE;
    }

    $src_dir = $directory;
    $dest_dir = $src_dir;

    if ($needs_copy) {
      $basename = basename(rtrim($src_dir, '/'));
      $dest_dir = "public://gallery_import/{$basename}";
      $fs->prepareDirectory($dest_dir, FileSystemInterface::CREATE_DIRECTORY | FileSystemInterface::MODIFY_PERMISSIONS);
    }

    if (!is_dir($src_dir)) {
      $this->io()->error("❌ Zdrojový adresár neexistuje: {$src_dir}");
      return DrushCommands::EXIT_FAILURE;
    }

    $allowed = ['jpg','jpeg','png','gif','webp'];
    $added_media_ids = [];

    foreach (scandir($src_dir) as $filename) {
      if ($filename === '.' || $filename === '..') {
        continue;
      }
      $ext = strtolower(pathinfo($filename, PATHINFO_EXTENSION));
      if (!in_array($ext, $allowed, TRUE)) {
        continue;
      }

      $src_uri = rtrim($src_dir, '/') . '/' . $filename;
      if (!file_exists($src_uri)) {
        continue;
      }

      $dest_uri = $src_uri;
      if ($needs_copy) {
        $dest_uri = rtrim($dest_dir, '/') . '/' . $filename;
        if (!file_exists($dest_uri)) {
          try {
            $fs->copy($src_uri, $dest_uri, FileSystemInterface::EXISTS_RENAME);
          } catch (\Throwable $e) {
            $this->io()->warning("Preskakujem {$filename} – kopírovanie zlyhalo: " . $e->getMessage());
            continue;
          }
        }
      }

      // Nájdeme alebo vytvoríme File entitu pre cieľový súbor.
      $file = current(\Drupal::entityTypeManager()->getStorage('file')->loadByProperties(['uri' => $dest_uri]));
      if (!$file) {
        $file = File::create(['uri' => $dest_uri]);
        $file->setPermanent();
        $file->save();
      }

      // Vytvoríme Media (image) a napojíme na súbor.
      try {
        $media = Media::create([
          'bundle' => 'image',
          'name' => pathinfo($filename, PATHINFO_FILENAME),
          'field_media_image' => [
            'target_id' => $file->id(),
            'alt' => $filename,
          ],
          'status' => 1,
        ]);
        $media->save();
      } catch (\Throwable $e) {
        $this->io()->warning("Preskakujem {$filename} – vytvorenie Media zlyhalo: " . $e->getMessage());
        continue;
      }

      $added_media_ids[] = ['target_id' => $media->id()];
    }

    if (!$added_media_ids) {
      $this->io()->warning("Nenašli sa žiadne vhodné obrázky v '{$directory}'.");
      return DrushCommands::EXIT_SUCCESS;
    }

    // Pridajme do poľa 'images'.
    $current = $gallery->get($field_name)->getValue();
    $gallery->set($field_name, array_merge($current, $added_media_ids));
    $gallery->save();

    $this->io()->success("✅ Do galérie '{$gallery_title}' bolo pridaných " . count($added_media_ids) . " obrázkov.");
    return DrushCommands::EXIT_SUCCESS;
  }
}

