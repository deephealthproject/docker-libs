![GitHub release (latest by date)](https://img.shields.io/github/v/release/deephealthproject/docker-libs)![GitHub](https://img.shields.io/github/license/deephealthproject/docker-libs)


# docker-libs

Docker images to develop and run software based on the [EDDL](https://github.com/deephealthproject/eddl) and [ECVL](https://github.com/deephealthproject/ecvl) libraries and their respective Python interfaces ([PyEDDL](https://github.com/deephealthproject/pyeddl) and [PyECVL](https://github.com/deephealthproject/pycvl)).

## TL;DR

E.g., `docker pull dhealth/pyecvl:0.1.0`


* Every library has a corresponding image repository:
  - `dhealth/eddl`
  - `dhealth/ecvl`
  - `dhealth/pyeddl`
  - `dhealth/pyecvl`

* Every tag and commit id you see in the git repository has a corresponding image tag
  - e.g., PyECVL [version 0.1.0](https://github.com/deephealthproject/pyecvl/tree/0.1.0) corresponds to the image tag [dhealth/pyecvl:0.1.0](https://hub.docker.com/layers/dhealth/pyecvl/0.1.0/)
  - e.g., PyECVL at [commit id 23a79c5](https://github.com/deephealthproject/pyecvl/tree/23a79c5b6ba39a5049901933edff2ca372713df7) corresponds to the image tag [dhealth/pyecvl:23a79c5](https://hub.docker.com/layers/dhealth/pyecvl/23a79c5/images/sha256-bea02aa37dbb4f0f987b56d5c33d319e4018c809b562bca09bd1df0b4c755425?context=explore) (use the first 7 characters of the commit id)

### Dependencies

When you use the DeepHealth image for a library, the image also contains the libraries on which it depends:
* PyECVL -> also contains PyEDDL, EDDL, ECVL
* PyEDDL -> also contains EDDL
* ECVL -> also contains EDDL
* EDDL -> on its own

If you want everything, **use the PyECVL image**.

### Toolkit

For all images, a toolkit version is also built that contains build requirements for software (compiler, headers, etc.).  You can use these to build your own software or rebuild the DeepHealth libraries from source.  Keep reading the section below for details.


## Detailed description

The `docker-libs` repository allows users to build and publish on a registry (e.g., DockerHub) Docker images containing the DeepHealth libraries: [EDDL](https://github.com/deephealthproject/eddl), [ECVL](https://github.com/deephealthproject/ecvl) and their Python wrappers, [PyEDDL](https://github.com/deephealthproject/pyeddl) and [PyECVL](https://github.com/deephealthproject/pycvl). All the images are based on the [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker) and the EDDL and ECVL libraries are configured to leverage NVIDIA GPUs.

Precompiled images for each DeepHealth library are published on [DockerHub](https://hub.docker.com/u/dhealth):

* **[`dhealth/eddl`](https://hub.docker.com/r/dhealth/eddl)** contains an installation of the EDDL library
* **[`dhealth/ecvl`](https://hub.docker.com/r/dhealth/ecvl)** contains an installation of the ECVL library with support for EDDL
* **[`dhealth/pyeddl`](https://hub.docker.com/r/dhealth/pyeddl)** contains an installation of the PyEDDL and EDDL library
* **[`dhealth/pyecvl`](https://hub.docker.com/r/dhealth/ecvl-toolkit)** contains an installation of the PyECVL library with support for PyEDDL

They are available with the `-toolkit` variant, which provides optional development tools (sources, compilers, etc.). 

In addition, to provide, under a common Docker tag, library revisions compatible with each other, the following images are periodically released on [DockerHub](https://hub.docker.com/u/dhealth) (see GitHub **[releases](https://github.com/deephealthproject/docker-libs/releases)**):

* **[`dhealth/libs`](https://hub.docker.com/r/dhealth/libs)** contains an installation of the EDDL and ECVL libraries
* **[`dhealth/libs-toolkit`](https://hub.docker.com/r/dhealth/libs-toolkit)** contains an installation of the EDDL and ECVL libraries, the source code of two libraries and all the development tools (compilers, libraries, etc.) you need to compile them
* **[`dhealth/pylibs`](https://hub.docker.com/r/dhealth/pylibs)** extends the `libs` image with the PyEDDL and PyECVL libraries
* **[`dhealth/pylibs-toolkit`](https://hub.docker.com/r/dhealth/pylibs-toolkit)** extends the `libs-toolkit` image with the PyEDDL and PyECVL libraries



##### Image TAGs

All the images are tagged accordingly with the revision of the corresponding libraries on GitHub, identified by commit ID or TAG: e.g., `dhealth/ecvl:1512be8` and`dhealth/ecvl-toolkit:1512be8`  are built on the `1512be8` revision (commit ID) of the ECVL library. If that revision is also associated with a Git TAG, it will be used as a Docker tag as well.



## Example usage

Open a shell in a container with access to the DeepHealth libraries:

```bash
docker run -it --rm dhealth/libs /bin/bash
```

Open a shell to compile your local project:

```bash
docker run -it -u $(id -u) -v $(pwd):/tests --rm dhealth/libs-toolkit /bin/bash
```



## How to build, test and publish

A `Makefile` allows to easily compile, test and publish the Docker images. Type `make help` to see the available `Makefile` targets, i.e.:

```bash
version                        Output the current version of this Makefile
help                           Show help
dependency_graph               make a dependency graph of the involved libraries
build                          Build all Docker images
build_eddl_toolkit             Build 'eddl-toolkit' image
build_ecvl_toolkit             Build 'ecvl-toolkit' image
build_libs_toolkit             Build 'libs-toolkit' image
build_eddl                     Build 'eddl' image
build_ecvl                     Build 'ecvl' image
build_libs                     Build 'libs' image
build_pyeddl_toolkit           Build 'pyeddl-toolkit' image
build_pyecvl_toolkit           Build 'pyecvl-toolkit' image
build_pylibs_toolkit           Build 'pylibs-toolkit' image
build_pyeddl                   Build 'pyeddl' image
build_pyecvl                   Build 'pyecvl' image
build_pylibs                   Build 'pylibs' image
test                           Test all docker images
test_eddl                      Test 'eddl' images
test_eddl_toolkit              Test 'eddl' images
test_ecvl                      Test 'ecvl' images
test_ecvl_toolkit              Test 'ecvl' images
test_pyeddl                    Test 'ecvl' images
test_pyeddl_toolkit            Test 'ecvl' images
test_pyecvl                    Test 'ecvl' images
test_pyecvl_toolkit            Test 'ecvl' images
push                           Push all images
push_libs                      Push 'libs' image
push_libs_base                 Push 'lib-base' image
push_eddl                      Push 'eddl' image
push_ecvl                      Push 'ecvl' image
push_libs_toolkit              Push 'libs-toolkit' image
push_libs_base_toolkit         Push 'libs-base-toolkit' image
push_eddl_toolkit              Push 'eddl-toolkit' images
push_ecvl_toolkit              Push 'ecvl-toolkit' images
push_pylibs                    Push 'pylibs' images
push_pyeddl                    Push 'pyeddl' images
push_pyecvl                    Push 'pyecvl' images
push_pylibs_toolkit            Push 'pylibs-toolkit' images
push_pyeddl_toolkit            Push 'pyeddl-toolkit' images
push_pyecvl_toolkit            Push 'pyeddl-toolkit' images
publish                        Publish all images to a Docker Registry (e.g., DockerHub)
publish_libs                   Publish 'libs' image
publish_eddl                   Publish 'eddl' image
publish_ecvl                   Publish 'ecvl' image
publish_libs_toolkit           Publish 'libs-toolkit' image
publish_eddl_toolkit           Publish 'eddl-toolkit' image
publish_ecvl_toolkit           Publish 'ecvl-toolkit' image
publish_pylibs                 Publish 'pylibs' image
publish_pyeddl                 Publish 'pyeddl' image
publish_pyecvl                 Publish 'pyecvl' image
publish_pylibs_toolkit         Publish 'pylibs-toolkit' image
publish_pyeddl_toolkit         Publish 'pyeddl-toolkit' image
publish_pyecvl_toolkit         Publish 'pyecvl-toolkit' image
docker-login                   Login to the Docker Registry
clean_eddl_sources             clean repository containing EDDL source code
clean_ecvl_sources             clean repository containing ECVL source code
clean_pyeddl_sources           clean repository containing PyEDDL source code
clean_pyecvl_sources           clean repository containing PyECVL source code
clean_libs_sources             clean repository containing libs source code
clean_pylibs_sources           clean repository containing pylibs source code
clean_sources                  clean repository containing source code
```

Edit the file `settings.conf` to customize your images (e.g., software revision, Docker registry, etc.)

