<?php
// Point d'upload — VULNÉRABLE : aucune validation d'extension ni de type.
// Le nom fourni par le client est réutilisé tel quel -> on peut déposer du .php
// dans un dossier servi et exécuté par Apache. (C'est le bug, volontaire.)
$uploads = __DIR__ . '/uploads';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file']) && $_FILES['file']['error'] === UPLOAD_ERR_OK) {
    $name = basename($_FILES['file']['name']);        // <- pas de filtrage
    $dest = $uploads . '/' . $name;
    if (move_uploaded_file($_FILES['file']['tmp_name'], $dest)) {
        header('Location: /?ok=' . rawurlencode($name));
        exit;
    }
    http_response_code(500);
    echo 'Échec de l\'enregistrement.';
    exit;
}

http_response_code(400);
header('Location: /');
