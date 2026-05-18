--
-- PostgreSQL database dump
--

-- Dumped from database version 17.5
-- Dumped by pg_dump version 17.5

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
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: fn_validar_comuna(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validar_comuna() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_estado_id        smallint;
    v_municipio_id     integer;
BEGIN

    SELECT
        m.estado_id,
        p.municipio_id
    INTO
        v_estado_id,
        v_municipio_id
    FROM parroquia p
    INNER JOIN municipio m
        ON m.id = p.municipio_id
    WHERE p.id = NEW.parroquia_id;

    IF v_estado_id IS NULL THEN
        RAISE EXCEPTION
            'La parroquia indicada no existe';
    END IF;

    IF NEW.estado_id <> v_estado_id THEN
        RAISE EXCEPTION
            'La parroquia no pertenece al estado indicado';
    END IF;

    IF NEW.municipio_id <> v_municipio_id THEN
        RAISE EXCEPTION
            'La parroquia no pertenece al municipio indicado';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_validar_comuna() OWNER TO postgres;

--
-- Name: fn_validar_despliegue(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_validar_despliegue() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count integer;
BEGIN

    SELECT count(*)
    INTO v_count
    FROM articulador_parroquia ap
    INNER JOIN comuna c
        ON c.parroquia_id = ap.parroquia_id
    WHERE ap.articulador_id = NEW.articulador_id
      AND c.id = NEW.comuna_id;

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'El articulador no tiene asignada la parroquia de la comuna';
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.fn_validar_despliegue() OWNER TO postgres;

--
-- Name: normalizar_texto(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.normalizar_texto(txt text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT upper(
        trim(
            public.unaccent(
                coalesce(txt, CAST('' AS text))
            )
        )
    );    
$$;


ALTER FUNCTION public.normalizar_texto(txt text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: articulador; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articulador (
    id bigint NOT NULL,
    cedula integer NOT NULL,
    nombres character varying(200),
    telefono character varying(20),
    correo character varying(150),
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.articulador OWNER TO postgres;

--
-- Name: TABLE articulador; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.articulador IS 'Personal articulador o personal INASS autorizado para registrar despliegues';


--
-- Name: articulador_estado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articulador_estado (
    articulador_id bigint NOT NULL,
    estado_id smallint NOT NULL
);


ALTER TABLE public.articulador_estado OWNER TO postgres;

--
-- Name: articulador_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.articulador_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.articulador_id_seq OWNER TO postgres;

--
-- Name: articulador_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.articulador_id_seq OWNED BY public.articulador.id;


--
-- Name: articulador_municipio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articulador_municipio (
    articulador_id bigint NOT NULL,
    municipio_id integer NOT NULL
);


ALTER TABLE public.articulador_municipio OWNER TO postgres;

--
-- Name: articulador_parroquia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.articulador_parroquia (
    articulador_id bigint NOT NULL,
    parroquia_id integer NOT NULL
);


ALTER TABLE public.articulador_parroquia OWNER TO postgres;

--
-- Name: comuna; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comuna (
    id bigint NOT NULL,
    estado_id smallint NOT NULL,
    municipio_id integer NOT NULL,
    parroquia_id integer NOT NULL,
    nombre character varying(250) NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.comuna OWNER TO postgres;

--
-- Name: TABLE comuna; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.comuna IS 'Comunas donde se realizan despliegues';


--
-- Name: comuna_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comuna_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comuna_id_seq OWNER TO postgres;

--
-- Name: comuna_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comuna_id_seq OWNED BY public.comuna.id;


--
-- Name: despliegue; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.despliegue (
    id bigint NOT NULL,
    articulador_id bigint NOT NULL,
    comuna_id bigint NOT NULL,
    fecha date NOT NULL,
    hubo_despliegue boolean NOT NULL,
    adultos_listado integer DEFAULT 0 NOT NULL,
    adultos_visitados integer DEFAULT 0 NOT NULL,
    vulnerables_detectados integer DEFAULT 0 NOT NULL,
    vulnerables_nuevos integer DEFAULT 0 NOT NULL,
    observaciones text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT despliegue_adultos_listado_check CHECK ((adultos_listado >= 0)),
    CONSTRAINT despliegue_adultos_visitados_check CHECK ((adultos_visitados >= 0)),
    CONSTRAINT despliegue_vulnerables_detectados_check CHECK ((vulnerables_detectados >= 0)),
    CONSTRAINT despliegue_vulnerables_nuevos_check CHECK ((vulnerables_nuevos >= 0))
);


ALTER TABLE public.despliegue OWNER TO postgres;

--
-- Name: TABLE despliegue; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.despliegue IS 'Registro operativo de despliegues realizados';


--
-- Name: despliegue_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.despliegue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.despliegue_id_seq OWNER TO postgres;

--
-- Name: despliegue_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.despliegue_id_seq OWNED BY public.despliegue.id;


--
-- Name: despliegue_institucion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.despliegue_institucion (
    despliegue_id bigint NOT NULL,
    institucion_id smallint NOT NULL
);


ALTER TABLE public.despliegue_institucion OWNER TO postgres;

--
-- Name: TABLE despliegue_institucion; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.despliegue_institucion IS 'Instituciones participantes por despliegue';


--
-- Name: estado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estado (
    id smallint NOT NULL,
    nombre character varying(100) NOT NULL
);


ALTER TABLE public.estado OWNER TO postgres;

--
-- Name: estado_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estado_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estado_id_seq OWNER TO postgres;

--
-- Name: estado_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estado_id_seq OWNED BY public.estado.id;


--
-- Name: institucion; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.institucion (
    id smallint NOT NULL,
    nombre character varying(200) NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


ALTER TABLE public.institucion OWNER TO postgres;

--
-- Name: institucion_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.institucion_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.institucion_id_seq OWNER TO postgres;

--
-- Name: institucion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.institucion_id_seq OWNED BY public.institucion.id;


--
-- Name: municipio; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.municipio (
    id integer NOT NULL,
    estado_id smallint NOT NULL,
    nombre character varying(120) NOT NULL
);


ALTER TABLE public.municipio OWNER TO postgres;

--
-- Name: municipio_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.municipio_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.municipio_id_seq OWNER TO postgres;

--
-- Name: municipio_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.municipio_id_seq OWNED BY public.municipio.id;


--
-- Name: parroquia; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parroquia (
    id integer NOT NULL,
    municipio_id integer NOT NULL,
    nombre character varying(120) NOT NULL
);


ALTER TABLE public.parroquia OWNER TO postgres;

--
-- Name: parroquia_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parroquia_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parroquia_id_seq OWNER TO postgres;

--
-- Name: parroquia_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parroquia_id_seq OWNED BY public.parroquia.id;


--
-- Name: vw_despliegues_resumen; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_despliegues_resumen AS
 SELECT d.id,
    d.fecha,
    a.cedula,
    a.nombres,
    e.nombre AS estado,
    m.nombre AS municipio,
    p.nombre AS parroquia,
    c.nombre AS comuna,
    d.hubo_despliegue,
    d.adultos_listado,
    d.adultos_visitados,
    d.vulnerables_detectados,
    d.vulnerables_nuevos
   FROM (((((public.despliegue d
     JOIN public.articulador a ON ((a.id = d.articulador_id)))
     JOIN public.comuna c ON ((c.id = d.comuna_id)))
     JOIN public.estado e ON ((e.id = c.estado_id)))
     JOIN public.municipio m ON ((m.id = c.municipio_id)))
     JOIN public.parroquia p ON ((p.id = c.parroquia_id)));


ALTER VIEW public.vw_despliegues_resumen OWNER TO postgres;

--
-- Name: articulador id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador ALTER COLUMN id SET DEFAULT nextval('public.articulador_id_seq'::regclass);


--
-- Name: comuna id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comuna ALTER COLUMN id SET DEFAULT nextval('public.comuna_id_seq'::regclass);


--
-- Name: despliegue id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue ALTER COLUMN id SET DEFAULT nextval('public.despliegue_id_seq'::regclass);


--
-- Name: estado id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado ALTER COLUMN id SET DEFAULT nextval('public.estado_id_seq'::regclass);


--
-- Name: institucion id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.institucion ALTER COLUMN id SET DEFAULT nextval('public.institucion_id_seq'::regclass);


--
-- Name: municipio id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio ALTER COLUMN id SET DEFAULT nextval('public.municipio_id_seq'::regclass);


--
-- Name: parroquia id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parroquia ALTER COLUMN id SET DEFAULT nextval('public.parroquia_id_seq'::regclass);


--
-- Data for Name: articulador; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.articulador (id, cedula, nombres, telefono, correo, activo, created_at) FROM stdin;
\.


--
-- Data for Name: articulador_estado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.articulador_estado (articulador_id, estado_id) FROM stdin;
\.


--
-- Data for Name: articulador_municipio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.articulador_municipio (articulador_id, municipio_id) FROM stdin;
\.


--
-- Data for Name: articulador_parroquia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.articulador_parroquia (articulador_id, parroquia_id) FROM stdin;
\.


--
-- Data for Name: comuna; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comuna (id, estado_id, municipio_id, parroquia_id, nombre, activo, created_at) FROM stdin;
\.


--
-- Data for Name: despliegue; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.despliegue (id, articulador_id, comuna_id, fecha, hubo_despliegue, adultos_listado, adultos_visitados, vulnerables_detectados, vulnerables_nuevos, observaciones, created_at) FROM stdin;
\.


--
-- Data for Name: despliegue_institucion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.despliegue_institucion (despliegue_id, institucion_id) FROM stdin;
\.


--
-- Data for Name: estado; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.estado (id, nombre) FROM stdin;
\.


--
-- Data for Name: institucion; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.institucion (id, nombre, activo) FROM stdin;
1	MPP Adultos Mayores	t
2	MPP Salud	t
3	MPP Alimentación	t
4	MPP Juventud	t
5	MPP Deporte	t
6	MPP Cultura	t
7	MPP Comunas	t
8	MPP Educación	t
9	MPP Educación Superior	t
10	Instituto Nacional de Nutrición	t
11	Instituto Nacional de los Servicios Sociales (INASS)	t
12	Gran Misión Abuelos y Abuelas de la Patria	t
13	Gran Misión Venezuela Joven	t
14	Somos Venezuela	t
15	Misión José Gregorio Hernández	t
16	Consejo Nacional para las Personas con Discapacidad (CONAPDIS)	t
17	Red Integral de Recreación (REIR)	t
18	Universidad de las Ciencias de la Salud (UCS)	t
19	Gobernación	t
20	Alcaldía	t
\.


--
-- Data for Name: municipio; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.municipio (id, estado_id, nombre) FROM stdin;
\.


--
-- Data for Name: parroquia; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.parroquia (id, municipio_id, nombre) FROM stdin;
\.


--
-- Name: articulador_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.articulador_id_seq', 1, false);


--
-- Name: comuna_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.comuna_id_seq', 1, false);


--
-- Name: despliegue_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.despliegue_id_seq', 1, false);


--
-- Name: estado_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.estado_id_seq', 1, false);


--
-- Name: institucion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.institucion_id_seq', 20, true);


--
-- Name: municipio_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.municipio_id_seq', 1, false);


--
-- Name: parroquia_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.parroquia_id_seq', 1, false);


--
-- Name: articulador articulador_cedula_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador
    ADD CONSTRAINT articulador_cedula_key UNIQUE (cedula);


--
-- Name: articulador_estado articulador_estado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_estado
    ADD CONSTRAINT articulador_estado_pkey PRIMARY KEY (articulador_id, estado_id);


--
-- Name: articulador_municipio articulador_municipio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_municipio
    ADD CONSTRAINT articulador_municipio_pkey PRIMARY KEY (articulador_id, municipio_id);


--
-- Name: articulador_parroquia articulador_parroquia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_parroquia
    ADD CONSTRAINT articulador_parroquia_pkey PRIMARY KEY (articulador_id, parroquia_id);


--
-- Name: articulador articulador_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador
    ADD CONSTRAINT articulador_pkey PRIMARY KEY (id);


--
-- Name: comuna comuna_parroquia_id_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_parroquia_id_nombre_key UNIQUE (parroquia_id, nombre);


--
-- Name: comuna comuna_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_pkey PRIMARY KEY (id);


--
-- Name: despliegue_institucion despliegue_institucion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue_institucion
    ADD CONSTRAINT despliegue_institucion_pkey PRIMARY KEY (despliegue_id, institucion_id);


--
-- Name: despliegue despliegue_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue
    ADD CONSTRAINT despliegue_pkey PRIMARY KEY (id);


--
-- Name: estado estado_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado
    ADD CONSTRAINT estado_nombre_key UNIQUE (nombre);


--
-- Name: estado estado_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estado
    ADD CONSTRAINT estado_pkey PRIMARY KEY (id);


--
-- Name: institucion institucion_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.institucion
    ADD CONSTRAINT institucion_nombre_key UNIQUE (nombre);


--
-- Name: institucion institucion_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.institucion
    ADD CONSTRAINT institucion_pkey PRIMARY KEY (id);


--
-- Name: municipio municipio_estado_id_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_estado_id_nombre_key UNIQUE (estado_id, nombre);


--
-- Name: municipio municipio_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_pkey PRIMARY KEY (id);


--
-- Name: parroquia parroquia_municipio_id_nombre_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parroquia
    ADD CONSTRAINT parroquia_municipio_id_nombre_key UNIQUE (municipio_id, nombre);


--
-- Name: parroquia parroquia_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parroquia
    ADD CONSTRAINT parroquia_pkey PRIMARY KEY (id);


--
-- Name: idx_articulador_cedula; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_articulador_cedula ON public.articulador USING btree (cedula);


--
-- Name: idx_comuna_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comuna_nombre ON public.comuna USING btree (nombre);


--
-- Name: idx_despliegue_articulador; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_despliegue_articulador ON public.despliegue USING btree (articulador_id);


--
-- Name: idx_despliegue_comuna; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_despliegue_comuna ON public.despliegue USING btree (comuna_id);


--
-- Name: idx_despliegue_fecha; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_despliegue_fecha ON public.despliegue USING btree (fecha);


--
-- Name: idx_estado_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_estado_nombre ON public.estado USING btree (nombre);


--
-- Name: idx_municipio_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_municipio_nombre ON public.municipio USING btree (nombre);


--
-- Name: idx_parroquia_nombre; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_parroquia_nombre ON public.parroquia USING btree (nombre);


--
-- Name: comuna tg_validar_comuna; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_validar_comuna BEFORE INSERT OR UPDATE ON public.comuna FOR EACH ROW EXECUTE FUNCTION public.fn_validar_comuna();


--
-- Name: despliegue tg_validar_despliegue; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER tg_validar_despliegue BEFORE INSERT OR UPDATE ON public.despliegue FOR EACH ROW EXECUTE FUNCTION public.fn_validar_despliegue();


--
-- Name: articulador_estado articulador_estado_articulador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_estado
    ADD CONSTRAINT articulador_estado_articulador_id_fkey FOREIGN KEY (articulador_id) REFERENCES public.articulador(id) ON DELETE CASCADE;


--
-- Name: articulador_estado articulador_estado_estado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_estado
    ADD CONSTRAINT articulador_estado_estado_id_fkey FOREIGN KEY (estado_id) REFERENCES public.estado(id) ON DELETE RESTRICT;


--
-- Name: articulador_municipio articulador_municipio_articulador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_municipio
    ADD CONSTRAINT articulador_municipio_articulador_id_fkey FOREIGN KEY (articulador_id) REFERENCES public.articulador(id) ON DELETE CASCADE;


--
-- Name: articulador_municipio articulador_municipio_municipio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_municipio
    ADD CONSTRAINT articulador_municipio_municipio_id_fkey FOREIGN KEY (municipio_id) REFERENCES public.municipio(id) ON DELETE RESTRICT;


--
-- Name: articulador_parroquia articulador_parroquia_articulador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_parroquia
    ADD CONSTRAINT articulador_parroquia_articulador_id_fkey FOREIGN KEY (articulador_id) REFERENCES public.articulador(id) ON DELETE CASCADE;


--
-- Name: articulador_parroquia articulador_parroquia_parroquia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.articulador_parroquia
    ADD CONSTRAINT articulador_parroquia_parroquia_id_fkey FOREIGN KEY (parroquia_id) REFERENCES public.parroquia(id) ON DELETE RESTRICT;


--
-- Name: comuna comuna_estado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_estado_id_fkey FOREIGN KEY (estado_id) REFERENCES public.estado(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: comuna comuna_municipio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_municipio_id_fkey FOREIGN KEY (municipio_id) REFERENCES public.municipio(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: comuna comuna_parroquia_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comuna
    ADD CONSTRAINT comuna_parroquia_id_fkey FOREIGN KEY (parroquia_id) REFERENCES public.parroquia(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: despliegue despliegue_articulador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue
    ADD CONSTRAINT despliegue_articulador_id_fkey FOREIGN KEY (articulador_id) REFERENCES public.articulador(id) ON DELETE RESTRICT;


--
-- Name: despliegue despliegue_comuna_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue
    ADD CONSTRAINT despliegue_comuna_id_fkey FOREIGN KEY (comuna_id) REFERENCES public.comuna(id) ON DELETE RESTRICT;


--
-- Name: despliegue_institucion despliegue_institucion_despliegue_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue_institucion
    ADD CONSTRAINT despliegue_institucion_despliegue_id_fkey FOREIGN KEY (despliegue_id) REFERENCES public.despliegue(id) ON DELETE CASCADE;


--
-- Name: despliegue_institucion despliegue_institucion_institucion_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.despliegue_institucion
    ADD CONSTRAINT despliegue_institucion_institucion_id_fkey FOREIGN KEY (institucion_id) REFERENCES public.institucion(id) ON DELETE RESTRICT;


--
-- Name: municipio municipio_estado_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.municipio
    ADD CONSTRAINT municipio_estado_id_fkey FOREIGN KEY (estado_id) REFERENCES public.estado(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: parroquia parroquia_municipio_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parroquia
    ADD CONSTRAINT parroquia_municipio_id_fkey FOREIGN KEY (municipio_id) REFERENCES public.municipio(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

