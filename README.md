# webAvanzada

Laboratorio evaluado de Ingeniería Web Avanzada: Git, Angular, GitHub Actions (CI/CD) y Terraform.

- **Integrante:** Carlos Ignacio Ruz Aguilera
- **Modalidad:** Individual
- **Rama de trabajo:** `devops/ci-cd`
- **Integración a `main`:** solo vía Pull Request

> Nota: las respuestas a continuación son un borrador generado como apoyo para el laboratorio. Carlos las revisará y ajustará antes de que cuenten como entrega final.

## Respuestas del laboratorio (1–16)

**1. ¿Por qué no se recomienda desarrollar directamente sobre `main` en este laboratorio?**
Porque `main` debe reflejar siempre código estable e integrado. Trabajar directo ahí implica que cualquier error o cambio a medio terminar queda expuesto de inmediato, sin pasar por revisión ni por el pipeline de CI. Usar una rama de trabajo (`devops/ci-cd`) permite desarrollar, probar y validar antes de integrar, y deja un historial claro de qué cambios entraron y por qué.

**2. ¿Qué problema se evita al utilizar `--skip-git` al crear el proyecto Angular?**
Angular CLI por defecto inicializa un repositorio Git nuevo (con su propio commit inicial) dentro de la carpeta `frontend`. Como el proyecto ya vive dentro del repositorio `webAvanzada` (que ya tiene su propio `.git`), usar `--skip-git` evita crear un repositorio anidado ("repo dentro de repo"), que generaría conflictos de versionado y haría que `frontend` no se trackeara correctamente como parte del repo principal.

**3. ¿Qué verifica `npm run build` en esta etapa del laboratorio?**
Verifica que el proyecto compile correctamente: que el código TypeScript sea válido, que no haya errores de tipado ni de plantillas, que las dependencias estén resueltas y que Angular pueda generar los artefactos finales (bundle JS/CSS/HTML) listos para desplegar en `dist/`. Es una validación de que el código está en condiciones de producción, no solo de que "compila en mi máquina".

**4. ¿Qué utilidad tiene revisar `git status` o `git diff --cached` antes de un commit?**
`git status` muestra qué archivos están modificados, agregados o sin trackear, evitando dejar fuera cambios importantes o incluir archivos que no correspondían (como `node_modules` o `.env`). `git diff --cached` muestra exactamente el contenido que quedará en el commit (lo ya agregado con `git add`), permitiendo revisar línea por línea antes de confirmar, evitando subir código de depuración, secretos o cambios accidentales.

**5. ¿Qué evento activa el workflow `ci.yml`?**
Se activa con el evento `pull_request` dirigido hacia la rama `main` (`on: pull_request: branches: [main]`), es decir, cada vez que se abre o actualiza un Pull Request que apunta a `main`.

**6. En `runs-on: ubuntu-latest`, ¿qué representa `ubuntu-latest`?**
Es la etiqueta del tipo de máquina virtual (runner) que GitHub Actions provisiona para ejecutar el job: una imagen de Ubuntu Linux mantenida por GitHub, actualizada automáticamente a la versión estable más reciente que GitHub soporta como "latest" (evitando fijar manualmente una versión de SO).

**7. Ordene las etapas de validación del job `frontend` y explique por qué `npm ci` corre antes que las pruebas.**
Orden: (1) `actions/checkout` – trae el código del repo; (2) `actions/setup-node` – configura Node 20 con caché de npm; (3) `npm ci` – instala dependencias exactas desde `package-lock.json`; (4) `npm test -- --watch=false` – ejecuta las pruebas unitarias; (5) `npm run build` – genera el build de producción.
`npm ci` corre antes que las pruebas porque las pruebas (y el build) necesitan que `node_modules` exista con las versiones exactas de las dependencias declaradas en el lockfile; sin ese paso, Angular/Karma/Jasmine ni siquiera podrían ejecutarse. Además `npm ci` es más rápido y determinista que `npm install` para entornos de CI, ya que no modifica el lockfile.

**8. Después del push con el fallo controlado, ¿qué etapa del pipeline falla y qué ocurre con las etapas siguientes?**
Falla la etapa de pruebas (`npm test -- --watch=false`), porque el test esperaba un texto distinto al que realmente renderiza el `h1`. Como los steps de un job en GitHub Actions se ejecutan secuencialmente y por defecto se detienen ante el primer error, la etapa siguiente (`npm run build`) no llega a ejecutarse: el job completo se marca como fallido (`failed`) en cuanto falla el step de pruebas.

**9. ¿Debería integrarse ese Pull Request a `main` mientras el pipeline está fallando? Justifique.**
No. Un pipeline en rojo indica que el código no cumple con las validaciones mínimas definidas por el equipo (en este caso, pruebas unitarias). Integrar código con CI fallando rompe la garantía de que `main` siempre está en un estado estable y desplegable, y puede arrastrar el problema a `cd.yml`, afectando el ambiente de staging. La buena práctica es corregir el problema, esperar a que el pipeline quede en verde, y solo entonces mergear.

**10. Clasifique como "versionable", "variable/configuración" o "secreto/no versionable":**
- `package.json` → **versionable**
- `API_URL` pública → **variable/configuración**
- `AWS_REGION` → **variable/configuración**
- `DB_PASSWORD` → **secreto/no versionable**
- `API_TOKEN` → **secreto/no versionable**
- `terraform.tfstate` → **secreto/no versionable** (puede contener datos sensibles de la infraestructura y además es un artefacto generado, no código fuente)

**11. ¿Por qué una contraseña o token no debe escribirse directamente dentro de `ci.yml`, `cd.yml` o un archivo TypeScript del frontend?**
Porque esos archivos quedan versionados en el repositorio (con todo su historial), y cualquier persona con acceso de lectura al repo —o a un fork, o al historial de commits— podría verlo, aunque después se elimine en un commit posterior. Además, el código del frontend se entrega compilado al navegador del usuario final, por lo que cualquier secreto ahí quedaría públicamente expuesto en el cliente. Los secretos deben vivir fuera del código, en un almacén seguro (como GitHub Actions Secrets), e inyectarse en tiempo de ejecución.

**12. Si un secreto real fue incluido en un commit y luego se agrega su archivo a `.gitignore`, ¿queda solucionado el problema? ¿Qué acción adicional debe realizarse?**
No queda solucionado. Agregar el archivo a `.gitignore` solo evita que se vuelvan a subir cambios futuros de ese archivo, pero el secreto sigue existiendo en el historial de commits (accesible con `git log`, clonando el repo, o incluso en forks ya hechos). Es necesario, como mínimo: (1) revocar/rotar el secreto inmediatamente en el sistema donde se usa (invalidarlo), y (2) eliminarlo del historial de Git (por ejemplo con `git filter-repo`, BFG Repo-Cleaner, o reescribiendo el historial) y forzar el push, coordinando con el resto del equipo porque esto reescribe commits.

**13. ¿Qué diferencia existe entre `terraform validate`, `terraform plan` y `terraform apply`?**
- `terraform validate`: revisa que la sintaxis y consistencia interna del código HCL sean correctas (tipos, referencias, bloques bien formados), sin consultar el proveedor ni el estado remoto.
- `terraform plan`: calcula y muestra qué cambios se realizarían (crear, modificar, destruir recursos) comparando el código con el estado actual, pero no ejecuta ningún cambio real.
- `terraform apply`: ejecuta efectivamente los cambios calculados por el plan, modificando la infraestructura/recursos reales y actualizando el archivo de estado.

**14. ¿Por qué `ci.yml` se activa con `pull_request` y `cd.yml` se activa con `push` sobre `main`?**
`ci.yml` valida cambios propuestos antes de integrarlos: tiene sentido que corra en cada Pull Request hacia `main`, como una compuerta de calidad previa al merge. `cd.yml`, en cambio, representa el despliegue a staging, que solo debe ocurrir con código ya integrado y aprobado en `main`; por eso se dispara con `push` sobre esa rama, es decir, después de que el PR fue mergeado, no antes.

**15. ¿Qué función cumple Terraform dentro de este flujo de CD?**
Terraform actúa como herramienta de Infraestructura como Código (IaC): a partir de la definición declarativa en `infra/main.tf`, automatiza la tarea de "entrega" del build del frontend (copiarlo a la carpeta `staging/`) de forma reproducible y versionada, en lugar de hacerlo manualmente. En un escenario real se usaría para aprovisionar y gestionar recursos de infraestructura (servidores, buckets, redes, etc.) de manera consistente en cada despliegue.

**16. ¿Por qué el workflow usa `${{ secrets.DEMO_TOKEN }}` en lugar de escribir el valor directamente?**
Porque `${{ secrets.DEMO_TOKEN }}` referencia el valor de forma segura desde el almacén de GitHub Actions Secrets, cifrado y oculto en los logs (GitHub lo enmascara automáticamente si aparece impreso). Escribir el valor directamente en el YAML lo dejaría en texto plano, versionado y visible para cualquiera con acceso al repositorio, eliminando cualquier control de acceso o posibilidad de rotarlo sin tocar el código.

## Enlaces del laboratorio

- **Repositorio:** https://github.com/CarlosIgRuz/webAvanzada
- **Ejecución de CI (Pull Request #1, workflow "CI Angular" en verde):** https://github.com/CarlosIgRuz/webAvanzada/actions/runs/34133430862
