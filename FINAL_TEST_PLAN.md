# Plan de Test Final - BassPro Player v1.0.0

## Vue d'ensemble

Ce document fournit un plan de test complet pour la validation finale de BassPro Player avant la distribution. Les tests doivent être effectués sur des appareils physiques avec différentes versions d'Android et tailles d'écran.

## Objectifs de Test

- Valider toutes les fonctionnalités sur plusieurs versions d'Android (5.0, 8.0, 10, 12, 14)
- Tester sur différentes tailles d'écran (téléphone, tablette)
- Vérifier les performances avec une grande bibliothèque (10 000+ pistes)
- Valider la lecture en arrière-plan pendant des périodes prolongées
- Mesurer l'utilisation de la batterie pendant la lecture
- Détecter les fuites de mémoire
- Vérifier que toutes les chaînes françaises sont correctes

## Configuration de Test Requise

### Appareils de Test

| Version Android | Appareil Recommandé | Taille d'Écran |
|-----------------|---------------------|----------------|
| Android 5.0 (API 21) | Émulateur ou ancien appareil | Téléphone |
| Android 8.0 (API 26) | Émulateur ou appareil | Téléphone |
| Android 10 (API 29) | Appareil physique | Téléphone |
| Android 12 (API 31) | Appareil physique | Téléphone |
| Android 14 (API 34) | Appareil physique | Téléphone |
| Android 10+ | Tablette | Tablette (7-10") |

### Données de Test

- **Petite bibliothèque**: 10-50 pistes
- **Bibliothèque moyenne**: 500-1000 pistes
- **Grande bibliothèque**: 10 000+ pistes
- **Pistes avec métadonnées manquantes**: Titres vides, artistes inconnus
- **Pistes avec noms très longs**: Titres > 100 caractères
- **Sources de streaming**: URLs valides et invalides


## Outils de Test

### Outils de Performance

1. **Android Profiler** (Android Studio)
   - Surveillance de la mémoire
   - Surveillance du CPU
   - Surveillance de la batterie

2. **ADB Commands**
   ```bash
   # Vérifier l'utilisation de la mémoire
   adb shell dumpsys meminfo com.example.basspro_player
   
   # Surveiller l'utilisation de la batterie
   adb shell dumpsys batterystats com.example.basspro_player
   
   # Vérifier les fuites de mémoire
   adb shell am dumpheap com.example.basspro_player /data/local/tmp/heap.hprof
   ```

3. **LeakCanary** (si intégré)
   - Détection automatique des fuites de mémoire

### Outils de Validation

- **Checklist de test** (voir sections ci-dessous)
- **Modèle de rapport de bug** (voir annexe)
- **Feuille de calcul de suivi des tests**

---

## Section 1: Tests de Configuration Initiale

### 1.1 Installation et Premier Lancement

**Objectif**: Vérifier que l'application s'installe et se lance correctement

**Procédure**:
1. Installer l'APK de version release sur l'appareil
2. Lancer l'application pour la première fois
3. Observer l'écran de démarrage
4. Attendre que la bibliothèque se charge

**Critères de Réussite**:
- [ ] L'application s'installe sans erreur
- [ ] L'écran de démarrage s'affiche pendant le chargement
- [ ] Les permissions de stockage sont demandées (Android < 10)
- [ ] La bibliothèque se charge en < 2 secondes (petite bibliothèque)
- [ ] L'écran Bibliothèque s'affiche avec les pistes
- [ ] Aucun crash au lancement


### 1.2 Permissions

**Objectif**: Vérifier la gestion des permissions

**Procédure**:
1. Tester sur Android 5.0-9.0: Vérifier la demande READ_EXTERNAL_STORAGE
2. Tester sur Android 10+: Vérifier l'accès MediaStore sans permission
3. Refuser les permissions et vérifier le message d'erreur
4. Accorder les permissions et vérifier que le scan fonctionne

**Critères de Réussite**:
- [ ] Android < 10: Permission READ_EXTERNAL_STORAGE demandée
- [ ] Android 10+: Aucune permission de stockage demandée
- [ ] Message d'erreur clair si permission refusée
- [ ] Scan de bibliothèque fonctionne après accord de permission
- [ ] Permission FOREGROUND_SERVICE accordée automatiquement

---

## Section 2: Tests de Navigation et Interface

### 2.1 Navigation par Onglets

**Objectif**: Vérifier la navigation entre les onglets principaux

**Procédure**:
1. Appuyer sur chaque onglet de navigation (Bibliothèque, Streaming, Playlists, Paramètres)
2. Vérifier que l'écran correspondant s'affiche
3. Vérifier que l'onglet actif est mis en surbrillance

**Critères de Réussite**:
- [ ] Onglet Bibliothèque affiche la liste des pistes
- [ ] Onglet Streaming affiche les sources de streaming
- [ ] Onglet Playlists affiche les playlists
- [ ] Onglet Paramètres affiche les options
- [ ] Transition fluide entre les onglets (< 100ms)
- [ ] Onglet actif visuellement distinct

### 2.2 Mini Lecteur

**Objectif**: Vérifier le comportement du mini lecteur

**Procédure**:
1. Lancer la lecture d'une piste
2. Vérifier que le mini lecteur apparaît en bas
3. Naviguer entre les onglets et vérifier que le mini lecteur reste visible
4. Appuyer sur le mini lecteur pour ouvrir l'écran Lecture en cours

**Critères de Réussite**:
- [ ] Mini lecteur apparaît lors de la lecture
- [ ] Mini lecteur visible sur tous les onglets
- [ ] Affiche la pochette, titre, artiste
- [ ] Boutons lecture/pause, précédent, suivant fonctionnent
- [ ] Appui ouvre l'écran Lecture en cours
- [ ] Animation de glissement fluide


### 2.3 Écran Lecture en Cours

**Objectif**: Vérifier l'interface de lecture complète

**Procédure**:
1. Ouvrir l'écran Lecture en cours
2. Vérifier tous les éléments d'interface
3. Tester le geste de glissement vers le bas pour fermer
4. Tester le geste de glissement gauche/droite pour changer de piste

**Critères de Réussite**:
- [ ] Grande pochette d'album affichée
- [ ] Titre, artiste, album affichés
- [ ] Barre de progression avec position actuelle et durée totale
- [ ] Boutons lecture/pause, précédent, suivant, aléatoire, répéter
- [ ] Bouton favori fonctionne
- [ ] Bouton égaliseur ouvre l'écran Égaliseur
- [ ] Glissement vers le bas ferme l'écran
- [ ] Glissement gauche/droite change de piste

---

## Section 3: Tests de Bibliothèque Musicale

### 3.1 Scan de Bibliothèque

**Objectif**: Vérifier le scan et l'affichage de la bibliothèque

**Procédure**:
1. Tester avec différentes tailles de bibliothèque (10, 500, 10 000+ pistes)
2. Vérifier que toutes les pistes sont détectées
3. Vérifier les métadonnées (titre, artiste, album, durée, pochette)
4. Tester le rescan depuis Paramètres

**Critères de Réussite**:
- [ ] Toutes les pistes audio sont détectées
- [ ] Métadonnées correctement extraites
- [ ] Pochettes d'album affichées (si disponibles)
- [ ] Placeholder affiché pour pistes sans pochette
- [ ] Scan de 10 000+ pistes en < 30 secondes
- [ ] Rescan met à jour les nouvelles/supprimées pistes

### 3.2 Affichage et Tri

**Objectif**: Vérifier l'affichage et le tri des pistes

**Procédure**:
1. Vérifier l'affichage de la liste des pistes
2. Tester chaque option de tri (Titre, Artiste, Album, Date, Durée)
3. Vérifier le défilement fluide avec grande bibliothèque

**Critères de Réussite**:
- [ ] Liste affiche pochette, titre, artiste, durée
- [ ] Tri par titre: ordre alphabétique
- [ ] Tri par artiste: ordre alphabétique
- [ ] Tri par album: ordre alphabétique
- [ ] Tri par date: plus récent en premier
- [ ] Tri par durée: plus court au plus long
- [ ] Défilement à 60fps avec 10 000+ pistes


### 3.3 Recherche

**Objectif**: Vérifier la fonctionnalité de recherche

**Procédure**:
1. Ouvrir la recherche
2. Rechercher par titre de piste
3. Rechercher par nom d'artiste
4. Rechercher par nom d'album
5. Tester avec requêtes partielles

**Critères de Réussite**:
- [ ] Recherche trouve les pistes par titre
- [ ] Recherche trouve les pistes par artiste
- [ ] Recherche trouve les pistes par album
- [ ] Recherche insensible à la casse
- [ ] Résultats mis à jour en temps réel
- [ ] Recherche rapide (< 100ms) même avec 10 000+ pistes

### 3.4 Favoris et Statistiques

**Objectif**: Vérifier les favoris et l'historique

**Procédure**:
1. Marquer plusieurs pistes comme favorites
2. Vérifier la liste des favoris
3. Jouer des pistes et vérifier "Récemment joués"
4. Vérifier "Les plus écoutés" après plusieurs lectures

**Critères de Réussite**:
- [ ] Marquer favori met à jour l'icône
- [ ] Liste Favoris contient toutes les pistes favorites
- [ ] Récemment joués affiche les dernières pistes jouées
- [ ] Les plus écoutés triés par nombre de lectures
- [ ] Compteur de lectures incrémenté à chaque lecture
- [ ] Horodatage de dernière lecture mis à jour

---

## Section 4: Tests de Lecture Audio

### 4.1 Contrôles de Lecture de Base

**Objectif**: Vérifier les contrôles de lecture

**Procédure**:
1. Appuyer sur une piste pour lancer la lecture
2. Tester lecture/pause
3. Tester suivant/précédent
4. Tester la barre de progression (seek)

**Critères de Réussite**:
- [ ] Appui sur piste lance la lecture
- [ ] Bouton lecture démarre/reprend la lecture
- [ ] Bouton pause met en pause
- [ ] Bouton suivant passe à la piste suivante
- [ ] Bouton précédent retourne à la piste précédente
- [ ] Glisser la barre de progression change la position
- [ ] Position et durée affichées correctement


### 4.2 Modes Aléatoire et Répétition

**Objectif**: Vérifier les modes de lecture

**Procédure**:
1. Activer le mode aléatoire et vérifier l'ordre de lecture
2. Désactiver l'aléatoire et vérifier le retour à l'ordre original
3. Tester répéter tout (la file redémarre à la fin)
4. Tester répéter une (la piste actuelle se répète)

**Critères de Réussite**:
- [ ] Aléatoire randomise l'ordre de la file
- [ ] Désactiver aléatoire restaure l'ordre original
- [ ] Répéter tout redémarre la file à la fin
- [ ] Répéter une rejoue la piste actuelle
- [ ] Icônes de mode visuellement distinctes
- [ ] Modes persistent pendant la session

### 4.3 Gestion de la File d'Attente

**Objectif**: Vérifier la gestion de la file d'attente

**Procédure**:
1. Ajouter des pistes à la file
2. Afficher la file d'attente
3. Réorganiser les pistes par glissement
4. Supprimer des pistes de la file
5. Vider la file

**Critères de Réussite**:
- [ ] Ajouter à la file ajoute la piste à la fin
- [ ] File affiche toutes les pistes en ordre
- [ ] Glisser-déposer réorganise la file
- [ ] Supprimer retire la piste de la file
- [ ] Vider la file supprime toutes les pistes
- [ ] File mise à jour en temps réel

### 4.4 Lecture en Arrière-Plan

**Objectif**: Vérifier la lecture en arrière-plan

**Procédure**:
1. Lancer la lecture
2. Appuyer sur le bouton Home (mettre l'app en arrière-plan)
3. Vérifier la notification
4. Tester les contrôles de notification
5. Verrouiller l'écran et vérifier les contrôles d'écran de verrouillage
6. Laisser jouer pendant 30 minutes

**Critères de Réussite**:
- [ ] Lecture continue en arrière-plan
- [ ] Notification affiche pochette, titre, artiste
- [ ] Contrôles de notification fonctionnent (lecture/pause, suivant, précédent)
- [ ] Contrôles d'écran de verrouillage fonctionnent
- [ ] Lecture stable pendant 30+ minutes
- [ ] Aucun crash en arrière-plan


### 4.5 Intégration Système

**Objectif**: Vérifier l'intégration avec le système Android

**Procédure**:
1. Tester les boutons média des écouteurs/Bluetooth
2. Recevoir un appel téléphonique pendant la lecture
3. Lancer une autre app audio (YouTube, Spotify)
4. Recevoir une notification

**Critères de Réussite**:
- [ ] Boutons écouteurs contrôlent la lecture
- [ ] Appel téléphonique met en pause, reprend après
- [ ] Autre app audio met en pause BassPro
- [ ] Notification réduit le volume (ducking)
- [ ] Focus audio géré correctement
- [ ] Aucun conflit audio

---

## Section 5: Tests d'Égaliseur

### 5.1 Interface Égaliseur

**Objectif**: Vérifier l'interface de l'égaliseur

**Procédure**:
1. Ouvrir l'écran Égaliseur depuis Lecture en cours
2. Vérifier tous les contrôles
3. Ajuster chaque bande de fréquence
4. Ajuster le préampli, sub-bass, bass

**Critères de Réussite**:
- [ ] Écran Égaliseur s'ouvre en modal
- [ ] 10 bandes de fréquence affichées (32Hz à 16kHz)
- [ ] Curseur de préampli fonctionne
- [ ] Curseurs sub-bass et bass fonctionnent
- [ ] Valeurs en dB affichées
- [ ] Limiteur activé par défaut
- [ ] Sélecteur de préréglage affiché

### 5.2 Ajustements en Temps Réel

**Objectif**: Vérifier que les ajustements audio sont appliqués en temps réel

**Procédure**:
1. Lancer la lecture d'une piste
2. Ouvrir l'égaliseur
3. Ajuster différentes bandes pendant la lecture
4. Augmenter le bass boost
5. Écouter les changements audio

**Critères de Réussite**:
- [ ] Changements appliqués immédiatement (< 100ms)
- [ ] Aucune interruption de lecture
- [ ] Bass boost audible
- [ ] Sub-bass boost audible
- [ ] Préampli affecte le volume global
- [ ] Aucune distorsion avec limiteur activé


### 5.3 Préréglages

**Objectif**: Vérifier les préréglages d'égaliseur

**Procédure**:
1. Sélectionner chaque préréglage intégré (Deep Bass, Punch Bass, Hip-Hop, EDM, Rock, Pop, Vocal Clarity, Balanced)
2. Vérifier que les paramètres changent
3. Créer un préréglage personnalisé
4. Renommer et supprimer un préréglage personnalisé

**Critères de Réussite**:
- [ ] 8 préréglages intégrés disponibles
- [ ] Sélection de préréglage applique les paramètres
- [ ] Préréglages Deep Bass et Punch Bass ont bass boost élevé
- [ ] Créer préréglage personnalisé fonctionne
- [ ] Préréglage personnalisé apparaît dans la liste
- [ ] Renommer préréglage fonctionne
- [ ] Supprimer préréglage personnalisé fonctionne
- [ ] Impossible de supprimer les préréglages intégrés

### 5.4 Limiteur et Avertissements

**Objectif**: Vérifier le limiteur anti-écrêtage

**Procédure**:
1. Augmenter tous les gains au maximum
2. Vérifier l'avertissement d'écrêtage
3. Activer le limiteur
4. Désactiver le limiteur avec gains élevés

**Critères de Réussite**:
- [ ] Avertissement affiché quand gain total > seuil
- [ ] Limiteur activé par défaut
- [ ] Limiteur empêche la distorsion
- [ ] Désactiver limiteur affiche avertissement
- [ ] Aucune distorsion audible avec limiteur
- [ ] Paramètres d'égaliseur persistent après redémarrage

---

## Section 6: Tests de Streaming

### 6.1 Gestion des Sources de Streaming

**Objectif**: Vérifier la gestion des sources de streaming

**Procédure**:
1. Ajouter une nouvelle source de streaming (nom, URL, catégorie)
2. Modifier une source existante
3. Marquer une source comme favorite
4. Supprimer une source

**Critères de Réussite**:
- [ ] Dialogue d'ajout collecte nom, URL, catégorie
- [ ] Source ajoutée apparaît dans la liste
- [ ] Modifier source met à jour les informations
- [ ] Marquer favori met à jour l'icône
- [ ] Supprimer source la retire de la liste
- [ ] Sources persistent après redémarrage


### 6.2 Lecture de Streaming

**Objectif**: Vérifier la lecture de flux audio en ligne

**Procédure**:
1. Sélectionner une source de streaming valide
2. Vérifier l'indicateur de mise en mémoire tampon
3. Vérifier que la lecture démarre
4. Tester avec URL invalide
5. Désactiver le réseau pendant la lecture

**URLs de Test**:
- Radio valide: http://stream.radioparadise.com/aac-320
- URL invalide: http://invalid.url.test/stream

**Critères de Réussite**:
- [ ] Indicateur de mise en mémoire tampon affiché
- [ ] Lecture démarre après mise en mémoire tampon
- [ ] URL invalide affiche message d'erreur avec option de réessai
- [ ] Perte de réseau met en pause et affiche erreur
- [ ] Historique de streaming enregistré
- [ ] Récemment joués affiche les flux récents
- [ ] Égaliseur fonctionne avec streaming

---

## Section 7: Tests de Playlists

### 7.1 Gestion des Playlists

**Objectif**: Vérifier la création et gestion des playlists

**Procédure**:
1. Créer une nouvelle playlist
2. Ajouter des pistes à la playlist
3. Réorganiser les pistes par glissement
4. Supprimer des pistes de la playlist
5. Renommer la playlist
6. Supprimer la playlist

**Critères de Réussite**:
- [ ] Créer playlist demande un nom
- [ ] Playlist créée apparaît dans la liste
- [ ] Ajouter piste l'ajoute à la fin
- [ ] Glisser-déposer réorganise les pistes
- [ ] Supprimer piste la retire de la playlist
- [ ] Renommer playlist met à jour le nom
- [ ] Supprimer playlist la retire complètement
- [ ] Playlists persistent après redémarrage

### 7.2 Playlists Intelligentes

**Objectif**: Vérifier les playlists automatiques

**Procédure**:
1. Vérifier la playlist Favoris
2. Vérifier la playlist Récemment ajoutés
3. Vérifier la playlist Les plus écoutés
4. Marquer une piste comme favorite et vérifier la mise à jour
5. Jouer une piste plusieurs fois et vérifier Les plus écoutés

**Critères de Réussite**:
- [ ] Playlist Favoris contient toutes les pistes favorites
- [ ] Playlist Récemment ajoutés triée par date
- [ ] Playlist Les plus écoutés triée par nombre de lectures
- [ ] Playlists intelligentes se mettent à jour automatiquement
- [ ] Impossible de modifier/supprimer les playlists intelligentes


### 7.3 Lecture de Playlist

**Objectif**: Vérifier la lecture de playlists

**Procédure**:
1. Ouvrir une playlist
2. Appuyer sur le bouton de lecture de playlist
3. Vérifier que toutes les pistes sont chargées dans la file
4. Vérifier l'ordre de lecture

**Critères de Réussite**:
- [ ] Lecture de playlist charge toutes les pistes
- [ ] Pistes jouées dans l'ordre de la playlist
- [ ] File d'attente affiche toutes les pistes de la playlist
- [ ] Modes aléatoire et répétition fonctionnent avec playlists

---

## Section 8: Tests de Paramètres

### 8.1 Thème

**Objectif**: Vérifier le changement de thème

**Procédure**:
1. Vérifier que le thème sombre est par défaut
2. Changer pour le thème clair
3. Vérifier que tous les écrans utilisent le nouveau thème
4. Redémarrer l'app et vérifier la persistance

**Critères de Réussite**:
- [ ] Thème sombre par défaut au premier lancement
- [ ] Changement de thème appliqué immédiatement
- [ ] Tous les écrans utilisent le thème sélectionné
- [ ] Thème persiste après redémarrage
- [ ] Contraste et lisibilité corrects dans les deux thèmes

### 8.2 Minuterie de Sommeil

**Objectif**: Vérifier la minuterie de sommeil

**Procédure**:
1. Lancer la lecture
2. Définir une minuterie de sommeil (15 minutes)
3. Vérifier l'affichage du temps restant
4. Attendre l'expiration (ou accélérer le temps de test)
5. Tester l'annulation de la minuterie

**Critères de Réussite**:
- [ ] Options disponibles: 15, 30, 45, 60, 90 minutes
- [ ] Temps restant affiché
- [ ] Lecture s'arrête à l'expiration (avec fondu)
- [ ] Annulation fonctionne
- [ ] Minuterie continue en arrière-plan
- [ ] Notification affichée pendant le compte à rebours


### 8.3 Autres Paramètres

**Objectif**: Vérifier les autres paramètres

**Procédure**:
1. Tester le rescan de bibliothèque
2. Tester l'option "Garder l'écran allumé"
3. Sélectionner un préréglage d'égaliseur par défaut

**Critères de Réussite**:
- [ ] Rescan détecte les nouvelles pistes
- [ ] Rescan supprime les pistes manquantes
- [ ] Garder l'écran allumé empêche la mise en veille pendant la lecture
- [ ] Préréglage par défaut appliqué au lancement
- [ ] Tous les paramètres persistent après redémarrage

---

## Section 9: Tests de Performance

### 9.1 Performance de Défilement

**Objectif**: Mesurer la fluidité du défilement

**Procédure**:
1. Charger une bibliothèque de 10 000+ pistes
2. Défiler rapidement dans la liste
3. Observer la fluidité et les saccades
4. Utiliser Android Profiler pour mesurer les FPS

**Critères de Réussite**:
- [ ] Défilement à 60 FPS constant
- [ ] Aucune saccade visible
- [ ] Pochettes se chargent progressivement
- [ ] Pas de ralentissement avec 10 000+ pistes
- [ ] Utilisation mémoire stable pendant le défilement

### 9.2 Performance de Requêtes

**Objectif**: Mesurer la vitesse des requêtes de base de données

**Procédure**:
1. Mesurer le temps de chargement de la bibliothèque
2. Mesurer le temps de recherche
3. Mesurer le temps de chargement des favoris
4. Mesurer le temps de chargement d'une playlist

**Critères de Réussite**:
- [ ] Chargement bibliothèque < 2 secondes (10 000 pistes)
- [ ] Recherche < 100ms
- [ ] Chargement favoris < 100ms
- [ ] Chargement playlist < 100ms
- [ ] Aucun blocage de l'interface


### 9.3 Temps de Démarrage

**Objectif**: Mesurer le temps de démarrage de l'application

**Procédure**:
1. Fermer complètement l'application
2. Lancer l'application
3. Mesurer le temps jusqu'à l'affichage de l'écran Bibliothèque
4. Répéter 5 fois et calculer la moyenne

**Critères de Réussite**:
- [ ] Démarrage < 2 secondes (moyenne)
- [ ] Écran de démarrage affiché pendant le chargement
- [ ] Interface réactive immédiatement après le chargement
- [ ] Aucun crash au démarrage

### 9.4 Utilisation de la Mémoire

**Objectif**: Mesurer et surveiller l'utilisation de la mémoire

**Procédure**:
1. Utiliser Android Profiler pour surveiller la mémoire
2. Naviguer entre tous les écrans
3. Jouer plusieurs pistes
4. Charger plusieurs playlists
5. Observer l'utilisation de la mémoire sur 30 minutes

**Commandes ADB**:
```bash
# Mémoire actuelle
adb shell dumpsys meminfo com.example.basspro_player | grep TOTAL

# Surveiller en continu
adb shell dumpsys meminfo com.example.basspro_player | grep TOTAL
```

**Critères de Réussite**:
- [ ] Utilisation mémoire < 150 MB en utilisation normale
- [ ] Pas d'augmentation continue de la mémoire (fuites)
- [ ] Mémoire stable après 30 minutes d'utilisation
- [ ] Pas de OutOfMemoryError
- [ ] Cache d'images limité à 100 images

### 9.5 Utilisation de la Batterie

**Objectif**: Mesurer l'impact sur la batterie

**Procédure**:
1. Charger l'appareil à 100%
2. Lancer la lecture en boucle pendant 2 heures
3. Mesurer la consommation de batterie
4. Comparer avec d'autres lecteurs audio

**Commandes ADB**:
```bash
# Réinitialiser les statistiques
adb shell dumpsys batterystats --reset

# Après 2 heures, obtenir les statistiques
adb shell dumpsys batterystats com.example.basspro_player
```

**Critères de Réussite**:
- [ ] Consommation raisonnable (< 10% par heure de lecture)
- [ ] Pas de drain excessif en arrière-plan
- [ ] Comparable aux autres lecteurs audio
- [ ] Pas de réveil excessif du CPU


---

## Section 10: Tests de Stabilité

### 10.1 Test de Lecture Prolongée

**Objectif**: Vérifier la stabilité pendant une lecture prolongée

**Procédure**:
1. Créer une playlist de 50+ pistes
2. Lancer la lecture en mode répéter tout
3. Laisser jouer pendant 4 heures
4. Vérifier périodiquement l'état de l'application

**Critères de Réussite**:
- [ ] Lecture continue sans interruption pendant 4+ heures
- [ ] Aucun crash
- [ ] Aucune fuite de mémoire
- [ ] Notification reste fonctionnelle
- [ ] Contrôles restent réactifs
- [ ] Utilisation mémoire stable

### 10.2 Test de Stress

**Objectif**: Tester l'application sous charge

**Procédure**:
1. Charger une bibliothèque de 10 000+ pistes
2. Effectuer des actions rapides et répétées:
   - Changer de piste rapidement (10 fois)
   - Ouvrir/fermer l'égaliseur rapidement (10 fois)
   - Changer de thème rapidement (5 fois)
   - Ajouter/supprimer des favoris rapidement (20 fois)
3. Observer la stabilité

**Critères de Réussite**:
- [ ] Aucun crash pendant les actions rapides
- [ ] Interface reste réactive
- [ ] Aucune corruption de données
- [ ] Aucun blocage de l'interface
- [ ] Récupération gracieuse des erreurs

### 10.3 Détection de Fuites Mémoire

**Objectif**: Détecter les fuites de mémoire

**Procédure**:
1. Utiliser Android Profiler
2. Naviguer entre tous les écrans 10 fois
3. Forcer le garbage collection
4. Observer les objets non libérés
5. Utiliser LeakCanary si intégré

**Commandes ADB**:
```bash
# Dump heap
adb shell am dumpheap com.example.basspro_player /data/local/tmp/heap.hprof
adb pull /data/local/tmp/heap.hprof
# Analyser avec Android Studio Memory Profiler
```

**Critères de Réussite**:
- [ ] Aucune fuite de mémoire détectée
- [ ] Objets correctement libérés après navigation
- [ ] Streams et listeners fermés correctement
- [ ] Pas d'accumulation d'objets en mémoire


---

## Section 11: Tests de Compatibilité

### 11.1 Tests Multi-Versions Android

**Objectif**: Vérifier la compatibilité sur différentes versions Android

**Matrice de Test**:

| Fonctionnalité | Android 5.0 | Android 8.0 | Android 10 | Android 12 | Android 14 |
|----------------|-------------|-------------|------------|------------|------------|
| Installation | ☐ | ☐ | ☐ | ☐ | ☐ |
| Scan bibliothèque | ☐ | ☐ | ☐ | ☐ | ☐ |
| Lecture audio | ☐ | ☐ | ☐ | ☐ | ☐ |
| Lecture arrière-plan | ☐ | ☐ | ☐ | ☐ | ☐ |
| Notification | ☐ | ☐ | ☐ | ☐ | ☐ |
| Égaliseur | ☐ | ☐ | ☐ | ☐ | ☐ |
| Streaming | ☐ | ☐ | ☐ | ☐ | ☐ |
| Permissions | ☐ | ☐ | ☐ | ☐ | ☐ |

**Points d'Attention Spécifiques**:
- **Android 5.0-9.0**: Permission READ_EXTERNAL_STORAGE requise
- **Android 10+**: Scoped storage, pas de permission requise
- **Android 12+**: Notification permission, exact alarm permission
- **Android 14**: Nouvelles restrictions de permissions

### 11.2 Tests Multi-Tailles d'Écran

**Objectif**: Vérifier l'interface sur différentes tailles d'écran

**Configurations à Tester**:
- Petit téléphone (< 5")
- Téléphone standard (5-6")
- Grand téléphone (6-7")
- Tablette 7"
- Tablette 10"

**Critères de Réussite**:
- [ ] Interface adaptée à toutes les tailles
- [ ] Texte lisible sur petits écrans
- [ ] Pas de débordement d'interface
- [ ] Boutons suffisamment grands pour être touchés
- [ ] Pochettes d'album bien dimensionnées
- [ ] Égaliseur utilisable sur petits écrans

### 11.3 Tests de Formats Audio

**Objectif**: Vérifier la compatibilité des formats audio

**Formats à Tester**:
- MP3 (128kbps, 320kbps)
- AAC
- FLAC
- OGG Vorbis
- WAV
- M4A

**Critères de Réussite**:
- [ ] Tous les formats supportés se lisent correctement
- [ ] Métadonnées extraites correctement
- [ ] Pochettes affichées correctement
- [ ] Égaliseur fonctionne avec tous les formats
- [ ] Aucune distorsion audio


---

## Section 12: Tests de Localisation

### 12.1 Vérification des Chaînes Françaises

**Objectif**: Vérifier que toutes les chaînes sont en français correct

**Procédure**:
1. Parcourir tous les écrans de l'application
2. Vérifier chaque label, bouton, message
3. Vérifier l'orthographe et la grammaire
4. Vérifier la cohérence terminologique

**Écrans à Vérifier**:
- [ ] Écran Bibliothèque (onglets, tri, recherche)
- [ ] Écran Streaming (ajouter, modifier, catégories)
- [ ] Écran Playlists (créer, renommer, supprimer)
- [ ] Écran Paramètres (toutes les options)
- [ ] Écran Lecture en cours (contrôles, actions)
- [ ] Écran Égaliseur (bandes, préréglages, limiteur)
- [ ] Mini lecteur
- [ ] Dialogues (confirmation, erreur, saisie)
- [ ] Messages d'erreur
- [ ] Notifications
- [ ] Écran de verrouillage

**Termes Clés à Vérifier**:
- Bibliothèque (pas Library)
- Lecture (pas Play)
- Piste (pas Track)
- Égaliseur (pas Equalizer)
- Préréglage (pas Preset)
- Aléatoire (pas Shuffle)
- Répéter (pas Repeat)
- Favori (pas Favorite)

### 12.2 Formatage et Conventions

**Objectif**: Vérifier le formatage correct

**Critères de Réussite**:
- [ ] Durées au format MM:SS
- [ ] Dates au format français (JJ/MM/AAAA)
- [ ] Nombres avec séparateurs corrects (espace pour milliers)
- [ ] Majuscules appropriées
- [ ] Ponctuation correcte
- [ ] Pas de texte tronqué

---

## Section 13: Tests de Gestion d'Erreurs

### 13.1 Erreurs Réseau

**Objectif**: Vérifier la gestion des erreurs réseau

**Scénarios à Tester**:
1. Streaming sans connexion Internet
2. Streaming avec connexion lente
3. Perte de connexion pendant le streaming
4. Timeout de connexion

**Critères de Réussite**:
- [ ] Message d'erreur clair en français
- [ ] Option de réessai disponible
- [ ] Pas de crash
- [ ] Retour gracieux à l'état précédent
- [ ] Notification d'erreur si en arrière-plan


### 13.2 Erreurs de Fichiers

**Objectif**: Vérifier la gestion des erreurs de fichiers

**Scénarios à Tester**:
1. Fichier audio supprimé pendant la lecture
2. Fichier audio corrompu
3. Fichier avec métadonnées manquantes
4. Stockage plein lors de la sauvegarde

**Critères de Réussite**:
- [ ] Message d'erreur approprié
- [ ] Passage automatique à la piste suivante si fichier manquant
- [ ] Affichage de placeholder pour métadonnées manquantes
- [ ] Gestion gracieuse des fichiers corrompus
- [ ] Pas de crash

### 13.3 Erreurs de Base de Données

**Objectif**: Vérifier la gestion des erreurs de base de données

**Scénarios à Tester**:
1. Base de données corrompue
2. Échec d'écriture
3. Contraintes violées

**Critères de Réussite**:
- [ ] Récupération automatique si possible
- [ ] Message d'erreur si récupération impossible
- [ ] Option de réinitialisation de la base de données
- [ ] Pas de perte de données critiques
- [ ] Logs d'erreur pour débogage

---

## Section 14: Tests de Régression

### 14.1 Checklist de Régression Rapide

**Objectif**: Vérifier rapidement les fonctionnalités principales

**Durée Estimée**: 15 minutes

**Procédure Rapide**:
1. [ ] Lancer l'application
2. [ ] Vérifier que la bibliothèque se charge
3. [ ] Jouer une piste
4. [ ] Tester lecture/pause/suivant/précédent
5. [ ] Ouvrir l'égaliseur et ajuster une bande
6. [ ] Créer une playlist et ajouter des pistes
7. [ ] Ajouter une source de streaming et la jouer
8. [ ] Changer le thème
9. [ ] Mettre l'app en arrière-plan et vérifier la notification
10. [ ] Revenir à l'app et arrêter la lecture

**Critères de Réussite**:
- [ ] Toutes les étapes complétées sans erreur
- [ ] Aucun crash
- [ ] Interface réactive


---

## Annexe A: Modèle de Rapport de Bug

### Informations Générales

**ID du Bug**: [Numéro unique]
**Date**: [JJ/MM/AAAA]
**Testeur**: [Nom]
**Priorité**: [ ] Critique [ ] Haute [ ] Moyenne [ ] Basse
**Statut**: [ ] Nouveau [ ] En cours [ ] Résolu [ ] Fermé

### Environnement

**Appareil**: [Marque et modèle]
**Version Android**: [Ex: Android 12]
**Version de l'App**: [Ex: 1.0.0]
**Taille de Bibliothèque**: [Nombre de pistes]

### Description du Bug

**Titre**: [Titre court et descriptif]

**Description Détaillée**:
[Description complète du problème]

**Étapes pour Reproduire**:
1. [Étape 1]
2. [Étape 2]
3. [Étape 3]

**Résultat Attendu**:
[Ce qui devrait se passer]

**Résultat Actuel**:
[Ce qui se passe réellement]

**Fréquence**:
[ ] Toujours [ ] Souvent [ ] Parfois [ ] Rare

### Informations Supplémentaires

**Captures d'Écran**: [Joindre si applicable]

**Logs**:
```
[Coller les logs pertinents]
```

**Notes**:
[Toute information supplémentaire utile]

---

## Annexe B: Checklist de Test Complète

### Résumé des Tests

| Section | Tests | Complétés | Échoués | Notes |
|---------|-------|-----------|---------|-------|
| 1. Configuration Initiale | 2 | ☐ | ☐ | |
| 2. Navigation et Interface | 3 | ☐ | ☐ | |
| 3. Bibliothèque Musicale | 4 | ☐ | ☐ | |
| 4. Lecture Audio | 5 | ☐ | ☐ | |
| 5. Égaliseur | 4 | ☐ | ☐ | |
| 6. Streaming | 2 | ☐ | ☐ | |
| 7. Playlists | 3 | ☐ | ☐ | |
| 8. Paramètres | 3 | ☐ | ☐ | |
| 9. Performance | 5 | ☐ | ☐ | |
| 10. Stabilité | 3 | ☐ | ☐ | |
| 11. Compatibilité | 3 | ☐ | ☐ | |
| 12. Localisation | 2 | ☐ | ☐ | |
| 13. Gestion d'Erreurs | 3 | ☐ | ☐ | |
| 14. Régression | 1 | ☐ | ☐ | |
| **TOTAL** | **43** | **☐** | **☐** | |


---

## Annexe C: Procédures de Test de Performance

### C.1 Mesure du Temps de Démarrage

**Script de Test**:
```bash
#!/bin/bash
# test_startup_time.sh

APP_PACKAGE="com.example.basspro_player"
ITERATIONS=5

echo "Test de temps de démarrage - $ITERATIONS itérations"
echo "================================================"

total_time=0

for i in $(seq 1 $ITERATIONS); do
    echo "Itération $i..."
    
    # Forcer l'arrêt de l'app
    adb shell am force-stop $APP_PACKAGE
    sleep 2
    
    # Lancer l'app et mesurer le temps
    start_time=$(date +%s%3N)
    adb shell am start -W -n $APP_PACKAGE/.MainActivity | grep "TotalTime" | awk '{print $2}'
    
    # Attendre que l'app soit complètement chargée
    sleep 3
done

echo "================================================"
echo "Test terminé"
```

### C.2 Mesure de l'Utilisation Mémoire

**Script de Surveillance**:
```bash
#!/bin/bash
# monitor_memory.sh

APP_PACKAGE="com.example.basspro_player"
DURATION=1800  # 30 minutes
INTERVAL=60    # Échantillonnage toutes les 60 secondes

echo "Surveillance mémoire - Durée: ${DURATION}s, Intervalle: ${INTERVAL}s"
echo "Timestamp,Total(KB),Native(KB),Dalvik(KB)" > memory_log.csv

elapsed=0
while [ $elapsed -lt $DURATION ]; do
    timestamp=$(date +%s)
    memory=$(adb shell dumpsys meminfo $APP_PACKAGE | grep "TOTAL")
    
    # Extraire les valeurs
    total=$(echo $memory | awk '{print $2}')
    native=$(echo $memory | awk '{print $3}')
    dalvik=$(echo $memory | awk '{print $4}')
    
    echo "$timestamp,$total,$native,$dalvik" >> memory_log.csv
    echo "[$elapsed s] Mémoire totale: $total KB"
    
    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
done

echo "Surveillance terminée. Résultats dans memory_log.csv"
```

### C.3 Test de Performance de Défilement

**Procédure Manuelle**:
1. Ouvrir Android Studio Profiler
2. Sélectionner l'application BassPro Player
3. Activer le profiling CPU
4. Dans l'app, naviguer vers la bibliothèque avec 10 000+ pistes
5. Défiler rapidement de haut en bas pendant 30 secondes
6. Arrêter le profiling
7. Analyser:
   - Frame rendering time (doit être < 16ms pour 60 FPS)
   - Méthodes les plus coûteuses
   - Temps passé dans le thread UI

**Critères de Réussite**:
- 95% des frames rendues en < 16ms
- Aucune frame > 32ms (frame drop)
- Temps UI thread < 80% du temps total


### C.4 Test de Batterie

**Procédure**:
```bash
#!/bin/bash
# battery_test.sh

APP_PACKAGE="com.example.basspro_player"

echo "Test de consommation batterie"
echo "=============================="

# Réinitialiser les statistiques
echo "Réinitialisation des statistiques de batterie..."
adb shell dumpsys batterystats --reset
adb shell dumpsys batterystats --enable full-wake-history

# Obtenir le niveau de batterie initial
initial_battery=$(adb shell dumpsys battery | grep level | awk '{print $2}')
echo "Niveau de batterie initial: $initial_battery%"

echo ""
echo "Lancer la lecture dans l'app maintenant."
echo "Appuyez sur Entrée quand la lecture est lancée..."
read

start_time=$(date +%s)
echo "Test démarré à $(date)"
echo ""
echo "Laissez l'app jouer pendant 2 heures..."
echo "Le test se terminera automatiquement."

# Attendre 2 heures (7200 secondes)
sleep 7200

end_time=$(date +%s)
duration=$((end_time - start_time))

# Obtenir le niveau de batterie final
final_battery=$(adb shell dumpsys battery | grep level | awk '{print $2}')
battery_used=$((initial_battery - final_battery))

echo ""
echo "=============================="
echo "Test terminé"
echo "Durée: $((duration / 3600))h $((duration % 3600 / 60))m"
echo "Batterie initiale: $initial_battery%"
echo "Batterie finale: $final_battery%"
echo "Batterie consommée: $battery_used%"
echo "Consommation par heure: $(echo "scale=2; $battery_used / ($duration / 3600)" | bc)%/h"

# Obtenir les statistiques détaillées
echo ""
echo "Génération du rapport détaillé..."
adb shell dumpsys batterystats $APP_PACKAGE > battery_stats.txt
echo "Rapport sauvegardé dans battery_stats.txt"
```

---

## Annexe D: Checklist de Validation Finale

### Avant la Release

**Documentation**:
- [ ] README.md complet et à jour
- [ ] CHANGELOG.md avec notes de version 1.0.0
- [ ] Guide utilisateur en français complet
- [ ] Documentation de build et déploiement

**Code**:
- [ ] Tous les tests unitaires passent
- [ ] Tous les tests d'intégration passent
- [ ] Aucun warning de compilation
- [ ] Code ProGuard/R8 configuré
- [ ] Aucun TODO ou FIXME critique dans le code

**Build**:
- [ ] Version number mis à jour (1.0.0)
- [ ] Keystore de release généré et sécurisé
- [ ] APK release construit et testé
- [ ] App Bundle construit et testé
- [ ] Taille de l'APK raisonnable (< 50 MB)

**Tests**:
- [ ] Tous les tests de ce plan complétés
- [ ] Testé sur Android 5.0, 8.0, 10, 12, 14
- [ ] Testé sur téléphone et tablette
- [ ] Testé avec grande bibliothèque (10 000+ pistes)
- [ ] Aucun bug critique non résolu
- [ ] Performance conforme aux objectifs

**Localisation**:
- [ ] Toutes les chaînes en français
- [ ] Orthographe et grammaire vérifiées
- [ ] Formatage correct (dates, nombres, durées)
- [ ] Aucun texte tronqué

**Qualité**:
- [ ] Aucune fuite de mémoire détectée
- [ ] Utilisation batterie acceptable
- [ ] Lecture stable pendant 4+ heures
- [ ] Aucun crash pendant les tests
- [ ] Gestion d'erreurs robuste


---

## Annexe E: Critères d'Acceptation de Release

### Critères Obligatoires (Bloquants)

Ces critères DOIVENT être satisfaits avant la release:

1. **Stabilité**:
   - [ ] Aucun crash pendant les tests de base
   - [ ] Lecture stable pendant 4+ heures
   - [ ] Aucune fuite de mémoire critique

2. **Fonctionnalités Principales**:
   - [ ] Scan et affichage de bibliothèque fonctionnent
   - [ ] Lecture audio locale fonctionne
   - [ ] Lecture en arrière-plan fonctionne
   - [ ] Notification et contrôles fonctionnent
   - [ ] Égaliseur fonctionne

3. **Performance**:
   - [ ] Démarrage < 3 secondes
   - [ ] Défilement fluide (pas de saccades majeures)
   - [ ] Utilisation mémoire < 200 MB

4. **Compatibilité**:
   - [ ] Fonctionne sur Android 5.0 minimum
   - [ ] Fonctionne sur Android 14
   - [ ] Permissions gérées correctement

5. **Localisation**:
   - [ ] Interface principale en français
   - [ ] Aucune chaîne anglaise visible

### Critères Recommandés (Non-Bloquants)

Ces critères sont souhaitables mais pas bloquants:

1. **Performance Optimale**:
   - [ ] Démarrage < 2 secondes
   - [ ] Défilement à 60 FPS constant
   - [ ] Requêtes < 100ms

2. **Fonctionnalités Avancées**:
   - [ ] Streaming fonctionne parfaitement
   - [ ] Tous les préréglages d'égaliseur disponibles
   - [ ] Playlists intelligentes fonctionnent

3. **Polish**:
   - [ ] Animations fluides
   - [ ] Transitions élégantes
   - [ ] Interface cohérente

### Seuils de Bugs Acceptables

**Pour la Release 1.0.0**:
- Bugs critiques: 0
- Bugs haute priorité: 0-2
- Bugs moyenne priorité: 0-5
- Bugs basse priorité: Illimité

**Définitions**:
- **Critique**: Crash, perte de données, fonctionnalité principale cassée
- **Haute**: Fonctionnalité importante ne fonctionne pas correctement
- **Moyenne**: Problème mineur affectant l'expérience utilisateur
- **Basse**: Problème cosmétique ou cas limite rare

---

## Annexe F: Calendrier de Test Suggéré

### Phase 1: Tests Fonctionnels (Jours 1-3)

**Jour 1**:
- Configuration initiale et installation
- Navigation et interface
- Bibliothèque musicale

**Jour 2**:
- Lecture audio
- Égaliseur
- Streaming

**Jour 3**:
- Playlists
- Paramètres
- Localisation

### Phase 2: Tests de Performance (Jour 4)

- Performance de défilement
- Performance de requêtes
- Temps de démarrage
- Utilisation mémoire

### Phase 3: Tests de Stabilité (Jours 5-6)

**Jour 5**:
- Test de lecture prolongée (4 heures)
- Test de stress

**Jour 6**:
- Test de batterie (2 heures)
- Détection de fuites mémoire

### Phase 4: Tests de Compatibilité (Jour 7)

- Tests multi-versions Android
- Tests multi-tailles d'écran
- Tests de formats audio

### Phase 5: Tests de Régression et Validation (Jour 8)

- Tests de gestion d'erreurs
- Tests de régression
- Validation finale
- Rapport de test

**Durée Totale Estimée**: 8 jours de test

---

## Conclusion

Ce plan de test fournit une couverture complète pour valider BassPro Player avant la release. Les testeurs doivent:

1. Suivre les procédures de test dans l'ordre
2. Documenter tous les bugs trouvés avec le modèle fourni
3. Vérifier tous les critères d'acceptation
4. Compléter la checklist de validation finale

**Contact pour Questions**:
[Ajouter les informations de contact de l'équipe de développement]

**Bonne chance avec les tests!** 🎵🎸
