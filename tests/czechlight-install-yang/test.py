#!/usr/bin/env python3

import json
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


def assert_file_exists(path):
    if not os.path.exists(path):
        raise FileNotFoundError('{} does not exist'.format(path))

    if not os.path.isfile(path):
        raise FileNotFoundError('{} is not a file'.format(path))


class TestError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class TestContext:
    def __init__(self, test_directory):
        self._test_directory = test_directory
        self._test_name = os.path.basename(self._test_directory)

        self._running_directory = os.path.join(SCRIPT_ROOT, '_tmp', self._test_name)
        self._sysrepo_repository = os.path.join(self._running_directory, 'sysrepo_repository')
        self._exported_file = os.path.join(self._running_directory, 'actual.json')

        self._expected_file = os.path.join(self._test_directory, 'expected.json')
        assert_file_exists(self._expected_file)

        self._proc_cmdline = os.path.join(self._test_directory, 'proc_cmdline')
        assert_file_exists(self._proc_cmdline)

        self._import_file = os.path.join(self._test_directory, 'startup.json')
        assert_file_exists(self._import_file)

        self._version_file = os.path.join(self._test_directory, 'startup_version')
        assert_file_exists(self._version_file)

        self._cleanup()
        os.makedirs(self._running_directory, exist_ok=True)
        os.makedirs(self._sysrepo_repository, exist_ok=True)


    @property
    def test_name(self):
        return self._test_name

    def get_expected_files(self):
        res = list()
        for entry in os.listdir(self._expected_directory):
            filename = os.path.join(self._expected_directory, entry)
            if not os.path.isfile(filename):
                continue

            num = int(os.path.basename(filename).split('.')[0], 10)
            res.append((num, filename))

        return res

    def get_env(self):
        res = os.environ.copy()
        res['SYSREPO_REPOSITORY_PATH'] = self._sysrepo_repository
        res['SYSREPO_SHM_PREFIX'] = self._test_name
        res['CLA_YANG'] = os.path.join(CLA_SYSREPO_PATH, 'yang')
        res['VELIA_YANG'] = os.path.join(VELIA_PATH, 'yang')
        res['PROC_CMDLINE'] = self._proc_cmdline
        res['CFG_VERSION_FILE'] = self._version_file
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


def migrate_and_assert(ctx):
    log('migration: current version is', read_file(ctx._version_file))
    log('migration: applying migration script')
    run_and_wait(ctx, 'migration', [MIGRATE_SCRIPT_PATH, 'one-step'])

    log('migration: checking datastore contents')
    run_and_wait(ctx, 'exporting startup ds content to actual.json file', ['sysrepocfg', '--export={}'.format(ctx._exported_file), '--format', 'json', '--datastore', 'startup'])

    with open('{}'.format(ctx._exported_file), 'r') as fp_actual:
        with open('{}'.format(ctx._expected_file), 'r') as fp_expected:
            log('migration: comparing files {} and {}'.format(os.path.basename(ctx._exported_file), os.path.basename(ctx._expected_file)))
            if compare(ctx, fp_actual, fp_expected) == False:
                log('migration: files differ')
                return False
            return True



def test(ctx):
    log('')
    log('Running test', ctx.test_name)

    # prepare sysrepo
    run_and_wait(ctx, 'netopeer2 setup.sh', [NETOPEER_SCRIPT_PATH])
    run_and_wait(ctx, 'czechlight-install-yang.sh', [INSTALL_SCRIPT_PATH])
    run_and_wait(ctx, 'restoring startup.json to sysrepo', ['sysrepocfg', '--datastore', 'startup', '--format', 'json', '--import={}'.format(ctx._import_file)])

    # perform the actual migration, one by one, and test the output
    return migrate_and_assert(ctx)


def main():
    results = dict()
    retcode = 0

    for directory_path in filter(lambda dirname: dirname.startswith('test_'), os.listdir(path=SCRIPT_ROOT)):
        try:
            ctx = TestContext(os.path.join(SCRIPT_ROOT, directory_path))

            if test(ctx) == True:
                status = 'OK'
            else:
                status = 'FAILURE'
                retcode = 1

            results[ctx] = status
            log('Test {}: {}'.format(ctx._test_name, status))
        except TestError as e:
            results[ctx] = 'FAIL (exception: {})'.format(e)
            log('Test {}: {}'.format(ctx._test_name, e))
            retcode = 1

    log('\nRESULTS')
    for ctx, msg in results.items():
        log('Test {}: {}'.format(ctx._test_name, msg))

    return retcode


if __name__ == '__main__':
    sys.exit(main())
