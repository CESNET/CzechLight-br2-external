#!/usr/bin/env python3

import json
import re
import os
import pathlib
import subprocess
import sys


SCRIPT_ROOT = pathlib.Path(__file__).resolve().parent
BR2_ROOT = (SCRIPT_ROOT / '../../').resolve()

INSTALL_SCRIPT_PATH = BR2_ROOT / 'package/czechlight-install-yang/czechlight-install-yang.sh'
MIGRATE_SCRIPT_PATH = BR2_ROOT / 'package/czechlight-cfg-fs/czechlight-migrate.sh'
NETOPEER_SCRIPT_PATH = BR2_ROOT / 'submodules/buildroot/package/netopeer2/setup.sh'

CLA_SYSREPO_PATH = BR2_ROOT / 'submodules/cla-sysrepo'
VELIA_PATH = BR2_ROOT / 'submodules/velia'
NETOPEER2_PATH = BR2_ROOT / 'submodules/dependencies/Netopeer2'


def remove_directory_contents(dirname, also_root_dir=False):
    for root, dirs, files in os.walk(dirname):
        for name in files:
            os.remove(pathlib.Path(root) / name)

        for name in dirs:
            remove_directory_contents(pathlib.Path(root) / name, also_root_dir=True)

    if also_root_dir:
        try:
            os.rmdir(dirname)
        except FileNotFoundError:
            pass


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
        if proc.returncode != 0:
            raise TestError(f'{desc} finished with return code {proc.returncode}')


class TestError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


def assert_file_exists(path):
    if not path.exists():
        raise TestError(f'{path} does not exist')

    if not path.is_file():
        raise TestError(f'{path} is not a file')


class TestContext:
    def __init__(self, test_directory):
        self._test_directory = test_directory
        if not isinstance(test_directory, pathlib.Path):
            self._test_directory = pathlib.Path(self._test_directory)

        self._test_name = self._test_directory.name
        self._running_directory = SCRIPT_ROOT / '_tmp' / self.test_name

        self._cleanup()
        os.makedirs(self._running_directory, exist_ok=True)

        self._expected_file = self._test_directory / 'expected.json'
        assert_file_exists(self._expected_file)

        self._tested_xpath = None
        self._process_config(self._test_directory / 'test.json')

        startup = self._test_directory / 'startup.json'
        assert_file_exists(startup)
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
            if 'xpath' in config_json:
                self._tested_xpath= config_json['xpath']

            with open(self._version_file, 'w') as f:
                f.write(str(config_json['version']))

            with open(self._proc_cmdline, 'w') as f:
                f.write(f'czechlight={config_json["czechlight"]}')

        assert_file_exists(self._version_file)
        assert_file_exists(self._proc_cmdline)

    @property
    def test_name(self):
        return self._test_name

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

    def _cleanup(self):
        remove_directory_contents(self._running_directory, also_root_dir=True)


def compare(ctx, actual_file, expected_file):
    actual = json.load(actual_file)
    expected = json.load(expected_file)

    if actual != expected:
        print(f'compare: {actual} != {expected}')
        return False
    return True


def test(ctx):
    print('\nRunning test', ctx.test_name)

    # prepare sysrepo
    run_and_wait(ctx, 'netopeer2 setup.sh', [NETOPEER_SCRIPT_PATH])
    run_and_wait(ctx, 'czechlight-install-yang.sh', [INSTALL_SCRIPT_PATH])
    run_and_wait(ctx, 'restoring startup.json to sysrepo', ['sysrepocfg', '--datastore', 'startup', '--format', 'json', f'--import={ctx._startup_file}'])

    current_version = int(read_file(ctx._version_file))

    # perform the actual migration, one by one, and test the output
    print('migration: current version is', current_version)
    print('migration: applying migration script')
    run_and_wait(ctx, 'migration', [MIGRATE_SCRIPT_PATH])

    after_migration_version = int(read_file(ctx._version_file))

    if current_version + 1 != after_migration_version:
        print(f'migration: expected version file after migration to be {current_version + 1} but is {after_migration_version}')
        return False

    print('migration: checking datastore contents')

    export_args = ['sysrepocfg', '--datastore', 'startup', '-f', 'json', f'--export={ctx._export_file}']
    if ctx._tested_xpath:
        export_args += ['-x', ctx._tested_xpath]
    run_and_wait(ctx, 'export', export_args)

    with open(ctx._export_file, 'r') as fp_actual:
        with open(ctx._expected_file, 'r') as fp_expected:
            print(f'migration: comparing files {ctx._startup_file.name} and {ctx._expected_file.name}')
            if compare(ctx, fp_actual, fp_expected) is False:
                print('migration: files differ')
                return False
            return True


def testdir_filter_builder():
    filters = [lambda dirname: dirname.startswith('test_')]

    if len(sys.argv) == 2:
        filters.append(lambda dirname: re.search(sys.argv[1], dirname) is not None)

    return lambda dirname: all(f(dirname) for f in filters)


def main():
    results = dict()
    retcode = 0

    is_testdir = testdir_filter_builder()

    for directory_path in filter(lambda dirname: is_testdir(dirname), os.listdir(path=SCRIPT_ROOT)):
        try:
            if test(TestContext(SCRIPT_ROOT / directory_path)) is True:
                status = 'OK'
            else:
                status = 'FAILURE'
                retcode = 1

            results[directory_path] = status
            print(f'Test {directory_path}: {status}')
        except TestError as e:
            results[directory_path] = f'EXCEPTION (exception: {e})'
            print(f'Test {directory_path}: {e}')
            retcode = 1

    print('\nRESULTS')
    for name, msg in results.items():
        print(f'Test {name}: {msg}')

    return retcode


if __name__ == '__main__':
    if len(sys.argv) != 1 and len(sys.argv) != 2:
        print(f'Usage: {sys.argv[0]} [regex-test-filter]')
        sys.exit(1)

    sys.exit(main())
