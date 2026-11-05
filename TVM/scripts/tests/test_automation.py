"""Self-tests for the TVM automation, run in a throwaway Git repository with a local bare remote.

Usage (from TVM/):  python scripts/tests/test_automation.py
Never touches the real repository, GitHub or Salesforce.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest

TVM = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def sh(args, cwd, check=True, input_text=None):
    p = subprocess.run(args, cwd=cwd, capture_output=True, text=True, input=input_text, encoding="utf-8")
    if check and p.returncode != 0:
        raise AssertionError(f"{args} failed: {p.stdout}{p.stderr}")
    return p


class AutomationTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix="tvm-test-")
        self.remote = os.path.join(self.tmp, "remote.git")
        self.repo = os.path.join(self.tmp, "repo")
        sh(["git", "init", "--bare", "-q", self.remote], self.tmp)
        os.makedirs(self.repo)
        sh(["git", "init", "-q", "-b", "main"], self.repo)
        sh(["git", "config", "user.email", "test@example.com"], self.repo)
        sh(["git", "config", "user.name", "TVM Test"], self.repo)
        sh(["git", "remote", "add", "origin", self.remote], self.repo)
        self.tvm = os.path.join(self.repo, "TVM")
        for d in ("scripts", "config"):
            shutil.copytree(os.path.join(TVM, d), os.path.join(self.tvm, d),
                            ignore=shutil.ignore_patterns("__pycache__", "tests"))
        shutil.copy(os.path.join(TVM, ".gitignore"), self.tvm)
        for d in ("01-Instructions",
                  "2026-10/07-Technical", "02-Knowledge-Base", "force-app/main/default/classes"):
            os.makedirs(os.path.join(self.tvm, d), exist_ok=True)
        with open(os.path.join(self.tvm, "2026-10/07-Technical", "Change-History.md"), "w") as fh:
            fh.write("# Change History\n\n| Date | Component | Change |\n|---|---|---|\n")
        cfg_path = os.path.join(self.tvm, "config", "tvm-project.json")
        cfg = json.load(open(cfg_path))
        cfg["git"]["remoteUrl"] = self.remote
        json.dump(cfg, open(cfg_path, "w"), indent=2)
        os.makedirs(os.path.join(self.repo, "OTHER"))
        self.write("OTHER/readme.md", "other project\n")
        sh(["git", "add", "--", "TVM", "OTHER"], self.repo)
        sh(["git", "commit", "-q", "-m", "init"], self.repo)
        sh(["git", "push", "-q", "origin", "main"], self.repo)
        sh(["git", "switch", "-q", "-c", "tvm/develop"], self.repo)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    # helpers
    def write(self, rel, text):
        path = os.path.join(self.repo, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)

    def autocommit(self, *args, stdin=None):
        return sh([sys.executable, os.path.join(self.tvm, "scripts", "autocommit.py"), *args], self.tvm, check=False,
                  input_text=stdin)

    def remote_files(self):
        p = sh(["git", "--git-dir", self.remote, "ls-tree", "-r", "--name-only", "tvm/develop"], self.tmp, check=False)
        return p.stdout.split() if p.returncode == 0 else []

    def head(self):
        return sh(["git", "rev-parse", "HEAD"], self.repo).stdout.strip()

    # tests
    def test_no_changes_is_noop(self):
        before = self.head()
        p = self.autocommit()
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(self.head(), before)

    def test_doc_change_commits_and_pushes_only_tvm(self):
        self.write("TVM/02-Knowledge-Base/Note.md", "# Note\n")
        self.write("OTHER/readme.md", "changed but not TVM\n")
        p = self.autocommit("-m", "Add note")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("Committed and pushed", p.stdout)
        files = sh(["git", "show", "--name-only", "--format=", "HEAD"], self.repo).stdout.split()
        self.assertTrue(files and all(f.startswith("TVM/") for f in files), files)
        self.assertIn("TVM/02-Knowledge-Base/Note.md", self.remote_files())
        self.assertIn("OTHER/readme.md", sh(["git", "status", "--porcelain"], self.repo).stdout)
        # idempotent: second run does nothing
        head = self.head()
        self.autocommit()
        self.assertEqual(self.head(), head)

    def test_staged_file_outside_tvm_stops(self):
        self.write("OTHER/readme.md", "staged elsewhere\n")
        sh(["git", "add", "OTHER/readme.md"], self.repo)
        self.write("TVM/02-Knowledge-Base/Note.md", "# Note\n")
        before = self.head()
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("outside TVM", p.stderr)
        self.assertEqual(self.head(), before)

    def test_secret_blocks_and_stages_nothing(self):
        self.write("TVM/02-Knowledge-Base/Leak.md", "token: ghp_" + "a" * 36 + "\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("Secret check failed", p.stderr)
        self.assertEqual(sh(["git", "diff", "--cached", "--name-only"], self.repo).stdout.strip(), "")

    def test_source_change_requires_change_history(self):
        self.write("TVM/force-app/main/default/classes/Foo.cls", "public class Foo {}\n")
        self.write("TVM/force-app/main/default/classes/Foo.cls-meta.xml",
                   '<?xml version="1.0" encoding="UTF-8"?><ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">'
                   "<apiVersion>68.0</apiVersion><status>Active</status></ApexClass>\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("Change-History.md", p.stderr)
        with open(os.path.join(self.tvm, "2026-10/07-Technical", "Change-History.md"), "a") as fh:
            fh.write("| 2026-10-14 | ApexClass `Foo` | Added (REQ-001) |\n")
        p = self.autocommit()
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("TVM/2026-10/07-Technical/Metadata-Inventory/Apex-Classes.md", self.remote_files())

    def test_invalid_xml_blocks(self):
        self.write("TVM/config/bad.xml", "<a><b></a>\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("invalid XML", p.stderr)

    def test_protected_branch_stops(self):
        sh(["git", "switch", "-q", "main"], self.repo)
        self.write("TVM/02-Knowledge-Base/Note.md", "# Note\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("protected", p.stderr)

    def test_wrong_remote_stops(self):
        sh(["git", "remote", "set-url", "origin", os.path.join(self.tmp, "elsewhere.git")], self.repo)
        self.write("TVM/02-Knowledge-Base/Note.md", "# Note\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("expected", p.stderr)

    def test_push_failure_keeps_commit_then_retries(self):
        os.rename(self.remote, self.remote + ".off")
        self.write("TVM/02-Knowledge-Base/Note.md", "# Note\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("push failed", p.stderr)
        sha = self.head()
        os.rename(self.remote + ".off", self.remote)
        p = self.autocommit()
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("Pushed earlier", p.stdout)
        self.assertEqual(sh(["git", "--git-dir", self.remote, "rev-parse", "tvm/develop"], self.tmp).stdout.strip(), sha)

    def test_hook_mode_blocks_once_then_reports(self):
        self.write("TVM/force-app/main/default/classes/Bar.cls", "public class Bar {}\n")
        p = self.autocommit("--hook", stdin=json.dumps({"stop_hook_active": False}))
        self.assertEqual(p.returncode, 2)
        self.assertIn("blocked", p.stderr)
        p = self.autocommit("--hook", stdin=json.dumps({"stop_hook_active": True}))
        self.assertEqual(p.returncode, 0)
        self.assertIn("NOT done", json.loads(p.stdout)["systemMessage"])

    def test_hook_commit_message_file(self):
        os.makedirs(os.path.join(self.tvm, ".tvm-state"), exist_ok=True)
        self.write("TVM/.tvm-state/commit-message.txt", "Add REQ-001 case routing\n")
        self.write("TVM/02-Knowledge-Base/Note.md", "# Note\n")
        p = self.autocommit("--hook", stdin="{}")
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("Committed and pushed", json.loads(p.stdout)["systemMessage"])
        msg = sh(["git", "log", "-1", "--format=%B"], self.repo).stdout
        self.assertTrue(msg.startswith("Add REQ-001 case routing"))
        self.assertIn("Co-Authored-By:", msg)
        self.assertFalse(os.path.exists(os.path.join(self.tvm, ".tvm-state", "commit-message.txt")))
        self.assertFalse(any(".tvm-state" in f for f in self.remote_files()))

    def test_new_doc_files_by_month_without_duplicates(self):
        nd = [sys.executable, os.path.join(self.tvm, "scripts", "new_doc.py")]
        a = sh(nd + ["REQ", "Case routing", "--month", "2026-11"], self.tvm).stdout
        b = sh(nd + ["REQ", "Case routing", "--month", "2026-12"], self.tvm).stdout
        c = sh(nd + ["REQ", "Another request", "--month", "2026-12"], self.tvm).stdout
        self.assertIn("Created 2026-11/03-Requirements/REQ-001_Case-Routing.md", a)
        self.assertIn("Already exists", b)
        self.assertIn("Created 2026-12/03-Requirements/REQ-002_Another-Request.md", c)   # numbers run across months
        for m in ("2026-11", "2026-12"):                                                  # full month structure created
            self.assertTrue(os.path.exists(os.path.join(self.tvm, m, "MONTH-INDEX.md")))
            self.assertTrue(os.path.isdir(os.path.join(self.tvm, m, "08-QA", "02-Manual-Testing")))
        p = self.autocommit()
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertIn("TVM/DOCUMENT-INDEX.md", self.remote_files())
        self.assertIn("TVM/2026-12/MONTH-INDEX.md", self.remote_files())

    def test_session_start_creates_current_month(self):
        month = __import__("datetime").date.today().strftime("%Y-%m")
        shutil.rmtree(os.path.join(self.tvm, month), ignore_errors=True)
        p = sh([sys.executable, os.path.join(self.tvm, "scripts", "hooks", "session_context.py"), "start"], self.tvm)
        self.assertIn(f"New month: created {month}/", p.stdout)
        self.assertTrue(os.path.exists(os.path.join(self.tvm, month, "MONTH-INDEX.md")))
        self.assertTrue(os.path.isdir(os.path.join(self.tvm, month, "08-QA", "01-Automated-Testing")))
        p = sh([sys.executable, os.path.join(self.tvm, "scripts", "hooks", "session_context.py"), "start"], self.tvm)
        self.assertNotIn("New month", p.stdout)   # only once per month

    def test_document_outside_month_folder_blocks(self):
        self.write("TVM/05-Conflicts/CON-009_Loose-Document.md", "# CON-009 — Loose\n")
        p = self.autocommit()
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("filed by month", p.stderr)

    def test_guard_blocks_unsafe_commands(self):
        guard = [sys.executable, os.path.join(self.tvm, "scripts", "hooks", "guard.py")]
        for cmd, code in [("git push --force origin tvm/develop", 2), ("git add -A", 2), ("git push origin main", 2),
                          ("sf project deploy start -o Fullsandbox", 2), ("git status", 0),
                          ("python scripts/sf_safe.py data query -q x", 0)]:
            p = sh(guard, self.tvm, check=False, input_text=json.dumps({"tool_input": {"command": cmd}}))
            self.assertEqual(p.returncode, code, cmd)


if __name__ == "__main__":
    unittest.main(verbosity=2)
