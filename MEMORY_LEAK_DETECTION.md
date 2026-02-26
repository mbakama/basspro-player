# Guide de Détection des Fuites Mémoire - BassPro Player

## Vue d'ensemble

Ce guide explique comment détecter et analyser les fuites de mémoire dans BassPro Player en utilisant les outils Android.

## Outils Requis

1. **Android Studio** avec Android Profiler
2. **ADB** (Android Debug Bridge)
3. **MAT** (Memory Analyzer Tool) - optionnel pour analyse avancée

---

## Méthode 1: Android Studio Profiler

### Étape 1: Démarrer le Profiling

1. Ouvrir Android Studio
2. Connecter l'appareil de test
3. Lancer BassPro Player
4. Ouvrir **View > Tool Windows > Profiler**
5. Sélectionner l'appareil et le processus `com.example.basspro_player`
6. Cliquer sur **Memory** pour démarrer le profiling mémoire

### Étape 2: Scénario de Test

Effectuer les actions suivantes pour tester les fuites:

**Test de Navigation**:
1. Noter la mémoire de base
2. Naviguer: Bibliothèque → Streaming → Playlists → Paramètres
3. Répéter 10 fois
4. Forcer le garbage collection (icône poubelle)
5. Observer si la mémoire revient au niveau de base

**Test de Lecture**:
1. Noter la mémoire de base
2. Lancer la lecture d'une piste
3. Ouvrir l'écran Lecture en cours
4. Fermer l'écran
5. Arrêter la lecture
6. Répéter 10 fois
7. Forcer le garbage collection
8. Observer la mémoire

**Test d'Égaliseur**:
1. Noter la mémoire de base
2. Ouvrir l'égaliseur
3. Ajuster plusieurs bandes
4. Fermer l'égaliseur
5. Répéter 10 fois
6. Forcer le garbage collection
7. Observer la mémoire

### Étape 3: Capturer un Heap Dump

1. Après les tests, cliquer sur **Dump Java heap** (icône de téléchargement)
2. Attendre que le dump soit capturé
3. Android Studio ouvrira automatiquement l'analyseur

### Étape 4: Analyser le Heap Dump

**Rechercher les Fuites Communes**:

1. **Activities non libérées**:
   - Chercher `MainActivity`, `NowPlayingScreen`, etc.
   - Vérifier le nombre d'instances
   - Devrait être 0-1 instance par Activity

2. **Providers non disposés**:
   - Chercher `StateNotifier`, `Provider`
   - Vérifier les listeners non fermés

3. **Streams non fermés**:
   - Chercher `StreamSubscription`, `StreamController`
   - Tous les streams doivent être fermés

4. **Audio Players non disposés**:
   - Chercher `AudioPlayer`, `AudioHandler`
   - Vérifier qu'ils sont correctement disposés

**Utiliser l'Analyseur**:
- Trier par **Retained Size** (taille retenue)
- Chercher les objets avec grande taille retenue
- Cliquer sur un objet et voir **References** pour comprendre pourquoi il est retenu

---

## Méthode 2: ADB et Ligne de Commande

### Capturer un Heap Dump

```bash
# Obtenir le PID de l'app
adb shell ps | grep basspro_player

# Ou directement
APP_PACKAGE="com.example.basspro_player"

# Capturer le heap dump
adb shell am dumpheap $APP_PACKAGE /data/local/tmp/heap.hprof

# Télécharger le fichier
adb pull /data/local/tmp/heap.hprof ./heap.hprof

# Nettoyer
adb shell rm /data/local/tmp/heap.hprof
```

### Convertir pour MAT

Le fichier heap.hprof d'Android doit être converti:

```bash
# Utiliser hprof-conv (dans Android SDK)
hprof-conv heap.hprof heap-converted.hprof
```

### Analyser avec MAT

1. Télécharger MAT: https://www.eclipse.org/mat/
2. Ouvrir le fichier converti
3. Sélectionner **Leak Suspects Report**
4. MAT identifiera automatiquement les fuites potentielles

---

## Méthode 3: Surveillance Continue

### Script de Surveillance Mémoire

```bash
#!/bin/bash
# monitor_memory_continuous.sh

APP_PACKAGE="com.example.basspro_player"
DURATION=3600  # 1 heure
INTERVAL=10    # Toutes les 10 secondes

echo "Surveillance mémoire continue"
echo "Timestamp,Total(KB),Native(KB),Dalvik(KB),Graphics(KB)" > memory_continuous.csv

elapsed=0
while [ $elapsed -lt $DURATION ]; do
    timestamp=$(date +%s)
    
    # Obtenir les infos mémoire
    meminfo=$(adb shell dumpsys meminfo $APP_PACKAGE | grep "TOTAL")
    
    if [ ! -z "$meminfo" ]; then
        total=$(echo $meminfo | awk '{print $2}')
        native=$(echo $meminfo | awk '{print $3}')
        dalvik=$(echo $meminfo | awk '{print $4}')
        graphics=$(echo $meminfo | awk '{print $8}')
        
        echo "$timestamp,$total,$native,$dalvik,$graphics" >> memory_continuous.csv
        echo "[$elapsed s] Total: $total KB"
    fi
    
    sleep $INTERVAL
    elapsed=$((elapsed + INTERVAL))
done

echo "Surveillance terminée"
```

### Analyser les Résultats

```python
# analyze_memory.py
import pandas as pd
import matplotlib.pyplot as plt

# Charger les données
df = pd.read_csv('memory_continuous.csv')

# Convertir timestamp en datetime
df['Time'] = pd.to_datetime(df['Timestamp'], unit='s')

# Tracer les graphiques
fig, axes = plt.subplots(2, 2, figsize=(15, 10))

# Total Memory
axes[0, 0].plot(df['Time'], df['Total(KB)'] / 1024)
axes[0, 0].set_title('Total Memory (MB)')
axes[0, 0].set_xlabel('Time')
axes[0, 0].set_ylabel('Memory (MB)')

# Native Memory
axes[0, 1].plot(df['Time'], df['Native(KB)'] / 1024, color='orange')
axes[0, 1].set_title('Native Memory (MB)')
axes[0, 1].set_xlabel('Time')
axes[0, 1].set_ylabel('Memory (MB)')

# Dalvik Memory
axes[1, 0].plot(df['Time'], df['Dalvik(KB)'] / 1024, color='green')
axes[1, 0].set_title('Dalvik Memory (MB)')
axes[1, 0].set_xlabel('Time')
axes[1, 0].set_ylabel('Memory (MB)')

# Graphics Memory
axes[1, 1].plot(df['Time'], df['Graphics(KB)'] / 1024, color='red')
axes[1, 1].set_title('Graphics Memory (MB)')
axes[1, 1].set_xlabel('Time')
axes[1, 1].set_ylabel('Memory (MB)')

plt.tight_layout()
plt.savefig('memory_analysis.png')
print("Graphique sauvegardé: memory_analysis.png")

# Statistiques
print("\n=== Statistiques Mémoire ===")
print(f"Total Memory:")
print(f"  Min: {df['Total(KB)'].min() / 1024:.2f} MB")
print(f"  Max: {df['Total(KB)'].max() / 1024:.2f} MB")
print(f"  Mean: {df['Total(KB)'].mean() / 1024:.2f} MB")
print(f"  Std: {df['Total(KB)'].std() / 1024:.2f} MB")

# Détecter les fuites (augmentation continue)
total_trend = df['Total(KB)'].diff().mean()
if total_trend > 10:  # Plus de 10 KB/échantillon
    print(f"\n⚠️  FUITE POTENTIELLE DÉTECTÉE!")
    print(f"   Tendance: +{total_trend:.2f} KB par échantillon")
else:
    print(f"\n✓ Pas de fuite évidente détectée")
    print(f"  Tendance: {total_trend:.2f} KB par échantillon")
```

---

## Fuites Communes à Vérifier

### 1. Listeners Non Supprimés

**Problème**:
```dart
// ❌ Mauvais
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    audioPlayer.positionStream.listen((position) {
      // Traiter la position
    });
  }
}
```

**Solution**:
```dart
// ✓ Bon
class MyWidget extends StatefulWidget {
  StreamSubscription? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = audioPlayer.positionStream.listen((position) {
      // Traiter la position
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

### 2. Controllers Non Disposés

**Problème**:
```dart
// ❌ Mauvais
class MyWidget extends StatefulWidget {
  final TextEditingController controller = TextEditingController();
}
```

**Solution**:
```dart
// ✓ Bon
class MyWidget extends StatefulWidget {
  final TextEditingController controller = TextEditingController();
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
```

### 3. Timers Non Annulés

**Problème**:
```dart
// ❌ Mauvais
Timer.periodic(Duration(seconds: 1), (timer) {
  // Mise à jour
});
```

**Solution**:
```dart
// ✓ Bon
Timer? _timer;

void startTimer() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    // Mise à jour
  });
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

### 4. Images Non Libérées

**Problème**: Cache d'images illimité

**Solution**: Utiliser un cache avec limite
```dart
final imageCache = ImageCache();
imageCache.maximumSize = 100;  // Max 100 images
imageCache.maximumSizeBytes = 50 * 1024 * 1024;  // Max 50 MB
```

---

## Checklist de Vérification

### Avant les Tests
- [ ] Build release configuré
- [ ] Appareil de test connecté
- [ ] Android Studio Profiler prêt
- [ ] Scripts de surveillance préparés

### Pendant les Tests
- [ ] Mémoire de base notée
- [ ] Scénarios de test exécutés
- [ ] Garbage collection forcé
- [ ] Heap dumps capturés

### Analyse
- [ ] Heap dumps analysés
- [ ] Graphiques de mémoire générés
- [ ] Tendances identifiées
- [ ] Fuites documentées

### Critères de Réussite
- [ ] Mémoire stable après GC
- [ ] Pas d'augmentation continue
- [ ] Utilisation < 150 MB normale
- [ ] Aucune Activity/Fragment retenu
- [ ] Tous les streams fermés
- [ ] Tous les controllers disposés

---

## Rapport de Fuite Mémoire

### Modèle de Rapport

**Date**: _______________
**Testeur**: _______________
**Version**: _______________

**Fuite Détectée**: [ ] Oui [ ] Non

**Détails**:
- **Type d'objet**: _______________
- **Nombre d'instances**: _______________
- **Taille retenue**: _______________ KB
- **Scénario de reproduction**: _______________

**Analyse**:
- **Cause probable**: _______________
- **Référence retenant l'objet**: _______________
- **Impact**: [ ] Critique [ ] Élevé [ ] Moyen [ ] Faible

**Recommandation**:
_______________________________________________
_______________________________________________

---

## Ressources

- [Android Memory Profiler](https://developer.android.com/studio/profile/memory-profiler)
- [MAT Documentation](https://www.eclipse.org/mat/documentation/)
- [Flutter Memory Management](https://flutter.dev/docs/testing/best-practices#memory-leaks)
