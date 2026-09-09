import importlib.util
import tempfile
import unittest
from pathlib import Path


SKILL_DIR = Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_DIR / "scripts" / "validate_skill.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("validate_skill", SCRIPT_PATH)
    if spec is None or spec.loader is None:
        raise ImportError(f"Não foi possível carregar {SCRIPT_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class ValidateSkillTests(unittest.TestCase):
    @staticmethod
    def write_skill(root: Path, body: str, reference: str = "") -> None:
        skill = root / "SKILL.md"
        skill.write_text(
            "---\nname: fixture\ndescription: fixture description\n---\n\n"
            + body,
            encoding="utf-8",
        )
        references = root / "references"
        references.mkdir(exist_ok=True)
        (references / "existing.md").write_text(reference, encoding="utf-8")

    def test_valid_skill_has_no_errors(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_skill(root, "Read `references/existing.md` when needed.")
            self.assertEqual(validator.validate_skill(root), [])

    def test_missing_reference_is_reported(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_skill(root, "Read `references/missing.md` when needed.")
            errors = validator.validate_skill(root)
            self.assertTrue(any("missing.md" in error for error in errors))

    def test_large_reference_requires_toc(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_skill(root, "")
            long_reference = "\n".join(f"line {index}" for index in range(301))
            (root / "references" / "existing.md").write_text(long_reference, encoding="utf-8")
            errors = validator.validate_skill(root)
            self.assertTrue(any("table of contents" in error.lower() for error in errors))

    def test_stale_actor_availability_claim_is_reported(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_skill(root, "Actors Swift | iOS 17")
            errors = validator.validate_skill(root)
            self.assertTrue(any("actor" in error.lower() for error in errors))

    def test_observable_object_snippet_requires_combine(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_skill(root, "")
            (root / "references" / "existing.md").write_text(
                "```swift\nfinal class Store: ObservableObject {\n"
                "    @Published var value = 0\n}\n```\n",
                encoding="utf-8",
            )
            errors = validator.validate_skill(root)
            self.assertTrue(any("Combine" in error for error in errors))

    def test_mutable_sendable_reference_is_reported(self):
        validator = load_validator()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.write_skill(root, "")
            (root / "references" / "existing.md").write_text(
                "```swift\nfinal class Store: Sendable {\n    var value = 0\n}\n```\n",
                encoding="utf-8",
            )
            errors = validator.validate_skill(root)
            self.assertTrue(any("Sendable" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
