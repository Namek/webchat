CREATE TABLE IF NOT EXISTS public.people (
	id SERIAL,
	"name" varchar(255) NOT NULL,
	password varchar(32) NOT NULL,
	avatar_seed integer NOT NULL
);
CREATE UNIQUE INDEX IF NOT EXISTS people_name_idx ON public.people ("name");

CREATE TABLE IF NOT EXISTS public.messages (
	id SERIAL,
	content varchar(1024) NOT NULL,
	author_id integer NOT NULL,
	datetime timestamp NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS messages_datetime_id_idx ON public.messages ("datetime", "id");