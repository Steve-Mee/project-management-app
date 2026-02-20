import json
from pathlib import Path

ARB_FILES = [
    r"c:\\my_project_management_app\\lib\\l10n\\app_de.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_en.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_ar.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_es.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_fr.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_zh.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_ru.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_pt.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_nl.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_ko.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_ja.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_it.arb",
    r"c:\\my_project_management_app\\lib\\l10n\\app_hi.arb",
]


def normalize_metadata(key: str, meta: dict | None) -> dict:
    if not isinstance(meta, dict):
        meta = {}
    description = meta.get("description")
    if not description:
        meta["description"] = f"Auto-generated description for {key}."
    return meta


for file_path in ARB_FILES:
    path = Path(file_path)
    text = path.read_text(encoding="utf-8")
    data = json.loads(text)
    stem = path.stem
    locale = stem.split("_", 1)[1] if "_" in stem else None

    # Rebuild JSON with metadata entries placed after each message key.
    ordered: dict[str, object] = {}
    if locale and "@@locale" not in data:
        ordered["@@locale"] = locale
    elif "@@locale" in data:
        ordered["@@locale"] = data["@@locale"]

    for key, value in data.items():
        if key == "@@locale":
            continue
        if key.startswith("@"):  # metadata handled next to its message key
            continue
        ordered[key] = value
        meta = normalize_metadata(key, data.get(f"@{key}"))
        ordered[f"@{key}"] = meta

    formatted = json.dumps(ordered, ensure_ascii=False, indent=2)
    newline = "\r\n" if "\r\n" in text else "\n"
    formatted = formatted.replace("\n", newline) + newline
    path.write_text(formatted, encoding="utf-8")
