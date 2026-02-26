# Guide de Test de Batterie - BassPro Player

## Vue d'ensemble

Ce guide explique comment mesurer et analyser l'impact de BassPro Player sur la batterie de l'appareil.

## Objectifs

- Mesurer la consommation de batterie pendant la lecture
- Comparer avec d'autres lecteurs audio
- Identifier les sources de drain excessif
- Vérifier que la consommation est acceptable (< 10% par heure)

---

## Préparation

### Matériel Requis

- Appareil Android physique (pas d'émulateur)
- Câble USB pour ADB
- Ordinateur avec Android SDK

### Configuration de l'Appareil

1. **Charger à 100%**
2. **Désactiver les optimisations**:
   - Désactiver le Wi-Fi (sauf si test de streaming)
   - Désactiver les données mobiles (sauf si test de streaming)
   - Désactiver le Bluetooth (sauf si test avec écouteurs BT)
   - Désactiver la synchronisation automatique
   - Régler la luminosité à 50%
   - Désactiver les autres apps en arrière-plan

3. **Réinitialiser les statistiques**:
```bash
adb shell dumpsys batterystats --reset
adb shell dumpsys batterystats --enable full-wake-history
```

---

## Test 1: Lecture Locale Standard

### Objectif
Mesurer la consommation pendant la lecture de fichiers locaux

### Procédure

1. **Préparer la playlist**:
   - Créer une playlist de 50+ pistes
   - Durée totale: 3+ heures
   - Format: MP3 320kbps

2. **Configuration de lecture**:
   - Mode: Répéter tout
   - Égaliseur: Désactivé (test de base)
   - Volume: 50%
   - Écran: Éteint après 30 secondes

3. **Lancer le test**:
```bash
#!/bin/bash
# battery_test_local.sh

APP_PACKAGE="com.example.basspro_player"

echo "=== Test de Batterie - Lecture Locale ==="
echo "Date: $(date)"
echo ""

# Niveau initial
initial=$(adb shell dumpsys battery | grep level | awk '{print $2}')
echo "Niveau initial: $initial%"
echo ""

echo "Lancez la lecture dans l'app maintenant."
echo "Appuyez sur Entrée quand prêt..."
read

start_time=$(date +%s)
echo "Test démarré à $(date)"
echo ""

# Surveiller pendant 2 heures
duration=7200
interval=300  # Toutes les 5 minutes

echo "Timestamp,Battery(%),Temp(°C)" > battery_local.csv

elapsed=0
while [ $elapsed -lt $duration ]; do
    timestamp=$(date +%s)
    battery=$(adb shell dumpsys battery | grep level | awk '{print $2}')
    temp=$(adb shell dumpsys battery | grep temperature | awk '{print $2}')
    temp_c=$(echo "scale=1; $temp / 10" | bc)
    
    echo "$timestamp,$battery,$temp_c" >> battery_local.csv
    echo "[$((elapsed/60)) min] Batterie: $battery%, Temp: $temp_c°C"
    
    sleep $interval
    elapsed=$((elapsed + interval))
done

# Résultats finaux
final=$(adb shell dumpsys battery | grep level | awk '{print $2}')
consumed=$((initial - final))
rate=$(echo "scale=2; $consumed / 2" | bc)

echo ""
echo "=== Résultats ==="
echo "Durée: 2 heures"
echo "Batterie initiale: $initial%"
echo "Batterie finale: $final%"
echo "Consommation: $consumed%"
echo "Taux: $rate%/heure"
echo ""

# Statistiques détaillées
adb shell dumpsys batterystats $APP_PACKAGE > battery_stats_local.txt
echo "Statistiques détaillées: battery_stats_local.txt"
```

4. **Critères de réussite**:
   - Consommation < 10% par heure
   - Température < 40°C
   - Pas de drain excessif en veille

---

## Test 2: Lecture avec Égaliseur

### Objectif
Mesurer l'impact de l'égaliseur sur la batterie

### Procédure

1. **Configuration**:
   - Même playlist que Test 1
   - Égaliseur: Activé avec préréglage "Deep Bass"
   - Limiteur: Activé
   - Autres paramètres identiques

2. **Lancer le test**:
```bash
#!/bin/bash
# battery_test_equalizer.sh

# Même script que battery_test_local.sh
# Mais avec fichier de sortie battery_equalizer.csv
```

3. **Comparer avec Test 1**:
   - Différence de consommation
   - Impact de l'égaliseur
   - Acceptable si < 2% supplémentaire par heure

---

## Test 3: Lecture en Streaming

### Objectif
Mesurer la consommation pendant le streaming

### Procédure

1. **Configuration**:
   - Activer le Wi-Fi
   - Source de streaming: Radio en ligne (AAC 128kbps)
   - Égaliseur: Désactivé
   - Volume: 50%

2. **Lancer le test**:
```bash
#!/bin/bash
# battery_test_streaming.sh

# Même structure que battery_test_local.sh
# Fichier de sortie: battery_streaming.csv
```

3. **Critères de réussite**:
   - Consommation < 15% par heure (réseau inclus)
   - Stable pendant 2 heures
   - Pas de reconnexions excessives

---

## Test 4: Lecture en Arrière-Plan

### Objectif
Vérifier que la consommation reste raisonnable en arrière-plan

### Procédure

1. **Configuration**:
   - Lancer la lecture
   - Mettre l'app en arrière-plan (Home)
   - Verrouiller l'écran

2. **Surveiller**:
```bash
#!/bin/bash
# battery_test_background.sh

APP_PACKAGE="com.example.basspro_player"

echo "=== Test Batterie - Arrière-Plan ==="

# Vérifier que l'app est en arrière-plan
state=$(adb shell dumpsys activity activities | grep "mResumedActivity")
echo "État app: $state"
echo ""

# Surveiller les wakelocks
echo "Wakelocks actifs:"
adb shell dumpsys power | grep "Wake Locks"
echo ""

# Test de 1 heure
duration=3600
interval=300

echo "Timestamp,Battery(%),Wakelocks" > battery_background.csv

elapsed=0
while [ $elapsed -lt $duration ]; do
    timestamp=$(date +%s)
    battery=$(adb shell dumpsys battery | grep level | awk '{print $2}')
    wakelocks=$(adb shell dumpsys power | grep -c "PARTIAL_WAKE_LOCK")
    
    echo "$timestamp,$battery,$wakelocks" >> battery_background.csv
    echo "[$((elapsed/60)) min] Batterie: $battery%, Wakelocks: $wakelocks"
    
    sleep $interval
    elapsed=$((elapsed + interval))
done

echo ""
echo "Test terminé"
```

3. **Critères de réussite**:
   - Consommation similaire au premier plan
   - Pas de wakelocks excessifs
   - Pas de réveil CPU inutile

---

## Test 5: Comparaison avec Autres Lecteurs

### Objectif
Comparer BassPro Player avec d'autres lecteurs audio

### Lecteurs à Comparer

- Google Play Music / YouTube Music
- VLC for Android
- Poweramp
- BlackPlayer

### Procédure

1. **Protocole identique pour chaque app**:
   - Même playlist (si possible)
   - Même durée (2 heures)
   - Même configuration (volume, égaliseur off)
   - Même conditions (Wi-Fi off, luminosité 50%)

2. **Tableau de comparaison**:

| Lecteur | Consommation (%) | Taux (%/h) | Température (°C) |
|---------|------------------|------------|------------------|
| BassPro Player | | | |
| YouTube Music | | | |
| VLC | | | |
| Poweramp | | | |
| BlackPlayer | | | |

3. **Analyse**:
   - BassPro doit être dans la moyenne
   - Acceptable si ± 2% des autres lecteurs

---

## Analyse des Résultats

### Script d'Analyse Python

```python
# analyze_battery.py
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime

def analyze_battery_test(csv_file, test_name):
    """Analyser un fichier de test de batterie"""
    
    # Charger les données
    df = pd.read_csv(csv_file)
    df['Time'] = pd.to_datetime(df['Timestamp'], unit='s')
    df['Minutes'] = (df['Timestamp'] - df['Timestamp'].iloc[0]) / 60
    
    # Calculer les statistiques
    initial = df['Battery(%)'].iloc[0]
    final = df['Battery(%)'].iloc[-1]
    consumed = initial - final
    duration_hours = df['Minutes'].iloc[-1] / 60
    rate = consumed / duration_hours
    
    # Tracer le graphique
    plt.figure(figsize=(12, 6))
    plt.plot(df['Minutes'], df['Battery(%)'], marker='o', linewidth=2)
    plt.title(f'Test de Batterie - {test_name}')
    plt.xlabel('Temps (minutes)')
    plt.ylabel('Niveau de Batterie (%)')
    plt.grid(True, alpha=0.3)
    
    # Ajouter les statistiques
    stats_text = f'Consommation: {consumed}%\nTaux: {rate:.2f}%/h'
    plt.text(0.02, 0.98, stats_text, transform=plt.gca().transAxes,
             verticalalignment='top', bbox=dict(boxstyle='round', 
             facecolor='wheat', alpha=0.5))
    
    plt.tight_layout()
    plt.savefig(f'battery_{test_name}.png')
    print(f"Graphique sauvegardé: battery_{test_name}.png")
    
    # Afficher les statistiques
    print(f"\n=== {test_name} ===")
    print(f"Durée: {duration_hours:.2f} heures")
    print(f"Batterie initiale: {initial}%")
    print(f"Batterie finale: {final}%")
    print(f"Consommation totale: {consumed}%")
    print(f"Taux de consommation: {rate:.2f}%/heure")
    
    # Vérifier les critères
    if rate < 10:
        print("✓ RÉUSSI: Consommation acceptable")
    elif rate < 12:
        print("⚠️  ATTENTION: Consommation élevée mais acceptable")
    else:
        print("❌ ÉCHEC: Consommation excessive")
    
    return {
        'test': test_name,
        'duration_hours': duration_hours,
        'consumed': consumed,
        'rate': rate
    }

# Analyser tous les tests
tests = [
    ('battery_local.csv', 'Lecture Locale'),
    ('battery_equalizer.csv', 'Avec Égaliseur'),
    ('battery_streaming.csv', 'Streaming'),
    ('battery_background.csv', 'Arrière-Plan')
]

results = []
for csv_file, test_name in tests:
    try:
        result = analyze_battery_test(csv_file, test_name)
        results.append(result)
    except FileNotFoundError:
        print(f"Fichier non trouvé: {csv_file}")

# Graphique comparatif
if results:
    plt.figure(figsize=(10, 6))
    tests_names = [r['test'] for r in results]
    rates = [r['rate'] for r in results]
    
    bars = plt.bar(tests_names, rates)
    plt.axhline(y=10, color='r', linestyle='--', label='Limite acceptable')
    plt.title('Comparaison des Taux de Consommation')
    plt.ylabel('Consommation (%/heure)')
    plt.xticks(rotation=45, ha='right')
    plt.legend()
    plt.tight_layout()
    plt.savefig('battery_comparison.png')
    print("\nGraphique comparatif sauvegardé: battery_comparison.png")
```

### Exécuter l'Analyse

```bash
python3 analyze_battery.py
```

---

## Analyse Avancée avec Batterystats

### Extraire les Statistiques Détaillées

```bash
# Après le test
adb shell dumpsys batterystats com.example.basspro_player > batterystats.txt

# Générer un rapport HTML
# Télécharger battery-historian: https://github.com/google/battery-historian
# Puis:
python historian.py batterystats.txt > battery_report.html
```

### Métriques Importantes

1. **Wakelocks**:
   - Nombre de wakelocks
   - Durée totale
   - Acceptable: < 5% du temps total

2. **CPU Usage**:
   - Temps CPU utilisé
   - Acceptable: < 10% du temps total

3. **Network Usage**:
   - Données transférées (streaming)
   - Nombre de connexions

4. **Audio**:
   - Temps de lecture audio
   - Doit correspondre à la durée du test

---

## Checklist de Test de Batterie

### Préparation
- [ ] Appareil chargé à 100%
- [ ] Optimisations désactivées
- [ ] Statistiques réinitialisées
- [ ] Scripts préparés

### Tests à Effectuer
- [ ] Test 1: Lecture locale (2h)
- [ ] Test 2: Avec égaliseur (2h)
- [ ] Test 3: Streaming (2h)
- [ ] Test 4: Arrière-plan (1h)
- [ ] Test 5: Comparaison avec autres apps

### Analyse
- [ ] Graphiques générés
- [ ] Statistiques calculées
- [ ] Comparaison effectuée
- [ ] Rapport rédigé

### Critères de Réussite
- [ ] Lecture locale: < 10%/h
- [ ] Avec égaliseur: < 12%/h
- [ ] Streaming: < 15%/h
- [ ] Arrière-plan: similaire au premier plan
- [ ] Comparable aux autres lecteurs (± 2%)

---

## Rapport de Test de Batterie

### Modèle de Rapport

**Date**: _______________
**Testeur**: _______________
**Appareil**: _______________
**Version Android**: _______________
**Version App**: _______________

### Résultats

| Test | Durée | Consommation | Taux (%/h) | Statut |
|------|-------|--------------|------------|--------|
| Lecture locale | 2h | ___% | ___% | ☐ |
| Avec égaliseur | 2h | ___% | ___% | ☐ |
| Streaming | 2h | ___% | ___% | ☐ |
| Arrière-plan | 1h | ___% | ___% | ☐ |

### Comparaison

| Lecteur | Taux (%/h) | Différence |
|---------|------------|------------|
| BassPro Player | ___% | - |
| YouTube Music | ___% | ___% |
| VLC | ___% | ___% |
| Poweramp | ___% | ___% |

### Observations

**Points Positifs**:
_________________________________________________________________

**Points à Améliorer**:
_________________________________________________________________

**Problèmes Détectés**:
_________________________________________________________________

### Recommandation

- [ ] **APPROUVÉ**: Consommation acceptable
- [ ] **APPROUVÉ AVEC RÉSERVES**: Optimisations recommandées
- [ ] **REJETÉ**: Consommation excessive

**Signature**: _______________  **Date**: _______________
