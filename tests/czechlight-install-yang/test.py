#!/usr/bin/env python3

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


def remove_directory_contents(dirname):
    for root, dirs, files in os.walk(dirname):
        for name in files:
            os.remove(os.path.join(root, name))

        for name in dirs:
            remove_directory_contents(os.path.join(root, name))
            os.rmdir(os.path.join(root, name))


class TestError(Exception):
    def __init__(self, msg):
        super().__init__(msg)


class TestContext:
    def __init__(self, test_directory):
        self._test_directory = test_directory
        self._test_name = os.path.basename(self._test_directory)

        self._tmp_directory = os.path.join(SCRIPT_ROOT, '_tmp', self._test_name)
        self._sysrepo_repository = os.path.join(self._tmp_directory, 'sysrepo_repository')

        self._import_file = os.path.join(self._test_directory, 'startup.json')
        self._expected_directory = os.path.join(self._test_directory, 'expected')
        self._actual_file = os.path.join(self._tmp_directory, 'actual.json')

        self.cleanup()
        os.makedirs(self._tmp_directory, exist_ok=True)
        os.makedirs(self._sysrepo_repository, exist_ok=True)

        self._env = self._create_env()

    def get_expected_files(self):
        res = list()
        for entry in os.listdir(self._expected_directory):
            filename = os.path.join(self._expected_directory, entry)
            if not os.path.isfile(filename):
                continue

            num = int(os.path.basename(filename).split('.')[0], 10)
            res.append((num, filename))

        return res

    def _create_env(self):
        res = os.environ.copy()
        res['SYSREPO_REPOSITORY_PATH'] = self._sysrepo_repository
        res['SYSREPO_SHM_PREFIX'] = self._test_name
        res['CLA_YANG'] = os.path.join(CLA_SYSREPO_PATH, 'yang')
        res['VELIA_YANG'] = os.path.join(VELIA_PATH, 'yang')
        res['PROC_CMDLINE'] = os.path.join(self._test_directory, 'fake_cmdline')
        res['NP2_MODULE_DIR'] = os.path.join(NETOPEER2_PATH, 'modules')
        res['NP2_MODULE_PERMS'] = '0600'
        res['USER'] = os.getlogin()
        return res

    def get_env(self):
        return self._env

    def cleanup(self):
        remove_directory_contents(self._tmp_directory)
        try:
            os.rmdir(self._tmp_directory)
        except FileNotFoundError:
            pass


def run_and_wait(ctx, desc, command_args):
    log('executing {}'.format(desc))
    with subprocess.Popen(command_args, stdout=sys.stdout, env=ctx.get_env()) as proc:
        proc.wait()
        if proc.returncode != 0:
            raise TestError('{} finished with return code {}'.format(desc, proc.returncode))


def migrate_and_assert(ctx):
    # find all our assertions and apply in batches of last to expect file
    last_applied = None
    for num, expected_file in ctx.get_expected_files():
        log("migration: applying migrations {} through {}".format(last_applied, num))
        run_and_wait(ctx, "migration", [MIGRATE_SCRIPT_PATH, str(last_applied + 1 if last_applied else 0), str(num)])
        last_applied = num

        # export contents and compare with expected contents
        log("migration: checking datastore contents after version {}".format(last_applied))
        run_and_wait(ctx, "exporting startup ds content to actual.json file", ['sysrepocfg', '--export={}'.format(ctx._actual_file), '--format', 'json', '--datastore', 'startup'])
        with open('{}'.format(ctx._actual_file), 'r') as f_actual:
            with open('{}'.format(expected_file), 'r') as f_expected:
                log("migration: comparing files {} and {}".format(os.path.basename(ctx._actual_file), os.path.basename(expected_file)))

                actual = f_actual.read()
                expected = f_expected.read()
                # print(actual)
                # print(expected)

                if actual != expected:
                    log("migration: {} and {} differ. Refusing to continue.".format(os.path.basename(ctx._actual_file), os.path.basename(expected_file)))
                    return False

    # TODO: somehow check that we assert for the latest revision?
    return True

def test(ctx):
    log('')
    log('Running test directory', ctx._test_directory)

    if not os.path.exists(ctx._import_file):
        raise TestError('startup.json does not exist')

    if not os.path.exists(ctx._expected_directory):
        raise TestError('expected directory does not exist')

    # prepare sysrepo
    run_and_wait(ctx, "netopeer2 setup.sh", [NETOPEER_SCRIPT_PATH])
    run_and_wait(ctx, "czechlight-install-yang.sh", [INSTALL_SCRIPT_PATH])
    run_and_wait(ctx, "restoring startup.json to sysrepo", ['sysrepocfg', '--datastore', 'startup', '--format', 'json', '--import={}'.format(ctx._import_file)])

    # perform the actual migration, one by one, and test the output
    return migrate_and_assert(ctx)


def main():
    results = dict()
    retcode = 0

    for directory_path in filter(lambda dirname: dirname.startswith('test_'), os.listdir(path=SCRIPT_ROOT)):
        ctx = TestContext(os.path.join(SCRIPT_ROOT, directory_path))

        try:
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
