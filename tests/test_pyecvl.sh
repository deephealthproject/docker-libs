#!/bin/bash

# set the path containing sources and tests
ECVL_SRC=${ECVL_SRC:-"/usr/local/src/ecvl"}
PYECVL_SRC=${PYECVL_SRC:-"/usr/local/src/pyecvl"}

# run tests
cd ${PYECVL_SRC} && pytest tests

# run examples
cd ${PYECVL_SRC}/examples 
python3 dataset.py "${ECVL_SRC}/examples/data/mnist/mnist.yml"
python3 ecvl_eddl.py "${ECVL_SRC}/examples/data/test.jpg" "${ECVL_SRC}/examples/data/mnist/mnist.yml"
python3 img_format.py "${ECVL_SRC}/examples/data/nifti/LR_nifti.nii" "${ECVL_SRC}/examples/data/dicom/ISIC_0000008.dcm"
python3 imgproc.py "${ECVL_SRC}/examples/data/test.jpg"
python3 openslide.py "${ECVL_SRC}/examples/data/hamamatsu/test3-DAPI 2 (387).ndpi"
python3 read_write.py "${ECVL_SRC}/examples/data/test.jpg" "test_mod.jpg"