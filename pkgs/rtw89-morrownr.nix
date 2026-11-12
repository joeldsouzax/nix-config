# USB RTL8852AU support missing from the locked nixpkgs rtw89 package.
# Call through the selected kernel package set so the module ABI matches.

{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
  nukeReferences,
}:

let
  kdir = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
  revision = "f2ce66eda6277e5505d5914a8a08454440518702";
in
stdenv.mkDerivation {
  pname = "rtw89-morrownr";
  version = "${kernel.version}-unstable-2026-11-09";

  src = fetchFromGitHub {
    owner = "morrownr";
    repo = "rtw89";
    rev = revision;
    hash = "sha256-u2sJ/1tvDM6MloulU7l3w9eLCc2GZqOBebI7/eQbeC8=";
  };

  nativeBuildInputs = [ nukeReferences ] ++ kernel.moduleBuildDependencies;

  hardeningDisable = [
    "pic"
    "format"
  ];
  enableParallelBuilding = true;

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail '$(shell git --git-dir=$(src)/.git rev-parse HEAD)' '${revision}'
  '';

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    kdir
    "M=$(PWD)"
    "INSTALL_MOD_PATH=${placeholder "out"}"
    "INSTALL_MOD_DIR=updates/rtw89"
  ];
  buildFlags = [ "modules" ];
  installTargets = [ "modules_install" ];
  # Remove build references before Kbuild strips, signs and compresses modules.
  preInstall = ''
    nuke-refs *.ko
  '';
  dontStrip = true;

  meta = {
    description = "morrownr out-of-tree rtw89 driver (Realtek WiFi 6/6E/7, incl. RTL8852AU USB)";
    homepage = "https://github.com/morrownr/rtw89";
    license = with lib.licenses; [
      gpl2Only
      bsd3
    ];
    platforms = [ "x86_64-linux" ];
    broken = kernel.kernelOlder "6.6";
  };
}
