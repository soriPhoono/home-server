#!/usr/bin/env python3

from setuptools import setup, find_packages

setup(name='console',
      version='0.1.0',
      description='A console application package to manage a home lab environment.',
      author='SoriPhoono',
      author_email='soriphoono@protonmail.com',
      packages=find_packages(),
      scripts=['homelab-console'])