"""
FigS11.py

Code to construct example of road network analysis set up

Pipeline
--------
1. For each district, find road segments within a 10 km buffer zone that are
   network-connected to the district's own roads.
2. Buffer those road segments by 5 km to create a road-proximity area.
3. Plot for DISTID == 101

Required input files
--------------------
district398.geojson       Afghan district polygons (DISTID field)
afg_road_network.geojson  Road network line geometries
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



# ── Input/output paths ───────────────────────────────────────────────────────
DISTRICT_SHP      = "./paper_figures_tables/data/district398.geojson"
ROAD_NETWORK      = "./paper_figures_tables/data/figS11_afg_road_network.geojson"


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


# ── Main pipeline ──────────────────────────────────────────────────────────────

if __name__ == '__main__':

    districts_utm = gpd.read_file(DISTRICT_SHP)
    districts_utm = districts_utm.to_crs(districts_utm.estimate_utm_crs())

    roads_utm = gpd.read_file(ROAD_NETWORK)
    roads_utm = roads_utm.to_crs(districts_utm.estimate_utm_crs())


    # 2. Find network-connected roads for district 101 ────────────────────────
    connected_roads_per_district = []
    for distid in [101]:
        district = districts_utm[districts_utm.DISTID == distid].copy()
        roads = find_connected_roads(district, roads_utm)
        roads['DISTID'] = distid
        connected_roads_per_district.append(roads)

    # 3. Buffer road segments by 5 km within the annular zone ────────────────
    road_proximity_per_district = list(map(make_road_proximity_polygon, connected_roads_per_district))

    df_base = pd.concat(connected_roads_per_district)
    df_base = df_base.reset_index()
    # df_base.columns = ['index', 'geometry']
    df_base = df_base.set_geometry("geometry")
    df_base = df_base.drop(columns = 'index')

    # 4. Assemble per-district road-proximity polygons into a single GeoDataFrame
    # Each element is a single-row GeoSeries;
    road_proximity = (
        pd.concat(road_proximity_per_district)
        .reset_index(drop=True)
        .to_frame(name='geometry')
    )
    road_proximity = gpd.GeoDataFrame(road_proximity, geometry='geometry')
    road_proximity['DISTID'] = [r.DISTID.unique()[0] for r in connected_roads_per_district]

    #### Supplementary Figure S12 - plot example for DISTID 101
    fig, ax = plt.subplots(figsize = (8, 8))

    road_proximity[road_proximity['DISTID'] == 101].to_crs(road_proximity.estimate_utm_crs()).plot(ax = ax, facecolor = 'None', edgecolor = 'grey')
    df_base[df_base.DISTID == 101].to_crs(df_base.estimate_utm_crs()).plot(ax = ax, color = 'black')
    districts_utm[districts_utm['DISTID'] == 101].buffer(10000).difference(districts_utm[districts_utm.DISTID == 101]).plot(ax = ax, facecolor = 'None', edgecolor = 'red')
    districts_utm[districts_utm.DISTID == 101].plot(ax = ax, facecolor = 'None', edgecolor = 'green')

    ### Legends (manually constructed)
    lmark1 = Line2D(
            [],
            [],
            color='grey',
            linewidth=3,
            alpha=0.4,
            label='5KM Road Buffer')

    lmark2 = Line2D(
            [],
            [],
            color='black',
            linewidth=3,
            alpha=0.4,
            label='Road')

    lmark3 = Line2D(
            [],
            [],
            color='red',
            linewidth=3,
            alpha=0.4,
            label='10 KM Buffer Zone Around District')

    lmark4 = Line2D(
            [],
            [],
            color='green',
            linewidth=3,
            alpha=0.4,
            label='District Boundary')
        
    ax.legend(
            handles=[
                lmark1, 
                lmark2,
                lmark3, 
                lmark4],
            # title="Legend",
            loc='lower left',
            ncol=1,
            shadow=True, 
        bbox_to_anchor = (1.05, 1))

    plt.axis("off")

    plt.savefig("./paper_figures_tables/output/figS11.pdf", bbox_inches="tight")
    plt.show()
