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


def get_test_revisions(tests_path=".", commits=None, reverse=False):
    revisions = sorted([(os.path.basename(v).split(".")[0],v) \
                 for v in glob(os.path.join(tests_path, "*.sh"))], \
                key=lambda x: commits.index(x[0]), reverse=reverse)
    _logger.debug("revisions %r", revisions)
    return revisions


def find_test_revision(repo_path=".", tests_path="."):
    found_revision = None
    commits = get_repo_commits(repo_path)
    current_revision = get_current_repo_revision(repo_path)
    test_revisions = get_test_revisions(tests_path, commits, reverse=True)
    if len(test_revisions) == 0:
        return None
    current_candidate = test_revisions.pop()
    while (len(test_revisions)>0):
        next_candidate = test_revisions.pop()
        if commits.index(current_revision) < commits.index(current_candidate[0]) \
            or commits.index(current_revision) >= commits.index(current_candidate[0]) \
            and commits.index(current_revision) < commits.index(next_candidate[0]):
            break
        else:
            current_candidate = next_candidate
    return current_candidate


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
