from pathlib import Path

def collect_swift_files(root: Path, output_file: Path):
    swift_files = sorted(root.rglob("*.swift"))

    with output_file.open("w", encoding="utf-8") as out:
        for swift_file in swift_files:
            out.write(f"\n// ===== FILE: {swift_file.relative_to(root)} =====\n\n")
            try:
                out.write(swift_file.read_text(encoding="utf-8"))
            except UnicodeDecodeError:
                out.write(f"// ⚠️ Could not read {swift_file}\n")

if __name__ == "__main__":
    root_dir = Path.cwd()
    output_path = root_dir / "collected_swift.txt"

    collect_swift_files(root_dir, output_path)
    print(f"Collected Swift files into: {output_path}")

