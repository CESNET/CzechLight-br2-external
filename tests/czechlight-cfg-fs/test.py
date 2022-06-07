#!/usr/bin/env python3

import json
import re
import os
import pathlib
import subprocess
import sys

import pytest


SCRIPT_ROOT = pathlib.Path(__file__).resolve().parent
BR2_ROOT = (SCRIPT_ROOT / '../../').resolve()

INSTALL_SCRIPT_PATH = BR2_ROOT / 'package/czechlight-install-yang/czechlight-install-yang.sh'
MIGRATE_SCRIPT_PATH = BR2_ROOT / 'package/czechlight-cfg-fs/czechlight-migrate.sh'
NETOPEER_SCRIPT_PATH = BR2_ROOT / 'submodules/buildroot/package/netopeer2/setup.sh'

CLA_SYSREPO_PATH = BR2_ROOT / 'submodules/cla-sysrepo'
VELIA_PATH = BR2_ROOT / 'submodules/velia'
NETOPEER2_PATH = BR2_ROOT / 'submodules/dependencies/Netopeer2'


def copy_file(src, dst):
    with open(src, 'r') as f_src:
        with open(dst, 'w') as f_dst:
            f_dst.write(f_src.read())


def read_file(path):
    with open(path, 'r') as f:
        return f.read()


def run_and_wait(ctx, desc, command_args):
    print('executing', desc)
    with subprocess.Popen(command_args, stdout=sys.stdout, env=ctx.get_env()) as proc:
        proc.wait()
        assert proc.returncode == 0


def assert_file_exists(path):
    assert path.exists()
    assert path.is_file()


class SysrepoFixture:
    def __init__(self, test_directory, tmp_path):
        self._test_directory = test_directory
        if not isinstance(test_directory, pathlib.Path):
            self._test_directory = pathlib.Path(self._test_directory)

        self._test_name = self._test_directory.name

        self._expected_file = self._test_directory / 'expected.json'
        startup = self._test_directory / 'startup.json'

        print(self._test_directory)
        assert_file_exists(self._expected_file)
        assert_file_exists(startup)

        self._running_directory = tmp_path / self.test_name
        self._running_directory.mkdir()

        self._process_config(self._test_directory / 'test.json')

        self._startup_file = self._running_directory / 'startup.json'
        copy_file(startup, self._startup_file)

        self._export_file = self._running_directory / 'export.json'

    def _process_config(self, config_file):
        assert_file_exists(config_file)

        self._proc_cmdline = self._running_directory / 'proc_cmdline'
        self._version_file = self._running_directory / 'startup_version'

        with open(config_file) as f_config:
            config_json = json.load(f_config)

            assert 'version' in config_json
            assert 'czechlight' in config_json

            self._tested_xpath = config_json['xpath'] if 'xpath' in config_json else None

            with open(self._version_file, 'w') as f:
                f.write(str(config_json['version']))

            with open(self._proc_cmdline, 'w') as f:
                f.write(f'czechlight={config_json["czechlight"]}')

        assert_file_exists(self._version_file)
        assert_file_exists(self._proc_cmdline)

    @property
    def test_name(self):
        return self._test_name

    @property
    def tested_xpath(self):
        return self._tested_xpath

    @property
    def startup_file_path(self):
        return self._startup_file

    @property
    def expected_file_path(self):
        return self._expected_file

    @property
    def version_file_path(self):
        return self._version_file

    def get_env(self):
        res = os.environ.copy()
        res['SYSREPO_SHM_PREFIX'] = self._test_name
        res['SYSREPO_REPOSITORY_PATH'] = self._running_directory / 'sysrepo_repository'
        res['CLA_YANG'] = CLA_SYSREPO_PATH / 'yang'
        res['VELIA_YANG'] = VELIA_PATH / 'yang'
        res['PROC_CMDLINE'] = self._proc_cmdline
        res['CFG_VERSION_FILE'] = self._version_file
        res['CFG_STARTUP_FILE'] = self._startup_file
        res['NP2_MODULE_DIR'] = NETOPEER2_PATH / 'modules'
        res['NP2_MODULE_PERMS'] = '0600'
        res['USER'] = os.getlogin()
        return res


@pytest.fixture(scope='session')
def max_version():
    return 2 # TODO: This should be fetched dynamically from migration script


@pytest.fixture
def sysrepo_fixture(request, tmp_path):
    return SysrepoFixture(request.param, tmp_path)


def find_test_directories():
    return [pytest.param(dirname) for dirname in filter(lambda dirname: dirname.startswith('test_'), os.listdir(path=SCRIPT_ROOT))]


@pytest.mark.parametrize("sysrepo_fixture", find_test_directories(), indirect=True)
def test(sysrepo_fixture, max_version):
    print('\nRunning test', sysrepo_fixture.test_name)

    # prepare sysrepo
    run_and_wait(sysrepo_fixture, 'netopeer2 setup.sh', [NETOPEER_SCRIPT_PATH])
    run_and_wait(sysrepo_fixture, 'czechlight-install-yang.sh', [INSTALL_SCRIPT_PATH])
    run_and_wait(sysrepo_fixture, 'restoring startup.json to sysrepo', ['sysrepocfg', '--datastore', 'startup', '--format', 'json', f'--import={sysrepo_fixture.startup_file_path}'])

    current_version = int(read_file(sysrepo_fixture._version_file))

    # perform the actual migration
    print('migration: current version is', current_version)
    print('migration: applying migration script')
    run_and_wait(sysrepo_fixture, 'migration', [MIGRATE_SCRIPT_PATH])

    after_migration_version = int(read_file(sysrepo_fixture.version_file_path))
    assert after_migration_version == max_version

    print('migration: checking datastore contents')
    export_args = ['sysrepocfg', '--datastore', 'startup', '-f', 'json', f'--export={sysrepo_fixture._export_file}']
    if sysrepo_fixture._tested_xpath:
        export_args += ['-x', sysrepo_fixture._tested_xpath]
    run_and_wait(sysrepo_fixture, 'export', export_args)

    with open(sysrepo_fixture._export_file, 'r') as fp_actual:
        with open(sysrepo_fixture._expected_file, 'r') as fp_expected:
            print(f'migration: comparing files {sysrepo_fixture._startup_file.name} and {sysrepo_fixture._expected_file.name}')

            actual = json.load(fp_actual)
            expected = json.load(fp_expected)
            assert actual == expected
