import gc
import os
import pandas as pd
from collections import Counter
from datetime import datetime
import glob


# ── Root directories (mirror config.R) ──────────────────────────────────────
CDR_ROOT = "/data/afg_anon"
SAT_ROOT = "/data/afg_satellite"
TMP_ROOT = "/home/xtai/tmp"

# ── Derived paths ────────────────────────────────────────────────────────────
DAILY_MODAL_DIR = os.path.join(CDR_ROOT, "displacement_metrics/home_locations/daily_modal_voice_only_2013-2020_version/")
MIGSTATS_DIR    = os.path.join(TMP_ROOT, "migstats/")
MIG_STATS_CSV   = os.path.join(SAT_ROOT, "snair/mig_stats_agg.csv")

# Date range covering the full observation period
STUDY_START = '2013-04-01'
STUDY_END   = '2020-10-31'


def find_location_in_window(x, d=30, go_back_window=90):
    """
    For a single individual's time series of daily home locations, identify
    migration events and classify subsequent movement behaviour.

    A person is defined as an in-migrant on day t if their current home location
    differs from their home location d days prior (default: 30 days).

    For each in-migrant day, two outcomes are tracked over a forward window
    of length go_back_window (default: 90 days):

        - stays_all_90:  the person is observed exclusively at the new (destination)
                         location throughout the entire forward window, i.e. no other
                         location appears. Indicates a permanent move.

        - goes_back_90:  the person's origin location (home location at t - d)
                         appears at least once in the forward window.
                         Indicates a temporary or return move.

    By construction, stays_all_90 and goes_back_90 are mutually exclusive:
    if only one location appears in the window (stays_all_90 = 1), the origin
    cannot be present, so goes_back_90 must be 0.

    Parameters
    ----------
    x : pd.DataFrame
        Individual-level data with columns ['day', 'home_location'].
        'day' should be parseable as a datetime.
    d : int, optional
        Look-back window in days used to define migration (default: 30).
    go_back_window : int, optional
        Forward window in days used to classify post-migration behaviour (default: 90).

    Returns
    -------
    pd.DataFrame
        Input dataframe reindexed to daily frequency over the study period,
        with the following columns added:
            - home_location_{d}_prev : home location d days prior
            - in_migrant             : 1 if current location != location d days ago
            - stays_all_{go_back_window} : 1 if in_migrant and only destination
                                           seen in forward window
            - goes_back_{go_back_window} : 1 if in_migrant and origin seen in
                                           forward window
    """
    # Reindex to a continuous daily calendar for the full study period,
    # filling unobserved days with NaN
    temp = x.set_index('day')
    days = pd.date_range(start=STUDY_START, end=STUDY_END, freq='D')
    temp = temp.reindex(days)
    temp = temp.reset_index()

    # Identify origin: home location d days before day t
    temp[f'home_location_{d}_prev'] = temp.home_location.shift(d)

    # Flag in-migrants: current location differs from origin, both observed
    temp['in_migrant'] = (
        (temp[f'home_location_{d}_prev'] != temp['home_location']) &
        temp['home_location'].notna() &
        temp[f'home_location_{d}_prev'].notna()
    ) * 1

    # Build a Counter of all locations observed in [t, t + go_back_window)
    # for each day t, ignoring NaN (unobserved days)
    indexer = pd.api.indexers.FixedForwardWindowIndexer(window_size=go_back_window)
    location_counts = [
        Counter(w.dropna())
        for w in temp['home_location'].rolling(window=indexer)
    ]
    temp[f'locations_d_dplus_{go_back_window}'] = location_counts

    # stays_all: in-migrant and only one unique location seen in forward window
    # (i.e. the destination — no return to origin or onward movement)
    temp[f'stays_all_{go_back_window}'] = temp.apply(
        lambda row: 1 if (
            (row['in_migrant'] == 1) &
            (row['home_location'] in row[f'locations_d_dplus_{go_back_window}']) &
            (len(row[f'locations_d_dplus_{go_back_window}']) == 1)
        ) else 0,
        axis=1
    )

    # goes_back: in-migrant and origin location appears anywhere in forward window
    temp[f'goes_back_{go_back_window}'] = temp.apply(
        lambda row: 1 if (
            (row['in_migrant'] == 1) &
            (row[f'home_location_{d}_prev'] in row[f'locations_d_dplus_{go_back_window}'])
        ) else 0,
        axis=1
    )

    # Drop intermediate column not needed downstream
    temp = temp.drop(columns=[f'locations_d_dplus_{go_back_window}'])

    return temp


# ---------------------------------------------------------------------------
# Main loop: process each input file and save district-day migration stats
# ---------------------------------------------------------------------------

# Columns to aggregate at the district-day level
STAT_COLS = ['in_migrant', 'stays_all_90', 'goes_back_90']

### Load files
files = glob.glob(os.path.join(DAILY_MODAL_DIR, '*.csv'))

print("No of Files", len(files))


mig_stat_dict = {}


for file in files:

    stub = file.split('/')[-1].split('.')[0]

    if stub not in mig_stat_dict:
        print(stub, datetime.now())

        df_base = pd.read_csv(file)

        if df_base.shape[0] == 0:
            print(stub, "no data!", datetime.now())
            continue

        df_base['day'] = pd.to_datetime(df_base['day'])
        df_base['ym'] = df_base['day'].dt.to_period('M').apply(str)
        df_base['year'] = df_base['day'].dt.year
        df_base = df_base.set_index('phoneHash1')

        print(f'Starting big job, {datetime.now()}')

        # Apply migration classification to each individual in parallel
        df_clean = df_base.groupby(level=0).apply(
            lambda x: find_location_in_window(x)
        )
        df_clean = df_clean.reset_index(drop=True, level=1)
        df_clean = df_clean.rename(columns={'index': 'day'})

        # Aggregate to district-day level
        mig_stats = (
            df_clean
            .reset_index()
            .groupby(['home_location', 'day'])[STAT_COLS]
            .sum()
            .reset_index()
        )

        mig_stats.to_csv(os.path.join(MIGSTATS_DIR, f"{stub}_mig_stats.csv"), index=False)

        # Free memory before next file
        df_base = None
        df_clean = None
        gc.collect()

files = glob.glob(os.path.join(MIGSTATS_DIR, "*.csv"))
len(files)

df_stats = pd.concat([pd.read_csv(f) for f in files])
df_stats = df_stats.groupby(['home_location', 'day']).sum().reset_index()
df_stats.to_csv(MIG_STATS_CSV, index = False)