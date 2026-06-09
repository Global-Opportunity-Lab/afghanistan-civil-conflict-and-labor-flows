"""
5a_figS12_dataprep.py

Identifies conflict events occurring near road networks within Afghan districts,
within a window (defined by WINDOW_DAYS) before each district's peak conflict date.

This script runs on a linux server (run time appox 3 mins) -- see README.md. Changes may be needed to run locally. 

Pipeline
--------
1. For each district, find road segments within a 10 km buffer zone that are
   network-connected to the district's own roads.
2. Buffer those road segments by 5 km to create a road-proximity area.
3. Spatially join ACLED conflict events to those road-proximity areas.
4. Filter to events in [bestDate_D, bestDate] (D-day pre-peak window).
5. Aggregate to district-year level; write results to violence_temp.csv.

Required input files
--------------------
district398.geojson           Afghan district polygons        (DISTID field)
afg_road_network.geojson  Road network line geometries
Conflict_district.csv           ACLED events with columns:
                                  geom_wkt, year, where_prec, date_prec,
                                  date_start, id
peakInMigDate.csv               Peak dates per district-year with columns:
                                  distid, bestDate, year

Minimal reproducible example
-----------------------------
Set USE_SYNTHETIC_DATA = True to run the full pipeline on generated data
without any real input files.
"""

import geopandas as gpd
import networkx as nx
import os
import pandas as pd
from multiprocessing import Pool
from shapely import wkt
from shapely.ops import unary_union

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

# ── Root directories (mirror config.R) ──────────────────────────────────────
SAT_ROOT = "/data/afg_satellite"

# ── Input/output paths ───────────────────────────────────────────────────────
DISTRICT_SHP      = os.path.join(SAT_ROOT, "shp/district398/district398.geojson")
ROAD_NETWORK      = os.path.join(SAT_ROOT, "intermediate_data/afg_road_network.geojson")
CONFLICT_CSV      = os.path.join(SAT_ROOT, "Conflict_district.csv")
PEAK_DATES_CSV    = os.path.join(SAT_ROOT, "intermediate_data/peakInMigDate.csv")
VIOLENCE_ROAD_CSV = os.path.join(SAT_ROOT, "intermediate_data/violence_roads.csv")

# Toggle to True to run on generated synthetic data (no real files needed)
USE_SYNTHETIC_DATA = False

# Number of days before bestDate defining the pre-peak conflict window
WINDOW_DAYS = 1


def find_connected_roads(district, roads, buffer_distance=10000):
    """
    Return roads within buffer_distance of a district that are network-connected
    to roads intersecting the district.

    Builds an adjacency graph of road segments within the buffer zone, then
    walks all nodes reachable from any segment that crosses the district itself.

    Parameters
    ----------
    district : GeoDataFrame
        Single-row GeoDataFrame for one district (projected CRS, metres).
    roads : GeoDataFrame
        Road network line geometries (same CRS as district).
    buffer_distance : float
        Buffer radius in metres. Default 10 000 m.

    Returns
    -------
    GeoDataFrame
        Road segments inside the annular buffer zone (buffer minus district)
        that are topologically reachable from the district's own road network.
    """
    # Annular ring: within buffer_distance of the district boundary, excluding
    # the district interior
    annular_buffer = district['geometry'].buffer(buffer_distance).difference(
        district['geometry']
    )

    district_roads = roads[roads.intersects(district.geometry.iloc[0])]
    buffer_roads   = roads[roads.intersects(annular_buffer.iloc[0])]

    # Build intersection graph: nodes = road segments, edges = physical intersections
    G = nx.Graph()
    for idx, road in buffer_roads.iterrows():
        G.add_node(idx, geometry=road.geometry)
    for idx1, road1 in buffer_roads.iterrows():
        for idx2, road2 in buffer_roads.iterrows():
            if idx1 < idx2 and road1.geometry.intersects(road2.geometry):
                G.add_edge(idx1, idx2)

    # Collect all buffer-zone segments reachable from any district road
    connected_idx = set()
    for idx in district_roads.index:
        if idx in G:
            connected_idx.update(nx.node_connected_component(G, idx))

    return buffer_roads.loc[list(connected_idx)].clip(annular_buffer)


def make_road_proximity_polygon(connected_roads):
    """
    Create a 5 km road-proximity polygon for one district's connected road segments.

    Dissolves all road geometries into a single shape, buffers it by 5 km, and
    clips the result to the 10 km annular ring around the district.

    Note: reads districts_utm from the module-level global — required for
    multiprocessing compatibility (Pool workers inherit globals via fork on Unix).

    Parameters
    ----------
    connected_roads : GeoDataFrame
        Connected road segments for one district (must have a DISTID column).

    Returns
    -------
    GeoSeries
        Single-element GeoSeries containing the road-proximity polygon.
    """
    distid   = connected_roads.DISTID.unique()[0]
    district = districts_utm[districts_utm.DISTID == distid].copy()
    annular_buffer = district['geometry'].buffer(10000).difference(district['geometry'])
    return (
        gpd.GeoDataFrame(geometry=[unary_union(connected_roads.geometry)], crs=connected_roads.crs)
        .buffer(5000)
        .clip(annular_buffer)
    )


def create_synthetic_data():
    """
    Generate minimal synthetic datasets matching the schema of the real inputs.

    Creates two districts, a simple road grid, three conflict events, and a
    peak-date table. The conflict events are placed along the roads so the
    pipeline produces non-empty output.

    Returns
    -------
    tuple : (districts_utm, roads_utm, conflict, peak_dates)
        GeoDataFrames / DataFrames in the CRS and schema expected by the pipeline.
    """
    from shapely.geometry import box, LineString, Point

    # UTM zone 42N covers Afghanistan; coordinates are in metres
    crs = 'EPSG:32642'

    # Two small square districts 30 km apart (10 km × 10 km each)
    districts = gpd.GeoDataFrame(
        {'DISTID': [1, 2]},
        geometry=[box(0, 0, 10000, 10000), box(30000, 0, 40000, 10000)],
        crs=crs,
    )

    # Three road segments crossing or connecting the two districts
    roads = gpd.GeoDataFrame(
        geometry=[
            LineString([(5000, -5000),  (5000,  20000)]),   # vertical through district 1
            LineString([(-5000,  5000), (45000,  5000)]),   # horizontal, spans both
            LineString([(35000, -5000), (35000, 20000)]),   # vertical through district 2
        ],
        crs=crs,
    )

    # Three ACLED-style conflict events near the roads
    # Stored in WGS-84 (EPSG:4326) to match the real data schema
    conflict = gpd.GeoDataFrame(
        {
            'id':         [10, 11, 12],
            'year':       [2015, 2015, 2016],
            'where_prec': [1, 2, 1],
            'date_prec':  [1, 1, 2],
            'date_start': ['2015-06-01', '2015-06-10', '2016-07-15'],
        },
        geometry=[Point(5000, 5000), Point(35000, 5000), Point(5000, 5000)],
        crs=crs,
    ).to_crs('EPSG:4326')

    peak_dates = pd.DataFrame({
        'distid':   [1,            2],
        'year':     [2015,         2016],
        'bestDate': ['2015-06-15', '2016-07-20'],
    })
    peak_dates['window_start'] = (
        pd.to_datetime(peak_dates['bestDate']) - pd.Timedelta(days=WINDOW_DAYS)
    ).dt.date

    return districts, roads, conflict, peak_dates


# ── Main pipeline ──────────────────────────────────────────────────────────────

if __name__ == '__main__':

    # 1. Load (or generate) input data ─────────────────────────────────────────
    if USE_SYNTHETIC_DATA:
        districts_utm, roads_utm, conflict, peak_dates = create_synthetic_data()
    else:
        districts_utm = gpd.read_file(DISTRICT_SHP)
        districts_utm = districts_utm.to_crs(districts_utm.estimate_utm_crs())

        roads_utm = gpd.read_file(ROAD_NETWORK)
        roads_utm = roads_utm.to_crs(roads_utm.estimate_utm_crs())

        conflict = pd.read_csv(CONFLICT_CSV)
        conflict['geometry'] = conflict['geom_wkt'].apply(wkt.loads)
        conflict = conflict.drop(columns=['geom_wkt', 'Unnamed: 0'])
        conflict = gpd.GeoDataFrame(conflict, geometry='geometry', crs='EPSG:4326')
        # ACLED quality filters: spatial precision ≤ 3, date precision ≤ 3
        conflict = conflict[
            (conflict['year'] >= 2013) & (conflict['year'] <= 2020) &
            (conflict['where_prec'] <= 3) & (conflict['date_prec'] <= 3)
        ]

        peak_dates = pd.read_csv(PEAK_DATES_CSV)
        peak_dates = peak_dates.drop(columns='Unnamed: 0')
        peak_dates['window_start'] = (
            pd.to_datetime(peak_dates['bestDate']) - pd.Timedelta(days=WINDOW_DAYS)
        ).dt.date

    # 2. Find network-connected roads for each district (serial) ───────────────
    connected_roads_per_district = []
    for distid in districts_utm.DISTID.unique():
        district = districts_utm[districts_utm.DISTID == distid].copy()
        roads = find_connected_roads(district, roads_utm)
        roads['DISTID'] = distid
        connected_roads_per_district.append(roads)

    # 3. Buffer road segments by 5 km within the annular zone (parallel) ───────
    # districts_utm must be a module-level global before Pool is created so that
    # make_road_proximity_polygon() can read it in each worker (Unix fork semantics)
    with Pool(processes=24) as pool:
        road_proximity_per_district = pool.map(make_road_proximity_polygon, connected_roads_per_district)

    df_base = pd.concat(connected_roads_per_district)
    df_base = df_base.reset_index()
    # df_base.columns = ['index', 'geometry']
    df_base = df_base.set_geometry("geometry")
    df_base = df_base.drop(columns = 'index')

    # 4. Assemble per-district road-proximity polygons into a single GeoDataFrame
    # Each element is a single-row GeoSeries; concat, then restore CRS and reproject
    road_proximity = (
        pd.concat(road_proximity_per_district)
        .reset_index(drop=True)
        .to_frame(name='geometry')
    )
    road_proximity = gpd.GeoDataFrame(road_proximity, geometry='geometry')
    road_proximity['DISTID'] = districts_utm.DISTID.unique()
    road_proximity = road_proximity.set_crs(districts_utm.crs).to_crs(conflict.crs)

    # 5. Spatially join conflict events to road-proximity polygons ─────────────
    conflict_near_roads = road_proximity.sjoin(conflict)
    conflict_near_roads['date_conflict'] = pd.to_datetime(conflict_near_roads['date_start']).dt.date
    conflict_near_roads = conflict_near_roads.rename(columns={'DISTID_left': 'DISTID'})

    # 6. Merge with peak-date window ───────────────────────────────────────────
    conflict_near_roads = conflict_near_roads.merge(
        peak_dates[['distid', 'bestDate', 'window_start', 'year']]
            .rename(columns={'distid': 'DISTID'}),
        on=['DISTID', 'year'],
        how='inner',
    )

    # Keep only events within the D-day pre-peak window [bestDate_D, bestDate]
    # String comparison works for ISO-format dates (YYYY-MM-DD)
    date = conflict_near_roads['date_conflict'].astype(str)
    in_window = (
        (date >= conflict_near_roads['window_start'].astype(str)) &
        (date <= conflict_near_roads['bestDate'].astype(str))
    )
    conflict_in_window = conflict_near_roads[in_window]

    # 7. Aggregate to district-year level and create binary indicator ───────────
    output = conflict_in_window.groupby(['DISTID', 'year'])['id'].count().reset_index()
    output = output.rename(columns={'id': 'n_events'})
    output['any_violence_road'] = (output['n_events'] > 0).astype(int)

    output.to_csv(VIOLENCE_ROAD_CSV, index=False)
    print(f"Done. {len(output)} district-year rows written to {VIOLENCE_ROAD_CSV}.")



