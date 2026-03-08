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

6. Stel runtime secrets in (pas keys/values aan op jouw omgeving).
   ```bash
   fly secrets set \
     SUPABASE_URL="<supabase-url>" \
     SUPABASE_SERVICE_ROLE_KEY="<supabase-service-role-key>" \
     OPENAI_API_KEY="<openai-api-key>" \
     MIRROR_ENV="production"
   ```

7. (Optioneel) Stel gewone config variables in als je die gebruikt.
   ```bash
   fly deploy --build-only
   fly config save
   ```

8. Deploy de service.
   ```bash
   fly deploy
   ```

9. Controleer de status van machines en release.
   ```bash
   fly status
   fly releases
   fly machines list
   ```

10. Controleer health en endpoint.
    ```bash
    fly checks list
    fly open
    ```

11. Bekijk live logs voor runtime validatie.
    ```bash
    fly logs
    ```

12. Test een smoke request tegen de publieke app URL.
    ```bash
    fly ips list
    # Gebruik daarna je endpoint (voorbeeld):
    # curl https://<your-app-name>.fly.dev/health
    ```

13. Rollback naar vorige release bij issues.
    ```bash
    fly releases
    fly deploy --image <previous-image-reference>
    ```

14. Scale instellingen updaten (CPU/RAM/instances) na succesvolle deploy.
    ```bash
    fly scale count 1
    fly scale vm shared-cpu-1x --memory 512
    ```

15. Verifieer definitieve productie-status.
    ```bash
    fly status
    fly checks list
    fly logs
    ```
