{
  lib,
  stdenv,
  testers,
  # fetchers
  fetchFromGitHub,
  gitUpdater,
  # build tools
  cmake,
  # native dependencies
  eigen,
  boost,
  cgal,
  gmp,
  hdf5,
  icu,
  libaec,
  libxml2,
  mpfr,
  nlohmann_json,
  opencascade-occt_7_6,
  opencollada,
  pcre,
  zlib,
}:
let
  opencascade-occt = opencascade-occt_7_6;
in
stdenv.mkDerivation rec {
  pname = "ifcopenshell";
  version = "0.8.3";

  src = fetchFromGitHub {
    owner = "IfcOpenShell";
    repo = "IfcOpenShell";
    tag = "ifcconvert-${version}";
    fetchSubmodules = true;
    hash = "sha256-qTr5bMC1Sab/GKZ2v2QV29/VHnUevC4JAVvLteJ/dP4=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    # ifcopenshell needs stdc++
    (lib.getLib stdenv.cc.cc)
    boost
    cgal
    eigen
    gmp
    hdf5
    icu
    libaec
    libxml2
    mpfr
    nlohmann_json
    opencascade-occt
    opencollada
    pcre
  ];

  cmakeFlags = [
    "-DCMAKE_CXX_STANDARD=17"
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_IFCPYTHON=OFF"
    "-DCITYJSON_SUPPORT=OFF"
    "-DEIGEN_DIR=${eigen}/include/eigen3"
    "-DJSON_INCLUDE_DIR=${nlohmann_json}/include/"
    "-DOCC_INCLUDE_DIR=${opencascade-occt}/include/opencascade"
    "-DOCC_LIBRARY_DIR=${lib.getLib opencascade-occt}/lib"
    "-DOPENCOLLADA_INCLUDE_DIR=${opencollada}/include/opencollada"
    "-DOPENCOLLADA_LIBRARY_DIR=${lib.getLib opencollada}/lib/opencollada"
    "-DLIBXML2_INCLUDE_DIR=${libxml2.dev}/include/libxml2"
    "-DLIBXML2_LIBRARIES=${lib.getLib libxml2}/lib/libxml2${stdenv.hostPlatform.extensions.sharedLibrary}"
    "-DGMP_LIBRARY_DIR=${lib.getLib gmp}/lib/"
    "-DMPFR_LIBRARY_DIR=${lib.getLib mpfr}/lib/"
    # HDF5 support is currently not optional, see https://github.com/IfcOpenShell/IfcOpenShell/issues/1815
    "-DHDF5_SUPPORT=ON"
    "-DHDF5_INCLUDE_DIR=${hdf5.dev}/include/"
    "-DHDF5_LIBRARIES=${lib.getLib hdf5}/lib/libhdf5_cpp.so;${lib.getLib hdf5}/lib/libhdf5.so;${lib.getLib zlib}/lib/libz.so;${lib.getLib libaec}/lib/libaec.so;"
  ];

  preConfigure = ''
    cd cmake
  '';

  passthru = {
    updateScript = gitUpdater { rev-prefix = "ifcconvert-"; };
    tests = {
      version = testers.testVersion {
        command = "IfcConvert --version";
      };
    };
  };

  meta = with lib; {
    broken = stdenv.hostPlatform.isDarwin;
    description = "Open source IFC library and geometry engine";
    homepage = "https://ifcopenshell.org/";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ autra ];
  };
}
