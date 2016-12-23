SELECT comid, characteristic_id, characteristic_value, percent_nodata
INTO characteristic_data.divergence_routed_characteristics2
FROM characteristic_data.divergence_routed_characteristics as char
  JOIN nhdplus.nhdflowline_np21 as flow
  ON flow.nhdplus_comid = char.comid;

DROP TABLE characteristic_data.divergence_routed_characteristics;
ALTER TABLE characteristic_data.divergence_routed_characteristics2
  RENAME TO divergence_routed_characteristics;
ALTER TABLE characteristic_data.divergence_routed_characteristics
  OWNER TO nldi;

SELECT comid, characteristic_id, characteristic_value, percent_nodata
INTO characteristic_data.total_accumulated_characteristics2
FROM characteristic_data.total_accumulated_characteristics as char
  JOIN nhdplus.nhdflowline_np21 as flow
  ON flow.nhdplus_comid = char.comid;
DROP TABLE characteristic_data.total_accumulated_characteristics;
ALTER TABLE characteristic_data.total_accumulated_characteristics2
  RENAME TO total_accumulated_characteristics;
ALTER TABLE characteristic_data.total_accumulated_characteristics
  OWNER TO nldi;

SELECT comid, characteristic_id, characteristic_value, percent_nodata
INTO characteristic_data.local_catchment_characteristics2
FROM characteristic_data.total_accumulated_characteristics as char
  JOIN nhdplus.nhdflowline_np21 as flow
  ON flow.nhdplus_comid = char.comid;
DROP TABLE characteristic_data.local_catchment_characteristics;
ALTER TABLE characteristic_data.local_catchment_characteristics2
  RENAME TO local_catchment_characteristics;
ALTER TABLE characteristic_data.local_catchment_characteristics
  OWNER TO nldi;