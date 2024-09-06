#!/usr/bin/env python3

import glob
import json
import re
import os
import pathlib
import pytest
import shutil
import subprocess
import sys


SCRIPT_ROOT = pathlib.Path(__file__).resolve().parent
BR2_EXT_ROOT = (SCRIPT_ROOT / '../../').resolve()
CFG_FS_SCRIPTS_PATH = BR2_EXT_ROOT / 'package' / 'czechlight-cfg-fs'

def run_and_wait(ctx, command_args):
    print(f'RUN {command_args}')
    with subprocess.Popen(command_args, stdout=sys.stdout, stderr=sys.stderr, env=ctx.get_env()) as proc:
        proc.wait()
        assert proc.returncode == 0


class SysrepoFixture:
    def __init__(self, test_directory, tmp_path):
        self.test_directory = SCRIPT_ROOT / test_directory
        test_name = self.test_directory.name
        self.running_directory = tmp_path / test_name
        self.running_directory.mkdir()
        self.tmp_path = tmp_path

        for fn in ('startup.json', 'version'):
            try:
                shutil.copy(self.test_directory / fn, self.running_directory)
            except FileNotFoundError:
                pass

        query_file = self.test_directory / 'query'
        self.query = query_file.read_text() if query_file.is_file() \
            else 'del(."ietf-keystore:keystore"."asymmetric-keys"."asymmetric-key"[0]."cleartext-private-key")'

        # all tests must run with clean sysrepo state
        self._shm_prefix = 'br2-migr-' + test_name
        self._repo_path = self.running_directory / 'sysrepo_repository'

    def get_env(self):
        res = os.environ.copy()
        res['SYSREPO_SHM_PREFIX'] = self._shm_prefix
        res['SYSREPO_REPOSITORY_PATH'] = self._repo_path
        res['LN2_MODULE_DIR'] = pathlib.Path(os.environ['LIBNETCONF2_SRCDIR']) / 'modules'
        res['NP2_MODULE_DIR'] = pathlib.Path(os.environ['NETOPEER2_SRCDIR']) / 'modules'
        res['NETOPEER2_SETUP_DIR'] = BR2_EXT_ROOT / 'submodules' / 'buildroot' / 'package' / 'netopeer2'
        res['CLA_YANG'] = pathlib.Path(os.environ['CLA_SYSREPO_SRCDIR']) / 'yang'
        res['VELIA_YANG'] = pathlib.Path(os.environ['VELIA_SRCDIR']) / 'yang'
        res['ALARMS_YANG'] = pathlib.Path(os.environ['SYSREPO_IETF_ALARMS_SRCDIR']) / 'yang'
        res['ROUSETTE_YANG'] = pathlib.Path(os.environ['ROUSETTE_SRCDIR']) / 'yang'
        res['CFG_FS_YANG'] = CFG_FS_SCRIPTS_PATH / 'yang'
        res['CFG_STATIC_DATA'] = CFG_FS_SCRIPTS_PATH / 'static-data'
        res['VELIA_STATIC_DATA'] = pathlib.Path(os.environ['VELIA_SRCDIR']) / 'yang'
        res['CLA_STATIC_DATA'] = pathlib.Path(os.environ['CLA_SYSREPO_SRCDIR']) / 'yang'
        res['PROC_CMDLINE'] = self.test_directory / 'cmdline'
        res['CFG_SYSREPO_DIR'] = self.running_directory
        res['CURRENT_VERSION_FILE'] = CFG_FS_SCRIPTS_PATH / 'CURRENT_CONFIG_VERSION'
        res['TMPDIR'] = self.tmp_path
        return res

    def nuke_shm(self):
        for f in glob.glob(f'/dev/shm/{self._shm_prefix}*'):
            os.remove(f)


@pytest.fixture(scope='session')
def max_version():
    return (CFG_FS_SCRIPTS_PATH / 'CURRENT_CONFIG_VERSION').read_text()


@pytest.fixture
def sysrepo_fixture(request, tmp_path):
    return SysrepoFixture(pathlib.Path(SCRIPT_ROOT / 'data' / request.param), tmp_path)


def find_test_directories():
    return [pytest.param(dirname) for dirname in os.listdir(path=SCRIPT_ROOT / 'data')]


@pytest.mark.parametrize("sysrepo_fixture", find_test_directories(), indirect=True)
def test(sysrepo_fixture, max_version):
    # prevent running with a stale SHM state
    sysrepo_fixture.nuke_shm()

    run_and_wait(sysrepo_fixture, [CFG_FS_SCRIPTS_PATH / "cfg-migrate.sh"])
    run_and_wait(sysrepo_fixture, [CFG_FS_SCRIPTS_PATH / "cfg-yang.sh"])

    assert (sysrepo_fixture.running_directory / 'version').read_text() == max_version

    dump = subprocess.run(['sysrepocfg', '-f', 'json', '-d', 'startup', '-X'], check=True, capture_output=True, env=sysrepo_fixture.get_env())
    jq = subprocess.run(['jq', sysrepo_fixture.query], input=dump.stdout, check=True, capture_output=True)
    actual = json.loads(jq.stdout.decode('utf-8'))
    with open(sysrepo_fixture.test_directory / 'expected.json', 'r') as fp_expected:
        expected = json.load(fp_expected)
        assert actual == expected

    sysrepo_fixture.nuke_shm()
