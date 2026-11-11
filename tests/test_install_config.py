import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('prepare_config', ROOT / 'prepare-config.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class ConfigTests(unittest.TestCase):
    def test_preserves_config_and_reinstall_has_one_include(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            original = '-- existing appearance and input\nhl.config({input={kb_layout="de"}})\n'
            (staged / 'hyprland.lua').write_text(original)
            for _ in range(2):
                module.prepare(staged, ROOT / 'single-monitor', Path('/nonexistent'))
            text = (staged / 'hyprland.lua').read_text()
            self.assertTrue(text.startswith(original))
            self.assertEqual(text.count('require("friend.keys")'), 1)
            self.assertTrue((staged / 'friend/scripts/hypr-kill-under-cursor').exists())

    def test_legacy_conf_rejected_without_overwriting(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory)
            (staged / 'hyprland.conf').write_text('original')
            with self.assertRaises(ValueError):
                module.prepare(staged, ROOT / 'single-monitor', Path('/nonexistent'))
            self.assertEqual((staged / 'hyprland.conf').read_text(), 'original')
            self.assertFalse((staged / 'hyprland.lua').exists())

    def test_fresh_install_uses_distribution_default(self):
        with tempfile.TemporaryDirectory() as directory:
            staged = Path(directory) / 'staged'
            staged.mkdir()
            default = Path(directory) / 'default.lua'
            default.write_text('-- distribution default\n')
            module.prepare(staged, ROOT / 'single-monitor', default)
            self.assertTrue((staged / 'hyprland.lua').read_text().startswith('-- distribution default'))
