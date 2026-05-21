CREATE TABLE IF NOT EXISTS public.user_estados (
    user_id integer NOT NULL,
    estado_id smallint NOT NULL REFERENCES public.estado(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, estado_id)
);

CREATE TABLE IF NOT EXISTS public.user_municipios (
    user_id integer NOT NULL,
    municipio_id integer NOT NULL REFERENCES public.municipio(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, municipio_id)
);

CREATE TABLE IF NOT EXISTS public.user_parroquias (
    user_id integer NOT NULL,
    parroquia_id integer NOT NULL REFERENCES public.parroquia(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, parroquia_id)
);
