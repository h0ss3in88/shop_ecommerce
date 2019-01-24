--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.8
-- Dumped by pg_dump version 9.6.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: add_role_to_user(integer, character varying); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.add_role_to_user(u_id integer, r_name character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$

  declare

    row_count integer := 0;

    role_id integer;

  begin

    if exists

      (select id from roles where name = lower(r_name))

    then

      select id into role_id from roles where name = lower(r_name);

      insert into users_roles(user_id, role_id) values (u_id,role_id);

      GET DIAGNOSTICS row_count = ROW_COUNT;

      return row_count;

    else

      return row_count;

    end if;

  end;

$$;


ALTER FUNCTION public.add_role_to_user(u_id integer, r_name character varying) OWNER TO hussein;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.categories (
    id integer NOT NULL,
    name character varying(35) NOT NULL,
    description character varying(1000) DEFAULT NULL::character varying,
    department_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.categories OWNER TO hussein;

--
-- Name: catalog_get_categories_in_department(integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_categories_in_department(dept_id integer) RETURNS SETOF public.categories
    LANGUAGE sql
    AS $$

  select id,name,description,department_id,created_at,modified_at from categories where department_id =dept_id;

$$;


ALTER FUNCTION public.catalog_get_categories_in_department(dept_id integer) OWNER TO hussein;

--
-- Name: catalog_get_category_details(integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_category_details(category_id integer) RETURNS TABLE(id integer, name character varying, description character varying, created_at timestamp with time zone, modified_at timestamp with time zone)
    LANGUAGE sql
    AS $$

  select id,name,description,created_at,modified_at from categories where id = category_id;

$$;


ALTER FUNCTION public.catalog_get_category_details(category_id integer) OWNER TO hussein;

--
-- Name: departments; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying(55) NOT NULL,
    description character varying(1000) DEFAULT NULL::character varying,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.departments OWNER TO hussein;

--
-- Name: catalog_get_department_details(integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_department_details(department_id integer) RETURNS SETOF public.departments
    LANGUAGE sql
    AS $$

  select id,name,description,created_at,modified_at from departments where id = department_id;

$$;


ALTER FUNCTION public.catalog_get_department_details(department_id integer) OWNER TO hussein;

--
-- Name: catalog_get_departments(); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_departments() RETURNS SETOF public.departments
    LANGUAGE sql
    AS $$

  select id,name,description,created_at,modified_at from departments;

$$;


ALTER FUNCTION public.catalog_get_departments() OWNER TO hussein;

--
-- Name: catalog_get_product_attributes(integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_product_attributes(prd_id integer) RETURNS TABLE(name character varying, value character varying, id integer)
    LANGUAGE sql
    AS $$

  select a.name as attribute_name ,av.value as attribute_value,av.id as attribute_value_id from attributes_values av

  inner join attributes a on a.id = av.attribute_id

  where av.id in

        (select pv.attribute_value_id from products_attributes_values pv

        where pv.product_id = prd_id)

  order by a.name;

$$;


ALTER FUNCTION public.catalog_get_product_attributes(prd_id integer) OWNER TO hussein;

--
-- Name: products; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.products (
    id integer NOT NULL,
    name character varying(55) NOT NULL,
    description character varying(1000) DEFAULT NULL::character varying,
    price numeric NOT NULL,
    thumbnail character varying(300) NOT NULL,
    image character varying(300) NOT NULL,
    promo_front bit(1) DEFAULT (0)::bit(1) NOT NULL,
    promo_dept bit(1) DEFAULT (0)::bit(1) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.products OWNER TO hussein;

--
-- Name: catalog_get_product_details(integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_product_details(product_id integer) RETURNS SETOF public.products
    LANGUAGE sql
    AS $$

  select id,name,description,price,thumbnail,image,promo_front,promo_dept,created_at,modified_at from products where id = product_id;

$$;


ALTER FUNCTION public.catalog_get_product_details(product_id integer) OWNER TO hussein;

--
-- Name: catalog_get_products_count_on_department_promo(integer, integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_products_count_on_department_promo(dept_id integer, description_length integer, OUT products_length bigint) RETURNS bigint
    LANGUAGE sql
    AS $$

  with products_row_number as (select row_number() over (order by pd.id) as row ,pd.id,pd.name ,pd.price,pd.thumbnail,pd.image,

                                      pd.promo_front,pd.promo_dept,pd.created_at,pd.modified_at,pd.description

                               from (select distinct p.id,p.name,

                                                     case when length(p.description::text) <= description_length then p.description

                                                          else substring(p.description::text,0,description_length) || '...' end as description,

                                                     p.thumbnail,

                                                     p.image,p.price,p.promo_dept,p.promo_front,p.created_at,p.modified_at

                                     from products p

                                            inner join products_categories pc on p.id = pc.product_id

                                            inner join categories c2 on pc.category_id = c2.id

                                     where p.promo_dept = 1::bit and c2.department_id = dept_id) as pd)

  select count(row) from products_row_number;

  $$;


ALTER FUNCTION public.catalog_get_products_count_on_department_promo(dept_id integer, description_length integer, OUT products_length bigint) OWNER TO hussein;

--
-- Name: catalog_get_products_count_on_front_promo(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_products_count_on_front_promo(description_length integer, page_number integer, products_per_page integer, OUT how_many_products bigint) RETURNS bigint
    LANGUAGE sql
    AS $$

with products_row_number as (select row_number() over (order by id) as row ,count(id) over(partition by id) as products,id,name ,price,thumbnail,image,

                                    case when length(description::text) <= description_length then products.description

                                         else substring(description::text,0,description_length) || '...' end as description

                             from products where promo_front = 1::bit)

   select count(row)  from products_row_number;

$$;


ALTER FUNCTION public.catalog_get_products_count_on_front_promo(description_length integer, page_number integer, products_per_page integer, OUT how_many_products bigint) OWNER TO hussein;

--
-- Name: catalog_get_products_in_category(integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_products_in_category(description_length integer, page_number integer, products_per_page integer, cat_id integer) RETURNS SETOF public.products
    LANGUAGE sql
    AS $$

with products_row_number as (select row_number() over (order by id) as row ,id,name ,price,thumbnail,image,

                promo_front,promo_dept,created_at,modified_at,

                case when length(description::text) <= description_length then products.description

                else substring(description::text,0,description_length) || '...' end as description

      from products inner join products_categories on products.id = products_categories.product_id where products_categories.category_id = cat_id)

  select id,name,description,price,thumbnail,image,promo_front,promo_dept,created_at,modified_at from products_row_number  WHERE row > (page_number - 1) * products_per_page

                                                                                                        AND row <= page_number * products_per_page;

$$;


ALTER FUNCTION public.catalog_get_products_in_category(description_length integer, page_number integer, products_per_page integer, cat_id integer) OWNER TO hussein;

--
-- Name: catalog_get_products_in_department(integer, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_products_in_department(dept_id integer, description_length integer, page_number integer, products_per_page integer) RETURNS SETOF public.products
    LANGUAGE sql
    AS $$

with products_row_number as (select row_number() over (order by pd.id) as row ,pd.id,pd.name ,pd.price,pd.thumbnail,pd.image,

                                    pd.promo_front,pd.promo_dept,pd.created_at,pd.modified_at,pd.description

                                    from (select distinct p.id,p.name,

                                                          case when length(p.description::text) <= description_length then p.description

                                                          else substring(p.description::text,0,description_length) || '...' end as description,

                                                          p.thumbnail,

                                                          p.image,p.price,p.promo_dept,p.promo_front,p.created_at,p.modified_at

                                          from products p

                                               inner join products_categories pc on p.id = pc.product_id

                                               inner join categories c2 on pc.category_id = c2.id

                                         where p.promo_dept = 1::bit and c2.department_id = dept_id) as pd)

select id,name,description,price,thumbnail,image,promo_front,promo_dept,created_at,modified_at from products_row_number  WHERE row > (page_number - 1) * products_per_page

                                                                                                                           AND row <= page_number * products_per_page;



$$;


ALTER FUNCTION public.catalog_get_products_in_department(dept_id integer, description_length integer, page_number integer, products_per_page integer) OWNER TO hussein;

--
-- Name: catalog_get_products_on_front_promo(integer, integer, integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.catalog_get_products_on_front_promo(description_length integer, page_number integer, products_per_page integer) RETURNS TABLE(id integer, name character varying, description character varying, price money, thumbnail character varying, image character varying)
    LANGUAGE sql
    AS $$





    with products_row_number as (select row_number() over (order by id) as row ,count(id) over(partition by id) as products,id,name ,price,thumbnail,image,

                                        case when length(description::text) <= description_length then products.description

                                             else substring(description::text,0,description_length) || '...' end as description

                                 from products where promo_front = 1::bit)

    select id,name,description,price::money,thumbnail,image from products_row_number WHERE row > (page_number - 1) * products_per_page

                                                                                    AND row <= page_number * products_per_page;

$$;


ALTER FUNCTION public.catalog_get_products_on_front_promo(description_length integer, page_number integer, products_per_page integer) OWNER TO hussein;

--
-- Name: full_text_search(character varying); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.full_text_search(query character varying) RETURNS SETOF public.products
    LANGUAGE sql
    AS $$

  with ts_vectorized as (select *,to_tsvector(concat(name,' ',description)) as z from products)

select id,name,description,price,thumbnail,image,promo_front,promo_dept,created_at,modified_at

  from ts_vectorized where z @@ to_tsquery(query)

$$;


ALTER FUNCTION public.full_text_search(query character varying) OWNER TO hussein;

--
-- Name: membership_delete_role(integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.membership_delete_role(i integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$

declare

  a_count integer;

BEGIN

  delete from roles where id=i;

  GET DIAGNOSTICS a_count = ROW_COUNT;

  RAISE NOTICE 'The rows affected by A=% ', a_count;

  return a_count::bigint;

end;

$$;


ALTER FUNCTION public.membership_delete_role(i integer) OWNER TO hussein;

--
-- Name: users; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.users (
    id integer NOT NULL,
    first_name text,
    last_name text,
    email text NOT NULL,
    gender character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
    salt text NOT NULL,
    hashed_password text NOT NULL,
    login_count integer DEFAULT 1 NOT NULL,
    is_active boolean DEFAULT false NOT NULL,
    status character varying(10) DEFAULT 'offline'::character varying NOT NULL,
    last_login_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO hussein;

--
-- Name: membership_get_users_in_claim(character varying, character varying); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.membership_get_users_in_claim(c_type character varying, c_value character varying) RETURNS SETOF public.users
    LANGUAGE plpgsql
    AS $$

  declare

    u_id integer[];

  begin

    if exists(select user_id::int[] from user_claim where claim_type = c_type and claim_value = c_value)

      then

        select user_id::int[] into u_id from user_claim where claim_type = c_type and claim_value = c_value;

    end if;

    return query(select id,first_name,last_name,email,salt,hashed_password,is_active,login_count,last_login_at,created_at,modified_at from users where id in (u_id) );

  end;

$$;


ALTER FUNCTION public.membership_get_users_in_claim(c_type character varying, c_value character varying) OWNER TO hussein;

--
-- Name: membership_register_role(text); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.membership_register_role(n text) RETURNS bigint
    LANGUAGE sql
    AS $$

    insert into roles(name) values(n) returning id::bigint;

$$;


ALTER FUNCTION public.membership_register_role(n text) OWNER TO hussein;

--
-- Name: membership_register_user(text, text, text); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.membership_register_user(email text, st text, hash_pass text) RETURNS public.users
    LANGUAGE sql
    AS $$

  insert into users(email,salt,hashed_password) values(email,st,hash_pass) returning *;

$$;


ALTER FUNCTION public.membership_register_user(email text, st text, hash_pass text) OWNER TO hussein;

--
-- Name: membership_update_role(character varying, integer); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.membership_update_role(n character varying, i integer) RETURNS bigint
    LANGUAGE plpgsql
    AS $$

declare

  a_count integer;

BEGIN

  update roles set name = 'guest',modified_at = now() where id=i;

  GET DIAGNOSTICS a_count = ROW_COUNT;

  RAISE NOTICE 'The rows affected by A=% ', a_count;

  return a_count::bigint;

end;

$$;


ALTER FUNCTION public.membership_update_role(n character varying, i integer) OWNER TO hussein;

--
-- Name: membership_update_user(text, text, character varying, text, text, text, integer, boolean, character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.membership_update_user(f_name text, l_name text, g character varying, e text, s text, p text, l_c integer, ia boolean, st character varying, lu_l timestamp with time zone) RETURNS integer
    LANGUAGE sql
    AS $$

  with rows as (update users set first_name=f_name,last_name=l_name,email=e,gender=g,salt=s,hashed_password=p,login_count=l_c,is_active=ia,status=st,last_login_at=lu_l,modified_at=now() where email = e returning 1)

  select count(*)::int from rows;

$$;


ALTER FUNCTION public.membership_update_user(f_name text, l_name text, g character varying, e text, s text, p text, l_c integer, ia boolean, st character varying, lu_l timestamp with time zone) OWNER TO hussein;

--
-- Name: remove_role_from_user(integer, character varying); Type: FUNCTION; Schema: public; Owner: hussein
--

CREATE FUNCTION public.remove_role_from_user(u_id integer, r_name character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$

    declare

      row_affected integer :=0;

      r_id integer;

    begin

      if exists

      (select id from roles where name = r_name)

      then

        select id into r_id from roles where name = r_name;

        delete from users_roles where user_id = u_id and role_id = r_id;

        GET DIAGNOSTICS row_affected = ROW_COUNT;

        return row_affected;

      else

        return row_affected;

      end if;

    end;

$$;


ALTER FUNCTION public.remove_role_from_user(u_id integer, r_name character varying) OWNER TO hussein;

--
-- Name: attributes; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.attributes (
    id integer NOT NULL,
    name character varying(35) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attributes OWNER TO hussein;

--
-- Name: attributes_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.attributes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attributes_id_seq OWNER TO hussein;

--
-- Name: attributes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.attributes_id_seq OWNED BY public.attributes.id;


--
-- Name: attributes_values; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.attributes_values (
    id integer NOT NULL,
    attribute_id integer NOT NULL,
    value character varying(25) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attributes_values OWNER TO hussein;

--
-- Name: attributes_values_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.attributes_values_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attributes_values_id_seq OWNER TO hussein;

--
-- Name: attributes_values_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.attributes_values_id_seq OWNED BY public.attributes_values.id;


--
-- Name: categories_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categories_id_seq OWNER TO hussein;

--
-- Name: categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.categories_id_seq OWNED BY public.categories.id;


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.departments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.departments_id_seq OWNER TO hussein;

--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: products_attributes_values; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.products_attributes_values (
    product_id integer NOT NULL,
    attribute_value_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.products_attributes_values OWNER TO hussein;

--
-- Name: products_categories; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.products_categories (
    category_id integer NOT NULL,
    product_id integer NOT NULL
);


ALTER TABLE public.products_categories OWNER TO hussein;

--
-- Name: products_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.products_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.products_id_seq OWNER TO hussein;

--
-- Name: products_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.products_id_seq OWNED BY public.products.id;


--
-- Name: role_claim; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.role_claim (
    id integer NOT NULL,
    role_id integer NOT NULL,
    claim_type character varying(256) NOT NULL,
    claim_value character varying(256) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.role_claim OWNER TO hussein;

--
-- Name: role_claim_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.role_claim_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_claim_id_seq OWNER TO hussein;

--
-- Name: role_claim_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.role_claim_id_seq OWNED BY public.role_claim.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.roles OWNER TO hussein;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO hussein;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: shoppingcart; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.shoppingcart (
    cart_id character varying(36) NOT NULL,
    product_id integer NOT NULL,
    attributes character varying(1000),
    quantity integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.shoppingcart OWNER TO hussein;

--
-- Name: user_claim; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.user_claim (
    id integer NOT NULL,
    user_id integer NOT NULL,
    claim_type character varying(256) NOT NULL,
    claim_value character varying(256) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.user_claim OWNER TO hussein;

--
-- Name: user_claim_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.user_claim_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_claim_id_seq OWNER TO hussein;

--
-- Name: user_claim_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.user_claim_id_seq OWNED BY public.user_claim.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: hussein
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO hussein;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: hussein
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: users_roles; Type: TABLE; Schema: public; Owner: hussein
--

CREATE TABLE public.users_roles (
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    modified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users_roles OWNER TO hussein;

--
-- Name: attributes id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.attributes ALTER COLUMN id SET DEFAULT nextval('public.attributes_id_seq'::regclass);


--
-- Name: attributes_values id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.attributes_values ALTER COLUMN id SET DEFAULT nextval('public.attributes_values_id_seq'::regclass);


--
-- Name: categories id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.categories ALTER COLUMN id SET DEFAULT nextval('public.categories_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: products id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products ALTER COLUMN id SET DEFAULT nextval('public.products_id_seq'::regclass);


--
-- Name: role_claim id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.role_claim ALTER COLUMN id SET DEFAULT nextval('public.role_claim_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: user_claim id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.user_claim ALTER COLUMN id SET DEFAULT nextval('public.user_claim_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: attributes; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.attributes (id, name, created_at, modified_at) FROM stdin;
1	Color	2018-11-16 14:27:16.641369-08	2018-11-16 14:27:16.641369-08
\.


--
-- Name: attributes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.attributes_id_seq', 1, false);


--
-- Data for Name: attributes_values; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.attributes_values (id, attribute_id, value, created_at, modified_at) FROM stdin;
1	1	White	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
2	1	Black	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
3	1	Red	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
4	1	Orange	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
5	1	Yellow	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
6	1	Green	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
7	1	Blue	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
8	1	Indigo	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
9	1	Purple	2018-11-16 14:28:58.926691-08	2018-11-16 14:28:58.926691-08
\.


--
-- Name: attributes_values_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.attributes_values_id_seq', 1, false);


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.categories (id, name, description, department_id, created_at, modified_at) FROM stdin;
1	Love & Romance	Here's our collection of balloons with romantic messages.	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
2	Birthdays	Tell someone "Happy Birthday" with one of these wonderful balloons!	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
3	Weddings	Going to a wedding? Here's a collection of balloons for that special event!	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
4	Message Balloons	Why write on paper, when you can deliver your message on a balloon?	2	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
5	Cartoons	Buy a balloon with your child's favorite cartoon character!	2	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
6	Miscellaneous	Various baloons that your kid will most certainly love!	2	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
7	new category name 	new category description.	3	2018-12-04 16:29:32.565937-08	2018-12-04 16:29:32.565937-08
\.


--
-- Name: categories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.categories_id_seq', 7, true);


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.departments (id, name, description, created_at, modified_at) FROM stdin;
1	Anniversary Balloons	These sweet balloons are the perfect gift for someone you love.	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
2	Balloons for Children	The colorful and funny balloons will make any child smile!	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
3	new depratment name	new department description .\r\n                	2018-12-04 15:39:21.135905-08	2018-12-04 15:39:21.135905-08
\.


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.departments_id_seq', 3, true);


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.products (id, name, description, price, thumbnail, image, promo_front, promo_dept, created_at, modified_at) FROM stdin;
1	I Love You (Simon Elvin)	An adorable romantic balloon by Simon Elvin. You'll fall in love with the cute bear bearing a bouquet of roses, a heart with I Love You, and a card.	121.9900	t0326801.jpg	0326801.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
2	Elvis Hunka Burning Love	A heart shaped balloon with the great Elvis on it and the words "You're My Hunka Hunka Burnin' Love!". Also a copy of the Kings Signature.	12.9900	t16110p.jpg	16110p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
3	Funny Love	A red heart-shaped balloon with "I love you" written on a white heart surrounded by cute little hearts and flowers.	12.9900	t16162p.jpg	16162p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
4	Today, Tomorrow & Forever	White heart-shaped balloon with the words "Today, Tomorrow and Forever" surrounded with red hearts of varying shapes. "I Love You" appears at the bottom in a red heart.	12.9900	t16363p.jpg	16363p.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
5	Smiley Heart Red Balloon	Red heart-shaped balloon with a smiley face. Perfect for saying I Love You!	12.9900	t16744p.jpg	16744p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
6	Love 24 Karat	A red heart-shaped balloon with "I Love You" in script writing.  ld heart outlines adorn the background.	12.9900	t16756p.jpg	16756p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
7	Smiley Kiss Red Balloon	Red heart-shaped balloon with a smiley face and three kisses. A perfect gift for Valentine's Day!	12.9900	t16864p.jpg	16864p.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
8	Love You Hearts	A balloon with a simple message of love. What can be more romantic?	12.9900	t16967p.jpg	16967p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
9	Love Me Tender	A heart-shaped balloon with a picture of the King himself-Elvis Presley. This must-have for any Elvis fan has "Love Me Tender" written on it with a copy of Elvis's signature.	12.9900	t16973p.jpg	16973p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
10	I Can't Get Enough of You Baby	When you just can't get enough of someone, this Austin Powers style balloon says it all.	12.9900	t16974p.jpg	16974p.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
11	Picture Perfect Love Swing	A red heart-shaped balloon with a cute picture of two children kissing on a swing.	12.9900	t16980p.jpg	16980p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
12	I Love You Roses	A white heart-shaped balloon has "I Love You" written on it and is beautifully decorated with two flowers, a small red heart in the middle, and miniature hearts all around.	12.9900	t214006p.jpg	214006p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
13	I Love You Script	A romantic red heart-shaped balloon with "I Love You" in white. What more can you say?	12.9900	t214041p.jpg	214041p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
14	Love Rose	A white heart-shaped balloon with a rose and the words "I Love You." Romantic and irresistible.	12.9900	t214168p.jpg	214168p.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
15	You're So Special	Tell someone how special he or she is with this lovely heart-shaped balloon with a cute bear holding a flower.	12.9900	t215302p.jpg	215302p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
16	I Love You Red Flourishes	A simple but romantic red heart-shaped balloon with "I Love You" in large script writing.	12.9900	t22849b.jpg	22849b.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
17	I Love You Script	A simple, romantic red heart-shaped balloon with "I Love You" in small script writing.	12.9900	t45093.jpg	45093.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
18	Love Cascade Hearts	A romantic red heart-shaped balloon with hearts and I "Love You."	12.9900	t68841b.jpg	68841b.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
19	You're So Special	Someone special in your life? Let them know by sending this "You're So Special" balloon!	12.9900	t7004801.jpg	7004801.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
20	Love Script	Romance is in the air with this red heart-shaped balloon. Perfect for the love of your life.	12.9900	t7008501.jpg	7008501.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
21	Baby Hi Little Angel	Baby Hi Little Angel	12.9900	t115343p.jpg	115343p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
22	I'm Younger Than You	Roses are red, violets are blue, but this balloon isn't a romantic balloon at all. Have a laugh, and tease someone older.	12.9900	t16118p.jpg	16118p.jpg	1	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
23	Birthday Balloon	Great Birthday Balloons. Available in pink or blue. One side says "Happy Birthday To You" and the other side says  "Birthday Girl" on the Pink Balloon and "Birthday Boy" on the Blue Balloon. Especially great for children's parties.	12.9900	t26013.jpg	26013.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
24	Birthday Star Balloon	Send a birthday message with this delightful star-shaped balloon and make someone's day!	12.9900	t35732.jpg	35732.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
25	Tweety Stars	A cute Tweety bird on a blue heart-shaped balloon with stars. Sylvester is in the background, plotting away as usual.	12.9900	t0276001.jpg	0276001.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
26	You're Special	An unusual heart-shaped balloon with the words "You're special.".	12.9900	t0704901.jpg	0704901.jpg	1	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
27	I'm Sorry (Simon Elvin) Balloon	The perfect way to say you're sorry. Send a thought with this cute bear  balloon.	12.9900	t0707401.jpg	0707401.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
28	World's Greatest Mom	A lovely way to tell your Mom that she's special. Surprise her with this lovely balloon on her doorstep.	12.9900	t114103p.jpg	114103p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
29	 od Luck	Big day ahead? Wish someone " od Luck" with this colorful balloon!	12.9900	t114118p.jpg	114118p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
30	Big Congratulations Balloon	Does someone deserve a special pat on the back? This balloon is a perfect way to pass on the message	12.9900	t114208p.jpg	114208p.jpg	1	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
31	You're So Special	A purple balloon with the simple words "You're so Special!" on it.   on, let them know they are special.	12.9900	t16148p.jpg	16148p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
32	Thinking of You	A round balloon just screaming out "Thinking of You!"; especially great if you are far away from someone you care for.	12.9900	t16151p.jpg	16151p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
33	Welcome Back	A great way to say Welcome Back!	12.9900	t16558p.jpg	16558p.jpg	1	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
34	Words of Thanks	A round balloon with lots and lots of Thank You's written on it. You're sure to get the message through with this grateful balloon.	12.9900	t16772p.jpg	16772p.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
35	Missed You'll Be	If someone special is  ing away, let this cute puppy balloon tell them they'll be missed.	12.9900	t16809p.jpg	16809p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
36	You're Appreciated	A spotty balloon with the words "You're Appreciated". I bet they'll appreciate it too!	12.9900	t16988p.jpg	16988p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
37	Thinking of You	Thinking of someone? Let them know with this thoughtful heart-shaped balloon with flowers in the background.	12.9900	t214046p.jpg	214046p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
38	Get Well-Daisy Smiles	We all get sick sometimes and need something to cheer us up. Make the world brighter for someone with this Get Well Soon balloon.	12.9900	t21825b.jpg	21825b.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
39	Toy Story	Woody and Buzz from Toy Story, on a round balloon.	12.9900	t0366101.jpg	0366101.jpg	1	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
40	Rugrats Tommy & Chucky	If you are a Rugrats fan, you'll be nuts about this purple Rugrats balloon featuring Chucky and Tommy. A definite Nickelodeon Toon favorite.	12.9900	t03944l.jpg	03944l.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
41	Rugrats & Reptar Character	Rugrats balloon featuring Angelica, Chucky, Tommy, and Reptar.	12.9900	t03945L.jpg	03945L.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
42	Tweety & Sylvester	A blue round balloon with the great cartoon pair: Tweety & Sylvester.	12.9900	t0510801.jpg	0510801.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
43	Mickey Close-up	A close-up of Mickey Mouse on a blue heart-shaped balloon. Check out our close-up matching Minnie balloon.	12.9900	t0521201.jpg	0521201.jpg	1	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
44	Minnie Close-up	A close-up of Minnie Mouse on a pink heart-shaped balloon. Check out our close-up matching Mickey balloon.	12.9900	t0522101.jpg	0522101.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
45	Teletubbies Time	Time for Teletubbies balloon. Great gift for any kid.	12.9900	t0611401.jpg	0611401.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
46	Barbie My Special Things	Barbie and her friends on a round balloon.	12.9900	t0661701.jpg	0661701.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
47	Paddington Bear	Remember Paddington? A must-have for any Paddington Bear lover.	12.9900	t215017p.jpg	215017p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
48	I Love You Snoopy	The one and only Snoopy hugging Charlie Brown to say "I Love You."	12.9900	t215402p.jpg	215402p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
49	Pooh Adult	An adorable Winnie the Pooh balloon.	12.9900	t81947pl.jpg	81947pl.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
50	Pokemon Character	A Pokemon balloon with a lot of mini pictures of the rest of the cast. Pokemon,  tta catch 'em all!	12.9900	t83947.jpg	83947.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
51	Pokemon Ash & Pikachu	A Pokemon balloon with Ash and Pikachu.  tta catch 'em all!	12.9900	t83951.jpg	83951.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
52	Smiley Kiss Yellow	The ever-famous Smiley Face balloon on the classic yellow background with three smooch kisses.	12.9900	t16862p.jpg	16862p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
53	Smiley Face	A red heart-shaped balloon with a cartoon smiley face.	12.9900	t214154p.jpg	214154p.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
54	Soccer Shape	A soccer-shaped balloon great for any soccer fan.	12.9900	t28734.jpg	28734.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
55	 al Ball	A round soccer balloon. Ideal for any sports fan, or an original way to celebrate an important  al in that "oh so important" game.	12.9900	ta1180401.jpg	a1180401.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
56	Wedding Doves	A white heart-shaped balloon with wedding wishes and intricate designs of doves in silver.	12.9900	t1368601.jpg	1368601.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
57	Crystal Rose Silver	A transparent heart-shaped balloon with silver roses. Perfect for a silver anniversary or a wedding with a silver theme.	12.9900	t38196.jpg	38196.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
58	Crystal Rose  ld	A transparent heart-shaped balloon with  ld roses. Perfect for a  lden anniversary or a wedding with a  ld theme.	12.9900	t38199.jpg	38199.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
59	Crystal Rose Red	A transparent heart-shaped balloon with red roses. Perfect for an anniversary or a wedding with a red theme.	12.9900	t38202.jpg	38202.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
60	Crystal Etched Hearts	A transparent heart-shaped balloon with silver hearts. Perfect for a silver anniversary or a wedding with a silver theme.	12.9900	t42014.jpg	42014.jpg	0	1	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
61	Crystal Love Doves Silver	A transparent heart-shaped balloon with two love doves in silver.	12.9900	t42080.jpg	42080.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
62	Crystal Etched Hearts	A transparent heart-shaped balloon with red hearts.	12.9900	t42139.jpg	42139.jpg	0	0	2018-11-04 15:26:13.762521-08	2018-11-04 15:26:13.762521-08
\.


--
-- Data for Name: products_attributes_values; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.products_attributes_values (product_id, attribute_value_id, created_at, modified_at) FROM stdin;
1	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	1	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	2	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	3	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	4	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	5	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	6	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	7	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	8	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
1	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
2	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
3	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
4	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
5	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
6	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
7	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
8	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
9	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
10	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
11	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
12	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
13	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
14	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
15	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
16	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
17	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
18	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
19	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
20	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
21	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
22	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
23	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
24	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
25	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
26	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
27	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
28	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
29	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
30	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
31	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
32	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
33	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
34	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
35	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
36	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
37	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
38	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
39	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
40	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
41	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
42	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
43	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
44	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
45	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
46	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
47	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
48	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
49	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
50	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
51	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
52	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
53	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
54	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
55	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
56	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
57	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
58	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
59	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
60	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
61	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
62	9	2018-11-16 14:30:41.439728-08	2018-11-16 14:30:41.439728-08
\.


--
-- Data for Name: products_categories; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.products_categories (category_id, product_id) FROM stdin;
1	1
2	1
1	2
4	2
6	2
1	3
3	3
4	3
1	4
2	4
4	4
6	4
1	5
1	6
3	6
4	6
1	7
1	8
1	9
1	10
1	11
1	12
4	12
1	13
4	13
1	14
4	14
1	15
1	16
4	16
1	17
4	17
1	18
4	18
1	19
4	19
6	19
1	20
4	20
4	21
5	21
6	21
2	22
4	22
2	23
4	23
2	24
5	25
1	26
4	26
2	28
4	28
6	28
4	29
4	30
6	30
4	31
4	32
4	33
4	34
4	35
4	36
4	37
6	37
4	38
6	38
5	39
5	40
5	41
5	42
5	43
5	44
5	45
5	46
5	47
5	48
5	49
5	50
5	51
6	52
5	53
6	53
5	54
6	54
5	55
6	55
3	56
1	57
2	57
3	57
1	58
2	58
3	58
3	58
1	59
2	59
3	59
1	60
2	60
3	60
1	61
3	61
1	62
3	62
\.


--
-- Name: products_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.products_id_seq', 1, false);


--
-- Data for Name: role_claim; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.role_claim (id, role_id, claim_type, claim_value, created_at, modified_at) FROM stdin;
\.


--
-- Name: role_claim_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.role_claim_id_seq', 1, false);


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.roles (id, name, created_at, modified_at) FROM stdin;
1	admin	2018-11-23 15:45:22.044642-08	2018-11-23 15:45:22.044642-08
2	guest	2018-11-23 15:45:29.771159-08	2018-11-23 16:31:29.403733-08
3	customer	2018-11-24 12:51:27.604398-08	2018-11-24 12:51:27.604398-08
4	ADMIN	2018-11-29 15:50:49.335592-08	2018-11-29 15:50:49.335592-08
\.


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.roles_id_seq', 4, true);


--
-- Data for Name: shoppingcart; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.shoppingcart (cart_id, product_id, attributes, quantity, created_at, modified_at) FROM stdin;
\.


--
-- Data for Name: user_claim; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.user_claim (id, user_id, claim_type, claim_value, created_at, modified_at) FROM stdin;
1	1	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name	TEST@TEST.COM	2018-12-03 16:36:40.285799-08	2018-12-03 16:36:40.285799-08
2	1	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress	TEST@TEST.COM	2018-12-03 16:36:40.496947-08	2018-12-03 16:36:40.496947-08
3	1	http://schemas.microsoft.com/ws/2008/06/identity/claims/role	ADMIN	2018-12-03 16:36:40.509009-08	2018-12-03 16:36:40.509009-08
4	1	http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid	1	2018-12-03 16:36:40.509957-08	2018-12-03 16:36:40.509957-08
5	2	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name	SEPIDEH1@GMAIL.COM	2018-12-04 13:47:35.361-08	2018-12-04 13:47:35.361-08
6	2	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress	SEPIDEH1@GMAIL.COM	2018-12-04 13:47:35.392041-08	2018-12-04 13:47:35.392041-08
7	2	http://schemas.microsoft.com/ws/2008/06/identity/claims/role	ADMIN	2018-12-04 13:47:35.393034-08	2018-12-04 13:47:35.393034-08
8	2	http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid	2	2018-12-04 13:47:35.393034-08	2018-12-04 13:47:35.393034-08
9	3	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name	HUSSEIN@GMAIL.COM	2018-12-06 13:56:12.664795-08	2018-12-06 13:56:12.664795-08
10	3	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress	HUSSEIN@GMAIL.COM	2018-12-06 13:56:12.695817-08	2018-12-06 13:56:12.695817-08
11	3	http://schemas.microsoft.com/ws/2008/06/identity/claims/role	ADMIN	2018-12-06 13:56:12.6968-08	2018-12-06 13:56:12.6968-08
12	3	http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid	3	2018-12-06 13:56:12.697801-08	2018-12-06 13:56:12.697801-08
13	3	http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier	3	2018-12-06 13:56:12.698801-08	2018-12-06 13:56:12.698801-08
\.


--
-- Name: user_claim_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.user_claim_id_seq', 13, true);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.users (id, first_name, last_name, email, gender, salt, hashed_password, login_count, is_active, status, last_login_at, created_at, modified_at) FROM stdin;
1	\N	\N	TEST@TEST.COM	unknown	1DCg5l3k1+/ApsIJGjU7sJgj8yERuE6kZEil/sYNFwTfi0Yf/WGgB/5wz15syl3wrc5OzlZ9IwN7lZL+Mkwu4b1Y+fZXKnZQVfh7ZN0haU3tlwGn2M8y4G5A2Ql63fTJBLHoMA==	fCvwv0oRyT6U4yW2jl7VtMgt1N9x7y9wQmar5inLjXo=	1	f	offline	2018-12-04 04:06:28.372228-08	2018-12-03 16:36:28.372228-08	2018-12-03 16:36:40.513961-08
2	\N	\N	SEPIDEH1@GMAIL.COM	unknown	+TiTZJa2cZinOr58iLc8Zf/fNlva4Z1lwmnmjQrX5bqL4bac/p9AW5WMDNOcd+XeB4zTwWht75MHKN8dp0Z9p9sxkTA7uPCFrYr9LNgD5Tq/LV8tVc1zSrhyiMK6rj3R0e0F7w==	T0irv5RQhC2CmVR+eXPLLScrXRppePBmO4Ms5Pdr/60=	1	f	offline	2018-12-05 01:17:34.932638-08	2018-12-04 13:47:34.932638-08	2018-12-04 13:47:35.39503-08
3	\N	\N	HUSSEIN@GMAIL.COM	unknown	13zUv0BDFz62G+HYhe7F1NpQ30oquMJtxSHchW+dMULGYSLBF5cFcE4NiL+B7mP8vacPybbDD5u30JnsJeGkc9Po4lSBSY0NCzVxpJrDz6/4/rgBT6SxxcHvwMkoSUb/kNZvCQ==	YHV/GYt73+9NI6eWWpPX6Ba7t8yKkR32WoxNZvhOuIo=	1	f	offline	2018-12-07 01:26:11.877616-08	2018-12-06 13:56:11.877616-08	2018-12-06 13:56:12.699802-08
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: hussein
--

SELECT pg_catalog.setval('public.users_id_seq', 3, true);


--
-- Data for Name: users_roles; Type: TABLE DATA; Schema: public; Owner: hussein
--

COPY public.users_roles (user_id, role_id, created_at, modified_at) FROM stdin;
1	1	2018-12-03 16:36:31.350233-08	2018-12-03 16:36:31.350233-08
2	1	2018-12-04 13:47:35.135827-08	2018-12-04 13:47:35.135827-08
3	1	2018-12-06 13:56:12.386545-08	2018-12-06 13:56:12.386545-08
\.


--
-- Name: attributes attributes_name_key; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_name_key UNIQUE (name);


--
-- Name: attributes attributes_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.attributes
    ADD CONSTRAINT attributes_pkey PRIMARY KEY (id);


--
-- Name: attributes_values attributes_values_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.attributes_values
    ADD CONSTRAINT attributes_values_pkey PRIMARY KEY (id);


--
-- Name: categories categories_name_key; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_name_key UNIQUE (name);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: products_attributes_values products_attributes_values_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products_attributes_values
    ADD CONSTRAINT products_attributes_values_pkey PRIMARY KEY (product_id, attribute_value_id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: role_claim role_claim_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.role_claim
    ADD CONSTRAINT role_claim_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: shoppingcart shoppingcart_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.shoppingcart
    ADD CONSTRAINT shoppingcart_pkey PRIMARY KEY (cart_id, product_id);


--
-- Name: user_claim user_claim_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.user_claim
    ADD CONSTRAINT user_claim_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_roles users_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT users_roles_pkey PRIMARY KEY (user_id, role_id);


--
-- Name: categories categories_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON DELETE CASCADE;


--
-- Name: products_attributes_values products_attributes_values_attribute_value_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products_attributes_values
    ADD CONSTRAINT products_attributes_values_attribute_value_id_fkey FOREIGN KEY (attribute_value_id) REFERENCES public.attributes_values(id);


--
-- Name: products_attributes_values products_attributes_values_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products_attributes_values
    ADD CONSTRAINT products_attributes_values_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: products_categories products_categories_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products_categories
    ADD CONSTRAINT products_categories_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE CASCADE;


--
-- Name: products_categories products_categories_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.products_categories
    ADD CONSTRAINT products_categories_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: role_claim role_claim_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.role_claim
    ADD CONSTRAINT role_claim_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id);


--
-- Name: shoppingcart shoppingcart_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.shoppingcart
    ADD CONSTRAINT shoppingcart_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: user_claim user_claim_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.user_claim
    ADD CONSTRAINT user_claim_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users_roles users_roles_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT users_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: users_roles users_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: hussein
--

ALTER TABLE ONLY public.users_roles
    ADD CONSTRAINT users_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

