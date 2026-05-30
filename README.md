# CogniRead 🧠
### Entrenamiento cognitivo de lectura activa

Una aplicación Flutter para mejorar la comprensión lectora, memoria y agilidad mental mediante la técnica de reconstrucción de palabras.

---

## 📱 Características

- **3 rondas progresivas** de dificultad creciente
- **Modo oscuro / claro** con persistencia
- **Animaciones fluidas** al cambiar de ronda
- **Contador de palabras y letras ocultas**
- **Ver texto original** para comparar
- **Reiniciar** a estado inicial

---

## 🚀 Instalación

### Requisitos
- Flutter SDK ≥ 3.10.0
- Dart SDK ≥ 3.0.0

### Pasos

```bash
# 1. Clona o descomprime el proyecto
cd cogni_read

# 2. Instala dependencias
flutter pub get

# 3. Ejecuta en dispositivo/emulador
flutter run

# 4. Build para Android
flutter build apk --release

# 5. Build para iOS
flutter build ipa
```

---

## 🧠 Lógica de transformación

### Ronda 1 — Principiante
- Se eliminan **1-2 letras** por palabra
- Nunca se elimina la primera letra
- La palabra sigue siendo fácilmente reconocible

### Ronda 2 — Intermedio  
- Se eliminan **2-3 letras** por palabra
- Se protege sólo la primera letra
- Requiere inferencia activa

### Ronda 3 — Experto
- Se elimina **hasta el 50%** de cada palabra
- Se mantienen la primera y última letra
- El texto es difícil pero reconstruible

---

## 📦 Dependencias

| Paquete | Uso |
|---------|-----|
| `google_fonts` | Tipografía (Space Grotesk + Source Serif 4) |
| `flutter_animate` | Animaciones de ronda |
| `shared_preferences` | Persistencia del modo oscuro |

---

## 🎨 Diseño

- **Paleta dark**: Fondo `#0D0F14`, acento `#4ECDC4`, missing `#FF6B6B`
- **Paleta light**: Fondo `#F0F4FF`, superficie blanca
- Tipografía display: **Space Grotesk** (700-800)
- Tipografía cuerpo: **Source Serif 4** (lectura cómoda)
