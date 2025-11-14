{
  lib,
  python3Packages,
  ...
}:
with python3Packages;
buildPythonApplication rec {
  pname = "homelab-console";
  version = "0.1.0";
  pyproject = true;

  src = ./console;

  build-system = [ setuptools ];

  dependencies = [
  ];
}