# Mirror Cloud Runner Deploy (Fly.io)

1. Installeer en controleer `flyctl`.
   ```bash
   # macOS / Linux
   curl -L https://fly.io/install.sh | sh

   # Windows (PowerShell)
   iwr https://fly.io/install.ps1 -useb | iex

   fly version
   ```

2. Log in op Fly.io.
   ```bash
   fly auth login
   ```

3. Ga naar de service-map.
   ```bash
   cd server/mirror-cloud-runner
   ```

4. Controleer of `fly.toml` aanwezig is en de app-naam/region correct is.
   ```bash
   fly config show
   ```

5. Maak de app aan als die nog niet bestaat.
   ```bash
   fly apps create <your-app-name>
   ```

6. Stel runtime secrets in (required).
   ```bash
   fly secrets set \
     SIGNED_URL_SECRET="<strong-random-secret>" \
     MIRROR_SERVICE_TOKEN="<service-token-for-edge-to-runner-auth>" \
     MIRROR_JWT_SECRET="<jwt-shared-secret>" \
     ARTIFACT_BASE_URL="https://<your-app-name>.fly.dev/artifacts"
   ```

   Vereist minimaal deze 4 secrets:
   - `SIGNED_URL_SECRET`
   - `MIRROR_SERVICE_TOKEN`
   - `MIRROR_JWT_SECRET`
   - `ARTIFACT_BASE_URL` (moet wijzen naar de publieke HTTP gateway, inclusief `/artifacts`)

7. (Optioneel) Stel extra JWT- en policy-gerelateerde secrets in.
   ```bash
   fly secrets set \
     MIRROR_JWT_KEYS_BY_KID="<kid1:secret1,kid2:secret2>" \
     MIRROR_JWT_AUDIENCE="<expected-audience>" \
     MIRROR_JWT_ISSUER="<expected-issuer>"
   ```

8. (Optioneel) Stel gewone config variables in als je die gebruikt.
   ```bash
   fly deploy --build-only
   fly config save
   ```

9. Deploy de service.
   ```bash
   fly deploy
   ```

10. Controleer de status van machines en release.
   ```bash
   fly status
   fly releases
   fly machines list
   ```

11. Controleer health en endpoint.
    ```bash
    fly checks list
    fly open
    ```

12. Bekijk live logs voor runtime validatie.
    ```bash
    fly logs
    ```

13. Test een smoke request tegen de publieke app URL.
    ```bash
    fly ips list
    # Gebruik daarna je endpoint (voorbeeld):
    # curl https://<your-app-name>.fly.dev/health
    ```

14. Rollback naar vorige release bij issues.
    ```bash
    fly releases
    fly deploy --image <previous-image-reference>
    ```

15. Scale instellingen updaten (CPU/RAM/instances) na succesvolle deploy.
    ```bash
    fly scale count 1
    fly scale vm shared-cpu-1x --memory 512
    ```

16. Verifieer definitieve productie-status.
    ```bash
    fly status
    fly checks list
    fly logs
    ```
