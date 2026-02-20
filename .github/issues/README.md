# Automatisch aangemaakte issue-bestanden

Deze map bevat per TODO een Markdown-bestand dat een GitHub-issue kan worden; elk bestand bevat titel, bronbestand, beschrijving en verwachte acties.

Script om issues aan te maken:

- `create_issues.ps1` maakt voor elk `.md`-bestand in deze map een GitHub Issue aan via de `gh` CLI.

Vereisten:
- GitHub CLI (`gh`) geïnstalleerd en ingelogd (`gh auth login`).
- Repo moet een GitHub remote hebben en je account moet repo-issue rechten hebben.

Voorbeeld (PowerShell):

```powershell
cd .github/issues
.\create_issues.ps1
```

Het script probeert elk markdown-bestand te gebruiken: de eerste regel (`# titel`) wordt gebruikt als issue title en de volledige file content als body.
