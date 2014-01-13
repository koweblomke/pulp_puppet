#!/usr/bin/env python
#
# Copyright (c) 2013 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

import os
import sys
import shutil

from gettext import gettext as _
from optparse import OptionParser
from subprocess import Popen, PIPE
from hashlib import sha256


URL = _('The URL to a git repository to be cloned. Repositories'
        'will be cloned into the current directory or the location'
        'specified by --path.')

BRANCH = _('The name of a git branch to be checked out.')

TAG = _('The name of a git tag to be checked out.')

WORKING_DIR = _('The working directory used for git cloning. Default: current directory.')

OUTPUT_DIR = _('The output location.')

RECURSIVE = _('Recursively process directories looking for puppet modules.')

CLEAN = _('Delete cloned repositories after building.')


def shell(command, exit_on_err=True):
    print command
    call = command.split()
    p = Popen(call, stdout=PIPE, stderr=PIPE)
    status, output = p.wait(), p.stdout.read()
    if exit_on_err and status != 0:
        print p.stderr.read()
        sys.exit(status)
    return status, output


def get_options():
    cwd = os.getcwd()
    parser = OptionParser()
    parser.add_option('-u', '--url', help=URL)
    parser.add_option('-b', '--branch', help=BRANCH)
    parser.add_option('-t', '--tag', help=TAG)
    parser.add_option('-w', '--working-dir', dest='working_dir', help=WORKING_DIR)
    parser.add_option('-o', '--output-dir', dest='output_dir', help=OUTPUT_DIR)
    parser.add_option('-r', '--recursive', default=False, action='store_true', help=RECURSIVE)
    parser.add_option('-c', '--clean', default=False, action='store_true', help=CLEAN)
    (opts, args) = parser.parse_args()
    if args:
        opts.path = args[0]
    else:
        opts.path = cwd
    if not opts.output_dir:
        opts.output_dir = opts.path
    if not opts.working_dir:
        opts.working_dir = opts.path
    return opts


def find_origin():
    status, output = shell('git status', False)
    if status != 0:
        return
    status, output = shell('git remote show -n origin')
    for line in output.split('\n'):
        line = line.strip()
        if line.startswith('Fetch URL:'):
            url = line.split(':', 1)[1]
            return url.strip()


def git_clone(options):
    if not options.url:
        # cloning not requested
        return
    _dir = os.getcwd()
    os.chdir(options.working_dir)
    shell('git clone %s' % options.url)
    os.chdir(_dir)


def git_checkout(options):
    if not options.origin:
        # not in a git repository
        return
    shell('git fetch')
    shell('git fetch --tags')
    if options.branch:
        shell('git checkout %s' % options.branch)
    if options.tag:
        shell('git checkout %s' % options.tag)
    shell('git pull')


def find_modules():
    status, output = shell('find . -name init.pp')
    for path in output.split('\n'):
        _path = path.split('/')
        if len(_path) < 3:
            continue
        if _path[-2] != 'manifests':
            continue
        if len(_path) > 3 and _path[-4] == 'pkg':
            continue
        module_dir = '/'.join(_path[:-2])
        yield module_dir


def publish_module(module_dir, publish_dir):
    for name in os.listdir(module_dir):
        if not name.endswith('.tar.gz'):
            continue
        path = os.path.join(module_dir, name)
        shutil.copy(path, publish_dir)
        print 'cp %s %s' % (path, publish_dir)


def build_puppet_modules(options):
    for path in find_modules():
        shell('puppet module build %s' % path)
        pkg_dir = os.path.join(path, 'pkg')
        publish_module(pkg_dir, options.output_dir)


def digest(path):
    h = sha256()
    with open(path) as fp:
        h.update(fp.read())
    return h.hexdigest()


def build_manifest(options):
    _dir = os.getcwd()
    os.chdir(options.output_dir)
    with open('PULP_MANIFEST', 'w+') as fp:
        for path in os.listdir('.'):
            if not path.endswith('.tar.gz'):
                continue
            fp.write(path)
            fp.write(',%s' % digest(path))
            fp.write(',%s\n' % os.path.getsize(path))
    os.chdir(_dir)


def main():
    options = get_options()
    os.chdir(options.path)
    git_clone(options)
    options.origin = find_origin()
    git_checkout(options)
    build_puppet_modules(options)
    build_manifest(options)


if __name__ == '__main__':
    main()