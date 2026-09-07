--
-- PostgreSQL database dump
--

\restrict N2LYQwsE0gVypoxULqPyvidYXzX3AX8A5f2tIGWugwMhNxGRXM9MOCvWEc4eZyY

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
-- Name: userrole; Type: TYPE; Schema: public; Owner: neondb_owner
--

CREATE TYPE public.userrole AS ENUM (
    'admin',
    'data_entry',
    'viewer'
);


ALTER TYPE public.userrole OWNER TO neondb_owner;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: invoice; Type: TABLE; Schema: public; Owner: neondb_owner
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


ALTER TABLE public.invoice OWNER TO neondb_owner;

--
-- Name: invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoice_id_seq OWNER TO neondb_owner;

--
-- Name: invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.invoice_id_seq OWNED BY public.invoice.id;


--
-- Name: invoicepricechangelog; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.invoicepricechangelog (
    id integer NOT NULL,
    fuel_type character varying NOT NULL,
    old_price double precision NOT NULL,
    new_price double precision NOT NULL,
    changed_at timestamp without time zone
);


ALTER TABLE public.invoicepricechangelog OWNER TO neondb_owner;

--
-- Name: invoicepricechangelog_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.invoicepricechangelog_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoicepricechangelog_id_seq OWNER TO neondb_owner;

--
-- Name: invoicepricechangelog_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.invoicepricechangelog_id_seq OWNED BY public.invoicepricechangelog.id;


--
-- Name: invoicepricesetting; Type: TABLE; Schema: public; Owner: neondb_owner
--

CREATE TABLE public.invoicepricesetting (
    id integer NOT NULL,
    fuel_type character varying NOT NULL,
    price double precision NOT NULL
);


ALTER TABLE public.invoicepricesetting OWNER TO neondb_owner;

--
-- Name: invoicepricesetting_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.invoicepricesetting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoicepricesetting_id_seq OWNER TO neondb_owner;

--
-- Name: invoicepricesetting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.invoicepricesetting_id_seq OWNED BY public.invoicepricesetting.id;


--
-- Name: modelconfig; Type: TABLE; Schema: public; Owner: neondb_owner
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


ALTER TABLE public.modelconfig OWNER TO neondb_owner;

--
-- Name: modelconfig_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.modelconfig_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modelconfig_id_seq OWNER TO neondb_owner;

--
-- Name: modelconfig_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.modelconfig_id_seq OWNED BY public.modelconfig.id;


--
-- Name: refuel; Type: TABLE; Schema: public; Owner: neondb_owner
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


ALTER TABLE public.refuel OWNER TO neondb_owner;

--
-- Name: refuel_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.refuel_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.refuel_id_seq OWNER TO neondb_owner;

--
-- Name: refuel_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.refuel_id_seq OWNED BY public.refuel.id;


--
-- Name: user; Type: TABLE; Schema: public; Owner: neondb_owner
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


ALTER TABLE public."user" OWNER TO neondb_owner;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_id_seq OWNER TO neondb_owner;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.user_id_seq OWNED BY public."user".id;


--
-- Name: vehicle; Type: TABLE; Schema: public; Owner: neondb_owner
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


ALTER TABLE public.vehicle OWNER TO neondb_owner;

--
-- Name: vehicle_id_seq; Type: SEQUENCE; Schema: public; Owner: neondb_owner
--

CREATE SEQUENCE public.vehicle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_id_seq OWNER TO neondb_owner;

--
-- Name: vehicle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: neondb_owner
--

ALTER SEQUENCE public.vehicle_id_seq OWNED BY public.vehicle.id;


--
-- Name: invoice id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.invoice ALTER COLUMN id SET DEFAULT nextval('public.invoice_id_seq'::regclass);


--
-- Name: invoicepricechangelog id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.invoicepricechangelog ALTER COLUMN id SET DEFAULT nextval('public.invoicepricechangelog_id_seq'::regclass);


--
-- Name: invoicepricesetting id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.invoicepricesetting ALTER COLUMN id SET DEFAULT nextval('public.invoicepricesetting_id_seq'::regclass);


--
-- Name: modelconfig id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.modelconfig ALTER COLUMN id SET DEFAULT nextval('public.modelconfig_id_seq'::regclass);


--
-- Name: refuel id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.refuel ALTER COLUMN id SET DEFAULT nextval('public.refuel_id_seq'::regclass);


--
-- Name: user id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public."user" ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: vehicle id; Type: DEFAULT; Schema: public; Owner: neondb_owner
--

ALTER TABLE ONLY public.vehicle ALTER COLUMN id SET DEFAULT nextval('public.vehicle_id_seq'::regclass);


--
-- Data for Name: invoice; Type: TABLE DATA; Schema: public; Owner: neondb_owner
--

COPY public.invoice (station, start_date, end_date, created_at, total_amount, items, prices, id, invoice_number) FROM stdin;
