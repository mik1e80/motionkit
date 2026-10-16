"""Check the real source archive, downstream API, and actual CSV demo.

Python 3.10+ standard library only; no runtime dependency for the MoonBit library.
"""
from pathlib import Path, PurePosixPath
import csv
import io
import math
import os
import re
import shutil
import subprocess
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
home = os.environ.get("MOON_HOME")
candidate = Path(home) / "bin" / ("moon.exe" if os.name == "nt" else "moon") if home else None
MOON = str(candidate) if candidate and candidate.is_file() else shutil.which("moon")
if MOON is None:
    raise SystemExit("MoonBit toolchain required")


def run(*args, cwd=ROOT, capture=False):
    return subprocess.run([MOON, *args], cwd=cwd, check=True, timeout=180,
                          text=True, encoding="utf-8", capture_output=capture)


def main():
    manifest = (ROOT / "moon.mod").read_text(encoding="utf-8-sig")
    name_match = re.search(r'^name\s*=\s*"([^"]+)"', manifest, re.M)
    version_match = re.search(r'^version\s*=\s*"([^"]+)"', manifest, re.M)
    if not name_match or not version_match:
        raise RuntimeError("Module name or version missing")
    name, version = name_match.group(1), version_match.group(1)
    run("package", "--list")
    archive = ROOT / "_build" / "publish" / f"{name.replace('/', '-')}-{version}.zip"
    workspace = Path(tempfile.mkdtemp(prefix="motionkit-consumer-"))
    package = workspace / "package"
    consumer = workspace / "consumer"
    package.mkdir()
    consumer.mkdir()
    required = {"LICENSE", "THIRD_PARTY_NOTICES.md", "README.md", "README.mbt.md",
                "moon.mod", "moon.pkg", "pkg.generated.mbti", "scurve.mbt",
                "docs/ARCHITECTURE.md", "docs/ACCEPTANCE.md", "docs/FAILURE_CASES.md",
                "cmd/demo/main.mbt", "cmd/boundary_demo/main.mbt", "bounds.mbt"}
    with zipfile.ZipFile(archive) as bundle:
        names = set()
        for entry in bundle.infolist():
            relative = PurePosixPath(entry.filename.replace("\\", "/"))
            if relative.is_absolute() or ".." in relative.parts or any(":" in p for p in relative.parts):
                raise RuntimeError("Unsafe archive path")
            if any(p in {".git", ".mooncakes", "_build", "target"} for p in relative.parts):
                raise RuntimeError("Development artifacts in archive")
            names.add(relative.as_posix())
            target = package.joinpath(*relative.parts)
            target.resolve().relative_to(package.resolve())
            if entry.is_dir():
                target.mkdir(parents=True, exist_ok=True)
            else:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(bundle.read(entry))
        if required - names:
            raise RuntimeError(f"Missing files: {required - names}")
    license_text = (package / "LICENSE").read_text(encoding="utf-8")
    if (package / "moon.mod").read_text(encoding="utf-8-sig") != manifest:
        raise RuntimeError("Packaged manifest differs from current source")
    if "Version 2.0, January 2004" not in license_text or "limitations under the License" not in license_text:
        raise RuntimeError("Incomplete project license")
    (workspace / "moon.work").write_text('members = ["package", "consumer"]\n', encoding="utf-8")
    (consumer / "moon.mod").write_text(
        f'name = "audit/motion_consumer"\nversion = "0.1.0"\nimport {{ "{name}@{version}" }}\n', encoding="utf-8")
    (consumer / "moon.pkg").write_text(f'import {{ "{name}" @motion }} for "test"\n', encoding="utf-8")
    (consumer / "consumer_test.mbt").write_text('''///|
test "consume packaged S curve and derivative limits" {
  let p = @motion.plan_scurve(0.0, 20.0, { velocity: 4.0, acceleration: 2.0, jerk: 4.0 }).unwrap()
  assert_true((p.duration() - 7.5).abs() < 1.0e-8)
  for sample in p.sample_grid(100).unwrap() {
    assert_true(sample.state.velocity.abs() <= 4.00000001)
    assert_true(sample.state.acceleration.abs() <= 2.00000001)
    assert_true(sample.state.jerk.abs() <= 4.00000001)
  }
}
///|
test "consume synchronization and invalid input diagnostics" {
  let limits : @motion.Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0 }
  let p = @motion.synchronize([{ start: 0.0, target: 20.0, limits }, { start: 3.0, target: -1.0, limits }]).unwrap()
  assert_eq(p.sample(p.duration()).unwrap()[1].position, -1.0)
  assert_true(@motion.plan_scurve(0.0, 1.0, { ..limits, jerk: 0.0 }) is Err(_))
}
///|
test "coverage and precision failures survive packaging" {
  let limits : @motion.Limits = { velocity: 4.0, acceleration: 2.0, jerk: 4.0 }
  assert_true(@motion.plan_trapezoid(0.0, 20.0, limits).unwrap().bounds().jerk is Unbounded)
  assert_true(@motion.plan_scurve(0.0, 20.0, limits).unwrap().bounds().jerk is Finite(4.0))
  assert_true(@motion.plan_scurve(1.0e8, 1.0e8 + 0.001, limits) is Err(_))
  assert_true(@motion.plan_scurve(0.0, 100.0, { velocity: 1.0e-6, acceleration: 1.0e6, jerk: 1.0e6 }) is Err(_))
}
''', encoding="utf-8")
    run("check", "--target", "all", "--deny-warn", cwd=consumer)
    for target in ("wasm", "wasm-gc", "js", "native"):
        run("test", "--target", target, cwd=consumer)
    for target in ("wasm", "js"):
        run("run", "cmd/boundary_demo", "--target", target, cwd=package)
    result = run("run", "cmd/csv", "--target", "js", cwd=package, capture=True)
    reader = csv.DictReader(io.StringIO(result.stdout))
    if reader.fieldnames != ["time", "position", "velocity", "acceleration", "jerk"]:
        raise RuntimeError("CSV schema mismatch")
    rows = [{k: float(v) for k, v in row.items()} for row in reader]
    if len(rows) != 201 or not all(math.isfinite(v) for row in rows for v in row.values()):
        raise RuntimeError("CSV row count or finiteness failed")
    if abs(rows[-1]["time"] - 3.25) > 1e-8 or rows[-1]["position"] != 100.0:
        raise RuntimeError("CSV analytic endpoint failed")
    if any(abs(r["velocity"]) > 40.000001 or abs(r["acceleration"]) > 80.000001 or abs(r["jerk"]) > 320.000001 for r in rows):
        raise RuntimeError("CSV exceeds configured limits")
    print(f"Source archive, consumer and CSV verified; workspace: {workspace}")


if __name__ == "__main__":
    main()
