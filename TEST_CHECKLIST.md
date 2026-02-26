# Checklist de Test Rapide - BassPro Player

## Informations de Test

**Date**: _______________
**Testeur**: _______________
**Appareil**: _______________
**Version Android**: _______________
**Version App**: _______________

---

## Tests Essentiels (15 minutes)

### Installation et Démarrage
- [ ] Installation réussie
- [ ] Premier lancement sans crash
- [ ] Permissions accordées
- [ ] Bibliothèque chargée

### Navigation
- [ ] Onglet Bibliothèque fonctionne
- [ ] Onglet Streaming fonctionne
- [ ] Onglet Playlists fonctionne
- [ ] Onglet Paramètres fonctionne

### Lecture de Base
- [ ] Jouer une piste
- [ ] Pause fonctionne
- [ ] Suivant fonctionne
- [ ] Précédent fonctionne
- [ ] Barre de progression fonctionne

### Mini Lecteur
- [ ] Apparaît pendant la lecture
- [ ] Visible sur tous les onglets
- [ ] Ouvre l'écran Lecture en cours

### Lecture en Arrière-Plan
- [ ] Continue en arrière-plan
- [ ] Notification affichée
- [ ] Contrôles de notification fonctionnent

### Égaliseur
- [ ] Écran s'ouvre
- [ ] Curseurs fonctionnent
- [ ] Changements audibles
- [ ] Préréglages fonctionnent

### Interface Française
- [ ] Tous les textes en français
- [ ] Aucune chaîne anglaise visible

---

## Tests Complets (2 heures)

### Bibliothèque (15 min)
- [ ] Scan détecte toutes les pistes
- [ ] Métadonnées correctes
- [ ] Pochettes affichées
- [ ] Recherche fonctionne
- [ ] Tri fonctionne (5 options)
- [ ] Favoris fonctionnent
- [ ] Récemment joués fonctionne
- [ ] Les plus écoutés fonctionne

### Lecture Audio (20 min)
- [ ] Lecture/pause
- [ ] Suivant/précédent
- [ ] Seek fonctionne
- [ ] Aléatoire fonctionne
- [ ] Répéter tout fonctionne
- [ ] Répéter une fonctionne
- [ ] File d'attente fonctionne
- [ ] Ajouter à la file fonctionne
- [ ] Réorganiser la file fonctionne
- [ ] Vider la file fonctionne

### Lecture en Arrière-Plan (15 min)
- [ ] Continue en arrière-plan
- [ ] Notification complète
- [ ] Contrôles notification fonctionnent
- [ ] Écran de verrouillage fonctionne
- [ ] Boutons écouteurs fonctionnent
- [ ] Appel téléphonique gère correctement
- [ ] Stable pendant 30 minutes

### Égaliseur (15 min)
- [ ] 10 bandes fonctionnent
- [ ] Préampli fonctionne
- [ ] Sub-bass fonctionne
- [ ] Bass fonctionne
- [ ] Limiteur fonctionne
- [ ] 8 préréglages intégrés
- [ ] Créer préréglage personnalisé
- [ ] Supprimer préréglage personnalisé
- [ ] Avertissement écrêtage fonctionne
- [ ] Changements en temps réel

### Streaming (15 min)
- [ ] Ajouter source fonctionne
- [ ] Modifier source fonctionne
- [ ] Supprimer source fonctionne
- [ ] Marquer favori fonctionne
- [ ] Lecture streaming fonctionne
- [ ] Indicateur mise en mémoire tampon
- [ ] Erreur URL invalide gérée
- [ ] Perte réseau gérée
- [ ] Historique enregistré
- [ ] Récemment joués affichés

### Playlists (15 min)
- [ ] Créer playlist fonctionne
- [ ] Ajouter pistes fonctionne
- [ ] Réorganiser pistes fonctionne
- [ ] Supprimer pistes fonctionne
- [ ] Renommer playlist fonctionne
- [ ] Supprimer playlist fonctionne
- [ ] Jouer playlist fonctionne
- [ ] Playlist Favoris fonctionne
- [ ] Playlist Récemment ajoutés fonctionne
- [ ] Playlist Les plus écoutés fonctionne

### Paramètres (10 min)
- [ ] Changer thème fonctionne
- [ ] Thème persiste
- [ ] Rescan bibliothèque fonctionne
- [ ] Minuterie sommeil fonctionne
- [ ] Annuler minuterie fonctionne
- [ ] Garder écran allumé fonctionne
- [ ] Préréglage par défaut fonctionne

### Gestion d'Erreurs (10 min)
- [ ] Fichier manquant géré
- [ ] Streaming sans réseau géré
- [ ] URL invalide gérée
- [ ] Permissions refusées gérées
- [ ] Messages d'erreur en français

---

## Tests de Performance (1 heure)

### Défilement (10 min)
- [ ] Fluide avec 100 pistes
- [ ] Fluide avec 1000 pistes
- [ ] Fluide avec 10000+ pistes
- [ ] Aucune saccade visible
- [ ] Pochettes se chargent progressivement

### Temps de Réponse (10 min)
- [ ] Démarrage < 2 secondes
- [ ] Recherche < 100ms
- [ ] Chargement favoris < 100ms
- [ ] Chargement playlist < 100ms
- [ ] Changement de piste < 100ms

### Mémoire (20 min)
- [ ] Utilisation < 150 MB normale
- [ ] Stable après 30 min utilisation
- [ ] Pas d'augmentation continue
- [ ] Aucune fuite détectée

### Batterie (20 min)
- [ ] Consommation raisonnable
- [ ] Pas de drain excessif
- [ ] Comparable autres lecteurs

---

## Tests de Stabilité (4 heures)

### Lecture Prolongée
- [ ] Stable pendant 1 heure
- [ ] Stable pendant 2 heures
- [ ] Stable pendant 4 heures
- [ ] Aucun crash
- [ ] Mémoire stable
- [ ] Contrôles restent réactifs

### Test de Stress
- [ ] Changements rapides de piste (10x)
- [ ] Ouvrir/fermer égaliseur (10x)
- [ ] Changer thème (5x)
- [ ] Ajouter/supprimer favoris (20x)
- [ ] Aucun crash
- [ ] Interface reste réactive

---

## Tests de Compatibilité

### Android 5.0 (API 21)
- [ ] Installation
- [ ] Scan bibliothèque
- [ ] Lecture audio
- [ ] Lecture arrière-plan
- [ ] Notification
- [ ] Égaliseur
- [ ] Permission READ_EXTERNAL_STORAGE

### Android 8.0 (API 26)
- [ ] Installation
- [ ] Scan bibliothèque
- [ ] Lecture audio
- [ ] Lecture arrière-plan
- [ ] Notification
- [ ] Égaliseur

### Android 10 (API 29)
- [ ] Installation
- [ ] Scan bibliothèque (scoped storage)
- [ ] Lecture audio
- [ ] Lecture arrière-plan
- [ ] Notification
- [ ] Égaliseur
- [ ] Pas de permission stockage requise

### Android 12 (API 31)
- [ ] Installation
- [ ] Scan bibliothèque
- [ ] Lecture audio
- [ ] Lecture arrière-plan
- [ ] Notification
- [ ] Égaliseur

### Android 14 (API 34)
- [ ] Installation
- [ ] Scan bibliothèque
- [ ] Lecture audio
- [ ] Lecture arrière-plan
- [ ] Notification
- [ ] Égaliseur

### Tailles d'Écran
- [ ] Petit téléphone (< 5")
- [ ] Téléphone standard (5-6")
- [ ] Grand téléphone (6-7")
- [ ] Tablette 7"
- [ ] Tablette 10"

---

## Validation Finale

### Critères Bloquants
- [ ] Aucun crash pendant tests de base
- [ ] Lecture stable 4+ heures
- [ ] Aucune fuite mémoire critique
- [ ] Scan bibliothèque fonctionne
- [ ] Lecture audio fonctionne
- [ ] Lecture arrière-plan fonctionne
- [ ] Notification fonctionne
- [ ] Égaliseur fonctionne
- [ ] Fonctionne Android 5.0+
- [ ] Interface en français

### Bugs Trouvés
**Critiques**: _____ (Max: 0)
**Haute priorité**: _____ (Max: 2)
**Moyenne priorité**: _____ (Max: 5)
**Basse priorité**: _____

### Recommandation
- [ ] **APPROUVÉ** pour release
- [ ] **APPROUVÉ AVEC RÉSERVES** (bugs mineurs)
- [ ] **REJETÉ** (bugs critiques)

**Commentaires**:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**Signature**: _______________  **Date**: _______________
