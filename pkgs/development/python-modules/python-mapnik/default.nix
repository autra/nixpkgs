{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  substituteAll,
  pybind11,
  isPyPy,
  python,
  setuptools,
  pillow,
  pycairo,
  pkg-config,
  boost,
  cairo,
  harfbuzz,
  icu,
  libjpeg,
  libpng,
  libtiff,
  libwebp,
  mapnik,
  proj,
  zlib,
  libxml2,
  sqlite,
  pytestCheckHook,
  darwin,
  sparsehash,
}:

buildPythonPackage rec {
  pname = "python-mapnik";
  version = "4.0.0.beta";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mapnik";
    repo = "python-mapnik";
    # chosen because
    rev = "e25ea400e3e7945baaf5c3856143413ef969d315";
    hash = "sha256-ukRwW9Ngx6KIyDixSiFdPk4k+LwOChLyVcBWcJ1OGGc=";
    # Only needed for test data
    fetchSubmodules = true;
  };

  patches = [
    # python-mapnik seems to depend on having the mapnik src directory
    # structure available at build time. We just hardcode the paths.
    (substituteAll {
      src = ./find-libmapnik.patch;
      libmapnik = "${mapnik}/lib";
    })
    # Use `std::optional` rather than `boost::optional`
    # ./python-mapnik_std_optional.patch
  ];

  stdenv = if python.stdenv.hostPlatform.isDarwin then darwin.apple_sdk_11_0.stdenv else python.stdenv;

  build-system = [ setuptools ];

  nativeBuildInputs = [
    mapnik # for mapnik_config
    pkg-config
  ];

  buildInputs = [

  pybind11
  setuptools

  ];

  dependencies = [
    mapnik
    boost
    cairo
    harfbuzz
    icu
    libjpeg
    libpng
    libtiff
    libwebp
    proj
    zlib
    libxml2
    sqlite
    sparsehash
  ];

  propagatedBuildInputs = [
    pillow
    pycairo
  ];

  configureFlags = [ "XMLPARSER=libxml2" ];

  disabled = isPyPy;

  preBuild = ''
    export BOOST_PYTHON_LIB="boost_python${"${lib.versions.major python.version}${lib.versions.minor python.version}"}"
    export BOOST_THREAD_LIB="boost_thread"
    export BOOST_SYSTEM_LIB="boost_system"
    export PYCAIRO=true
    export XMLPARSER=libxml2
  '';

  nativeCheckInputs = [ pytestCheckHook ];

  preCheck =
    ''
      # import from $out
      rm -r mapnik
    ''
    + lib.optionalString stdenv.hostPlatform.isDarwin ''
      # Replace the hardcoded /tmp references with $TMPDIR
      sed -i "s,/tmp,$TMPDIR,g" test/python_tests/*.py
    '';

  # https://github.com/mapnik/python-mapnik/issues/255
  disabledTests = [
    "test_geometry_type"
    "test_passing_pycairo_context_pdf"
    "test_pdf_printing"
    "test_render_with_scale_factor"
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    "test_passing_pycairo_context_png"
    "test_passing_pycairo_context_svg"
    "test_pycairo_pdf_surface1"
    "test_pycairo_pdf_surface2"
    "test_pycairo_pdf_surface3"
    "test_pycairo_svg_surface1"
    "test_pycairo_svg_surface2"
    "test_pycairo_svg_surface3"
  ];

  pythonImportsCheck = [ "mapnik" ];

  meta = with lib; {
    description = "Python bindings for Mapnik";
    maintainers = [ ];
    homepage = "https://mapnik.org";
    license = licenses.lgpl21Plus;
  };
}
