import json
import pathlib
import zipfile

ROOT = pathlib.Path(__file__).resolve().parent.parent
MOD = "Namds-Miner"
mod_dir = ROOT / "mods-unpacked" / MOD
version = json.loads((mod_dir / "manifest.json").read_text())["version_number"]

out_dir = ROOT / ".tools" / "dist" / f"{MOD}-{version}"
out_dir.mkdir(parents=True, exist_ok=True)
zip_path = out_dir / f"{MOD}-{version}.zip"

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for path in sorted(mod_dir.rglob("*")):
        if path.is_file() and path.name != ".DS_Store":
            z.write(path, path.relative_to(ROOT).as_posix())

print(zip_path)
