--
-- PostgreSQL database dump
--



-- Dumped from database version 18.4 (eaf151e)
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: userrole; Type: TYPE; Schema: public; Owner: 
--

CREATE TYPE public.userrole AS ENUM (
    'admin',
    'data_entry',
    'viewer'
);



SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: invoice; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public.invoice (
    station character varying NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    created_at date NOT NULL,
    total_amount double precision NOT NULL,
    items json,
    prices json,
    id integer NOT NULL,
    invoice_number character varying
);



--
-- Name: invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.invoice_id_seq OWNED BY public.invoice.id;


--
-- Name: invoicepricechangelog; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public.invoicepricechangelog (
    id integer NOT NULL,
    fuel_type character varying NOT NULL,
    old_price double precision NOT NULL,
    new_price double precision NOT NULL,
    changed_at timestamp without time zone
);



--
-- Name: invoicepricechangelog_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.invoicepricechangelog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: invoicepricechangelog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.invoicepricechangelog_id_seq OWNED BY public.invoicepricechangelog.id;


--
-- Name: invoicepricesetting; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public.invoicepricesetting (
    id integer NOT NULL,
    fuel_type character varying NOT NULL,
    price double precision NOT NULL
);



--
-- Name: invoicepricesetting_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.invoicepricesetting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: invoicepricesetting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.invoicepricesetting_id_seq OWNED BY public.invoicepricesetting.id;


--
-- Name: modelconfig; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public.modelconfig (
    model_name character varying NOT NULL,
    vehicle_type character varying NOT NULL,
    fuel_type character varying NOT NULL,
    standard_consumption double precision NOT NULL,
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_synced boolean NOT NULL
);



--
-- Name: modelconfig_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.modelconfig_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: modelconfig_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.modelconfig_id_seq OWNED BY public.modelconfig.id;


--
-- Name: refuel; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public.refuel (
    vehicle_id integer,
    current_odometer double precision NOT NULL,
    liters double precision NOT NULL,
    actual_percentage double precision NOT NULL,
    created_at date NOT NULL,
    is_excess boolean NOT NULL,
    is_illogical boolean NOT NULL,
    station character varying,
    id integer NOT NULL,
    is_synced boolean NOT NULL,
    updated_at timestamp without time zone
);



--
-- Name: refuel_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.refuel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: refuel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.refuel_id_seq OWNED BY public.refuel.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public."user" (
    username character varying NOT NULL,
    full_name character varying,
    role public.userrole NOT NULL,
    id integer NOT NULL,
    hashed_password character varying NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_synced boolean NOT NULL
);



--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: vehicle; Type: TABLE; Schema: public; Owner: 
--

CREATE TABLE public.vehicle (
    number character varying NOT NULL,
    letters character varying,
    registry character varying,
    code character varying,
    brand character varying,
    model character varying,
    vehicle_type character varying NOT NULL,
    fuel_type character varying NOT NULL,
    standard_consumption double precision NOT NULL,
    last_odometer double precision NOT NULL,
    manufacture_year integer,
    last_odometer_date date NOT NULL,
    id integer NOT NULL,
    is_synced boolean NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);



--
-- Name: vehicle_id_seq; Type: SEQUENCE; Schema: public; Owner: 
--

CREATE SEQUENCE public.vehicle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: vehicle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: 
--

ALTER SEQUENCE public.vehicle_id_seq OWNED BY public.vehicle.id;


--
-- Name: invoice id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.invoice ALTER COLUMN id SET DEFAULT nextval('public.invoice_id_seq'::regclass);


--
-- Name: invoicepricechangelog id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.invoicepricechangelog ALTER COLUMN id SET DEFAULT nextval('public.invoicepricechangelog_id_seq'::regclass);


--
-- Name: invoicepricesetting id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.invoicepricesetting ALTER COLUMN id SET DEFAULT nextval('public.invoicepricesetting_id_seq'::regclass);


--
-- Name: modelconfig id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.modelconfig ALTER COLUMN id SET DEFAULT nextval('public.modelconfig_id_seq'::regclass);


--
-- Name: refuel id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.refuel ALTER COLUMN id SET DEFAULT nextval('public.refuel_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: vehicle id; Type: DEFAULT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.vehicle ALTER COLUMN id SET DEFAULT nextval('public.vehicle_id_seq'::regclass);


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO public.invoice (station, start_date, end_date, created_at, total_amount, items, prices, id, invoice_number) VALUES ('محطة بورفؤاد', '2026-07-01', '2026-07-07', '2026-07-13', 94338, '[{"fuel_type": "\u0628\u0646\u0632\u064a\u0646 92", "quantity": 1734, "price": 22.25, "total": 38581.5}, {"fuel_type": "\u0628\u0646\u0632\u064a\u0646 95", "quantity": 40, "price": 24, "total": 960}, {"fuel_type": "\u0633\u0648\u0644\u0627\u0631", "quantity": 2673, "price": 20.5, "total": 54796.5}]', '{"\u0628\u0646\u0632\u064a\u0646 92": 22.25, "\u0628\u0646\u0632\u064a\u0646 95": 24, "\u0633\u0648\u0644\u0627\u0631": 20.5}', 2, 764);
INSERT INTO public.invoice (station, start_date, end_date, created_at, total_amount, items, prices, id, invoice_number) VALUES ('محطة بورفؤاد', '2026-07-08', '2026-07-13', '2026-07-14', 58048.5, '[{"fuel_type": "\u0628\u0646\u0632\u064a\u0646 92", "quantity": 1460, "price": 22.25, "total": 32485}, {"fuel_type": "\u0633\u0648\u0644\u0627\u0631", "quantity": 1247, "price": 20.5, "total": 25563.5}]', '{"\u0628\u0646\u0632\u064a\u0646 92": 22.25, "\u0628\u0646\u0632\u064a\u0646 95": 24, "\u0633\u0648\u0644\u0627\u0631": 20.5}', 3, 765);


--
-- Data for Name: invoicepricechangelog; Type: TABLE DATA; Schema: public; Owner: 
--



--
-- Data for Name: invoicepricesetting; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO public.invoicepricesetting (id, fuel_type, price) VALUES (1, 'بنزين 92', 22.25);
INSERT INTO public.invoicepricesetting (id, fuel_type, price) VALUES (2, 'بنزين 95', 24);
INSERT INTO public.invoicepricesetting (id, fuel_type, price) VALUES (3, 'سولار', 20.5);


--
-- Data for Name: modelconfig; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO public.modelconfig (model_name, vehicle_type, fuel_type, standard_consumption, id, created_at, updated_at, is_synced) VALUES ('Toyota Hiace', 'ميكروباص', 'ديزل', 12, 1, '2026-07-04 17:07:14.83691', '2026-07-04 17:07:20.635319', true);
INSERT INTO public.modelconfig (model_name, vehicle_type, fuel_type, standard_consumption, id, created_at, updated_at, is_synced) VALUES ('Hyundai Elantra', 'سيارة', 'بنزين', 14, 2, '2026-07-04 17:07:15.532187', '2026-07-04 17:07:21.751196', true);
INSERT INTO public.modelconfig (model_name, vehicle_type, fuel_type, standard_consumption, id, created_at, updated_at, is_synced) VALUES ('Volvo FH', 'شاحنة', 'ديزل', 9, 3, '2026-07-04 17:07:16.209293', '2026-07-04 17:07:22.831986', true);


--
-- Data for Name: refuel; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (274, 298369, 1, 0, '2026-06-30', false, true, NULL, 122, true, '2026-07-12 19:52:51.362317');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (276, 599492, 1, 0, '2026-06-30', false, true, NULL, 124, true, '2026-07-12 19:53:53.394356');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (277, 412205, 1, 0, '2026-06-30', false, true, NULL, 125, true, '2026-07-12 19:53:54.50632');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (279, 31827, 1, 0, '2026-06-30', false, true, NULL, 127, true, '2026-07-12 19:54:56.442936');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (280, 465472, 1, 0, '2026-06-30', false, true, NULL, 128, true, '2026-07-12 19:54:57.312136');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (282, 253289, 1, 0, '2026-06-30', false, true, NULL, 130, true, '2026-07-12 19:55:58.606426');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (283, 545782, 1, 0, '2026-06-30', false, true, NULL, 131, true, '2026-07-12 19:55:59.494988');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (285, 55648, 1, 0, '2026-06-30', false, true, NULL, 133, true, '2026-07-12 19:57:01.485259');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (286, 450869, 1, 0, '2026-06-30', false, true, NULL, 134, true, '2026-07-12 19:57:02.269591');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (288, 787900, 1, 0.5263157894736842, '2026-06-30', false, true, 'غير محدد', 136, true, '2026-07-13 08:05:35.097189');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (289, 9495, 1, 0, '2026-06-30', false, true, NULL, 137, true, '2026-07-12 19:58:05.035027');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (291, 65143, 1, 0.5208333333333333, '2026-06-30', false, true, 'غير محدد', 139, true, '2026-07-13 09:13:44.207538');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (292, 19420, 1, 0.6211180124223602, '2026-06-30', false, true, 'غير محدد', 140, true, '2026-07-13 08:07:41.137676');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (294, 388050, 1, 0.33333333333333337, '2026-06-30', false, true, 'غير محدد', 142, true, '2026-07-13 06:03:27.984847');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (296, 682468, 1, 0, '2026-06-30', false, true, NULL, 144, true, '2026-07-12 20:02:13.564948');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (299, 433731, 1, 0.39215686274509803, '2026-06-30', false, true, 'غير محدد', 147, true, '2026-07-13 08:43:45.322007');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (302, 493938, 1, 0, '2026-06-30', false, true, NULL, 150, true, '2026-07-12 20:04:18.568852');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (305, 527260, 1, 0, '2026-06-30', false, true, NULL, 153, true, '2026-07-12 20:06:22.903962');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (310, 874280, 1, 0.0016666666666666668, '2026-06-30', false, true, NULL, 156, true, '2026-07-12 20:07:24.97364');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (313, 3151, 1, 0, '2026-06-30', false, true, NULL, 159, true, '2026-07-12 20:08:28.429113');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (316, 477937, 1, 0.33444816053511706, '2026-06-30', false, true, 'غير محدد', 162, true, '2026-07-13 06:04:30.693312');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (324, 331808, 1, 0, '2026-06-30', false, true, NULL, 171, true, '2026-07-12 20:12:38.85094');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 832273, 1, 0.11441647597254005, '2026-06-30', false, true, 'غير محدد', 173, true, '2026-07-13 06:12:42.701187');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (327, 6815, 1, 0, '2026-06-30', false, true, NULL, 174, true, '2026-07-12 20:13:41.788181');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (329, 456817, 1, 0, '2026-06-30', false, true, NULL, 175, true, '2026-07-12 20:14:43.85888');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (331, 928982, 1, 0.35335689045936397, '2026-06-30', false, true, 'غير محدد', 177, true, '2026-07-13 09:00:18.241756');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (332, 21632, 1, 0.5988023952095809, '2026-06-30', false, true, 'غير محدد', 178, true, '2026-07-13 09:05:24.126601');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (336, 458350, 1, 0, '2026-06-30', false, true, NULL, 180, true, '2026-07-12 20:16:48.814723');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (337, 27583, 1, 0, '2026-06-30', false, true, NULL, 181, true, '2026-07-12 20:16:49.58882');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (339, 459816, 1, 0.1594896331738437, '2026-06-30', false, true, 'غير محدد', 183, true, '2026-07-13 06:12:43.742936');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (340, 726706, 1, 0, '2026-06-30', false, true, NULL, 184, true, '2026-07-12 20:17:52.59685');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (342, 354893, 1, 0, '2026-06-30', false, true, NULL, 186, true, '2026-07-12 20:17:53.297065');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (343, 805876, 1, 0.20964360587002098, '2026-06-30', false, true, 'غير محدد', 187, true, '2026-07-13 09:09:34.624646');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (344, 252562, 1, 1.3513513513513513, '2026-06-30', false, true, 'غير محدد', 188, true, '2026-07-13 05:58:16.164763');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (346, 514804, 1, 0, '2026-06-30', false, true, NULL, 190, true, '2026-07-12 20:19:58.040851');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (347, 279365, 1, 0, '2026-06-30', false, true, NULL, 191, true, '2026-07-12 20:19:58.742183');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (349, 390832, 1, 0.5376344086021506, '2026-06-30', false, true, 'غير محدد', 193, true, '2026-07-13 08:06:37.507454');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (350, 447681, 1, 1.4492753623188406, '2026-06-30', false, true, 'غير محدد', 194, true, '2026-07-13 08:08:42.413456');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 509325, 1, 0.09293680297397769, '2026-06-30', false, true, 'غير محدد', 232, true, '2026-07-13 06:13:47.573978');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (354, 248295, 1, 0.12738853503184713, '2026-06-30', false, true, 'غير محدد', 198, true, '2026-07-13 08:30:25.243844');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (355, 541459, 1, 0, '2026-06-30', false, true, NULL, 199, true, '2026-07-12 20:23:06.160879');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (358, 170786, 1, 0.1941747572815534, '2026-06-30', false, true, 'غير محدد', 202, true, '2026-07-13 06:27:10.205664');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (361, 389718, 1, 0.10482180293501049, '2026-06-30', false, true, 'غير محدد', 203, true, '2026-07-13 06:02:24.977389');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 393959, 1, 0.29940119760479045, '2026-06-30', false, true, 'غير محدد', 205, true, '2026-07-13 07:28:49.733442');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 701051, 1, 0.16286644951140067, '2026-06-30', false, true, 'غير محدد', 208, true, '2026-07-13 06:12:44.742861');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 463994, 1, 0.05422993492407809, '2026-06-30', false, true, 'غير محدد', 211, true, '2026-07-13 05:59:18.113999');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (372, 333306, 1, 0.15847860538827258, '2026-06-30', false, true, 'غير محدد', 214, true, '2026-07-13 08:07:40.285352');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (375, 679511, 1, 0.18050541516245489, '2026-06-30', false, true, 'غير محدد', 217, true, '2026-07-13 06:18:55.359463');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (378, 575434, 1, 0.591715976331361, '2026-06-30', false, true, 'غير محدد', 220, true, '2026-07-13 07:21:34.494588');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (381, 211833, 1, 0.2506265664160401, '2026-06-30', false, true, NULL, 223, true, '2026-07-12 20:33:28.804913');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (384, 226455, 1, 0, '2026-06-30', false, true, NULL, 226, true, '2026-07-12 20:35:32.879615');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (387, 287233, 1, 1.1235955056179776, '2026-06-30', false, true, 'غير محدد', 229, true, '2026-07-13 08:06:38.358668');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (392, 208328, 1, 0.5319148936170213, '2026-06-30', false, true, NULL, 234, true, '2026-07-12 20:39:40.500467');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (393, 371200, 1, 0.25, '2026-06-30', false, true, 'غير محدد', 235, true, '2026-07-13 07:31:53.641311');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (395, 294725, 1, 0.2638522427440633, '2026-06-30', false, true, 'غير محدد', 237, true, '2026-07-13 07:55:21.770479');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (396, 272122, 1, 0, '2026-06-30', false, true, NULL, 238, true, '2026-07-12 20:41:45.425452');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (399, 825241, 1, 0, '2026-06-30', false, true, NULL, 240, true, '2026-07-12 20:42:46.717108');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (400, 103442, 1, 0, '2026-06-30', false, true, NULL, 241, true, '2026-07-12 20:43:48.816445');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (402, 225859, 1, 0, '2026-06-30', false, true, NULL, 243, true, '2026-07-12 20:43:49.684063');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (404, 185560, 1, 0, '2026-06-30', false, true, NULL, 244, true, '2026-07-12 20:44:51.90253');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (407, 214170, 1, 1.4285714285714286, '2026-06-30', false, true, 'غير محدد', 247, true, '2026-07-13 06:24:01.737378');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (408, 728414, 1, 0.00015490954831473902, '2026-06-30', false, true, NULL, 248, true, '2026-07-12 20:47:56.396996');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 572298, 1, 0.24691358024691357, '2026-06-30', false, true, 'غير محدد', 250, true, '2026-07-13 06:34:22.50225');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (411, 568212, 1, 0.2557544757033248, '2026-06-30', false, true, NULL, 251, true, '2026-07-12 20:50:00.19096');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (413, 606256, 1, 0.13280212483399734, '2026-06-30', false, true, 'غير محدد', 253, true, '2026-07-13 07:53:19.184633');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (414, 164144, 1, 0.1457725947521866, '2026-06-30', false, true, 'غير محدد', 254, true, '2026-07-13 07:49:14.157574');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (417, 56829, 1, 0.27472527472527475, '2026-06-30', false, true, NULL, 256, true, '2026-07-12 20:52:04.161356');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (419, 178805, 1, 0, '2026-06-30', false, true, NULL, 257, true, '2026-07-12 20:53:06.316088');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (433, 80740, 1, 0.0333000333000333, '2026-06-30', false, true, 'غير محدد', 271, true, '2026-07-13 06:15:50.730532');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (422, 116872, 1, 0, '2026-06-30', false, true, NULL, 260, true, '2026-07-12 20:54:10.810113');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (424, 124397, 1, 0.6622516556291391, '2026-06-30', false, true, 'غير محدد', 263, true, '2026-07-13 08:28:21.828761');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (427, 124174, 1, 0, '2026-06-30', false, true, NULL, 265, true, '2026-07-12 20:58:15.831963');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (421, 191046, 1, 0.23255813953488372, '2026-06-30', false, true, 'غير محدد', 259, true, '2026-07-13 06:01:22.851652');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (432, 81022, 1, 0.15923566878980894, '2026-06-30', false, true, NULL, 270, true, '2026-07-12 21:00:22.232775');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (436, 123025, 1, 0.28735632183908044, '2026-06-30', false, true, NULL, 274, true, '2026-07-12 21:01:24.112402');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (435, 62527, 1, 0, '2026-06-30', false, true, NULL, 273, true, '2026-07-12 21:01:24.885639');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (438, 81805, 1, 0.2849002849002849, '2026-06-30', false, true, NULL, 276, true, '2026-07-12 21:02:26.079937');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (439, 62243, 1, 0, '2026-06-30', false, true, NULL, 277, true, '2026-07-12 21:02:26.870088');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (452, 84514, 1, 0.07633587786259542, '2026-06-30', false, true, NULL, 275, true, '2026-07-12 21:02:27.63853');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (275, 541445, 1, 0.6622516556291391, '2026-06-30', false, true, 'غير محدد', 123, true, '2026-07-13 06:25:05.408489');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (431, 128903, 39, 2.9839326702371842, '2026-07-01', false, true, 'محطة بورفؤاد', 325, true, '2026-07-13 06:42:40.555861');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (281, 664238, 1, 1, '2026-06-30', false, true, 'غير محدد', 129, true, '2026-07-13 06:42:39.880712');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 449899, 1, 0.33333333333333337, '2026-06-30', false, true, 'غير محدد', 204, true, '2026-07-13 06:35:23.791544');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (284, 524305, 35, 9.776536312849162, '2026-07-01', false, false, 'محطة بورفؤاد', 328, true, '2026-07-13 06:44:43.816502');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 450199, 41, 13.666666666666666, '2026-07-01', false, false, 'محطة بورفؤاد', 329, true, '2026-07-13 06:46:45.582394');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 832809, 57, 10.634328358208956, '2026-07-02', false, false, 'محطة بورسعيد', 332, true, '2026-07-13 06:47:47.649276');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (345, 491630, 1, 0.3401360544217687, '2026-06-30', false, true, 'غير محدد', 189, true, '2026-07-13 06:02:26.701363');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (377, 608651, 1, 0.4273504273504274, '2026-06-30', false, true, 'غير محدد', 219, true, '2026-07-13 06:55:56.132184');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (352, 499685, 40, 14.925373134328357, '2026-07-02', false, false, 'محطة بورفؤاد', 337, true, '2026-07-13 07:03:06.548444');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (398, 280630, 35, 26.515151515151516, '2026-07-03', false, false, 'محطة بورسعيد', 347, true, '2026-07-13 07:11:17.71239');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 464852, 51, 11.697247706422019, '2026-07-02', false, false, 'محطة بورفؤاد', 340, true, '2026-07-13 07:04:08.639574');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 832928, 15, 12.605042016806722, '2026-07-04', false, false, 'محطة بورسعيد', 353, true, '2026-07-13 07:19:31.131244');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (426, 57574, 1, 0.48543689320388345, '2026-06-30', false, true, 'غير محدد', 264, true, '2026-07-13 07:16:25.361488');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (357, 230259, 321, 54.49915110356537, '2026-07-04', false, false, 'محطة بورسعيد', 361, true, '2026-07-13 07:24:40.419687');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (284, 523947, 1, 0.27932960893854747, '2026-06-30', false, true, 'غير محدد', 132, true, '2026-07-13 06:12:45.417786');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (287, 474626, 1, 0, '2026-06-30', false, true, NULL, 135, true, '2026-07-12 19:58:05.718183');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (290, 39192, 1, 0, '2026-06-30', false, true, NULL, 138, true, '2026-07-12 19:59:07.795934');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (293, 553908, 1, 0, '2026-06-30', false, true, NULL, 141, true, '2026-07-12 20:00:10.072707');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (295, 772911, 1, 0.09174311926605505, '2026-06-30', false, true, 'غير محدد', 143, true, '2026-07-13 08:23:11.658796');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (297, 498781, 1, 0, '2026-06-30', false, true, NULL, 145, true, '2026-07-12 20:02:14.345358');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (298, 179433, 1, 0, '2026-06-30', false, true, NULL, 146, true, '2026-07-12 20:03:16.506339');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (300, 683700, 1, 0.5780346820809248, '2026-06-30', false, true, 'غير محدد', 148, true, '2026-07-13 09:25:55.972581');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (301, 163351, 1, 0.411522633744856, '2026-06-30', false, true, 'غير محدد', 149, true, '2026-07-13 06:04:31.450165');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (303, 455560, 1, 0, '2026-06-30', false, true, NULL, 151, true, '2026-07-12 20:05:20.734697');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (304, 867757, 1, 0, '2026-06-30', false, true, NULL, 152, true, '2026-07-12 20:05:21.608361');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (306, 638818, 1, 0, '2026-06-30', false, true, NULL, 154, true, '2026-07-12 20:06:23.777191');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (309, 799265, 1, 0.5988023952095809, '2026-06-30', false, true, 'غير محدد', 155, true, '2026-07-13 08:55:06.11645');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (429, 120860, 1, 0.2890173410404624, '2026-06-30', false, true, 'غير محدد', 267, true, '2026-07-13 08:04:33.142276');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (312, 13841, 1, 0, '2026-06-30', false, true, NULL, 158, true, '2026-07-12 20:07:27.131475');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (314, 34381, 1, 0.5050505050505051, '2026-06-30', false, true, 'غير محدد', 160, true, '2026-07-13 08:45:49.527481');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (317, 270323, 1, 0, '2026-06-30', false, true, NULL, 163, true, '2026-07-12 20:10:33.311277');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (318, 796070, 1, 0, '2026-06-30', false, true, NULL, 164, true, '2026-07-12 20:10:34.107619');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (320, 697750, 1, 0, '2026-06-30', false, true, NULL, 166, true, '2026-07-12 20:10:34.800501');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (321, 454412, 1, 0, '2026-06-30', false, true, NULL, 167, true, '2026-07-12 20:11:36.774991');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (323, 402621, 1, 0, '2026-06-30', false, true, NULL, 169, true, '2026-07-12 20:11:37.557623');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (324, 331808, 1, 0, '2026-06-30', false, true, NULL, 170, true, '2026-07-12 20:12:39.714804');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (325, 718429, 1, 0, '2026-06-30', false, true, NULL, 172, true, '2026-07-12 20:13:42.564724');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (330, 787813, 1, 0, '2026-06-30', false, true, NULL, 176, true, '2026-07-12 20:14:44.555884');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (335, 745820, 1, 0.31645569620253167, '2026-06-30', false, true, 'غير محدد', 179, true, '2026-07-13 06:05:32.742361');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (338, 367954, 1, 0.1984126984126984, '2026-06-30', false, true, 'غير محدد', 182, true, '2026-07-13 08:05:36.241504');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (341, 741851, 1, 0, '2026-06-30', false, true, NULL, 185, true, '2026-07-12 20:17:53.985507');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435010, 1, 0.09718172983479105, '2026-06-30', false, true, 'غير محدد', 197, true, '2026-07-13 06:02:25.850325');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (348, 591559, 1, 0.15037593984962408, '2026-06-30', false, true, 'غير محدد', 192, true, '2026-07-13 06:14:49.544505');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (351, 289415, 1, 0, '2026-06-30', false, true, NULL, 195, true, '2026-07-12 20:21:02.111731');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (382, 301048, 1, 0.11947431302270012, '2026-06-30', false, true, 'غير محدد', 224, true, '2026-07-13 06:03:29.458154');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (388, 775139, 1, 0.029913251570445706, '2026-06-30', false, true, 'غير محدد', 230, true, '2026-07-13 06:07:37.581414');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (357, 229670, 1, 0.08748906386701663, '2026-06-30', false, true, 'غير محدد', 201, true, '2026-07-13 06:24:02.594403');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (364, 417717, 1, 0, '2026-06-30', false, true, NULL, 206, true, '2026-07-12 20:26:13.114744');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (365, 831781, 1, 0.1564945226917058, '2026-06-30', false, true, 'غير محدد', 207, true, '2026-07-13 08:33:29.145504');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 453883, 1, 0.13123359580052493, '2026-06-30', false, true, 'غير محدد', 233, true, '2026-07-13 07:47:11.59355');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (367, 192466, 1, 0, '2026-06-30', false, true, NULL, 209, true, '2026-07-12 20:27:16.702563');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (380, 269488, 1, 0.5882352941176471, '2026-06-30', false, true, 'غير محدد', 222, true, '2026-07-13 05:57:13.041522');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (370, 281456, 1, 0, '2026-06-30', false, true, NULL, 212, true, '2026-07-12 20:28:18.589188');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 692220, 1, 0.21645021645021645, '2026-06-30', false, true, 'غير محدد', 213, true, '2026-07-13 05:58:16.836762');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (373, 181181, 1, 0.12033694344163659, '2026-06-30', false, true, 'غير محدد', 215, true, '2026-07-13 08:40:39.874135');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (374, 409253, 1, 0.9090909090909091, '2026-06-30', false, true, 'غير محدد', 216, true, '2026-07-13 08:56:09.22341');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (376, 477753, 1, 0.39370078740157477, '2026-06-30', false, true, NULL, 218, true, '2026-07-12 20:31:24.738931');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (379, 534200, 1, 0, '2026-06-30', false, true, NULL, 221, true, '2026-07-12 20:32:27.514633');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 764145, 1, 0.014900908955446282, '2026-06-30', false, true, 'غير محدد', 236, true, '2026-07-13 06:24:03.358522');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (356, 573951, 1, 0.1152073732718894, '2026-06-30', false, true, 'غير محدد', 200, true, '2026-07-13 06:03:28.770085');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (383, 314600, 1, 0, '2026-06-30', false, true, NULL, 225, true, '2026-07-12 20:34:31.588747');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (385, 174888, 1, 0, '2026-06-30', false, true, NULL, 227, true, '2026-07-12 20:35:33.661054');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (386, 288036, 1, 0.9090909090909091, '2026-06-30', false, true, NULL, 228, true, '2026-07-12 20:36:34.952413');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (431, 127596, 1, 0.07651109410864575, '2026-06-30', false, true, 'غير محدد', 269, true, '2026-07-13 06:07:36.804871');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 653078, 1, 0.09372071227741331, '2026-06-30', false, true, 'غير محدد', 231, true, '2026-07-13 06:18:56.039522');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (398, 280983, 23, 13.142857142857142, '2026-07-05', false, false, 'محطة بورسعيد', 387, true, '2026-07-13 07:56:23.826481');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (398, 280498, 1, 0.2061855670103093, '2026-06-30', false, true, 'غير محدد', 239, true, '2026-07-13 06:17:53.30452');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (401, 303768, 1, 0, '2026-06-30', false, true, NULL, 242, true, '2026-07-12 20:43:50.550238');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (406, 412939, 1, 0.17123287671232876, '2026-06-30', false, true, NULL, 246, true, '2026-07-12 20:46:55.182049');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (409, 175340, 1, 0, '2026-06-30', false, true, NULL, 249, true, '2026-07-12 20:48:57.685177');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (412, 894668, 1, 0.4273504273504274, '2026-06-30', false, true, NULL, 252, true, '2026-07-12 20:50:00.878341');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (415, 188761, 1, 0, '2026-06-30', false, true, NULL, 255, true, '2026-07-12 20:52:05.030232');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (420, 188056, 1, 0, '2026-06-30', false, true, NULL, 258, true, '2026-07-12 20:53:08.418441');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (311, 740696, 1, 1.0869565217391304, '2026-06-30', false, true, 'غير محدد', 157, true, '2026-07-13 08:04:33.921491');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (423, 97202, 1, 0, '2026-06-30', false, true, NULL, 262, true, '2026-07-12 20:57:14.63908');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (428, 112770, 1, 0, '2026-06-30', false, true, NULL, 266, true, '2026-07-12 20:58:17.370915');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (434, 63395, 1, 0, '2026-06-30', false, true, NULL, 272, true, '2026-07-12 21:00:22.91477');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (444, 53512, 1, 0, '2026-06-30', false, true, NULL, 282, true, '2026-07-12 21:05:33.085657');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (447, 49240, 1, 0, '2026-06-30', false, true, NULL, 285, true, '2026-07-12 21:06:35.16502');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (281, 664338, 24, 24, '2026-07-01', true, false, 'محطة بورفؤاد', 324, true, '2026-07-13 06:42:39.105267');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (443, 85398, 1, 0.13123359580052493, '2026-06-30', false, true, 'غير محدد', 281, true, '2026-07-13 06:05:33.523663');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (462, 360071, 60, 0.016663380277778552, '2026-07-01', false, true, 'محطة بورفؤاد', 327, true, '2026-07-13 06:43:41.833855');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (339, 460322, 40, 7.905138339920949, '2026-07-02', false, false, 'محطة بورسعيد', 331, true, '2026-07-13 06:47:46.88029');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 692915, 29, 12.446351931330472, '2026-07-02', false, false, 'محطة بورسعيد', 334, true, '2026-07-13 06:48:49.713631');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 764950, 64, 18.6046511627907, '2026-07-02', false, false, 'محطة بورسعيد', 336, true, '2026-07-13 06:58:59.164919');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (339, 460443, 10, 8.264462809917356, '2026-07-03', false, false, 'محطة بورسعيد', 344, true, '2026-07-13 07:10:15.743587');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 86798, 1, 0.25, '2026-06-30', false, true, 'غير محدد', 280, true, '2026-07-13 06:21:59.158656');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 87198, 57, 14.249999999999998, '2026-07-03', false, false, 'محطة بورفؤاد', 352, true, '2026-07-13 07:17:27.37787');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 526967, 43, 31.61764705882353, '2026-07-04', false, false, 'محطة بورسعيد', 358, true, '2026-07-13 07:22:35.766293');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (441, 86617, 1, 0.2570694087403599, '2026-06-30', false, true, 'غير محدد', 279, true, '2026-07-13 06:26:07.472975');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 86264, 1, 0, '2026-06-30', false, true, 'غير محدد', 278, true, '2026-07-13 06:26:08.243459');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 450478, 37, 13.261648745519713, '2026-07-04', false, false, 'محطة بورفؤاد', 368, true, '2026-07-13 07:27:47.002292');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 613127, 1, 0.13227513227513227, '2026-06-30', false, true, 'غير محدد', 245, true, '2026-07-13 07:51:16.723556');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (413, 607009, 58, 7.702523240371846, '2026-07-05', false, false, 'محطة بورسعيد', 382, true, '2026-07-13 07:54:20.478059');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 454645, 88, 23.848238482384822, '2026-07-05', false, false, 'محطة بورسعيد', 384, true, '2026-07-13 07:56:23.060882');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (352, 499984, 44, 14.715719063545151, '2026-07-05', false, false, 'محطة بورفؤاد', 394, true, '2026-07-13 08:09:46.063667');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (387, 287322, 20, 22.47191011235955, '2026-07-05', false, true, 'محطة بورفؤاد', 398, true, '2026-07-13 08:10:49.330885');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (372, 333937, 60, 9.508716323296355, '2026-07-05', false, false, 'محطة بورفؤاد', 401, true, '2026-07-13 08:11:52.058376');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (446, 23335, 1, 0.2127659574468085, '2026-06-30', false, true, 'غير محدد', 284, true, '2026-07-13 08:12:55.35677');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (443, 86160, 55, 13.095238095238097, '2026-07-05', false, false, 'محطة بورفؤاد', 406, true, '2026-07-13 08:13:56.682689');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (421, 191912, 51, 11.697247706422019, '2026-07-06', false, false, 'محطة بورسعيد', 407, true, '2026-07-13 08:20:03.858884');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 765770, 82, 17.86492374727669, '2026-07-06', false, false, 'محطة بورسعيد', 410, true, '2026-07-13 08:20:04.743943');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (436, 123373, 39, 11.206896551724139, '2026-07-06', false, false, 'محطة بورسعيد', 413, true, '2026-07-13 08:21:07.838644');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (295, 774001, 25, 2.293577981651376, '2026-07-06', false, true, 'محطة بورسعيد', 415, true, '2026-07-13 08:23:12.417296');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (377, 609112, 33, 13.360323886639677, '2026-07-06', false, false, 'محطة بورفؤاد', 420, true, '2026-07-13 08:26:17.793542');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (354, 248830, 36, 6.728971962616822, '2026-07-06', false, false, 'محطة بورفؤاد', 425, true, '2026-07-13 08:31:26.517361');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (365, 832037, 25, 9.765625, '2026-07-06', false, false, 'محطة بورفؤاد', 427, true, '2026-07-13 08:33:30.01038');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (376, 478007, 43, 16.92913385826772, '2026-07-06', true, false, 'محطة بورفؤاد', 430, true, '2026-07-13 08:34:31.985663');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (387, 287378, 18, 32.142857142857146, '2026-07-07', false, true, 'محطة بورسعيد', 434, true, '2026-07-13 08:38:37.940416');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (381, 212232, 103, 25.81453634085213, '2026-07-07', false, false, 'محطة بورسعيد', 438, true, '2026-07-13 08:41:41.913366');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 694428, 15, 13.88888888888889, '2026-07-07', false, false, 'محطة بورسعيد', 440, true, '2026-07-13 08:44:46.59786');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (314, 34579, 18, 9.090909090909092, '2026-07-07', false, false, 'محطة بورسعيد', 442, true, '2026-07-13 08:46:50.800257');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 511504, 58, 14.009661835748794, '2026-07-07', false, false, 'محطة بورسعيد', 445, true, '2026-07-13 08:46:51.561337');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (438, 82156, 11, 3.133903133903134, '2026-07-07', false, true, 'محطة بورسعيد', 448, true, '2026-07-13 08:47:54.876954');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (392, 208516, 35, 18.617021276595743, '2026-07-07', false, false, 'محطة بورسعيد', 451, true, '2026-07-13 08:48:58.352702');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 410334, 30, 11.627906976744185, '2026-07-07', false, false, 'محطة بورسعيد', 454, true, '2026-07-13 08:48:59.027574');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (309, 799432, 38, 22.75449101796407, '2026-07-07', true, false, 'محطة بورفؤاد', 456, true, '2026-07-13 08:55:07.916505');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (374, 409363, 15, 13.636363636363635, '2026-07-07', false, false, 'محطة بورفؤاد', 458, true, '2026-07-13 08:57:10.794816');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (319, 312999, 1, 0, '2026-06-30', false, true, 'غير محدد', 165, true, '2026-07-13 08:58:14.351814');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (431, 129441, 32, 5.947955390334572, '2026-07-08', false, false, 'محطة بورفؤاد', 493, true, '2026-07-13 09:27:59.480374');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 574623, 48, 8.465608465608465, '2026-07-09', false, false, 'محطة بورسعيد', 501, true, '2026-07-13 09:36:08.409436');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (407, 214670, 46, 10.69767441860465, '2026-07-09', false, false, 'محطة بورسعيد', 498, true, '2026-07-13 09:36:09.39344');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 766460, 60, 17.441860465116278, '2026-07-09', false, false, 'محطة بورسعيد', 504, true, '2026-07-13 09:39:15.409706');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (466, 90483, 1, 0.0011051799785595086, '2026-06-30', false, true, NULL, 507, true, '2026-07-13 09:46:23.058745');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (354, 249331, 29, 11.553784860557768, '2026-07-09', false, false, 'محطة بورسعيد', 510, true, '2026-07-13 09:47:25.563671');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (392, 208710, 52, 26.804123711340207, '2026-07-09', false, false, 'محطة بورفؤاد', 513, true, '2026-07-13 09:48:29.019879');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (337, 27834, 26, 10.358565737051793, '2026-07-09', false, false, 'محطة بورفؤاد', 516, true, '2026-07-13 09:48:29.716719');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 436368, 40, 12.158054711246201, '2026-07-09', false, false, 'محطة بورفؤاد', 519, true, '2026-07-13 09:49:33.068295');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (316, 478654, 81, 19.37799043062201, '2026-07-09', false, false, 'محطة بورفؤاد', 522, true, '2026-07-13 09:49:33.756463');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (443, 86723, 56, 14.545454545454545, '2026-07-09', false, false, 'محطة بورفؤاد', 525, true, '2026-07-13 09:50:36.96642');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 395121, 42, 8.75, '2026-07-09', false, false, 'محطة بورفؤاد', 528, true, '2026-07-13 09:51:40.319116');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 455685, 18, 17.82178217821782, '2026-07-10', false, false, 'محطة بورسعيد', 533, true, '2026-07-13 09:55:45.98713');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (339, 460862, 13, 9.352517985611511, '2026-07-10', false, false, 'محطة بورسعيد', 536, true, '2026-07-13 09:55:46.7565');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 436503, 22, 16.296296296296298, '2026-07-10', false, false, 'محطة بورفؤاد', 540, true, '2026-07-13 09:57:53.783848');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (368, 524425, 20, 16, '2026-07-10', false, false, 'محطة بورفؤاد', 543, true, '2026-07-13 09:57:54.64401');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (348, 592540, 49, 15.50632911392405, '2026-07-10', false, false, 'محطة بورفؤاد', 546, true, '2026-07-13 09:58:57.261665');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 833694, 20, 16.80672268907563, '2026-07-11', false, false, 'محطة بورسعيد', 550, true, '2026-07-13 10:02:02.457557');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 655480, 55, 11.827956989247312, '2026-07-11', false, false, 'محطة بورسعيد', 552, true, '2026-07-13 10:02:03.234344');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (352, 500588, 33, 11.34020618556701, '2026-07-11', false, false, 'محطة بورفؤاد', 553, true, '2026-07-13 10:02:04.093419');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (465, 213686, 60, 14.77832512315271, '2026-07-11', false, false, 'محطة بورفؤاد', 555, true, '2026-07-13 10:03:07.299955');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 702309, 49, 14.893617021276595, '2026-07-12', false, false, 'محطة بورسعيد', 557, true, '2026-07-13 10:46:31.169844');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (428, 113615, 44, 5.207100591715976, '2026-07-12', false, true, 'محطة بورسعيد', 558, true, '2026-07-13 10:47:33.243921');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 695748, 12, 15, '2026-07-12', false, false, 'محطة بورسعيد', 560, true, '2026-07-13 10:47:34.259232');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (422, 117294, 53, 12.559241706161137, '2026-07-12', false, false, 'محطة بورسعيد', 561, true, '2026-07-13 10:48:36.332942');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (277, 412327, 40, 32.78688524590164, '2026-07-12', false, true, 'محطة بورسعيد', 563, true, '2026-07-13 10:48:37.108098');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (408, 729289, 50, 9.487666034155598, '2026-07-12', false, false, 'محطة بورسعيد', 564, true, '2026-07-13 10:48:37.784315');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 511938, 56, 12.903225806451612, '2026-07-12', false, false, 'محطة بورسعيد', 567, true, '2026-07-13 10:49:40.40069');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (356, 575285, 67, 14.377682403433475, '2026-07-12', false, false, 'محطة بورسعيد', 569, true, '2026-07-13 10:49:41.07953');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 410917, 42, 12.173913043478262, '2026-07-12', false, false, 'محطة بورسعيد', 570, true, '2026-07-13 10:49:41.766647');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (445, 49485, 1, 0.2008032128514056, '2026-06-30', false, true, NULL, 283, true, '2026-07-12 21:05:33.869882');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (448, 27412, 1, 0, '2026-06-30', false, true, NULL, 286, true, '2026-07-12 21:06:36.659315');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (388, 778482, 44, 1.3161830690996112, '2026-07-01', false, true, 'محطة بورفؤاد', 326, true, '2026-07-13 06:43:42.522693');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 701424, 47, 12.600536193029491, '2026-07-02', false, false, 'محطة بورسعيد', 330, true, '2026-07-13 06:47:48.43356');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 510586, 24, 12.972972972972974, '2026-07-02', false, false, 'محطة بورسعيد', 333, true, '2026-07-13 06:48:50.603996');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (377, 608865, 36, 16.822429906542055, '2026-07-02', true, false, 'محطة بورسعيد', 335, true, '2026-07-13 06:56:57.446585');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 693703, 43, 12.874251497005988, '2026-07-04', false, false, 'محطة بورسعيد', 364, true, '2026-07-13 07:24:41.268687');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 86846, 50, 12.72264631043257, '2026-07-04', false, false, 'محطة بورفؤاد', 375, true, '2026-07-13 07:31:54.493901');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (464, 0, 10, 0, '2026-07-05', false, true, 'محطة بورسعيد', 378, true, '2026-07-13 07:45:09.288057');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (338, 368458, 181, 35.91269841269841, '2026-07-05', false, false, 'محطة بورفؤاد', 393, true, '2026-07-13 08:09:45.216035');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (348, 592224, 59, 18.91025641025641, '2026-07-06', false, false, 'محطة بورفؤاد', 421, true, '2026-07-13 08:27:19.773653');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (424, 124548, 43, 28.47682119205298, '2026-07-06', true, false, 'محطة بورفؤاد', 423, true, '2026-07-13 08:28:22.68477');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (432, 81261, 29, 12.133891213389122, '2026-07-06', false, false, 'محطة بورفؤاد', 426, true, '2026-07-13 08:31:27.381546');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (411, 568603, 46, 11.76470588235294, '2026-07-06', false, false, 'محطة بورفؤاد', 428, true, '2026-07-13 08:33:30.712831');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (375, 680065, 32, 11.510791366906476, '2026-07-06', false, false, 'محطة بورفؤاد', 431, true, '2026-07-13 08:35:34.100311');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (380, 270141, 20, 7.905138339920949, '2026-07-07', false, false, 'محطة بورسعيد', 436, true, '2026-07-13 08:41:42.784881');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (432, 81650, 35, 8.997429305912597, '2026-07-07', false, false, 'محطة بورسعيد', 441, true, '2026-07-13 08:44:47.476');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 455214, 87, 23.705722070844686, '2026-07-07', false, false, 'محطة بورسعيد', 443, true, '2026-07-13 08:46:52.254792');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (378, 575738, 24, 17.77777777777778, '2026-07-07', true, false, 'محطة بورسعيد', 446, true, '2026-07-13 08:46:53.021942');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (408, 728762, 39, 11.206896551724139, '2026-07-07', false, false, 'محطة بورسعيد', 449, true, '2026-07-13 08:47:55.645083');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 614477, 57, 9.595959595959595, '2026-07-07', false, false, 'محطة بورسعيد', 452, true, '2026-07-13 08:48:59.695284');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (319, 313317, 36, 11.320754716981133, '2026-07-07', false, false, 'محطة بورفؤاد', 459, true, '2026-07-13 08:58:12.067621');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (429, 121580, 35, 9.358288770053475, '2026-07-07', false, false, 'محطة بورفؤاد', 462, true, '2026-07-13 08:59:15.623536');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 394641, 30, 8.695652173913043, '2026-07-07', false, false, 'محطة بورفؤاد', 469, true, '2026-07-13 09:06:25.402325');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (443, 86338, 22, 12.359550561797752, '2026-07-07', false, false, 'محطة بورفؤاد', 472, true, '2026-07-13 09:07:30.007177');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (412, 894902, 32, 13.675213675213676, '2026-07-07', false, false, 'محطة بورفؤاد', 475, true, '2026-07-13 09:07:30.774116');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (343, 806353, 50, 10.482180293501047, '2026-07-08', false, false, 'محطة بورسعيد', 477, true, '2026-07-13 09:10:35.92756');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (377, 609249, 33, 24.087591240875913, '2026-07-08', false, true, 'محطة بورسعيد', 480, true, '2026-07-13 09:10:36.628124');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (458, 345279, 49, 20.24793388429752, '2026-07-08', true, false, 'محطة بورسعيد', 483, true, '2026-07-13 09:12:41.433208');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (301, 163594, 21, 16.8, '2026-07-08', false, false, 'محطة بورفؤاد', 488, true, '2026-07-13 09:14:45.489373');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (368, 524300, 32, 32.98969072164948, '2026-07-08', false, true, 'محطة بورفؤاد', 489, true, '2026-07-13 09:17:49.293955');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (302, 494049, 34, 30.630630630630627, '2026-07-08', false, true, 'محطة بورفؤاد', 490, true, '2026-07-13 09:24:54.668971');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (300, 683873, 24, 13.872832369942195, '2026-07-08', false, false, 'محطة بورفؤاد', 491, true, '2026-07-13 09:26:57.249792');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (344, 252860, 31, 30.097087378640776, '2026-07-08', true, false, 'محطة بورفؤاد', 494, true, '2026-07-13 09:28:00.329678');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (455, 329143, 45, 0, '2026-07-07', false, true, 'محطة بورفؤاد', 496, true, '2026-07-13 09:33:05.41703');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (289, 9552, 14, 24.561403508771928, '2026-07-09', true, false, 'محطة بورسعيد', 499, true, '2026-07-13 09:36:10.160775');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (465, 213280, 75, 0.035165041260315076, '2026-07-09', false, true, 'محطة بورسعيد', 502, true, '2026-07-13 09:38:13.350532');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (466, 90575, 14, 15.217391304347828, '2026-07-09', false, false, 'محطة بورسعيد', 508, true, '2026-07-13 09:46:24.177852');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 455584, 86, 23.243243243243246, '2026-07-09', false, false, 'محطة بورسعيد', 511, true, '2026-07-13 09:47:26.265767');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (413, 607969, 40, 9.59232613908873, '2026-07-09', false, false, 'محطة بورفؤاد', 514, true, '2026-07-13 09:48:30.401808');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (309, 799655, 30, 13.452914798206278, '2026-07-09', false, false, 'محطة بورفؤاد', 520, true, '2026-07-13 09:49:34.423455');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (365, 832788, 33, 8.967391304347826, '2026-07-09', false, false, 'محطة بورفؤاد', 523, true, '2026-07-13 09:50:37.65189');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (374, 409461, 20, 20.408163265306122, '2026-07-09', true, false, 'محطة بورفؤاد', 526, true, '2026-07-13 09:50:38.325215');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (375, 680395, 35, 10.606060606060606, '2026-07-09', false, false, 'محطة بورفؤاد', 529, true, '2026-07-13 09:51:41.00209');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 87437, 56, 14.07035175879397, '2026-07-10', false, false, 'محطة بورفؤاد', 547, true, '2026-07-13 09:59:59.992981');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 833575, 56, 13.084112149532709, '2026-07-09', false, false, 'محطة بورسعيد', 505, true, '2026-07-13 09:54:44.790371');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 701700, 5, 14.285714285714285, '2026-07-10', false, false, 'محطة بورسعيد', 531, true, '2026-07-13 17:54:43.709439');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 655015, 52, 12.121212121212121, '2026-07-10', false, false, 'محطة بورسعيد', 534, true, '2026-07-13 09:55:48.27161');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (427, 125097, 23, 2.4918743228602382, '2026-07-10', false, true, 'محطة بورسعيد', 537, true, '2026-07-13 09:56:50.960316');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 466179, 53, 15.542521994134898, '2026-07-10', false, false, 'محطة بورفؤاد', 541, true, '2026-07-13 09:57:55.316063');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 395400, 35, 12.544802867383511, '2026-07-10', false, false, 'محطة بورفؤاد', 544, true, '2026-07-13 09:58:57.935171');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (324, 332048, 61, 25.416666666666664, '2026-07-10', false, false, 'محطة بورفؤاد', 545, true, '2026-07-13 09:58:58.704727');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 701980, 45, 14.754098360655737, '2026-07-11', false, false, 'محطة بورسعيد', 548, true, '2026-07-13 10:02:04.76382');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (393, 371840, 43, 24.71264367816092, '2026-07-11', false, false, 'محطة بورسعيد', 551, true, '2026-07-13 10:02:05.445346');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 695668, 17, 14.529914529914532, '2026-07-11', false, false, 'محطة بورسعيد', 549, true, '2026-07-13 10:02:06.100091');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 436683, 22, 12.222222222222221, '2026-07-11', false, false, 'محطة بورفؤاد', 554, true, '2026-07-13 10:03:07.972022');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (377, 609406, 22, 14.012738853503185, '2026-07-12', false, false, 'محطة بورسعيد', 556, true, '2026-07-13 10:46:31.953927');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (447, 49782, 28, 5.166051660516605, '2026-07-12', false, true, 'محطة بورسعيد', 559, true, '2026-07-13 10:47:35.028848');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 767151, 67, 19.476744186046513, '2026-07-12', false, false, 'محطة بورسعيد', 562, true, '2026-07-13 10:48:38.449587');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (393, 372355, 105, 20.388349514563107, '2026-07-12', false, false, 'محطة بورسعيد', 566, true, '2026-07-13 10:49:39.639409');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (439, 63000, 73, 9.64332892998679, '2026-07-12', false, false, 'محطة بورسعيد', 565, true, '2026-07-13 10:49:42.453313');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 655666, 21, 11.29032258064516, '2026-07-12', false, false, 'محطة بورسعيد', 568, true, '2026-07-13 10:49:43.124411');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 615290, 41, 9.832134292565947, '2026-07-12', false, false, 'محطة بورسعيد', 572, true, '2026-07-13 10:50:44.223044');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 527542, 63, 32.98429319371728, '2026-07-12', false, false, 'محطة بورسعيد', 571, true, '2026-07-13 10:50:44.894983');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 702623, 42, 13.375796178343949, '2026-07-12', false, false, 'محطة بورسعيد', 573, true, '2026-07-13 10:50:45.572619');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (368, 524780, 61, 17.183098591549296, '2026-07-12', false, false, 'محطة بورفؤاد', 574, true, '2026-07-13 10:55:50.511309');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (290, 39291, 24, 24.242424242424242, '2026-07-12', true, false, 'محطة بورفؤاد', 575, true, '2026-07-13 10:55:51.366398');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (311, 740902, 36, 31.57894736842105, '2026-07-12', false, true, 'محطة بورفؤاد', 576, true, '2026-07-13 10:55:52.128444');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (314, 34744, 20, 12.121212121212121, '2026-07-12', false, false, 'محطة بورفؤاد', 577, true, '2026-07-13 10:56:53.386537');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (304, 868017, 27, 10.384615384615385, '2026-07-12', false, false, 'محطة بورفؤاد', 579, true, '2026-07-13 10:56:54.904585');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (344, 252964, 33, 31.73076923076923, '2026-07-12', true, false, 'محطة بورفؤاد', 581, true, '2026-07-13 10:57:56.850648');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (382, 302240, 150, 42.25352112676056, '2026-07-07', false, false, 'محطة بورفؤاد', 460, true, '2026-07-13 08:58:12.833967');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (446, 24384, 34, 5.872193436960276, '2026-07-07', false, false, 'محطة بورفؤاد', 461, true, '2026-07-13 08:58:13.680459');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435304, 21, 14.285714285714285, '2026-07-02', false, false, 'محطة بورفؤاد', 338, true, '2026-07-13 07:03:07.341761');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (433, 83743, 30, 0.999000999000999, '2026-07-02', false, true, 'محطة بورفؤاد', 341, true, '2026-07-13 07:04:09.338891');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (368, 523961, 1, 0.4132231404958678, '2026-06-30', false, true, 'غير محدد', 210, true, '2026-07-13 05:57:13.834176');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (417, 57193, 46, 12.637362637362637, '2026-07-07', false, false, 'محطة بورفؤاد', 463, true, '2026-07-13 08:59:16.305946');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 653513, 53, 12.183908045977011, '2026-07-03', false, false, 'محطة بورسعيد', 348, true, '2026-07-13 07:11:19.534354');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (426, 57780, 38, 18.446601941747574, '2026-07-03', false, false, 'محطة بورفؤاد', 350, true, '2026-07-13 07:16:26.175041');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (445, 49983, 87, 17.46987951807229, '2026-07-07', false, false, 'محطة بورفؤاد', 464, true, '2026-07-13 08:59:16.97305');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 526831, 52, 15.028901734104046, '2026-07-03', false, false, 'محطة بورسعيد', 345, true, '2026-07-13 07:18:29.872288');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 693369, 13, 13.131313131313133, '2026-07-04', false, false, 'محطة بورسعيد', 354, true, '2026-07-13 07:19:31.897469');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (378, 575603, 29, 17.159763313609467, '2026-07-04', true, false, 'محطة بورسعيد', 356, true, '2026-07-13 07:22:36.433565');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 653945, 57, 13.194444444444445, '2026-07-04', false, false, 'محطة بورسعيد', 359, true, '2026-07-13 07:22:37.105735');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (361, 390672, 52, 9.20353982300885, '2026-07-04', false, false, 'محطة بورسعيد', 362, true, '2026-07-13 07:24:41.947178');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 409617, 1, 0.10471204188481677, '2026-06-30', false, true, NULL, 365, true, '2026-07-13 07:26:44.370625');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 465166, 56, 17.8343949044586, '2026-07-04', false, false, 'محطة بورفؤاد', 367, true, '2026-07-13 07:26:45.070426');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435639, 24, 15.09433962264151, '2026-07-04', false, false, 'محطة بورفؤاد', 370, true, '2026-07-13 07:27:47.770894');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (403, 171193, 29, 0, '2026-07-04', false, true, 'محطة بورفؤاد', 372, true, '2026-07-13 07:29:50.997771');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (441, 87006, 54, 13.881748071979436, '2026-07-04', false, false, 'محطة بورفؤاد', 374, true, '2026-07-13 07:31:55.256544');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (358, 171301, 179, 34.75728155339806, '2026-07-04', false, false, 'محطة بورفؤاد', 377, true, '2026-07-13 07:33:57.809204');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 454276, 29, 7.37913486005089, '2026-07-05', false, true, 'محطة بورسعيد', 379, true, '2026-07-13 07:48:12.872528');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (414, 164830, 208, 30.32069970845481, '2026-07-05', false, false, 'محطة بورسعيد', 380, true, '2026-07-13 07:49:14.922445');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (395, 295104, 39, 10.29023746701847, '2026-07-05', false, false, 'محطة بورسعيد', 383, true, '2026-07-13 07:56:24.592366');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 511090, 58, 11.507936507936508, '2026-07-05', false, false, 'محطة بورسعيد', 386, true, '2026-07-13 07:56:25.268852');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 693981, 37, 13.309352517985612, '2026-07-05', false, false, 'محطة بورسعيد', 389, true, '2026-07-13 07:57:27.149082');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (278, 824984, 1, 0.38910505836575876, '2026-06-30', false, true, 'غير محدد', 126, true, '2026-07-13 08:06:39.018393');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (311, 740788, 24, 26.08695652173913, '2026-07-05', true, false, 'محطة بورفؤاد', 391, true, '2026-07-13 08:08:43.173791');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (344, 252757, 40, 33.057851239669425, '2026-07-05', true, false, 'محطة بورفؤاد', 397, true, '2026-07-13 08:10:48.658167');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (292, 19581, 35, 21.73913043478261, '2026-07-05', false, false, 'محطة بورفؤاد', 400, true, '2026-07-13 08:11:51.295636');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 87586, 57, 14.690721649484537, '2026-07-05', false, false, 'محطة بورفؤاد', 403, true, '2026-07-13 08:11:52.823231');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (446, 23805, 24, 5.106382978723404, '2026-07-05', false, true, 'محطة بورفؤاد', 405, true, '2026-07-13 08:15:59.993503');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (356, 574819, 63, 15.291262135922329, '2026-07-06', false, false, 'محطة بورسعيد', 409, true, '2026-07-13 08:20:05.734486');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 654586, 55, 12.471655328798185, '2026-07-06', false, false, 'محطة بورسعيد', 412, true, '2026-07-13 08:21:08.517235');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 410076, 37, 12.052117263843648, '2026-07-06', false, false, 'محطة بورسعيد', 417, true, '2026-07-13 08:24:13.695701');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 465838, 52, 17.747440273037544, '2026-07-07', false, false, 'محطة بورفؤاد', 455, true, '2026-07-13 08:54:04.806484');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 436039, 20, 15.037593984962406, '2026-07-07', false, false, 'محطة بورفؤاد', 457, true, '2026-07-13 08:55:07.148762');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (331, 929265, 19, 6.713780918727916, '2026-07-07', false, true, 'محطة بورفؤاد', 465, true, '2026-07-13 09:01:19.513713');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (357, 230813, 262, 47.292418772563174, '2026-07-07', false, false, 'محطة بورفؤاد', 466, true, '2026-07-13 09:01:20.280027');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (332, 21799, 27, 16.16766467065868, '2026-07-07', false, false, 'محطة بورفؤاد', 467, true, '2026-07-13 09:06:26.526707');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 87039, 27, 13.989637305699482, '2026-07-07', false, false, 'محطة بورفؤاد', 468, true, '2026-07-13 09:06:27.389289');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 87790, 21, 10.294117647058822, '2026-07-07', false, false, 'محطة بورفؤاد', 470, true, '2026-07-13 09:06:28.161413');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (354, 249080, 31, 12.4, '2026-07-07', false, false, 'محطة بورفؤاد', 471, true, '2026-07-13 09:06:28.830039');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (406, 413523, 52, 12.590799031477, '2026-07-07', false, false, 'محطة بورفؤاد', 474, true, '2026-07-13 09:07:32.138048');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 694525, 16, 16.49484536082474, '2026-07-08', false, false, 'محطة بورسعيد', 476, true, '2026-07-13 09:08:33.33955');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 694859, 38, 11.377245508982035, '2026-07-08', false, false, 'محطة بورسعيد', 478, true, '2026-07-13 09:10:37.507712');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (421, 192229, 30, 9.46372239747634, '2026-07-08', false, false, 'محطة بورسعيد', 479, true, '2026-07-13 09:10:38.286669');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 695127, 34, 12.686567164179104, '2026-07-08', false, false, 'محطة بورسعيد', 481, true, '2026-07-13 09:10:38.983691');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 410572, 30, 12.605042016806722, '2026-07-08', false, false, 'محطة بورسعيد', 482, true, '2026-07-13 09:11:40.081174');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (459, 530099, 14, 13.333333333333334, '2026-07-08', false, false, 'محطة بورفؤاد', 484, true, '2026-07-13 09:12:42.200118');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (413, 607552, 53, 9.760589318600369, '2026-07-08', false, false, 'محطة بورفؤاد', 485, true, '2026-07-13 09:12:42.999268');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (291, 65335, 26, 13.541666666666666, '2026-07-08', false, false, 'محطة بورفؤاد', 486, true, '2026-07-13 09:14:46.34457');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (352, 500297, 40, 12.779552715654951, '2026-07-08', false, false, 'محطة بورفؤاد', 487, true, '2026-07-13 09:14:47.02718');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (349, 391018, 18, 40.909090909090914, '2026-07-08', false, true, 'محطة بورفؤاد', 492, true, '2026-07-13 09:26:58.26351');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (365, 832420, 34, 8.87728459530026, '2026-07-08', false, false, 'محطة بورفؤاد', 495, true, '2026-07-13 09:28:01.005767');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 614873, 38, 9.595959595959595, '2026-07-09', false, false, 'محطة بورسعيد', 497, true, '2026-07-13 09:35:07.11403');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (303, 455780, 23, 10.454545454545453, '2026-07-09', false, false, 'محطة بورسعيد', 500, true, '2026-07-13 09:36:10.853714');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (339, 460723, 20, 7.142857142857142, '2026-07-09', false, true, 'محطة بورسعيد', 503, true, '2026-07-13 09:38:14.20649');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (328, 19349, 1, 0.005168225748100677, '2026-06-30', false, true, NULL, 506, true, '2026-07-13 09:45:21.854694');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (434, 63709, 24, 7.643312101910828, '2026-07-09', false, false, 'محطة بورسعيد', 509, true, '2026-07-13 09:47:27.03323');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (398, 281231, 37, 14.919354838709678, '2026-07-09', false, false, 'محطة بورسعيد', 512, true, '2026-07-13 09:47:27.717957');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (297, 499002, 17, 7.6923076923076925, '2026-07-09', false, false, 'محطة بورفؤاد', 515, true, '2026-07-13 09:48:31.86754');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (279, 32055, 24, 10.526315789473683, '2026-07-09', false, false, 'محطة بورفؤاد', 518, true, '2026-07-13 09:49:35.109122');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (327, 7005, 25, 13.157894736842104, '2026-07-09', false, false, 'محطة بورفؤاد', 521, true, '2026-07-13 09:49:35.775269');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (355, 541627, 28, 16.666666666666664, '2026-07-09', false, false, 'محطة بورفؤاد', 524, true, '2026-07-13 09:50:39.116192');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 695318, 24, 12.56544502617801, '2026-07-09', false, false, 'محطة بورفؤاد', 527, true, '2026-07-13 09:51:41.694361');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (441, 87564, 72, 12.903225806451612, '2026-07-09', false, false, 'محطة بورفؤاد', 530, true, '2026-07-13 09:51:42.506091');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (380, 270388, 16, 6.477732793522267, '2026-07-10', false, false, 'محطة بورسعيد', 532, true, '2026-07-13 09:55:49.081337');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 695551, 31, 13.304721030042918, '2026-07-10', false, false, 'محطة بورسعيد', 535, true, '2026-07-13 09:55:49.754797');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 766807, 63, 18.155619596541786, '2026-07-10', false, false, 'محطة بورسعيد', 538, true, '2026-07-13 09:56:51.735203');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 527351, 53, 27.31958762886598, '2026-07-10', false, false, 'محطة بورسعيد', 539, true, '2026-07-13 10:01:01.272135');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (376, 478201, 38, 19.587628865979383, '2026-07-10', true, false, 'محطة بورفؤاد', 542, true, '2026-07-13 09:57:55.994529');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (335, 746136, 55, 17.405063291139243, '2026-07-01', false, false, 'محطة بورفؤاد', 321, true, '2026-07-13 06:41:36.398845');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (443, 85581, 24, 13.114754098360656, '2026-07-01', false, false, 'محطة بورفؤاد', 322, true, '2026-07-13 06:41:37.159444');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (458, 345037, 40, 12.195121951219512, '2026-07-01', false, false, 'محطة بورفؤاد', 323, true, '2026-07-13 06:41:37.920807');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 613883, 69, 9.126984126984127, '2026-07-05', false, false, 'محطة بورسعيد', 381, true, '2026-07-13 07:52:17.982894');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (430, 70280, 1, 0.24691358024691357, '2026-06-30', false, true, 'غير محدد', 268, true, '2026-07-13 05:59:19.641859');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (459, 529852, 1, 0.4048582995951417, '2026-06-30', false, true, NULL, 296, true, '2026-07-13 06:01:23.71173');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (458, 344709, 1, 0.17543859649122806, '2026-06-30', false, true, NULL, 297, true, '2026-07-13 06:06:35.485072');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (352, 499417, 1, 0.0022041967906894725, '2026-06-30', false, true, 'غير محدد', 196, true, '2026-07-13 06:13:46.7178');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 526485, 1, 0.1488095238095238, '2026-06-30', false, true, NULL, 298, true, '2026-07-13 06:17:54.077371');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (403, 171193, 1, 0.0005841360335995047, '2026-06-30', false, true, NULL, 299, true, '2026-07-13 06:26:08.91347');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (380, 269658, 12, 7.0588235294117645, '2026-07-01', false, false, 'محطة بورسعيد', 300, true, '2026-07-13 06:32:14.652485');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (368, 524203, 37, 15.289256198347106, '2026-07-01', false, false, 'محطة بورسعيد', 301, true, '2026-07-13 06:32:15.433579');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (344, 252636, 22, 29.72972972972973, '2026-07-01', true, false, 'محطة بورسعيد', 302, true, '2026-07-13 06:32:16.548344');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 510401, 49, 4.553903345724907, '2026-07-01', false, true, 'محطة بورسعيد', 303, true, '2026-07-13 06:32:17.304593');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 692520, 39, 13, '2026-07-01', false, false, 'محطة بورسعيد', 304, true, '2026-07-13 06:33:18.588053');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (430, 70685, 43, 10.617283950617285, '2026-07-01', false, false, 'محطة بورسعيد', 305, true, '2026-07-13 06:33:19.26851');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 764606, 84, 18.22125813449024, '2026-07-01', false, false, 'محطة بورسعيد', 306, true, '2026-07-13 06:33:19.958196');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 692682, 21, 12.962962962962962, '2026-07-01', false, false, 'محطة بورسعيد', 307, true, '2026-07-13 06:33:20.726528');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 464416, 65, 15.402843601895736, '2026-07-01', false, false, 'محطة بورفؤاد', 308, true, '2026-07-13 06:33:21.400858');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 572703, 48, 11.851851851851853, '2026-07-01', false, false, 'محطة بورفؤاد', 309, true, '2026-07-13 06:35:24.568135');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (459, 529994, 23, 16.19718309859155, '2026-07-01', false, false, 'محطة بورفؤاد', 310, true, '2026-07-13 06:38:26.819223');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (421, 191476, 50, 11.627906976744185, '2026-07-01', false, false, 'محطة بورفؤاد', 311, true, '2026-07-13 06:38:27.66221');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435157, 19, 12.925170068027212, '2026-07-01', false, false, 'محطة بورفؤاد', 312, true, '2026-07-13 06:38:28.340077');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (361, 390107, 34, 8.740359897172237, '2026-07-01', false, false, 'محطة بورفؤاد', 313, true, '2026-07-13 06:38:29.112749');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (345, 491924, 40, 13.60544217687075, '2026-07-01', false, false, 'محطة بورفؤاد', 314, true, '2026-07-13 06:39:30.40948');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (356, 574407, 60, 13.157894736842104, '2026-07-01', false, false, 'محطة بورفؤاد', 315, true, '2026-07-13 06:39:31.162913');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (382, 301885, 160, 19.11589008363202, '2026-07-01', false, true, 'محطة بورفؤاد', 316, true, '2026-07-13 06:40:32.350209');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (294, 388350, 32, 10.666666666666668, '2026-07-01', false, false, 'محطة بورفؤاد', 317, true, '2026-07-13 06:40:33.114007');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (316, 478236, 68, 22.74247491638796, '2026-07-01', false, false, 'محطة بورفؤاد', 318, true, '2026-07-13 06:40:33.975597');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (301, 163469, 21, 17.796610169491526, '2026-07-01', false, false, 'محطة بورفؤاد', 319, true, '2026-07-13 06:40:34.648349');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 573091, 36, 9.278350515463918, '2026-07-01', false, false, 'محطة بورفؤاد', 320, true, '2026-07-13 06:40:35.321534');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 654145, 22, 11, '2026-07-05', false, false, 'محطة بورسعيد', 385, true, '2026-07-13 07:56:26.041096');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (348, 591912, 60, 16.997167138810198, '2026-07-02', false, false, 'محطة بورفؤاد', 339, true, '2026-07-13 07:04:10.117565');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 86453, 25, 13.227513227513226, '2026-07-02', false, false, 'محطة بورفؤاد', 342, true, '2026-07-13 07:05:11.315518');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 526641, 45, 28.846153846153843, '2026-07-03', false, false, 'محطة بورسعيد', 343, true, '2026-07-13 07:10:16.515586');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 693270, 46, 12.957746478873238, '2026-07-03', false, false, 'محطة بورسعيد', 346, true, '2026-07-13 07:11:20.300359');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435480, 27, 15.340909090909092, '2026-07-03', false, false, 'محطة بورفؤاد', 349, true, '2026-07-13 07:12:21.495547');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (375, 679787, 32, 11.594202898550725, '2026-07-03', false, false, 'محطة بورفؤاد', 351, true, '2026-07-13 07:17:28.586577');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (380, 269888, 21, 9.130434782608695, '2026-07-04', false, false, 'محطة بورسعيد', 355, true, '2026-07-13 07:19:32.745985');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 765311, 72, 19.94459833795014, '2026-07-04', false, false, 'محطة بورسعيد', 357, true, '2026-07-13 07:22:37.954764');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (398, 280808, 19, 10.674157303370785, '2026-07-04', false, false, 'محطة بورسعيد', 360, true, '2026-07-13 07:23:39.227175');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (407, 214240, 13, 18.571428571428573, '2026-07-04', false, false, 'محطة بورسعيد', 363, true, '2026-07-13 07:24:42.620185');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 409769, 16, 10.526315789473683, '2026-07-04', false, false, 'محطة بورسعيد', 366, true, '2026-07-13 07:26:45.733982');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (275, 541596, 25, 16.55629139072848, '2026-07-04', false, false, 'محطة بورفؤاد', 369, true, '2026-07-13 07:27:48.464061');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 394296, 29, 8.605341246290802, '2026-07-04', false, false, 'محطة بورفؤاد', 371, true, '2026-07-13 07:29:51.850483');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (393, 371666, 107, 22.96137339055794, '2026-07-04', false, false, 'محطة بورفؤاد', 373, true, '2026-07-13 07:31:55.935773');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (443, 85740, 25, 15.723270440251572, '2026-07-04', false, false, 'محطة بورفؤاد', 376, true, '2026-07-13 07:33:58.67382');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 833147, 52, 23.74429223744292, '2026-07-05', false, false, 'محطة بورسعيد', 388, true, '2026-07-13 07:57:27.832921');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (429, 121206, 30, 8.670520231213873, '2026-07-05', false, false, 'محطة بورفؤاد', 390, true, '2026-07-13 08:08:43.947995');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (288, 788090, 22, 11.578947368421053, '2026-07-05', false, false, 'محطة بورفؤاد', 392, true, '2026-07-13 08:09:46.731973');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (278, 825241, 47, 18.28793774319066, '2026-07-05', false, false, 'محطة بورفؤاد', 395, true, '2026-07-13 08:09:47.399724');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435777, 26, 18.84057971014493, '2026-07-05', true, false, 'محطة بورفؤاد', 396, true, '2026-07-13 08:10:50.005555');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (349, 390974, 53, 37.32394366197183, '2026-07-05', false, true, 'محطة بورفؤاد', 399, true, '2026-07-13 08:11:53.496498');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 465545, 51, 13.456464379947231, '2026-07-05', false, false, 'محطة بورفؤاد', 402, true, '2026-07-13 08:11:54.264164');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (350, 447750, 33, 47.82608695652174, '2026-07-05', false, true, 'محطة بورفؤاد', 404, true, '2026-07-13 08:13:58.202831');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 573672, 66, 11.359724612736661, '2026-07-06', false, false, 'محطة بورسعيد', 408, true, '2026-07-13 08:20:06.542027');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 694320, 41, 12.094395280235988, '2026-07-06', false, false, 'محطة بورسعيد', 411, true, '2026-07-13 08:21:09.209396');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (452, 85824, 31, 2.366412213740458, '2026-07-06', false, true, 'محطة بورسعيد', 414, true, '2026-07-13 08:22:10.47776');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 527157, 50, 26.31578947368421, '2026-07-06', false, false, 'محطة بورسعيد', 416, true, '2026-07-13 08:24:14.389059');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (406, 413110, 27, 15.789473684210526, '2026-07-06', false, false, 'محطة بورفؤاد', 419, true, '2026-07-13 08:26:18.572715');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 435906, 20, 15.503875968992247, '2026-07-06', false, false, 'محطة بورفؤاد', 422, true, '2026-07-13 08:27:20.632969');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (386, 288146, 25, 22.727272727272727, '2026-07-06', false, true, 'محطة بورفؤاد', 424, true, '2026-07-13 08:28:23.458752');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (281, 664505, 38, 22.75449101796407, '2026-07-06', true, false, 'محطة بورفؤاد', 429, true, '2026-07-13 08:34:32.827694');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 450729, 38, 15.139442231075698, '2026-07-06', false, false, 'محطة بورفؤاد', 432, true, '2026-07-13 08:35:34.97002');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 454847, 50, 24.752475247524753, '2026-07-07', false, false, 'محطة بورسعيد', 433, true, '2026-07-13 08:37:36.759159');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (395, 295499, 37, 9.367088607594937, '2026-07-07', false, false, 'محطة بورسعيد', 437, true, '2026-07-13 08:41:43.54953');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (299, 433986, 23, 9.019607843137255, '2026-07-07', false, false, 'محطة بورسعيد', 439, true, '2026-07-13 08:44:48.254806');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 701665, 22, 9.12863070539419, '2026-07-07', false, false, 'محطة بورسعيد', 444, true, '2026-07-13 08:46:53.690797');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 574056, 41, 10.677083333333332, '2026-07-07', false, false, 'محطة بورسعيد', 447, true, '2026-07-13 08:47:56.330502');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 766116, 68, 19.653179190751445, '2026-07-07', false, false, 'محطة بورسعيد', 453, true, '2026-07-13 08:49:00.382968');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 436856, 26, 15.028901734104046, '2026-07-12', false, false, 'محطة بورفؤاد', 578, true, '2026-07-13 10:56:54.150573');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (411, 569080, 50, 10.482180293501047, '2026-07-12', false, false, 'محطة بورفؤاد', 584, true, '2026-07-13 10:58:59.480398');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (281, 664710, 48, 23.414634146341466, '2026-07-12', true, false, 'محطة بورفؤاد', 582, true, '2026-07-13 10:57:57.531401');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (375, 680710, 33, 10.476190476190476, '2026-07-12', false, false, 'محطة بورفؤاد', 585, true, '2026-07-13 10:59:00.15993');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (413, 608407, 40, 9.1324200913242, '2026-07-12', false, false, 'محطة بورفؤاد', 588, true, '2026-07-13 10:59:00.823271');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (373, 181540, 30, 8.356545961002785, '2026-07-07', false, false, 'محطة بورفؤاد', 599, true, '2026-07-13 18:30:04.727732');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (373, 181862, 27, 8.385093167701864, '2026-07-07', false, false, 'محطة بورسعيد', 601, true, '2026-07-13 18:34:08.260293');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (468, 38750, 17, 20.238095238095237, '2026-07-13', false, false, 'محطة بورفؤاد', 606, true, '2026-07-14 04:55:16.475538');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (369, 466543, 46, 12.637362637362637, '2026-07-13', false, false, 'محطة بورفؤاد', 609, true, '2026-07-14 04:55:17.321522');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (349, 391110, 43, 46.73913043478261, '2026-07-12', false, true, 'محطة بورفؤاد', 580, true, '2026-07-13 10:57:56.183463');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 88087, 51, 17.17171717171717, '2026-07-12', false, false, 'محطة بورفؤاد', 583, true, '2026-07-13 10:57:58.299743');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 450986, 39, 15.17509727626459, '2026-07-12', false, false, 'محطة بورفؤاد', 586, true, '2026-07-13 10:59:01.49511');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (348, 592726, 40, 21.50537634408602, '2026-07-12', false, false, 'محطة بورفؤاد', 589, true, '2026-07-13 10:59:02.169626');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (467, 443646, 9, 50, '2026-07-07', false, true, 'محطة بورسعيد', 598, true, '2026-07-13 17:49:38.52642');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (373, 182386, 42, 8.015267175572518, '2026-07-08', false, false, 'محطة بورفؤاد', 602, true, '2026-07-13 18:35:09.454176');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (304, 868036, 10, 52.63157894736842, '2026-07-13', false, true, 'محطة بورفؤاد', 604, true, '2026-07-14 04:48:09.102699');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (468, 38666, 1, 0.002586251487094605, '2026-06-30', false, true, NULL, 605, true, '2026-07-14 04:53:13.857603');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 437065, 30, 14.354066985645932, '2026-07-13', false, false, 'محطة بورفؤاد', 607, true, '2026-07-14 04:55:18.073988');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 395679, 33, 11.827956989247312, '2026-07-13', false, false, 'محطة بورفؤاد', 610, true, '2026-07-14 04:55:18.73387');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (441, 87747, 23, 12.568306010928962, '2026-07-12', false, false, 'محطة بورفؤاد', 587, true, '2026-07-13 10:59:02.83907');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (395, 295895, 38, 9.595959595959595, '2026-07-14', false, false, 'محطة بورسعيد', 637, true, '2026-07-15 05:56:04.383144');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (467, 443440, 1, 0.0002255096518130976, '2026-06-30', false, true, NULL, 591, true, '2026-07-13 17:23:16.165892');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (467, 443628, 26, 13.829787234042554, '2026-07-06', false, false, 'محطة بورفؤاد', 593, true, '2026-07-13 17:29:21.851145');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (373, 182751, 27, 7.397260273972603, '2026-07-09', false, true, 'محطة بورفؤاد', 603, true, '2026-07-13 18:37:11.139675');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (284, 524782, 45, 9.433962264150944, '2026-07-13', false, false, 'محطة بورفؤاد', 608, true, '2026-07-14 04:55:19.691738');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (467, 443836, 20, 10.526315789473683, '2026-07-13', false, false, 'محطة بورفؤاد', 611, true, '2026-07-14 04:56:20.876718');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (278, 825422, 32, 17.67955801104972, '2026-07-13', false, false, 'محطة بورفؤاد', 612, true, '2026-07-14 04:56:21.540743');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (428, 113781, 15, 9.036144578313253, '2026-07-13', false, false, 'محطة بورفؤاد', 613, true, '2026-07-14 04:56:22.206718');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (436, 123736, 38, 10.46831955922865, '2026-07-13', false, false, 'محطة بورفؤاد', 614, true, '2026-07-14 04:57:23.46616');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (421, 193211, 55, 5.6008146639511205, '2026-07-13', false, true, 'محطة بورفؤاد', 615, true, '2026-07-14 04:57:24.322981');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (365, 833191, 40, 9.925558312655088, '2026-07-13', false, false, 'محطة بورفؤاد', 616, true, '2026-07-14 04:57:25.098229');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (380, 270595, 15, 7.246376811594203, '2026-07-13', false, false, 'محطة بورفؤاد', 617, true, '2026-07-14 04:58:26.273281');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (302, 494184, 18, 13.333333333333334, '2026-07-13', false, false, 'محطة بورفؤاد', 618, true, '2026-07-14 04:58:27.134009');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (438, 83257, 22, 1.9981834695731153, '2026-07-13', false, true, 'محطة بورفؤاد', 619, true, '2026-07-14 04:58:27.7985');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (431, 129804, 28, 7.7134986225895315, '2026-07-13', false, false, 'محطة بورفؤاد', 620, true, '2026-07-14 04:58:28.483036');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 87828, 62, 15.856777493606138, '2026-07-13', false, false, 'محطة بورفؤاد', 621, true, '2026-07-14 04:59:29.674761');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 88261, 21, 12.068965517241379, '2026-07-13', false, false, 'محطة بورفؤاد', 622, true, '2026-07-14 04:59:30.340588');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (441, 88134, 44, 11.369509043927648, '2026-07-13', false, false, 'محطة بورفؤاد', 623, true, '2026-07-14 04:59:30.9984');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (409, 175739, 55, 13.784461152882205, '2026-07-13', false, false, 'محطة بورسعيد', 624, true, '2026-07-14 07:55:58.511454');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (420, 189045, 62, 6.268958543983821, '2026-07-13', false, true, 'محطة بورسعيد', 625, true, '2026-07-14 07:55:59.20785');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (464, 0, 20, 0, '2026-07-13', false, true, 'محطة بورسعيد', 626, true, '2026-07-14 07:57:00.413918');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (298, 179785, 24, 6.8181818181818175, '2026-07-13', false, true, 'محطة بورسعيد', 627, true, '2026-07-14 07:59:02.212442');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (378, 575858, 23, 19.166666666666668, '2026-07-13', true, false, 'محطة بورسعيد', 628, true, '2026-07-14 08:00:03.51975');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 656159, 60, 12.170385395537526, '2026-07-13', false, false, 'محطة بورسعيد', 629, true, '2026-07-14 08:00:04.384125');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (401, 305423, 199, 12.024169184290031, '2026-07-13', false, true, 'محطة بورسعيد', 630, true, '2026-07-14 08:00:05.243881');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 615710, 41, 9.761904761904763, '2026-07-13', false, false, 'محطة بورسعيد', 631, true, '2026-07-14 08:01:06.427793');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (391, 455878, 44, 22.797927461139896, '2026-07-13', false, false, 'محطة بورسعيد', 632, true, '2026-07-14 08:01:07.287518');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (439, 63183, 61, 33.33333333333333, '2026-07-13', true, false, 'محطة بورسعيد', 633, true, '2026-07-14 08:23:20.10138');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (397, 269219, 43, 18.777292576419214, '2026-07-14', false, false, 'محطة بورسعيد', 634, true, '2026-07-15 05:55:01.322018');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 702955, 46, 13.855421686746988, '2026-07-14', false, false, 'محطة بورسعيد', 635, true, '2026-07-15 05:55:02.022816');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 695964, 30, 13.88888888888889, '2026-07-14', false, false, 'محطة بورسعيد', 636, true, '2026-07-15 05:56:03.314281');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (398, 281549, 52, 16.352201257861633, '2026-07-14', false, false, 'محطة بورسعيد', 638, true, '2026-07-15 05:56:05.063487');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (326, 834029, 45, 13.432835820895523, '2026-07-14', false, false, 'محطة بورسعيد', 639, true, '2026-07-15 05:56:05.737449');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (394, 767610, 83, 18.082788671023962, '2026-07-14', false, false, 'محطة بورسعيد', 640, true, '2026-07-15 05:56:06.413292');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (303, 456185, 32, 7.901234567901234, '2026-07-14', false, false, 'محطة بورسعيد', 641, true, '2026-07-15 05:56:07.087251');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 512388, 60, 13.333333333333334, '2026-07-14', false, false, 'محطة بورسعيد', 642, true, '2026-07-15 05:57:08.186398');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (389, 656534, 48, 12.8, '2026-07-14', false, false, 'محطة بورسعيد', 643, true, '2026-07-15 05:57:08.856454');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (377, 609582, 35, 19.886363636363637, '2026-07-14', true, false, 'محطة بورسعيد', 644, true, '2026-07-15 05:57:09.523009');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (420, 189241, 24, 12.244897959183673, '2026-07-14', false, false, 'محطة بورسعيد', 645, true, '2026-07-15 05:57:10.18941');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (354, 249544, 28, 13.145539906103288, '2026-07-14', false, false, 'محطة بورسعيد', 646, true, '2026-07-15 05:57:10.954999');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (405, 616113, 40, 9.925558312655088, '2026-07-14', false, false, 'محطة بورسعيد', 647, true, '2026-07-15 05:58:12.20424');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (450, 527736, 50, 25.773195876288657, '2026-07-14', false, false, 'محطة بورسعيد', 648, true, '2026-07-15 05:58:12.871316');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (407, 215100, 50, 11.627906976744185, '2026-07-14', false, false, 'محطة بورسعيد', 649, true, '2026-07-15 05:58:13.5334');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 411202, 41, 14.385964912280702, '2026-07-14', false, false, 'محطة بورسعيد', 650, true, '2026-07-15 05:58:14.196464');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (412, 895207, 36, 11.80327868852459, '2026-07-14', false, false, 'محطة بورفؤاد', 651, true, '2026-07-15 05:58:14.859995');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (406, 413870, 44, 12.680115273775217, '2026-07-14', false, false, 'محطة بورفؤاد', 652, true, '2026-07-15 05:59:15.949202');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (446, 24933, 35, 6.375227686703097, '2026-07-14', false, false, 'محطة بورفؤاد', 653, true, '2026-07-15 05:59:16.710404');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (275, 541919, 38, 11.76470588235294, '2026-07-14', false, false, 'محطة بورفؤاد', 654, true, '2026-07-15 05:59:17.45873');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (363, 396004, 19, 5.846153846153846, '2026-07-14', false, false, 'محطة بورفؤاد', 655, true, '2026-07-15 05:59:18.132604');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 437261, 24, 12.244897959183673, '2026-07-14', false, false, 'محطة بورفؤاد', 656, true, '2026-07-15 06:00:19.409606');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 451149, 20, 12.269938650306749, '2026-07-14', false, false, 'محطة بورفؤاد', 657, true, '2026-07-15 06:00:20.093041');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (292, 19793, 35, 16.50943396226415, '2026-07-14', false, false, 'محطة بورفؤاد', 658, true, '2026-07-15 06:00:20.768963');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (419, 179175, 32, 8.64864864864865, '2026-07-14', false, false, 'محطة بورفؤاد', 659, true, '2026-07-15 06:00:21.427633');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (331, 929455, 19, 10, '2026-07-14', false, false, 'محطة بورفؤاد', 660, true, '2026-07-15 06:00:22.183519');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (323, 402808, 40, 21.390374331550802, '2026-07-14', false, false, 'محطة بورفؤاد', 661, true, '2026-07-15 06:01:23.274663');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (330, 788152, 41, 12.094395280235988, '2026-07-14', false, false, 'محطة بورفؤاد', 662, true, '2026-07-15 06:01:23.952896');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (288, 788350, 27, 10.384615384615385, '2026-07-14', false, false, 'محطة بورفؤاد', 663, true, '2026-07-15 06:01:24.721059');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (440, 88002, 20, 11.494252873563218, '2026-07-14', false, false, 'محطة بورفؤاد', 664, true, '2026-07-15 06:01:25.384203');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (465, 214155, 62, 13.219616204690832, '2026-07-14', false, false, 'محطة بورفؤاد', 665, true, '2026-07-15 06:01:26.1415');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (294, 388635, 30, 10.526315789473683, '2026-07-14', false, false, 'محطة بورفؤاد', 666, true, '2026-07-15 06:01:26.893482');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (442, 88442, 20, 11.049723756906078, '2026-07-14', false, false, 'محطة بورفؤاد', 667, true, '2026-07-15 06:02:28.004077');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (388, 779711, 47, 3.8242473555736374, '2026-07-14', false, true, 'محطة بورفؤاد', 668, true, '2026-07-15 06:02:28.681415');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (317, 270601, 29, 10.431654676258994, '2026-07-14', false, false, 'محطة بورسعيد', 669, true, '2026-07-15 07:06:01.638135');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 696065, 14, 13.861386138613863, '2026-07-15', false, false, 'محطة بورسعيد', 670, true, '2026-07-16 05:51:20.926179');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (428, 114120, 29, 8.55457227138643, '2026-07-15', false, false, 'محطة بورسعيد', 671, true, '2026-07-16 05:51:21.708167');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (366, 703259, 44, 14.473684210526317, '2026-07-15', false, false, 'محطة بورسعيد', 672, true, '2026-07-16 05:51:22.709337');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (306, 639640, 28, 3.40632603406326, '2026-07-15', false, true, 'محطة بورسعيد', 673, true, '2026-07-16 05:52:23.990598');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (356, 575470, 27, 14.594594594594595, '2026-07-15', false, false, 'محطة بورسعيد', 674, true, '2026-07-16 05:52:24.656191');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (304, 868043, 38, 542.8571428571429, '2026-07-15', false, true, 'محطة بورسعيد', 676, true, '2026-07-16 05:54:27.223312');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (371, 696252, 22, 11.76470588235294, '2026-07-15', false, false, 'محطة بورسعيد', 685, true, '2026-07-16 07:00:14.815715');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (464, 0, 10, 0, '2026-07-15', false, true, 'محطة بورسعيد', 686, true, '2026-07-16 07:01:16.111041');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (410, 574992, 41, 11.11111111111111, '2026-07-15', false, false, 'محطة بورسعيد', 687, true, '2026-07-16 07:01:17.233189');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (436, 124099, 39, 10.743801652892563, '2026-07-15', false, false, 'محطة بورسعيد', 690, true, '2026-07-16 07:02:20.016933');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (459, 530241, 25, 17.6056338028169, '2026-07-15', false, false, 'محطة بورفؤاد', 694, true, '2026-07-16 07:04:23.372453');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (350, 447836, 43, 50, '2026-07-15', false, true, 'محطة بورفؤاد', 697, true, '2026-07-16 07:05:25.408801');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (319, 313800, 33, 6.832298136645963, '2026-07-15', false, true, 'محطة بورفؤاد', 700, true, '2026-07-16 07:06:29.682565');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (344, 253130, 41, 24.69879518072289, '2026-07-15', false, false, 'محطة بورفؤاد', 704, true, '2026-07-16 07:09:34.132281');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (422, 117820, 62, 11.787072243346007, '2026-07-15', false, false, 'محطة بورفؤاد', 707, true, '2026-07-16 07:10:37.029642');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (390, 512856, 59, 12.606837606837606, '2026-07-15', false, false, 'محطة بورسعيد', 688, true, '2026-07-16 07:01:18.053097');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (451, 411475, 36, 13.186813186813188, '2026-07-15', false, false, 'محطة بورسعيد', 691, true, '2026-07-16 07:02:20.795572');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (445, 50186, 45, 22.167487684729064, '2026-07-15', false, false, 'محطة بورفؤاد', 695, true, '2026-07-16 07:05:26.183457');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (302, 494224, 12, 30, '2026-07-15', true, false, 'محطة بورفؤاد', 698, true, '2026-07-16 07:05:27.048693');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (316, 479054, 81, 20.25, '2026-07-15', false, false, 'محطة بورفؤاد', 701, true, '2026-07-16 07:06:30.367941');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (469, 189828, 69, 0.03634869460775018, '2026-07-15', false, true, 'محطة بورفؤاد', 702, true, '2026-07-16 07:09:34.983585');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (282, 253738, 42, 9.35412026726058, '2026-07-15', false, false, 'محطة بورفؤاد', 705, true, '2026-07-16 07:10:37.804349');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (408, 729820, 48, 9.03954802259887, '2026-07-15', false, false, 'محطة بورفؤاد', 708, true, '2026-07-16 07:10:38.481955');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (343, 806781, 48, 11.214953271028037, '2026-07-15', false, false, 'محطة بورسعيد', 689, true, '2026-07-16 07:01:18.715673');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (458, 345746, 62, 13.276231263383298, '2026-07-15', false, false, 'محطة بورسعيد', 692, true, '2026-07-16 07:02:21.569661');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (368, 525212, 60, 13.88888888888889, '2026-07-15', false, false, 'محطة بورفؤاد', 693, true, '2026-07-16 07:04:24.228722');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (413, 608936, 54, 10.207939508506616, '2026-07-15', false, false, 'محطة بورفؤاد', 696, true, '2026-07-16 07:05:27.74517');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (353, 437402, 21, 14.893617021276595, '2026-07-15', false, false, 'محطة بورفؤاد', 699, true, '2026-07-16 07:05:28.503942');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (362, 451482, 37, 11.11111111111111, '2026-07-15', false, false, 'محطة بورفؤاد', 703, true, '2026-07-16 07:09:35.749942');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (411, 569490, 53, 12.926829268292684, '2026-07-15', false, false, 'محطة بورفؤاد', 706, true, '2026-07-16 07:10:39.150239');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (370, 281960, 52, 10.317460317460316, '2026-07-15', false, false, 'محطة بورفؤاد', 709, true, '2026-07-16 07:11:40.420115');
INSERT INTO public.refuel (vehicle_id, current_odometer, liters, actual_percentage, created_at, is_excess, is_illogical, station, id, is_synced, updated_at) VALUES (375, 681069, 38, 10.584958217270195, '2026-07-15', false, false, 'محطة بورفؤاد', 710, true, '2026-07-16 07:11:41.194899');


--
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO public."user" (username, full_name, role, id, hashed_password, is_active, created_at, updated_at, is_synced) VALUES ('ayman', 'مدير النظام', 'admin', 1, '$pbkdf2-sha256$29000$fY8xhjCmdE4JIYSw1rpXqg$ff27.vE/XABoN/h38cxuKGMYcu2.VlpEKVLMwiG.gZ8', true, '2026-07-04 17:07:13.8871', '2026-07-07 04:27:01.259189', true);
INSERT INTO public."user" (username, full_name, role, id, hashed_password, is_active, created_at, updated_at, is_synced) VALUES ('admin', 'مدير النظام', 'admin', 2, '$pbkdf2-sha256$29000$3XvPeW9NCUHoPefcG4Mw5g$NOI1AkSguJH2jkioevyWH/JD3SB/w1h/PuekjfnXClY', true, '2026-07-07 10:36:01.200609', '2026-07-07 10:36:03.739663', true);


--
-- Data for Name: vehicle; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1894, 'ط ع أ', 280, 114, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 298369, 1990, '2026-06-30', 274, true, '2026-07-07 04:40:13.659085', '2026-07-07 04:41:09.731084');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6532, 'ط ن م', 504, 229, 'ايسوزو Tfr10', NULL, 'سيارة نقل بيك اب', 'بنزين 92', 15, 599492, 1991, '2026-06-30', 276, true, '2026-07-07 04:40:13.659673', '2026-07-12 19:53:05.455841');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5317, 'ط هـ ع', 742, 329, 'نصر دوجان', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 39291, 2000, '2026-07-12', 290, true, '2026-07-07 04:40:13.662339', '2026-07-14 04:49:10.239983');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2856, 'ط هـ ل', 805, 379, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 494224, 1997, '2026-07-15', 302, true, '2026-07-07 04:40:13.664711', '2026-07-16 07:05:04.865953');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8574, 'ط ص ب', 557, 248, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 465472, 1992, '2026-06-30', 280, true, '2026-07-07 04:40:13.660455', '2026-07-12 19:54:54.076877');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2584, 'ط هـ ل', 856, 398, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 799655, 1997, '2026-07-09', 309, true, '2026-07-07 04:40:13.666228', '2026-07-13 09:49:08.382054');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4392, 'ط هـ ل', 745, 332, 'نصر دوجان', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 19793, 2024, '2026-07-14', 292, true, '2026-07-07 04:40:13.662733', '2026-07-16 06:52:09.038081');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1329, 'ط ص ق', 1214, 64, 'مازدا T3500', NULL, 'ميني باص', 'سولار', 20, 682468, 2024, '2026-06-30', 296, true, '2026-07-07 04:40:13.663518', '2026-07-12 20:01:39.705785');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2915, 'ط ص ج', 309, 126, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 388635, 1994, '2026-07-14', 294, true, '2026-07-07 04:40:13.663122', '2026-07-15 06:01:22.483441');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9657, 'ط هـ ف', 717, 304, 'نصر شاهين', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 55648, 2024, '2026-06-30', 285, true, '2026-07-07 04:40:13.66129', '2026-07-12 19:56:35.441287');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1572, 'ط ع ا', 428, 180, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 450869, 1993, '2026-06-30', 286, true, '2026-07-07 04:40:13.661468', '2026-07-12 19:56:58.234887');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6937, 'ط ص ج', 555, 247, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 474626, 1993, '2026-06-30', 287, true, '2026-07-07 04:40:13.661601', '2026-07-12 19:57:16.321313');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3471, 'ط ص د', 611, 266, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 788350, 1993, '2026-07-14', 288, true, '2026-07-07 04:40:13.661788', '2026-07-15 06:00:48.628246');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4175, 'ط هـ ع', 863, 405, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 740902, 1997, '2026-07-12', 311, true, '2026-07-07 04:40:13.666724', '2026-07-13 10:55:44.226819');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6145, 'ط ل ر', 513, 234, 'ايسوزو', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 541919, 1990, '2026-07-14', 275, true, '2026-07-07 04:40:13.659377', '2026-07-15 05:59:05.236799');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2195, 'ط هـ ع', 743, 330, 'نصر دوجان', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 65335, 2024, '2026-07-08', 291, true, '2026-07-07 04:40:13.662533', '2026-07-13 09:14:12.198624');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4943, 'ط هـ و', 442, 191, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 499002, 1995, '2026-07-09', 297, true, '2026-07-07 04:40:13.663715', '2026-07-13 09:47:55.979429');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4978, 'ط ع س', 167, 123, 'مرسيدس بنز', NULL, 'اتوبيس', 'سولار', 30, 553908, 1995, '2026-06-30', 293, true, '2026-07-07 04:40:13.662929', '2026-07-12 20:00:00.541281');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1592, 'ط ع ا', 458, 201, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 179785, 1995, '2026-07-13', 298, true, '2026-07-07 04:40:13.663914', '2026-07-14 07:58:44.017357');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7269, 'ط ص ب', 540, 244, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 774001, 2024, '2026-07-06', 295, true, '2026-07-07 04:40:13.663321', '2026-07-13 08:23:03.076766');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9846, 'ط هـ ق', 861, 403, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 874280, 1997, '2026-06-30', 310, true, '2026-07-07 04:40:13.666431', '2026-07-12 20:06:45.308001');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8921, 'ط ص ط', 642, 232, 'سوزوكي K410', NULL, 'ميكروباص', 'بنزين 92', 17, 32055, 1992, '2026-07-09', 279, true, '2026-07-07 04:40:13.660266', '2026-07-13 09:48:46.489268');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1762, 'ص د ص', 823, 308, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 456185, 1997, '2026-07-14', 303, true, '2026-07-07 04:40:13.664919', '2026-07-15 05:55:59.355185');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8763, 'ط ع ا', 622, 270, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 433986, 1995, '2026-07-07', 299, true, '2026-07-07 04:40:13.664114', '2026-07-13 08:44:03.361179');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2197, 'ص د ص', 357, 154, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 253738, 1993, '2026-07-15', 282, true, '2026-07-07 04:40:13.660791', '2026-07-16 07:09:42.772067');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8296, 'ط ص ب', 887, 324, 'ميتسوبيشى 200L', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 270601, 1997, '2026-07-14', 317, true, '2026-07-07 04:40:13.667984', '2026-07-15 07:05:50.883766');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4683, 'ط ل ى', 799, 373, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 163594, 1997, '2026-07-08', 301, true, '2026-07-07 04:40:13.664505', '2026-07-13 09:14:40.803088');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2794, 'ط ص س', 739, 326, 'نصر شاهين', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 9552, 2000, '2026-07-09', 289, true, '2026-07-07 04:40:13.662097', '2026-07-13 09:35:25.70368');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1375, 'ط ص ق', 103, 76, 'ايسوزو Wfr', NULL, 'ميكروباص', 'بنزين 92', 15, 664710, 1992, '2026-07-12', 281, true, '2026-07-07 04:40:13.660581', '2026-07-13 10:57:36.054646');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1759, 'ص د ص', 825, 310, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 527260, 1997, '2026-06-30', 305, true, '2026-07-07 04:40:13.665443', '2026-07-12 20:05:35.184412');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1753, 'ص د ص', 824, 309, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 868043, 1997, '2026-07-15', 304, true, '2026-07-07 04:40:13.665222', '2026-07-16 05:54:25.105612');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2135, 'ص د ص', 494, 222, 'ايسوزو Tfr10', NULL, 'سيارة نقل بيك اب', 'بنزين 92', 15, 412327, 1991, '2026-07-12', 277, true, '2026-07-07 04:40:13.65989', '2026-07-13 10:48:10.77723');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4852, 'ط ع س', 837, 136, 'مرسيدس بنز', NULL, 'اتوبيس', 'سولار', 30, 0, 1997, '1989-09-04', 307, true, '2026-07-07 04:40:13.665839', '2026-07-07 04:41:33.201273');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9847, 'ط هـ ق', 855, 397, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 924745, 1997, '2024-12-17', 308, true, '2026-07-07 04:40:13.666034', '2026-07-07 04:41:33.873496');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4381, 'ط هـ ق', 797, 371, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 683873, 1997, '2026-07-08', 300, true, '2026-07-07 04:40:13.66431', '2026-07-13 09:26:25.534417');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5422, 'ط ع د', 867, 138, 'مازدا T3500', NULL, 'ميني باص', 'سولار', 20, 479054, 1996, '2026-07-15', 316, true, '2026-07-07 04:40:13.667749', '2026-07-16 07:05:33.705357');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9658, 'ط ل ى', 841, 383, 'نصر شاهين', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 13841, 2024, '2026-06-30', 312, true, '2026-07-07 04:40:13.666929', '2026-07-12 20:07:23.993008');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3269, 'ط ص ج', 178, 38, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 524782, 1993, '2026-07-13', 284, true, '2026-07-07 04:40:13.661142', '2026-07-14 04:54:41.370578');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6453, 'ط هـ ع', 843, 385, 'نصر شاهين', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 3151, 2000, '2026-06-30', 313, true, '2026-07-07 04:40:13.66714', '2026-07-14 11:01:38.957277');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7421, 'ط ن ط', 847, 389, 'شاهين 1400', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 34744, 1997, '2026-07-12', 314, true, '2026-07-07 04:40:13.667356', '2026-07-13 10:55:57.185455');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1784, 'ط ع ب', 274, 110, 'ايسوزو Tfr10', NULL, 'سيارة نقل بيك اب', 'بنزين 92', 15, 825422, 1991, '2026-07-13', 278, true, '2026-07-07 04:40:13.660079', '2026-07-14 04:55:51.254997');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1763, 'ص د ص', 826, 311, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 639640, 1997, '2026-07-15', 306, true, '2026-07-07 04:40:13.665636', '2026-07-16 05:51:20.17119');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1754, 'ص د ص', 449, 197, 'ايسوزو Tfr52', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 545782, 1993, '2026-06-30', 283, true, '2026-07-07 04:40:13.660988', '2026-07-12 19:55:57.031331');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1934, 'ط هـ ق', 970, 450, 'شاهين 1400', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 21799, 2000, '2026-07-07', 332, true, '2026-07-07 04:40:13.671351', '2026-07-13 09:05:24.545275');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6593, 'ط ل أ', 895, 417, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 454412, 1999, '2026-06-30', 321, true, '2026-07-07 04:40:13.668943', '2026-07-12 20:10:43.297652');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6162, 'ط ل ف', 932, 434, 'شاهين1400', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 7005, 2000, '2026-07-09', 327, true, '2026-07-07 04:40:13.670271', '2026-07-13 09:49:16.634901');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9748, 'ط ص ع', 917, 155, 'ميتسوبيشي', NULL, 'ميني باص', 'سولار', 18, 834029, 2000, '2026-07-14', 326, true, '2026-07-07 04:40:13.670061', '2026-07-15 05:55:36.965969');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7256, 'ط ب و', 1065, 478, 'تويوتا هاي ايس', NULL, 'سيارة اسعاف', 'بنزين 92', 18, 253130, 2003, '2026-07-15', 344, true, '2026-07-07 04:40:13.674061', '2026-07-16 07:09:32.151236');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9824, 'ط ص ع', 915, 153, 'ميتسوبيشي روزا', NULL, 'ميني باص', 'سولار', 18, 718429, 1999, '2026-06-30', 325, true, '2026-07-07 04:40:13.669845', '2026-07-12 20:12:41.760893');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2318, 'ط ع ب', 879, 316, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 313800, 1997, '2026-07-15', 319, true, '2026-07-07 04:40:13.668531', '2026-07-16 07:05:25.256287');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1485, 'ط ص ق', 1126, 191, 'ميتسوبيشي روزا', NULL, 'ميني باص', 'سولار', 18, 575470, 2024, '2026-07-15', 356, true, '2026-07-07 04:40:13.676535', '2026-07-16 05:51:42.404573');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9165, 'ط ط ر', 262, 30, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'بنزين 92', 15, 456817, 2000, '2026-06-30', 329, true, '2026-07-07 04:40:13.670675', '2026-07-12 20:13:53.568755');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7512, 'ط ص و', 1157, 520, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 396004, 2013, '2026-07-14', 363, true, '2026-07-07 04:40:13.677919', '2026-07-15 05:59:14.609668');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1593, 'ط ص ق', 1173, 196, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 703259, 2012, '2026-07-15', 366, true, '2026-07-07 04:40:13.678741', '2026-07-16 05:51:05.480792');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1586, 'ط ل هـ', 896, 418, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 402808, 1999, '2026-07-14', 323, true, '2026-07-07 04:40:13.66937', '2026-07-15 06:00:25.991982');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1296, 'ط ص ق', 1061, 182, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 806781, 2003, '2026-07-15', 343, true, '2026-07-07 04:40:13.673843', '2026-07-16 07:01:15.531766');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7451, 'ط ص و', 1152, 515, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 417717, 2013, '2026-06-30', 364, true, '2026-07-07 04:40:13.678127', '2026-07-12 20:25:31.754981');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1298, 'ط ع أ', 0, 0, 'نصر', NULL, 'سيارة نقل لوري', 'سولار', 27, 0, 2000, '1989-09-04', 333, true, '2026-07-07 04:40:13.671549', '2026-07-07 04:41:50.781977');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4621, 'ط ع س', 978, 162, 'مرسيدس بنز Mcv 400 R', NULL, 'اتوبيس', 'سولار', 30, 52820, 2000, '2026-06-30', 334, true, '2026-07-07 04:40:13.671771', '2026-07-07 04:41:51.462041');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9872, 'ط ص ع', 996, 172, 'ميتسوبيشي GB800', NULL, 'ميني باص', 'سولار', 20, 458350, 2001, '2026-06-30', 336, true, '2026-07-07 04:40:13.672173', '2026-07-12 20:15:49.912188');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2671, 'ط هـ ع', 1117, 510, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 437402, 2009, '2026-07-15', 353, true, '2026-07-07 04:40:13.675939', '2026-07-16 07:05:16.054354');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4967, 'ط ع س', 1089, 187, 'ميتسوبيشي روزا', NULL, 'ميني باص', 'سولار', 20, 592726, 2007, '2026-07-12', 348, true, '2026-07-07 04:40:13.674915', '2026-07-13 10:58:48.72184');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2356, 'ط ع ى', 1049, 392, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 726706, 2003, '2026-06-30', 340, true, '2026-07-07 04:40:13.67296', '2026-07-12 20:17:06.428873');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1823, 'ص د ص', 1050, 393, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 741851, 2003, '2026-06-30', 341, true, '2026-07-07 04:40:13.673384', '2026-07-12 20:17:20.27367');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6914, 'ط ع ق', 1099, 497, 'تويوتا', NULL, 'سيارة اسعاف', 'بنزين 92', 18, 447836, 2008, '2026-07-15', 350, true, '2026-07-07 04:40:13.67532', '2026-07-16 07:04:46.386109');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1423, 'ط ع أ', 1047, 390, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 354893, 2003, '2026-06-30', 342, true, '2026-07-07 04:40:13.673624', '2026-07-07 04:41:56.84956');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4971, 'ط ع س', 1035, 178, 'مرسيدس بنز Mcv 400 R', NULL, 'اتوبيس', 'سولار', 30, 368458, 2002, '2026-07-05', 338, true, '2026-07-07 04:40:13.67256', '2026-07-13 08:09:10.201123');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7359, 'ط هـ ق', 1118, 511, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 249544, 2009, '2026-07-14', 354, true, '2026-07-07 04:40:13.676129', '2026-07-15 05:56:59.563137');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9781, 'ط هـ ص', 1076, 487, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 514804, 2005, '2026-06-30', 346, true, '2026-07-07 04:40:13.674444', '2026-07-12 20:19:00.208788');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1768, 'ط ع أ', 1085, 406, 'شيفروليه', NULL, 'سيارة نقل خفيف', 'سولار', 17, 279365, 2006, '2026-06-30', 347, true, '2026-07-07 04:40:13.674704', '2026-07-12 20:19:22.674244');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8843, 'ط ص ى', 1136, 425, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 390672, 2010, '2026-07-04', 361, true, '2026-07-07 04:40:13.677515', '2026-07-13 07:23:58.661434');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1825, 'ص د ص', 878, 315, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 697750, 1997, '2026-06-30', 320, true, '2026-07-07 04:40:13.668747', '2026-07-12 20:10:25.173241');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1437, 'ط ص ق', 993, 171, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 746136, 2001, '2026-07-01', 335, true, '2026-07-07 04:40:13.671968', '2026-07-13 06:40:39.059869');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8853, 'ط ص ب', 1104, 414, 'رينو', NULL, 'سيارة نقل لوري', 'سولار', 40, 289415, 2008, '2026-06-30', 351, true, '2026-07-07 04:40:13.67552', '2026-07-12 20:20:45.001363');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2856, 'ط هـ ع', 1112, 505, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 500588, 2009, '2026-07-11', 352, true, '2026-07-07 04:40:13.675714', '2026-07-13 10:01:58.002007');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5316, 'ط هـ ع', 1075, 486, 'بيجو 405', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 491924, 2005, '2026-07-01', 345, true, '2026-07-07 04:40:13.674254', '2026-07-13 06:38:34.404978');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6893, 'ط ص ج', 1175, 447, 'Freight Liner', NULL, 'سيارة نقل', 'سولار', 30, 192466, 2012, '2026-06-30', 367, true, '2026-07-07 04:40:13.678951', '2026-07-12 20:26:34.692814');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7521, 'ط ص و', 1161, 524, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 451482, 2013, '2026-07-15', 362, true, '2026-07-07 04:40:13.677708', '2026-07-16 07:09:15.835658');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1496, 'ط ص ق', 1127, 192, 'ميتسوبيشي روزا', NULL, 'ميني باص', 'سولار', 18, 541627, 2009, '2026-07-09', 355, true, '2026-07-07 04:40:13.676326', '2026-07-13 09:49:44.670018');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6549, 'ط ه ل', 1094, 494, 'تويوتا', NULL, 'سيارة اسعاف', 'بنزين 92', 18, 391110, 2007, '2026-07-12', 349, true, '2026-07-07 04:40:13.675109', '2026-07-13 10:56:53.9092');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1427, 'ط ع أ', 1133, 422, 'فولفو', NULL, 'جرار نقل تريلا', 'سولار', 40, 171301, 2010, '2026-07-04', 358, true, '2026-07-07 04:40:13.676928', '2026-07-13 07:33:39.835622');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6931, 'ط ع ب', 0, 0, 'بريما', NULL, 'مقطورة', '-', 0, 0, 2010, '1989-09-04', 359, true, '2026-07-07 04:40:13.67712', '2026-07-07 04:42:08.175');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6932, 'ط ع ب', 0, 0, 'بريما', NULL, 'مقطورة', '-', 0, 0, 2010, '1989-09-04', 360, true, '2026-07-07 04:40:13.677325', '2026-07-07 04:42:08.835532');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2174, 'ص د ص', 1048, 391, 'شيفروليه', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 460862, 2003, '2026-07-10', 339, true, '2026-07-07 04:40:13.672761', '2026-07-13 09:55:43.848977');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7634, 'ط ع د', 1169, 444, 'نيسان', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 833191, 2012, '2026-07-13', 365, true, '2026-07-07 04:40:13.678535', '2026-07-14 04:57:13.549864');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4946, 'ط ن و', 900, 422, 'تويوتا هاي ايس', NULL, 'سيارة اسعاف', 'بنزين 92', 18, 332048, 1999, '2026-07-10', 324, true, '2026-07-07 04:40:13.669566', '2026-07-13 09:58:42.290219');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5364, 'ط ص ج', 949, 351, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 929455, 2000, '2026-07-14', 331, true, '2026-07-07 04:40:13.671154', '2026-07-15 06:00:17.323485');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6714, 'ط ل ى', 936, 438, 'نصر شاهين', NULL, 'سيارة ملاكي', 'بنزين 92', 15, 19349, 2000, '2026-06-30', 328, true, '2026-07-07 04:40:13.670473', '2026-07-13 09:44:55.356019');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9914, 'ط ص أ', 948, 350, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 788152, 2000, '2026-07-14', 330, true, '2026-07-07 04:40:13.670953', '2026-07-15 06:00:40.377373');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1426, 'ط ع أ', 1132, 421, 'فولفو', NULL, 'جرار نقل تريلا', 'سولار', 40, 230813, 2010, '2026-07-07', 357, true, '2026-07-07 04:40:13.67674', '2026-07-13 09:00:55.056092');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2946, 'ص د ل', 1262, 208, 'مرسيدس بنز Mcv 400L', NULL, 'اتوبيس', 'سولار', 40, 314600, 2015, '2026-06-30', 383, true, '2026-07-07 04:40:13.682287', '2026-07-12 20:34:11.731246');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5717, 'ط هـ و', 1354, 486, 'ميتسوبيشي', NULL, 'سيارة نقل', 'سولار', 18, 269219, 2015, '2026-07-14', 397, true, '2026-07-07 04:40:13.685806', '2026-07-15 05:54:46.34398');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3175, 'ط ن و', 1285, 214, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 779711, 2015, '2026-07-14', 388, true, '2026-07-07 04:40:13.683271', '2026-07-15 06:02:07.291903');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2971, 'ط ل ط', 1278, 604, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 287378, 2024, '2026-07-07', 387, true, '2026-07-07 04:40:13.683067', '2026-07-16 10:32:17.18848');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3182, 'ط ن و', 1320, 229, 'تويوتا كوستر', NULL, 'ميني باص', 'سولار', 27, 767610, 2015, '2026-07-14', 394, true, '2026-07-07 04:40:13.685175', '2026-07-15 05:55:46.236213');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1843, 'ط ل ن', 1244, 581, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 575858, 2014, '2026-07-13', 378, true, '2026-07-07 04:40:13.681113', '2026-07-14 07:59:09.530631');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7719, 'ط ص أ', 1384, 655, 'تويوتا', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 175739, 2016, '2026-07-13', 409, true, '2026-07-07 04:40:13.693278', '2026-07-14 07:55:05.392895');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1637, 'ط ص ق', 1263, 209, 'مرسيدس بنز Mcv 400L', NULL, 'اتوبيس', 'سولار', 40, 302240, 2014, '2026-07-07', 382, true, '2026-07-07 04:40:13.682032', '2026-07-13 08:58:01.352047');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9981, 'ط ص ع', 1408, 679, 'تويوتا', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 608936, 2016, '2026-07-15', 413, true, '2026-07-07 04:40:13.694247', '2026-07-16 07:04:36.078257');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4737, 'ط ن هـ', 1210, 562, 'تويوتا', NULL, 'سيارة اسعاف', 'سولار', 18, 281960, 2013, '2026-07-15', 370, true, '2026-07-07 04:40:13.679541', '2026-07-16 07:10:36.953409');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5725, 'ط هـ و', 1353, 485, 'ميتسوبيشي', NULL, 'سيارة نقل', 'سولار', 18, 272122, 2015, '2026-06-30', 396, true, '2026-07-07 04:40:13.685605', '2026-07-12 20:41:40.673206');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9246, 'ط ص ج', 1394, 665, 'تويوتا هاي لوكس', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 895207, 2016, '2026-07-14', 412, true, '2026-07-07 04:40:13.694054', '2026-07-15 05:58:05.851527');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6238, 'ص د ج', 1359, 636, 'Volks Wagon', NULL, 'سيارة اسعاف', 'سولار', 18, 171193, 2016, '2026-07-04', 403, true, '2026-07-07 04:40:13.687022', '2026-07-13 07:29:35.006335');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5143, 'ط ع س', 1258, 204, 'مرسيدس بنز Mcv 400L', NULL, 'اتوبيس', 'سولار', 40, 226455, 2014, '2026-06-30', 384, true, '2026-07-07 04:40:13.68249', '2026-07-12 20:35:07.720481');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4176, 'ط هـ ع', 1271, 597, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 174888, 2015, '2026-06-30', 385, true, '2026-07-07 04:40:13.682681', '2026-07-12 20:35:31.696883');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3176, 'ط ن و', 1286, 215, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 656534, 2015, '2026-07-14', 389, true, '2026-07-07 04:40:13.684098', '2026-07-15 05:56:16.172964');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7768, 'ط ص ق', 1225, 453, 'نيسان', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 333937, 2014, '2026-07-05', 372, true, '2026-07-07 04:40:13.679928', '2026-07-13 08:11:20.474044');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6426, 'ط هـ و', 1406, 677, 'تويوتا', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 729820, 2016, '2026-07-15', 408, true, '2026-07-07 04:40:13.68809', '2026-07-16 07:10:24.399172');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7965, 'ط ل س', 1341, 477, 'تويوتا', NULL, 'سيارة نقل بيك اب', 'سولار', 18, 281549, 2015, '2026-07-14', 398, true, '2026-07-07 04:40:13.68602', '2026-07-15 05:55:28.04961');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8321, 'ط ل ن', 1237, 574, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 681069, 2014, '2026-07-15', 375, true, '2026-07-07 04:40:13.680509', '2026-07-16 07:10:54.531148');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9731, 'ط ل ن', 1245, 582, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 534200, 2014, '2026-06-30', 379, true, '2026-07-07 04:40:13.681302', '2026-07-12 20:32:15.119521');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2915, 'ط ص د', 1411, 682, 'تويوتا هاي لوكس', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 413870, 2016, '2026-07-14', 406, true, '2026-07-07 04:40:13.687679', '2026-07-15 05:58:22.100846');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7769, 'ط ص ق', 1226, 454, 'نيسان', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 182751, 2014, '2026-07-09', 373, true, '2026-07-07 04:40:13.680123', '2026-07-13 18:36:26.742991');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3582, 'ط ص ق', 1288, 217, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 512856, 2024, '2026-07-15', 390, true, '2026-07-07 04:40:13.684329', '2026-07-16 07:00:53.727678');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5264, 'ط هـ ص', 1530, 779, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 57193, 2019, '2026-07-07', 417, true, '2026-07-07 04:40:13.695098', '2026-07-13 08:58:30.978741');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3189, 'ط ن و', 1315, 224, 'تويوتا كوستر', NULL, 'ميني باص', 'سولار', 27, 208710, 2015, '2026-07-09', 392, true, '2026-07-07 04:40:13.684782', '2026-07-13 09:47:33.544873');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5173, 'ط ع س', 1374, 646, 'مرسيدس بنز Mcv 400L', NULL, 'اتوبيس', 'سولار', 40, 305423, 2016, '2026-07-13', 401, true, '2026-07-07 04:40:13.686613', '2026-07-14 08:00:02.152607');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3212, 'ط هـ و', 1330, 466, 'نيسان بيك اب', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 295895, 2015, '2026-07-14', 395, true, '2026-07-07 04:40:13.685392', '2026-07-15 05:55:18.451539');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1974, 'ط ع ى', 1368, 634, 'Freight Liner', NULL, 'سيارة نقل', 'سولار', 30, 825241, 2016, '2026-06-30', 399, true, '2026-07-07 04:40:13.686223', '2026-07-12 20:42:25.640762');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5169, 'ط ع س', 1423, 694, 'مرسيدس بنز Mcv 400L', NULL, 'اتوبيس', 'سولار', 40, 103442, 2016, '2026-06-30', 400, true, '2026-07-07 04:40:13.686418', '2026-07-12 20:42:54.912404');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2976, 'ط ص د', 1390, 661, 'تويوتا هاي لوكس', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 215100, 2016, '2026-07-14', 407, true, '2026-07-07 04:40:13.687883', '2026-07-15 05:57:29.728945');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5172, 'ط ع س', 1380, 652, 'مرسيدس بنز Mcv 400L', NULL, 'اتوبيس', 'سولار', 40, 225859, 2016, '2026-06-30', 402, true, '2026-07-07 04:40:13.686823', '2026-07-12 20:43:33.272387');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3541, 'ط ب ل', 1360, 637, 'Volks Wagon', NULL, 'سيارة اسعاف', 'سولار', 18, 185560, 2016, '2026-06-30', 404, true, '2026-07-07 04:40:13.687236', '2026-07-12 20:44:21.291538');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3187, 'ط ن و', 1314, 223, 'تويوتا كوستر', NULL, 'ميني باص', 'سولار', 27, 455878, 2015, '2026-07-13', 391, true, '2026-07-07 04:40:13.684564', '2026-07-14 08:00:25.210209');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4729, 'ط ط ر', 1409, 680, 'تويوتا', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 616113, 2016, '2026-07-14', 405, true, '2026-07-07 04:40:13.68743', '2026-07-15 05:57:09.386595');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8532, 'ط ص ب', 1253, 458, 'Freight Liner', NULL, 'سيارة نقل', 'سولار', 30, 212232, 2014, '2026-07-07', 381, true, '2026-07-07 04:40:13.681805', '2026-07-16 06:52:21.063752');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9926, 'ط ص ن', 1442, 622, 'مان', NULL, 'سيارة نقل', 'سولار', 30, 164830, 2018, '2026-07-05', 414, true, '2026-07-07 04:40:13.694452', '2026-07-13 07:49:01.23615');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7167, 'ط ل ب', 1197, 549, 'بيجو 508', NULL, 'سيارة ملاكي', 'بنزين 92', 12, 466543, 2014, '2026-07-13', 369, true, '2026-07-07 04:40:13.679352', '2026-07-14 04:54:52.087713');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8319, 'ط ل ن', 1241, 578, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 609582, 2014, '2026-07-14', 377, true, '2026-07-07 04:40:13.680913', '2026-07-15 05:56:36.324337');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8142, 'ط ل و', 1238, 575, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 478201, 2014, '2026-07-10', 376, true, '2026-07-07 04:40:13.680718', '2026-07-13 09:57:31.089485');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7531, 'ط ل م', 1251, 588, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 270595, 2024, '2026-07-13', 380, true, '2026-07-07 04:40:13.681492', '2026-07-14 04:57:28.550386');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9764, 'ط هـ ص', 1276, 602, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 288146, 2015, '2026-07-06', 386, true, '2026-07-07 04:40:13.682879', '2026-07-13 08:28:15.689333');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7924, 'ط ص ب', 1383, 654, 'تويوتا', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 574992, 2016, '2026-07-15', 410, true, '2026-07-07 04:40:13.693527', '2026-07-16 07:00:45.466396');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (4817, 'ط هـ ص', 1527, 776, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 188761, 2019, '2026-06-30', 415, true, '2026-07-07 04:40:13.694757', '2026-07-12 20:51:10.402343');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2675, 'ط هـ ع', 1230, 567, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 409461, 2024, '2026-07-09', 374, true, '2026-07-07 04:40:13.680322', '2026-07-13 09:50:30.562707');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6172, 'ط هـ ص', 1533, 782, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 184888, 2019, '2026-06-25', 416, true, '2026-07-07 04:40:13.694932', '2026-07-07 04:43:47.104779');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3196, 'ط ن و', 1316, 225, 'تويوتا كوستر', NULL, 'ميني باص', 'سولار', 27, 372355, 2015, '2026-07-12', 393, true, '2026-07-07 04:40:13.68498', '2026-07-13 10:48:49.41385');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6183, 'ط هـ ص', 1536, 785, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 0, 2019, '1989-09-04', 418, true, '2026-07-07 04:40:13.696112', '2026-07-07 04:43:48.43292');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3473, 'ط ن ر', 1685, 936, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 83257, 2024, '2026-07-13', 438, true, '2026-07-07 04:40:13.703495', '2026-07-14 04:58:05.719782');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2159, 'ط ن هـ', 1622, 873, 'نيسان', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 121580, 2024, '2026-07-07', 429, true, '2026-07-07 04:40:13.70048', '2026-07-13 08:58:20.243571');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9687, 'ط ل ن', 1581, 832, 'Iveco', NULL, 'سيارة اسعاف', 'سولار', 18, 124548, 2020, '2026-07-06', 424, true, '2026-07-07 04:40:13.698423', '2026-07-13 08:27:51.038912');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3291, 'ط ن و', 1615, 866, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 15, 70685, 2022, '2026-07-01', 430, true, '2026-07-07 04:40:13.700653', '2026-07-13 06:32:27.739425');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3549, 'ط ص ق', 1583, 834, 'فولفو', NULL, 'اتوبيس', 'سولار', 40, 0, 2020, '1989-09-04', 425, true, '2026-07-07 04:40:13.698623', '2026-07-07 04:43:53.06509');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5263, 'ط هـ ص', 1529, 778, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 179175, 2019, '2026-07-14', 419, true, '2026-07-07 04:40:13.696365', '2026-07-15 06:00:08.643199');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8961, 'ط ل هـ', 1022, 464, 'سوزوكي K410', NULL, 'ميكروباص', 'بنزين 92', 17, 27834, 2024, '2026-07-09', 337, true, '2026-07-07 04:40:13.672369', '2026-07-13 09:48:05.360222');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9353, 'ط ن د', 1666, 917, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 129804, 2024, '2026-07-13', 431, true, '2026-07-07 04:40:13.701946', '2026-07-14 04:58:21.825286');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2153, 'ط ن هـ', 1617, 868, 'نيسان', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 114120, 2024, '2026-07-15', 428, true, '2026-07-07 04:40:13.700304', '2026-07-16 05:50:56.328482');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1385, 'ص د ص', 1713, 964, 'ميتسوبيشي', NULL, 'سيارة شاسيه طويل', 'سولار', 18, 50186, 2023, '2026-07-15', 445, true, '2026-07-07 04:40:13.706013', '2026-07-16 07:04:27.06205');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8461, 'ص د ج', 1644, 895, 'مرسيدس', NULL, 'سيارة اسعاف', 'سولار', 17, 53512, 2022, '2026-06-30', 444, true, '2026-07-07 04:40:13.705825', '2026-07-12 21:04:32.870374');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8457, 'ص د ج', 1636, 887, 'مرسيدس', NULL, 'سيارة اسعاف', 'سولار', 17, 88002, 2022, '2026-07-14', 440, true, '2026-07-07 04:40:13.704969', '2026-07-15 06:00:57.784775');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6259, 'ط ن ل', 1742, 993, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 49782, 2024, '2026-07-12', 447, true, '2026-07-07 04:40:13.707389', '2026-07-13 10:54:49.194649');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7211, 'ط ص ج', 1218, 199, 'تويوتا هاي ايس', NULL, 'ميكروباص', 'سولار', 18, 696252, 2013, '2026-07-15', 371, true, '2026-07-07 04:40:13.67974', '2026-07-16 07:00:08.507331');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8459, 'ص د ج', 1639, 890, 'مرسيدس', NULL, 'سيارة اسعاف', 'سولار', 17, 86723, 2022, '2026-07-09', 443, true, '2026-07-07 04:40:13.705655', '2026-07-13 09:49:58.65239');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3494, 'ط ن ر', 1690, 941, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 124099, 2024, '2026-07-15', 436, true, '2026-07-07 04:40:13.703153', '2026-07-16 07:01:29.168389');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1585, 'ط ه و', 1540, 789, 'فيات دوكادو', NULL, 'فان', 'سولار', 15, 214155, NULL, '2026-07-14', 465, true, '2026-07-13 09:37:10.59178', '2026-07-15 06:01:10.538238');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2312, 'ط ن ر', 1672, 923, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 62527, 2024, '2026-06-30', 435, true, '2026-07-07 04:40:13.702957', '2026-07-12 21:00:31.334592');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (12345, 'ط ط ط', 1234, 1234, 'ديهاتسون', NULL, 'معاقين', 'بنزين 92', 10, 450450, 2002, '2026-01-15', 461, true, '2026-07-13 02:56:35.540618', '2026-07-13 02:56:40.604052');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9373, 'ط ن د', 1669, 920, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 81650, 2024, '2026-07-07', 432, true, '2026-07-07 04:40:13.702134', '2026-07-13 08:44:20.179852');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3729, 'ط ب ص', 1592, 843, 'تويوتا', NULL, 'سيارة اسعاف', 'سولار', 18, 57780, 2020, '2026-07-03', 426, true, '2026-07-07 04:40:13.699798', '2026-07-13 07:16:13.119852');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8984, 'ط ه م', 971, 451, 'شاهين 1400', NULL, 'ملاكي', 'بنزين 92', 15, 38750, 2000, '2026-07-13', 468, true, '2026-07-14 04:51:33.903007', '2026-07-14 04:54:16.656107');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9691, 'ط ل ج', 1196, 548, 'بيجو 508', NULL, 'ملاكي', 'بنزين 95', 12, 345746, 2015, '2026-07-15', 458, true, '2026-07-09 05:32:59.261527', '2026-07-16 07:01:49.375019');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8453, 'ص د ج', 1637, 888, 'مرسيدس', NULL, 'سيارة اسعاف', 'سولار', 17, 88442, 2022, '2026-07-14', 442, true, '2026-07-07 04:40:13.705464', '2026-07-15 06:01:52.522282');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (10000, 'ورشة سولار', 1000, 1000, 'ورشة قسم النقل', NULL, 'ورشة الصيانة', 'سولار', 0, 0, 0, '1989-09-04', 463, true, '2026-07-13 07:40:59.311288', '2026-07-13 07:44:07.008317');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6279, 'ط ن ل', 1748, 999, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 27412, 2024, '2026-06-30', 448, true, '2026-07-07 04:40:13.707562', '2026-07-12 21:06:31.890735');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8165, 'ط ط ب', 1702, 953, 'ميتسوبيشي', NULL, 'سيارة نقل شاسيه طويل', 'سولار', 18, 63183, 2024, '2026-07-13', 439, true, '2026-07-07 04:40:13.704784', '2026-07-14 08:22:52.852951');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7383, 'ط هـ و', 1565, 816, 'فيات دوكاتو', NULL, 'سيارة فان', 'سولار', 15, 97202, 2019, '2026-06-30', 423, true, '2026-07-07 04:40:13.697946', '2026-07-12 20:56:43.855761');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9363, 'ط ن د', 1668, 919, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 83743, 2024, '2026-07-02', 433, true, '2026-07-07 04:40:13.702303', '2026-07-13 07:00:59.470585');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9287, 'ط ه ق', 860, 402, 'بيجو 405', NULL, 'ملاكي', 'بنزين 92', 15, 530241, 1997, '2026-07-15', 459, true, '2026-07-09 05:35:48.727039', '2026-07-16 07:04:18.366813');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (12345, 'ط ط ر', 5555, 4444, 'ت', NULL, 'ن', 'بنزين 92', 10, 0, NULL, '1989-09-04', 456, true, '2026-07-08 08:52:50.338293', '2026-07-08 08:53:20.138498');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7497, 'ط هـ و', 1573, 824, 'فيات دوكاتو', NULL, 'سيارة فان', 'سولار', 15, 117820, 2019, '2026-07-15', 422, true, '2026-07-07 04:40:13.697771', '2026-07-16 07:10:14.009023');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1782, 'ط ل ي', 898, 420, 'بيجو 405', NULL, 'سارة ملاكي', 'بنزين 92', 15, 443836, 1999, '2026-07-13', 467, true, '2026-07-13 17:21:07.539563', '2026-07-14 04:55:17.359737');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2154, 'ط ن هـ', 1618, 869, 'نيسان', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 125097, 2024, '2026-07-10', 427, true, '2026-07-07 04:40:13.700001', '2026-07-13 09:56:05.685021');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8456, 'ص د ج', 1634, 885, 'مرسيدس', NULL, 'سيارة اسعاف', 'سولار', 17, 88134, 2022, '2026-07-13', 441, true, '2026-07-07 04:40:13.705141', '2026-07-14 04:58:53.531946');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2325, 'ط ن ر', 1675, 926, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 63709, 2024, '2026-07-09', 434, true, '2026-07-07 04:40:13.702473', '2026-07-13 09:46:32.462673');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2343, 'ط هـ و', 1544, 793, 'فيات دوكاتو', NULL, 'سيارة فان', 'سولار', 15, 189241, 2019, '2026-07-14', 420, true, '2026-07-07 04:40:13.696554', '2026-07-15 05:56:48.496425');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (6278, 'ط ن ل', 1747, 998, 'نيسان', NULL, 'سيارة ملاكي', 'بنزين 92', 11, 24933, 2024, '2026-07-14', 446, true, '2026-07-07 04:40:13.707211', '2026-07-15 05:58:35.285375');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2482, 'ط هـ و', 1556, 805, 'فيات دوكاتو', NULL, 'سيارة فان', 'سولار', 15, 193211, 2019, '2026-07-13', 421, true, '2026-07-07 04:40:13.697575', '2026-07-14 04:56:46.102387');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (12345, 'ط ط ر', 5555, 4444, 'ت', NULL, 'ن', 'بنزين 92', 10, 0, NULL, '1989-09-04', 457, true, '2026-07-08 08:53:11.624898', '2026-07-08 08:53:20.139493');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2973, 'ط ل ط', 965, 445, 'شاهين', NULL, 'ركوب', 'بنزين 92', 15, 90575, 2000, '2026-07-09', 466, true, '2026-07-13 09:39:58.460853', '2026-07-13 09:46:06.029701');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1892, 'ط ص ج', 885, 322, 'ايسوزو Tfr54', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 796070, 1997, '2026-06-30', 318, true, '2026-07-07 04:40:13.668178', '2026-07-12 20:09:46.853208');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (1268, 'ط ص ق', 158, 115, 'تويوتا كوستر', NULL, 'ميني باص', 'بنزين 92', 27, 527736, 2015, '2026-07-14', 450, true, '2026-07-07 05:57:40.828634', '2026-07-15 05:57:18.209602');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (10000, 'ورشة بنزين', 100, 100, 'ورشة قسم النقل', NULL, 'ورشة الصيانة', 'بنزين 92', 0, 0, 0, '2026-07-15', 464, true, '2026-07-13 07:43:26.665906', '2026-07-16 07:00:23.865272');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (9343, 'ط ل ا', 1200, 522, 'بيجو 301', NULL, 'سيارة ملاكي', 'بنزين 95', 12, 411475, 2015, '2026-07-15', 451, true, '2026-07-07 06:03:23.096619', '2026-07-16 07:01:40.236436');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7379, 'ط ل ق', 1475, 733, 'تويوتا كرولا', NULL, 'ركوب', 'بنزين 92', 10, 329143, 2015, '2026-07-07', 455, true, '2026-07-08 04:53:40.312103', '2026-07-08 04:54:14.48951');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (5835, 'ط ل ب', 1199, 551, 'بيجو 508', NULL, 'سيارة ملاكي', 'بنزين 92', 12, 525212, 2014, '2026-07-15', 368, true, '2026-07-07 04:40:13.67915', '2026-07-16 07:04:10.344127');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (2472, 'ط ه و', 1554, 803, 'فيات دوكادو', NULL, 'فان', 'سولار', 15, 189828, 2019, '2026-07-15', 469, true, '2026-07-16 07:07:22.561509', '2026-07-16 07:09:33.362357');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (8137, 'ط ص ب', 1388, 659, 'تويوتا هاي لوكس', NULL, 'سيارة نقل بيك اب', 'سولار', 15, 569490, 2016, '2026-07-15', 411, true, '2026-07-07 04:40:13.693844', '2026-07-16 07:09:51.932896');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (7192, 'ط ط ا', 1304, 619, 'تويوتا', NULL, 'ملاكي', 'بنزين 92', 10, 360071, 2015, '2026-07-01', 462, true, '2026-07-13 06:11:15.97886', '2026-07-13 06:43:31.339717');
INSERT INTO public.vehicle (number, letters, registry, code, brand, model, vehicle_type, fuel_type, standard_consumption, last_odometer, manufacture_year, last_odometer_date, id, is_synced, created_at, updated_at) VALUES (3474, 'ط ن ر', 1686, 937, 'نيسان n17', NULL, 'سيلرة ملاكي', 'بنزين 92', 11, 85824, 2024, '2026-07-06', 452, true, '2026-07-07 06:04:13.13522', '2026-07-13 08:21:08.252294');


--
-- Name: invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.invoice_id_seq', 3, true);


--
-- Name: invoicepricechangelog_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.invoicepricechangelog_id_seq', 1, false);


--
-- Name: invoicepricesetting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.invoicepricesetting_id_seq', 3, true);


--
-- Name: modelconfig_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.modelconfig_id_seq', 3, true);


--
-- Name: refuel_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.refuel_id_seq', 711, true);


--
-- Name: user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.user_id_seq', 2, true);


--
-- Name: vehicle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: 
--

SELECT pg_catalog.setval('public.vehicle_id_seq', 469, true);


--
-- Name: invoice invoice_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.invoice
    ADD CONSTRAINT invoice_pkey PRIMARY KEY (id);


--
-- Name: invoicepricechangelog invoicepricechangelog_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.invoicepricechangelog
    ADD CONSTRAINT invoicepricechangelog_pkey PRIMARY KEY (id);


--
-- Name: invoicepricesetting invoicepricesetting_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.invoicepricesetting
    ADD CONSTRAINT invoicepricesetting_pkey PRIMARY KEY (id);


--
-- Name: modelconfig modelconfig_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.modelconfig
    ADD CONSTRAINT modelconfig_pkey PRIMARY KEY (id);


--
-- Name: refuel refuel_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.refuel
    ADD CONSTRAINT refuel_pkey PRIMARY KEY (id);


--
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: vehicle vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (id);


--
-- Name: ix_invoicepricesetting_fuel_type; Type: INDEX; Schema: public; Owner: 
--

CREATE UNIQUE INDEX ix_invoicepricesetting_fuel_type ON public.invoicepricesetting USING btree (fuel_type);


--
-- Name: ix_vehicle_number; Type: INDEX; Schema: public; Owner: 
--

CREATE INDEX ix_vehicle_number ON public.vehicle USING btree (number);


--
-- Name: refuel refuel_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: 
--

ALTER TABLE ONLY public.refuel
    ADD CONSTRAINT refuel_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(id) ON DELETE CASCADE;


--
--




--
--




--
-- PostgreSQL database dump complete
--



