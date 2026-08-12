# Haskell — Grupo 10, Paradigmas de Programación

Exposición sobre el lenguaje **Haskell**, curso de Paradigmas de Programación.

**Integrantes:**
- Marisol Quirós Víquez
- Josué Sánchez Salazar


---

## Contenido de este repositorio

- Guía de instalación de Haskell (Windows)
- Guía de instalación de la extensión de Haskell para VSCode
- Ejemplos de código usados en la exposición
- Capturas de pantalla de apoyo (ver carpeta [`/imagenes`](./imagenes))

---

## Instalación de Haskell en Windows (GHCup)

GHCup es el instalador oficial recomendado para obtener GHC (el compilador de Haskell) y GHCi (su entorno interactivo).

### Pasos

1. Ingresa a la página oficial de Haskell: [haskell.org](https://www.haskell.org)
2. Abre **PowerShell como administrador**.
3. Copia y pega el siguiente comando en la terminal:

   ```powershell
   Set-ExecutionPolicy Bypass -Scope Process -Force;[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; try { & ([ScriptBlock]::Create((Invoke-WebRequest https://www.haskell.org/ghcup/sh/bootstrap-haskell.ps1 -UseBasicParsing))) -Interactive -DisableCurl } catch { Write-Error $_ }
   ```

4. El proceso puede tardar varios minutos — es normal, no lo cierres.
5. Cuando se te pida autorización para guardar archivos en `C:\`, responde `Y` (o `y`) a todas las preguntas.
6. Al finalizar la instalación, verifica que todo quedó correcto ejecutando:

   ```powershell
   ghci --version
   ```

7. Si ves un número de versión, Haskell ya está instalado en tu equipo.

![Verificación de instalación con ghci --version](imagenes/instalacion-exitosa.png)

### ¿Los pasos no funcionaron?

Si tienes problemas con la instalación, puedes seguir este video tutorial más detallado:

[Video: Cómo instalar Haskell paso a paso](https://www.youtube.com/watch?v=kMY3bUVhE9g)

---

## Configuración en Visual Studio Code

Para programar y ejecutar Haskell directamente desde VSCode:

1. Abre VSCode y ve a la pestaña de **Extensiones**.
2. Busca la extensión llamada **Haskell** (publicada por *haskell.haskell*).
3. Instálala.
4. Con esta extensión podrás:
   - Escribir y resaltar sintaxis de Haskell.
   - Ejecutar y probar código directamente desde la terminal integrada de VSCode.
   - Ver errores y sugerencias en tiempo real.

![Extensión de Haskell instalada en VSCode](imagenes/vscode-extension.png)

---

## Imágenes de apoyo

Las capturas de pantalla del proceso de instalación y ejecución se encuentran en la carpeta [`/imagenes`](./imagenes) de este repositorio:

| Imagen | Descripción |
|---|---|
| `imagenes/powershell-comando.png` | Comando ejecutándose en PowerShell |
| `imagenes/instalacion-exitosa.png` | Verificación con `ghci --version` |
| `imagenes/vscode-extension.png` | Extensión de Haskell instalada en VSCode |
| `imagenes/ejemplo-ghci.png` | Ejemplo de código corriendo en GHCi |

*(Actualiza esta tabla según los nombres reales de tus archivos.)*

---

## Recursos adicionales

- [Sitio oficial de Haskell](https://www.haskell.org)
- [Documentación de GHCup](https://www.haskell.org/ghcup/)
- [HaskellWiki](https://wiki.haskell.org/)
