# Openstaande TODOs - Uitvoering

Dit bestand bevat de nog openstaande, technisch valide punten uit `Done Todos implementation check.md` die nu uitgevoerd worden.

## TODO-lijst

- [x] 1. Verwijder dubbele `ProjectFilter` modeldefinitie in `pma_core` en behoud een canonieke modelbron.
- [x] 2. Consolideer dashboard sync-statuspad: vervang lokale boolean sync-provider met de centrale offline-status providerselectie.
- [x] 3. Consolideer project-infinite-scroll op providerpad en verwijder dubbele lokale paginatielogica in projectscreen.
- [x] 4. Valideer/opschonen AI legacy drift: documenteer en borg dat de actieve provider als canonical geldt.
- [x] 5. Verhard project-detail cache observability en maak TTL-gedrag expliciet configureerbaar met veilige default.
- [x] 6. Voeg release evidence template toe en koppel dit in release documentatie/workflow-context.

## Vervolg-batch

- [x] 7. Centraliseer dashboard error/status codes in een gedeelde taxonomie en vervang losse string literals.
- [x] 8. Verwijder ongebruikte app-level duplicate `project_filter` modelbestanden en behoud `pma_core` als canonieke bron.
- [x] 9. Voeg contractguard-test toe die afdwingt dat `HiveAuthRepository` alle auth subinterfaces implementeert.
- [x] 10. Leg AI usage source-of-truth contract expliciet vast (Supabase aggregate vs Hive history) en koppel dit in docs.
- [x] 11. Vervang mention-tap placeholder door echte profieldetail-navigatie.
- [x] 12. Documenteer provider importmigratie en markeer legacy AI-barrel als compatibiliteitspad.
- [x] 13. Migreer resterende legacy AI test-import naar canoniek providerpad.
- [x] 14. Update README-documentatie-index met nieuwe AI usage contract- en provider importmigratie-pagina's.
- [x] 15. Koppel release evidence template expliciet in `release.yml` via artifact-upload.
