#!/usr/bin/env python3

import json
import re
import os
import subprocess
import sys


SCRIPT_ROOT = os.path.dirname(os.path.realpath(__file__))
BR2_ROOT = os.path.realpath(os.path.join(SCRIPT_ROOT, '../../'))

INSTALL_SCRIPT_PATH = os.path.join(BR2_ROOT, 'package/czechlight-install-yang/czechlight-install-yang.sh')
MIGRATE_SCRIPT_PATH = os.path.join(BR2_ROOT, 'package/czechlight-install-yang/czechlight-migrate.sh')
NETOPEER_SCRIPT_PATH = os.path.join(BR2_ROOT, 'submodules/buildroot/package/netopeer2/setup.sh')

CLA_SYSREPO_PATH = os.path.join(BR2_ROOT, 'submodules/cla-sysrepo')
VELIA_PATH = os.path.join(BR2_ROOT, 'submodules/velia')
NETOPEER2_PATH = os.path.join(BR2_ROOT, 'submodules/dependencies/Netopeer2')


def log(*args):
    print(*args)


def remove_directory_contents(dirname, also_root_dir=False):
    for root, dirs, files in os.walk(dirname):
        for name in files:
            os.remove(os.path.join(root, name))

        for name in dirs:
            remove_directory_contents(os.path.join(root, name), also_root_dir=True)

    if also_root_dir:
        try:
            os.rmdir(dirname)
        except FileNotFoundError:
            pass


def read_file(path):
    with open(path, 'r') as f:
        return f.read()


class TestError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


def assert_file_exists(path):
    if not os.path.exists(path):
        raise TestError('{} does not exist'.format(path))

    if not os.path.isfile(path):
        raise TestError('{} is not a file'.format(path))


class TestContext:
    def __init__(self, test_directory):
        self._test_directory = test_directory
        self._test_name = os.path.basename(self._test_directory)

        self._running_directory = os.path.join(SCRIPT_ROOT, '_tmp', self._test_name)
        self._sysrepo_repository = os.path.join(self._running_directory, 'sysrepo_repository')
        self._exported_file = os.path.join(self._running_directory, 'startup.json')

        self._expected_file = os.path.join(self._test_directory, 'expected.json')
        assert_file_exists(self._expected_file)

        self._import_file = os.path.join(self._test_directory, 'startup.json')
        assert_file_exists(self._import_file)

        self._config_file = os.path.join(self._test_directory, 'test.json')
        assert_file_exists(self._config_file)

        self._version_file_writable = os.path.join(self._running_directory, 'startup_version')

        self._cleanup()
        os.makedirs(self._running_directory, exist_ok=True)
        os.makedirs(self._sysrepo_repository, exist_ok=True)
        self._create_dummy_files()


    def _create_dummy_files(self):
        self._proc_cmdline = os.path.join(self._running_directory, 'proc_cmdline')
        self._version_file = os.path.join(self._running_directory, 'startup_version')

        with open(self._config_file) as f_config:
            config_json = json.load(f_config)

            assert 'version' in config_json
            assert 'czechlight' in config_json

            with open(self._version_file, 'w') as f:
                f.write(str(config_json['version']))

            with open(self._proc_cmdline, 'w') as f:
                f.write('czechlight={}'.format(config_json['czechlight']))

        assert_file_exists(self._version_file)
        assert_file_exists(self._proc_cmdline)

    @property
    def test_name(self):
        return self._test_name

    def get_env(self):
        res = os.environ.copy()
        res['SYSREPO_REPOSITORY_PATH'] = self._sysrepo_repository
        res['SYSREPO_SHM_PREFIX'] = self._test_name
        res['CLA_YANG'] = os.path.join(CLA_SYSREPO_PATH, 'yang')
        res['VELIA_YANG'] = os.path.join(VELIA_PATH, 'yang')
        res['PROC_CMDLINE'] = self._proc_cmdline
        res['CFG_VERSION_FILE'] = self._version_file
        res['CFG_VERSION_FILE_WRITABLE_END'] = self._version_file_writable
        res['CFG_STARTUP_FILE'] = self._import_file
        res['CFG_STARTUP_FILE_WRITABLE_END'] = self._exported_file
        res['NP2_MODULE_DIR'] = os.path.join(NETOPEER2_PATH, 'modules')
        res['NP2_MODULE_PERMS'] = '0600'
        res['USER'] = os.getlogin()
        return res

    def _cleanup(self):
        remove_directory_contents(self._running_directory, also_root_dir=True)


def run_and_wait(ctx, desc, command_args):
    log('executing {}'.format(desc))
    with subprocess.Popen(command_args, stdout=sys.stdout, env=ctx.get_env()) as proc:
        proc.wait()
        if proc.returncode != 0:
            raise TestError('{} finished with return code {}'.format(desc, proc.returncode))


def compare(ctx, actual_file, expected_file):
    actual = json.load(actual_file)
    expected = json.load(expected_file)

    if actual != expected:
        log('compare: {} != {}'.format(actual, expected))
        return False
    return True


def test(ctx):
    log('')
    log('Running test', ctx.test_name)

    # prepare sysrepo
    run_and_wait(ctx, 'netopeer2 setup.sh', [NETOPEER_SCRIPT_PATH])
    run_and_wait(ctx, 'czechlight-install-yang.sh', [INSTALL_SCRIPT_PATH])
    run_and_wait(ctx, 'restoring startup.json to sysrepo', ['sysrepocfg', '--datastore', 'startup', '--format', 'json', '--import={}'.format(ctx._import_file)])

    current_version = int(read_file(ctx._version_file))

    # perform the actual migration, one by one, and test the output
    log('migration: current version is', current_version)
    log('migration: applying migration script')
    run_and_wait(ctx, 'migration', [MIGRATE_SCRIPT_PATH, 'one-step'])

    after_migration_version = int(read_file(ctx._version_file_writable))

    if current_version + 1 != after_migration_version:
        log('migration: expected version file after migration to be {} but is {}'.format(current_version + 1, after_migration_version))
        return False

    log('migration: checking datastore contents')

    with open('{}'.format(ctx._exported_file), 'r') as fp_actual:
        with open('{}'.format(ctx._expected_file), 'r') as fp_expected:
            log('migration: comparing files {} and {}'.format(os.path.basename(ctx._exported_file), os.path.basename(ctx._expected_file)))
            if compare(ctx, fp_actual, fp_expected) == False:
                log('migration: files differ')
                return False
            return True


def testdir_filter_builder(argv):
    if len(argv) != 1 and len(argv) != 2:
        raise Exception("Usage")  # FIXME

    filters = [lambda dirname: dirname.startswith('test_')]

    if len(argv) == 2:
        filters.append(lambda dirname: re.search(argv[1], dirname) != None)

    return lambda dirname: all(f(dirname) for f in filters)


def main():
    results = dict()
    retcode = 0

    is_testdir = testdir_filter_builder(sys.argv)

    for directory_path in filter(lambda dirname: is_testdir(dirname), os.listdir(path=SCRIPT_ROOT)):
        try:
            ctx = TestContext(os.path.join(SCRIPT_ROOT, directory_path))

            if test(ctx) == True:
                status = 'OK'
            else:
                status = 'FAILURE'
                retcode = 1

            results[directory_path] = status
            log('Test {}: {}'.format(directory_path, status))
        except TestError as e:
            results[directory_path] = 'EXCEPTION (exception: {})'.format(e)
            log('Test {}: {}'.format(directory_path, e))
            retcode = 1

    log('\nRESULTS')
    for name, msg in results.items():
        log('Test {}: {}'.format(name, msg))

    return retcode


if __name__ == '__main__':
    sys.exit(main())
