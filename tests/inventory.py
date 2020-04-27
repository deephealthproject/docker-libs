#!/usr/bin/env python
import os
import logging
import argparse
import subprocess
from glob import glob

# Set script logger
_logger = logging.getLogger()


def get_repo_commits(repo_path):
    if not os.path.exists(repo_path):
        raise FileNotFoundError("The repository %s doesn't exist", repo_path)
    cmd_result = subprocess.Popen("cd {} && git rev-list --all --reverse".format(repo_path), shell=True,
                                  stdout=subprocess.PIPE)
    subprocess_return = cmd_result.stdout.read()
    repo_list = subprocess_return.decode("utf-8").split('\n')
    _logger.debug(repo_list)
    return repo_list


def get_current_repo_revision(repo_path):
    if not os.path.exists(repo_path):
        raise FileNotFoundError("The repository %s doesn't exist", repo_path)
    cmd_result = subprocess.Popen("cd {} && git rev-parse HEAD".format(repo_path), shell=True, stdout=subprocess.PIPE)
    subprocess_return = cmd_result.stdout.read()
    repo_list = subprocess_return.decode("utf-8").strip()
    _logger.debug(repo_list)
    return repo_list


def get_test_revisions(tests_path=".", order_by=None):
    revisions = {os.path.basename(v).split(".")[0]: v \
                 for v in glob(os.path.join(tests_path, "*.sh"))}
    return revisions if not order_by else \
        [rev for x in order_by for rev in revisions.items() if rev[0] == x]


def find_test_revision(repo_path=".", tests_path="."):
    found_revision = None

    commits = get_repo_commits(repo_path)
    current_revision = get_current_repo_revision(repo_path)
    test_revision_order = commits.copy()
    test_revision_order.reverse()
    test_revisions = get_test_revisions(tests_path, test_revision_order)

    _logger.debug("List of commits %r", commits)
    _logger.debug("Current revision %r", current_revision)
    _logger.debug("Test revisions %r", test_revisions)

    remaining_revisions = test_revisions
    while len(remaining_revisions) > 0:
        found_revision = remaining_revisions.pop()
        _logger.debug("Current found %r", found_revision)
        _logger.debug("Remaining revisions: %r", len(remaining_revisions))

        if len(remaining_revisions) == 0 \
           or commits.index(current_revision) < commits.index(found_revision[0]):
            break
        _logger.debug("indexes %d %d", commits.index(found_revision[0]), commits.index(remaining_revisions[-1][0]))
        current_slice = [commits[x] \
                         for x in range(commits.index(found_revision[0]), \
                                        commits.index(remaining_revisions[-1][0]))]
        if current_revision in current_slice:
            break
    return found_revision


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('repo_path', metavar='REPO_PATH', type=str, help='Path of the git repository')
    parser.add_argument('test_revisions_path', metavar='TEST_REVISIONS_PATH', type=str,
                        help='Path containing revisions of a test')
    parser.add_argument('--debug', action='store_true', help='Enable debug')
    args = parser.parse_args()
    logging.basicConfig(level=logging.DEBUG if args.debug else logging.INFO)
    found_test_revision = find_test_revision(args.repo_path, args.test_revisions_path)
    _logger.debug(found_test_revision)
    if found_test_revision:
        print(found_test_revision[1])


if __name__ == "__main__":
    main()
