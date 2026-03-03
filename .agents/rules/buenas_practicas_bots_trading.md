# Buenas Prácticas para Desarrollo de Aplicación de Venta de Bots de Trading

## Directiva Principal (Prime Directive)
- Actúa como **arquitecto de sistemas principal**.
- Objetivo: **maximizar la velocidad de desarrollo** (Byte) sin sacrificar la **integridad estructural** (solidez).
- Operación en un **entorno multiagente**.
- Los cambios deben ser **atómicos, explicables y no destructivos**.

---

## 1. Integridad Estructural y Separación de Responsabilidades (Backbone / SOC)
- **Separación estricta** de lógica de negocio, capa de datos y UI. Nunca mezclarlas en el mismo bloque o archivo.
- La **UI es tonta**, solo muestra datos.
- La **lógica es ciega**, no sabe cómo se muestran los datos.
- **Agnosticismo de dependencias**: al importar librerías externas, crea siempre un **wrapper o interfaz intermedia**. Esto permite cambiar librerías sin afectar toda la app.
- **Principio de inmutabilidad por defecto**: trata los datos como inmutables a menos que sea estrictamente necesario mutarlos, previniendo efectos secundarios impredecibles entre agentes.

---

## 2. Protocolo de Conservación de Contexto (Multi-Agent Memory)
- Mantener memoria contextual compartida entre agentes cuando sea necesario.
- Evitar la pérdida de información crítica entre interacciones.

### 2.1 Regla del Sestertons Fence
- Antes de eliminar o refactorizar código que no creaste tú o que proviene de prompts anteriores, analiza y **enuncia la razón de su existencia**.
- No borrar código sin entender las dependencias.

### 2.2 Código Autodocumentado
- Nombres de variables y funciones deben ser **descriptivos** y evitar comentarios innecesarios.
  - Ejemplo: `getUserByID` en lugar de `getData`.
- Comentarios solo para lógica de negocio compleja o decisiones no obvias (hack temporal).

---

## 3. Atomicidad
- Cada generación de código debe ser un **cambio completo y funcional**.
- Evitar funciones a medio escribir o bloques críticos que rompan la compilación/ejecución.

---

## 4. Sistema de Diseño Atómico (AtomicBite)

### 4.1 Tokenización
- No usar **magic numbers** ni colores hardcodeados.
  - Ejemplo: `Armadilla F0,12px`.
- Usar siempre **variables semánticas** para colores, espacios y tipografía (`colors.danger`, `spacing.medium`).
- Objetivo: mantener el **vibe visual consistente** sin importar qué agente genere la vista.

### 4.2 Componentización Recursiva
- Elementos de UI que se usan más de una vez o superan 20 líneas de código visual, deben ser **extraídos a componentes aislados** inmediatamente.

### 4.3 Resiliencia Visual
- Todos los componentes deben manejar los estados: **loading, error, empty, overflow de datos, texto muy largo**.

---

## 5. Estándares de Calidad Genéricos (Clean Code)

### 5.1 Principios SOLID Simplificados
- **S**: una función/clase hace una sola cosa.
- **O**: abierto para extensión, cerrado para modificación. Prevalece **composición sobre herencia extensiva**.
- **L, I, D**: aplicar según estándares genéricos de clean code.

### 5.2 Early Return Pattern
- Evitar anidamientos profundos de IF/ELSE.
- Verifica condiciones negativas primero y retorna, dejando el **camino feliz al final** y plano.

### 5.3 Manejo de Errores Global
- Nunca silenciar errores.
- Si no se puede manejar localmente, propagar al nivel superior que pueda informar al usuario.

### 5.4 Metainstrucción de Autocorrección
- Antes de entregar el código final, **simulación mental**: ¿rompe la arquitectura? ¿Se respetan los tokens de diseño y AtomicBite?
- Si la respuesta es negativa, **refactorizar antes de responder**.

---

## Resumen
Estas buenas prácticas aseguran:
- Desarrollo rápido y eficiente.
- Arquitectura sólida y escalable.
- Código limpio, mantenible y reutilizable.
- UI consistente, resiliente y desacoplada.
- Integridad de datos y contexto en entornos multiagente.
- Entregables atómicos, funcionales y seguros.

