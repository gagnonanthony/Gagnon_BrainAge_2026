#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Replace atlas labels with effect sizes from a CSV file.
"""

import argparse

import pandas as pd
import nibabel as nib
import numpy as np


subcortical_regions = [
    "GP_L",
    "GP_R",
    "NAC_L",
    "NAC_R",
    "Otha_L",
    "Otha_R",
    "PPtha_L",
    "PPtha_R",
    "Stha_L",
    "Stha_R",
    "brainstem",
    "cHipp_L",
    "cHipp_R",
    "cTtha_L",
    "cTtha_R",
    "dCa_L",
    "dCa_R",
    "dlPu_L",
    "dlPu_R",
    "lAmyg_L",
    "lAmyg_R",
    "lPFtha_L",
    "lPFtha_R",
    "left_cerebellum_cortex",
    "mAmyg_L",
    "mAmyg_R",
    "mPFtha_L",
    "mPFtha_R",
    "mPMtha_L",
    "mPMtha_R",
    "rHipp_L",
    "rHipp_R",
    "rTtha_L",
    "rTtha_R",
    "right_cerebellum_cortex",
    "vCa_L",
    "vCa_R",
    "vmPu_L",
    "vmPu_R",
]
frontal_regions = [
    "SFG_L_6_1",
    "SFG_L_6_2",
    "SFG_L_6_3",
    "SFG_L_6_4",
    "SFG_L_6_5",
    "SFG_L_6_6",
    "SFG_R_6_1",
    "SFG_R_6_2",
    "SFG_R_6_3",
    "SFG_R_6_4",
    "SFG_R_6_5",
    "SFG_R_6_6",
    "MFG_L_7_1",
    "MFG_L_7_2",
    "MFG_L_7_3",
    "MFG_L_7_4",
    "MFG_L_7_5",
    "MFG_L_7_6",
    "MFG_L_7_7",
    "MFG_R_7_1",
    "MFG_R_7_2",
    "MFG_R_7_3",
    "MFG_R_7_4",
    "MFG_R_7_5",
    "MFG_R_7_6",
    "MFG_R_7_7",
    "IFG_L_6_1",
    "IFG_L_6_2",
    "IFG_L_6_3",
    "IFG_L_6_4",
    "IFG_L_6_5",
    "IFG_L_6_6",
    "IFG_R_6_1",
    "IFG_R_6_2",
    "IFG_R_6_3",
    "IFG_R_6_4",
    "IFG_R_6_5",
    "IFG_R_6_6",
    "OrG_L_6_1",
    "OrG_L_6_2",
    "OrG_L_6_3",
    "OrG_L_6_4",
    "OrG_L_6_5",
    "OrG_L_6_6",
    "OrG_R_6_1",
    "OrG_R_6_2",
    "OrG_R_6_3",
    "OrG_R_6_4",
    "OrG_R_6_5",
    "OrG_R_6_6",
    "PrG_L_6_1",
    "PrG_L_6_2",
    "PrG_L_6_3",
    "PrG_L_6_4",
    "PrG_L_6_5",
    "PrG_L_6_6",
    "PrG_R_6_1",
    "PrG_R_6_2",
    "PrG_R_6_3",
    "PrG_R_6_4",
    "PrG_R_6_5",
    "PrG_R_6_6",
    "PCL_L_2_1",
    "PCL_L_2_2",
    "PCL_R_2_1",
    "PCL_R_2_2",
]
temporal_regions = [
    "STG_L_6_1",
    "STG_L_6_2",
    "STG_L_6_3",
    "STG_L_6_4",
    "STG_L_6_5",
    "STG_L_6_6",
    "STG_R_6_1",
    "STG_R_6_2",
    "STG_R_6_3",
    "STG_R_6_4",
    "STG_R_6_5",
    "STG_R_6_6",
    "MTG_L_4_1",
    "MTG_L_4_2",
    "MTG_L_4_3",
    "MTG_L_4_4",
    "MTG_R_4_1",
    "MTG_R_4_2",
    "MTG_R_4_3",
    "MTG_R_4_4",
    "ITG_L_5_1",
    "ITG_L_5_2",
    "ITG_L_5_3",
    "ITG_L_5_4",
    "ITG_L_5_5",
    "ITG_R_5_1",
    "ITG_R_5_2",
    "ITG_R_5_3",
    "ITG_R_5_4",
    "ITG_R_5_5",
    "FuG_L_3_1",
    "FuG_L_3_2",
    "FuG_L_3_3",
    "FuG_R_3_1",
    "FuG_R_3_2",
    "FuG_R_3_3",
    "PhG_L_6_1",
    "PhG_L_6_2",
    "PhG_L_6_3",
    "PhG_L_6_4",
    "PhG_L_6_5",
    "PhG_L_6_6",
    "PhG_R_6_1",
    "PhG_R_6_2",
    "PhG_R_6_3",
    "PhG_R_6_4",
    "PhG_R_6_5",
    "PhG_R_6_6",
    "pSTS_L_2_1",
    "pSTS_L_2_2",
    "pSTS_R_2_1",
    "pSTS_R_2_2",
]
parietal_regions = [
    "SPL_L_4_1",
    "SPL_L_4_2",
    "SPL_L_4_3",
    "SPL_L_4_4",
    "SPL_R_4_1",
    "SPL_R_4_2",
    "SPL_R_4_3",
    "SPL_R_4_4",
    "IPL_L_6_1",
    "IPL_L_6_2",
    "IPL_L_6_3",
    "IPL_L_6_4",
    "IPL_L_6_5",
    "IPL_L_6_6",
    "IPL_R_6_1",
    "IPL_R_6_2",
    "IPL_R_6_3",
    "IPL_R_6_4",
    "IPL_R_6_5",
    "IPL_R_6_6",
    "PCun_L_4_1",
    "PCun_L_4_2",
    "PCun_L_4_3",
    "PCun_L_4_4",
    "PCun_R_4_1",
    "PCun_R_4_2",
    "PCun_R_4_3",
    "PCun_R_4_4",
    "PoG_L_4_1",
    "PoG_L_4_2",
    "PoG_L_4_3",
    "PoG_L_4_4",
    "PoG_R_4_1",
    "PoG_R_4_2",
    "PoG_R_4_3",
    "PoG_R_4_4",
]
insular_regions = [
    "INS_L_6_1",
    "INS_L_6_2",
    "INS_L_6_3",
    "INS_R_6_1",
    "INS_R_6_2",
    "INS_R_6_3",
]
limbic_regions = [
    "CG_L_5_1",
    "CG_L_5_2",
    "CG_L_5_3",
    "CG_L_5_4",
    "CG_L_5_5",
    "CG_R_5_1",
    "CG_R_5_2",
    "CG_R_5_3",
    "CG_R_5_4",
    "CG_R_5_5",
]
occipital_regions = [
    "MVOcC_L_5_1",
    "MVOcC_L_5_2",
    "MVOcC_L_5_3",
    "MVOcC_L_5_4",
    "MVOcC_L_5_5",
    "MVOcC_R_5_1",
    "MVOcC_R_5_2",
    "MVOcC_R_5_3",
    "MVOcC_R_5_4",
    "MVOcC_R_5_5",
    "LOcC_L_4_1",
    "LOcC_L_4_2",
    "LOcC_L_4_3",
    "LOcC_L_4_4",
    "LOcC_R_4_1",
    "LOcC_R_4_2",
    "LOcC_R_4_3",
    "LOcC_R_4_4",
]


def main(atlas_file, lut, dx, effects_file, out_file):
    # Load atlas
    atlas_gii = nib.load(atlas_file)
    labels = atlas_gii.darrays[0].data.astype(int)

    print(labels)

    # Load effect sizes (region name → effect size)
    df = pd.read_csv(effects_file)

    # Extract effect sizes for the specified diagnosis
    df = df[df["Diagnosis"] == dx]

    # For each individual region in region groups above, append the effect size
    # in a new df.
    BAG_list = [
        "BAG_Frontal",
        "BAG_Temporal",
        "BAG_Parietal",
        "BAG_Insula",
        "BAG_Limbic",
        "BAG_Occipital",
        "BAG_Subcortical",
    ]
    list_d = []

    for region_group, bag_name in zip(
        [
            frontal_regions,
            temporal_regions,
            parietal_regions,
            insular_regions,
            limbic_regions,
            occipital_regions,
            subcortical_regions,
        ],
        BAG_list,
    ):
        for region in region_group:
            list_d.append(
                0
                if df.loc[df.loc[:, "Region"] == bag_name,
                          "p-value permuted"].item()
                > 0.05
                else int(
                    df.loc[df.loc[:, "Region"] == bag_name,
                           "Cohen's d"].item() * 100
                )
            )

    # Create a dictionary mapping region names to effect sizes
    effect_dict = dict(
        zip(
            (
                frontal_regions
                + temporal_regions
                + parietal_regions
                + insular_regions
                + limbic_regions
                + occipital_regions
                + subcortical_regions
            ),
            list_d,
        )
    )

    # Grab label table.
    label_table = pd.read_csv(lut, sep="\t")

    # Initialize effect map for all vertices
    effect_map = np.full_like(labels, np.nan, dtype=float)

    # Loop over label table rows
    for _, row in label_table.iterrows():
        region_id = row["index"]   # integer ID in label.gii
        region_name = row["label"]  # string region name

        if region_name in effect_dict:
            effect_val = effect_dict[region_name]
            effect_map[labels == region_id] = effect_val

    # Count the number of nan and non-nan.
    num_nan = np.sum(np.isnan(effect_map))
    num_non_nan = effect_map.size - num_nan
    print(f"Number of NaN values: {num_nan}")
    print(f"Number of non-NaN values: {num_non_nan}")
    # Save new atlas
    new_darray = nib.gifti.GiftiDataArray(effect_map.astype(np.float32))
    new_gii = nib.gifti.GiftiImage(darrays=[new_darray])
    nib.save(new_gii, out_file)
    print(f"✅ Saved effect size atlas to: {out_file}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Map effect sizes to brain atlas")
    parser.add_argument("--dx", required=True,
                        help="Diagnosis label (e.g., 'ADHD')")
    parser.add_argument(
        "--atlas", required=True, help="Input atlas NIfTI file (.nii.gz)"
    )
    parser.add_argument("--lut", required=True,
                        help="Lookup table (TSV file).")
    parser.add_argument("--effects", required=True,
                        help="CSV with effect size data.")
    parser.add_argument(
        "--out", required=True, help="Output NIfTI file with effect sizes"
    )
    args = parser.parse_args()

    main(args.atlas, args.lut, args.dx, args.effects, args.out)
