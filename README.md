
## **Regional brain age deviations reveal divergent developmental pathways in youth**

Authors: Anthony Gagnon<sup>1,2</sup>, Marie Brunet<sup>1</sup>, Maxime Descoteaux<sup>2</sup>, Larissa Takser<sup>1</sup>

Affiliations:\
<sup>1</sup> Department of Pediatrics, University of Sherbrooke, Québec, Canada\
<sup>2</sup> Sherbrooke Connectivity Imaging Lab (SCIL), University of Sherbrooke, Quebec, Canada

This repository contains all relevant code and scripts to reproduce the results found in Gagnon et al. 2025

## Setting up

This repository is using multiple virutal environment to access uncompatible dependencies. Please create individual virtualenv for the following package below:

`neurostatx`: Official instruction can be seen [here](https://gagnonanthony.github.io/NeuroStatX/)
```bash
pip install neurostatx==0.1.0

# Test the installation by calling the help of a CLI script.

AddNodesAttributes -h
```

`combat`: Official instructions can be seen [here](https://github.com/scil-vital/clinical-ComBAT)

Some additional R dependencies are always required to use the [lcmm](https://cecileproust-lima.github.io/lcmm/index.html) and [forestploter](https://github.com/adayim/forestploter).

## Structure

### `notebooks/`
Jupyter notebooks containing the complete analytical workflow (run sequentially):

1. **`1-QC.ipynb`** - Quality control of MRI raw data.
2. **`2-Harmonization.ipynb`** - Pairwise ComBAT harmonization.
3. **`3-BrainAge.ipynb`** - Brain age model development using XGBoost.
4. **`4-BAG-Diagnosis.ipynb`** - Case-control differences in Brain Age Gap (BAG) across psychiatric diagnoses
5. **`5-BAG-Profiles.ipynb`** - Associations between BAG and cognitive/behavioral profiles
6. **`6-BAG-Trajectories.ipynb`** - Longitudinal trajectories of individual maturation patterns
7. **`7-Viz.ipynb`** - Visualization of results
8. **`8-Demographics.ipynb`** - Demographic tables and descriptive statistics

### `scripts/`
R and Python scripts for specific analyses:

- **`mlcmm.R`** - Latent class mixed models for trajectory analysis using `lcmm` package
- **`evaluateTrajectories.R`** - Model evaluation and trajectory characterization
- **`trajectoryPredictors.R`** - Predictors of trajectory class membership
- **`posteriorProbabilities.R`** - Posterior probability calculations for class assignment
- **`bestModel.R`** - Model selection based on fit statistics
- **`plotForest.R`** - Forest plot generation for odds ratios with publication-ready formatting
- **`generateSurfaceOverlay.py`** - Brain surface visualization overlays
- **`cmd_mlcmm.sh`** - Wrapper script for running trajectory models on HCP servers.

### `atlas/`
Brainnetome Child atlas files and conversion scripts:

- **`atlas-BrainnetomeChild/`** - BIDS-compliant atlas files (fsaverage and fsLR-32k spaces)
- **`create_atlas_fsLR_32k.sh`** - Bash script for atlas conversion to fsLR surface space
- **`refs/`** - Reference files including FreeSurfer labels and lookup tables
- **`readme.md`** - Detailed atlas documentation and usage instructions

## Contact

For questions or issues, please open an issue! 

