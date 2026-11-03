<?php
// FileDrop — partage de fichiers interne (appli volontairement vulnérable)
$uploads = __DIR__ . '/uploads';
$files = is_dir($uploads) ? array_values(array_diff(scandir($uploads), ['.', '..', '.gitkeep'])) : [];
$ok = isset($_GET['ok']) ? basename($_GET['ok']) : null;
?>
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>FileDrop · partage interne</title>
  <style>
    :root { color-scheme: dark; }
    body { font-family: system-ui, sans-serif; background:#0d1117; color:#c9d1d9; margin:0; }
    .wrap { max-width:720px; margin:0 auto; padding:32px 16px; }
    h1 { font-size:1.6rem; margin:0 0 4px; }
    .sub { color:#8b949e; margin:0 0 24px; }
    .card { background:#161b22; border:1px solid #30363d; border-radius:10px; padding:20px; margin-bottom:20px; }
    input[type=file] { color:#c9d1d9; }
    button { background:#238636; color:#fff; border:0; border-radius:6px; padding:8px 16px; cursor:pointer; font-size:1rem; }
    ul { list-style:none; padding:0; margin:0; }
    li { padding:8px 0; border-bottom:1px solid #21262d; }
    a { color:#58a6ff; text-decoration:none; }
    .ok { background:#132e1a; border:1px solid #238636; color:#7ee787; padding:10px 14px; border-radius:6px; margin-bottom:16px; }
    footer { color:#484f58; font-size:.8rem; margin-top:28px; text-align:center; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>📁 FileDrop</h1>
    <p class="sub">Partage de fichiers interne de l'équipe — v1.2</p>

    <?php if ($ok): ?>
      <div class="ok">Fichier « <?= htmlspecialchars($ok) ?> » envoyé. Il est disponible dans <code>/uploads/</code>.</div>
    <?php endif; ?>

    <div class="card">
      <form action="upload.php" method="post" enctype="multipart/form-data">
        <p>Dépose un fichier à partager :</p>
        <input type="file" name="file" required>
        <button type="submit">Envoyer</button>
      </form>
    </div>

    <div class="card">
      <h2 style="font-size:1.1rem;margin-top:0">Fichiers partagés</h2>
      <?php if (!$files): ?>
        <p class="sub" style="margin:0">Aucun fichier pour le moment.</p>
      <?php else: ?>
        <ul>
          <?php foreach ($files as $f): ?>
            <li>📄 <a href="uploads/<?= rawurlencode($f) ?>"><?= htmlspecialchars($f) ?></a></li>
          <?php endforeach; ?>
        </ul>
      <?php endif; ?>
    </div>

    <footer>FileDrop — powered by PHP <?= PHP_VERSION ?> on <?= php_uname('s') ?></footer>
  </div>
</body>
</html>
