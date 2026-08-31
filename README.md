# Control

App de control de gastos personal en Flutter. Presupuestos mensuales, categorias, graficas y analiticas.

## Caracteristicas

- Cuentas multiples con balances
- Presupuesto mensual por categoria
- Gastos e ingresos con categorias
- Graficas: linea, barras y pastel
- Comparativa vs mes anterior
- Calculo de disponible diario
- Persistencia local (SharedPreferences)
- Diseno glass moderno (estilo SolarScan)

## Desarrollo local

```bash
flutter pub get
flutter run -d chrome   # web
flutter run           # dispositivo / emulador
flutter test
```

## Despliegue

GitHub Actions despliega automaticamente en cada push a `master`/`main`:

| Workflow | Resultado |
|----------|-----------|
| `web.yml` | Sitio en GitHub Pages → `https://ramiros1.github.io/control/` |
| `android.yml` | APK descargable desde Actions → Artifacts |

### GitHub Pages (primera vez)

1. Repo → **Settings** → **Pages**
2. **Source**: GitHub Actions

## Estructura

```
lib/
  core.dart          # Design system (glass, tokens)
  models.dart        # Cuentas, transacciones, presupuestos
  services.dart      # Calculos financieros + persistencia
  state.dart         # AppState + Store
  screens/           # Home, presupuesto, analiticas, agregar
  widgets/           # Componentes reutilizables
```

## Repo

https://github.com/RamiroS1/control
