# morrownr/rtw89 — actively-maintained out-of-tree Realtek WiFi 6/6E/7 driver.
#
# Why this exists: the RTL8852AU (TP-Link Archer TX20U Plus, our only NIC) has
# NO in-tree USB support until kernel 6.19, and the previously-used
# lwfinger/rtl8852au is dead (builds only up to ~6.9/6.16, marked broken on
# newer kernels). morrownr/rtw89 supports kernel 6.6+, so it builds against Zen.
#
# The .ko files are installed under `updates/` so depmod prefers them over the
# incomplete in-tree rtw89 (avoids a file-path collision in kernel/).
#
# Build via the kernel's package set so `kernel` matches the running kernel:
#   config.boot.kernelPackages.callPackage ./pkgs/rtw89-morrownr.nix { }

{ lib, stdenv, fetchFromGitHub, kernel, bc, nukeReferences }:

let
  kdir = "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build";
in
stdenv.mkDerivation {
  pname = "rtw89-morrownr";
  version = "${kernel.version}-unstable-2026-07-04";

  src = fetchFromGitHub {
    owner = "morrownr";
    repo = "rtw89";
    rev = "8987afcc9277586557649fd1cb0e3a77d4295136";
    hash = "sha256-06NDWwmpAN8C9NAlObjPBbrtdpyp7vvbBsRZjgGhob8=";
  };

  nativeBuildInputs = [ bc nukeReferences ] ++ kernel.moduleBuildDependencies;

  hardeningDisable = [ "pic" "format" ];
  # Realtek out-of-tree trees trip newer-GCC default-init errors.
  env.NIX_CFLAGS_COMPILE = "-Wno-designated-init";
  enableParallelBuilding = true;

  buildPhase = ''
    runHook preBuild
    make -j"$NIX_BUILD_CORES" \
      ARCH=${stdenv.hostPlatform.linuxArch} \
      ${lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform)
        "CROSS_COMPILE=${stdenv.cc.targetPrefix}"} \
      KVER=${kernel.modDirVersion} KDIR=${kdir} \
      -C ${kdir} M="$PWD" modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    dest="$out/lib/modules/${kernel.modDirVersion}/updates"
    mkdir -p "$dest"
    find . -name '*.ko' -exec cp -v {} "$dest/" \;
    nuke-refs "$dest"/*.ko
    runHook postInstall
  '';

  meta = {
    description = "morrownr out-of-tree rtw89 driver (Realtek WiFi 6/6E/7, incl. RTL8852AU USB)";
    homepage = "https://github.com/morrownr/rtw89";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    broken = kernel.kernelOlder "6.6";
  };
}
