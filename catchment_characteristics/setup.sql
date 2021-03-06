SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = characteristic_data, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = true;

DROP TABLE characteristic_metadata;
CREATE TABLE characteristic_data.characteristic_metadata
(
characteristic_id text NOT NULL,
characteristic_description text,
units text,
dataset_label text,
dataset_url text,
theme_label text,
theme_url text,
characteristic_type text,
CONSTRAINT characteristic_metadata_pk PRIMARY KEY (characteristic_id)
)
WITH (
  OIDS=TRUE
);
ALTER TABLE characteristic_data.characteristic_metadata
OWNER TO nldi_data;

GRANT SELECT ON TABLE characteristic_data.characteristic_metadata TO nldi_user;

DROP TABLE characteristic_data.divergence_routed_characteristics;

DROP TABLE characteristic_data.total_accumulated_characteristics;

DROP TABLE characteristic_data.local_catchment_characteristics;

CREATE TABLE characteristic_data.divergence_routed_characteristics
(
comid integer NOT NULL,
characteristic_id text NOT NULL,
characteristic_value numeric,
percent_nodata smallint
);

CREATE TABLE characteristic_data.total_accumulated_characteristics
(
comid integer NOT NULL,
characteristic_id text NOT NULL,
characteristic_value numeric,
percent_nodata smallint
);

CREATE TABLE characteristic_data.local_catchment_characteristics
(
comid integer NOT NULL,
characteristic_id text NOT NULL,
characteristic_value numeric,
percent_nodata smallint
);

ALTER TABLE characteristic_data.divergence_routed_characteristics
OWNER TO nldi_data;

GRANT SELECT ON TABLE characteristic_data.divergence_routed_characteristics TO nldi_user;

ALTER TABLE characteristic_data.total_accumulated_characteristics
OWNER TO nldi_data;

GRANT SELECT ON TABLE characteristic_data.total_accumulated_characteristics TO nldi_user;

ALTER TABLE characteristic_data.local_catchment_characteristics
OWNER TO nldi_data;

GRANT SELECT ON TABLE characteristic_data.local_catchment_characteristics TO nldi_user;


