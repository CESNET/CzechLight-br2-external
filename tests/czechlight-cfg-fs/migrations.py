#!/usr/bin/env python3

import json
import re
import os
import pathlib
import shutil
import subprocess
import sys

import pytest


SCRIPT_ROOT = pathlib.Path(__file__).resolve().parent
BR2_ROOT = (SCRIPT_ROOT / '../../').resolve()

INSTALL_SCRIPT_PATH = BR2_ROOT / 'package/czechlight-cfg-fs/czechlight-install-yang.sh'
MIGRATE_SCRIPT_PATH = BR2_ROOT / 'package/czechlight-cfg-fs/czechlight-migrate.sh'
MIGRATE_DEFINITIONS_PATH = BR2_ROOT / 'package/czechlight-cfg-fs/czechlight-migration-list.sh'
NETOPEER_SCRIPT_PATH = BR2_ROOT / 'submodules/buildroot/package/netopeer2/setup.sh'

CLA_SYSREPO_PATH = BR2_ROOT / 'submodules/cla-sysrepo'
VELIA_PATH = BR2_ROOT / 'submodules/velia'
NETOPEER2_PATH = BR2_ROOT / 'submodules/dependencies/Netopeer2'


def run_and_wait(ctx, desc, command_args):
    print('executing', desc)
    with subprocess.Popen(command_args, stdout=sys.stdout, env=ctx.get_env()) as proc:
        proc.wait()
        assert proc.returncode == 0


class SysrepoFixture:
    def __init__(self, test_directory, tmp_path):
        test_directory = SCRIPT_ROOT / test_directory
        self.test_name = test_directory.name

        self.expected_file = test_directory / 'expected.json'
        assert self.expected_file.is_file()

        startup = test_directory / 'startup.json'
        assert startup.is_file()

        self.proc_cmdline = test_directory / 'cmdline'
        assert self.proc_cmdline.is_file()

        version_file = test_directory / 'version'
        assert version_file.is_file()

        tested_xpath_file = test_directory / 'xpath'
        self.tested_xpath = tested_xpath_file.read_text() if tested_xpath_file.is_file() else None

        self._running_directory = tmp_path / self.test_name
        self._running_directory.mkdir()

        self.startup_file = self._running_directory / 'startup.json'
        shutil.copyfile(startup, self.startup_file)

        self.export_file = self._running_directory / 'export.json'

        self.version_file = self._running_directory / 'version'
        shutil.copy(version_file, self.version_file)

    def get_env(self):
        res = os.environ.copy()
        res['SYSREPO_SHM_PREFIX'] = self.test_name
        res['SYSREPO_REPOSITORY_PATH'] = self._running_directory / 'sysrepo_repository'
        res['CLA_YANG'] = CLA_SYSREPO_PATH / 'yang'
        res['VELIA_YANG'] = VELIA_PATH / 'yang'
        res['PROC_CMDLINE'] = self.proc_cmdline
        res['CFG_VERSION_FILE'] = self.version_file
        res['CFG_STARTUP_FILE'] = self.startup_file
        res['NP2_MODULE_DIR'] = NETOPEER2_PATH / 'modules'
        res['NP2_MODULE_PERMS'] = '0600'
        res['USER'] = os.getlogin()
        return res


@pytest.fixture(scope='session')
def max_version():
    """
    Fetches last version from czechlight-migrate script by sourcing the
    migration definitions file and verifying the length of the migration
    files array.
    """
    args = ["/bin/bash", "-c", "source " + str(MIGRATE_DEFINITIONS_PATH) + " && echo ${#MIGRATION_FILES[@]}"]
    with subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as proc:
        proc.wait()
        stdout, stderr = proc.communicate()
        assert proc.returncode == 0
        assert stderr.decode().strip() == ''

    return int(stdout.decode().strip())


@pytest.fixture
def sysrepo_fixture(request, tmp_path):
    return SysrepoFixture(pathlib.Path(SCRIPT_ROOT / 'data' / request.param), tmp_path)


def find_test_directories():
    return [pytest.param(dirname) for dirname in os.listdir(path=SCRIPT_ROOT / 'data')]


@pytest.mark.parametrize("sysrepo_fixture", find_test_directories(), indirect=True)
def test(sysrepo_fixture, max_version):
    print('\nRunning test', sysrepo_fixture.test_name)

    # prepare sysrepo
    run_and_wait(sysrepo_fixture, 'netopeer2 setup.sh', [NETOPEER_SCRIPT_PATH])
    run_and_wait(sysrepo_fixture, 'czechlight-install-yang.sh', [INSTALL_SCRIPT_PATH])
    run_and_wait(sysrepo_fixture, 'restoring startup.json to sysrepo', ['sysrepocfg', '--datastore', 'startup', '--format', 'json', f'--import={sysrepo_fixture.startup_file}'])

    current_version = int(sysrepo_fixture.version_file.read_text())

    # perform the actual migration
    print(f'migration: current version is {current_version}')
    print('migration: applying migration script')
    run_and_wait(sysrepo_fixture, 'migration', [MIGRATE_SCRIPT_PATH])

    after_migration_version = int(sysrepo_fixture.version_file.read_text())
    assert after_migration_version == max_version

    print('migration: checking datastore contents')
    export_args = ['sysrepocfg', '--datastore', 'startup', '-f', 'json', f'--export={sysrepo_fixture.export_file}']
    if sysrepo_fixture.tested_xpath:
        export_args += ['-x', sysrepo_fixture.tested_xpath]
    run_and_wait(sysrepo_fixture, 'export', export_args)

    with open(sysrepo_fixture.export_file, 'r') as fp_actual:
        with open(sysrepo_fixture.expected_file, 'r') as fp_expected:
            print(f'migration: comparing files {sysrepo_fixture.startup_file.name} and {sysrepo_fixture.expected_file.name}')

            actual = json.load(fp_actual)
            expected = json.load(fp_expected)
            assert actual == expected
