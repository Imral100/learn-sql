-- =====================================================================
-- person-car: tabloların SON hali (aşama 1–7 sonrası)
--
-- Bu dosya tabloları doğrudan son yapılarıyla oluşturur.
-- Migration'lar (stage-*/migration.sql) tarihsel kayıttır;
-- bu dosyadan sonra ÇALIŞTIRILMAMALIDIR.
--
-- Doğrulama: migration yolu ile pg_dump --schema-only karşılaştırması
-- sonucunda iki yolun birebir aynı şemayı ürettiği görüldü.
-- =====================================================================

drop table if exists car;
drop table if exists person;


create table person (
    id bigint generated always as identity,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    email varchar(150),
    fin_code varchar(7) not null,
    date_of_birth date not null,
    registered_at timestamp not null default now(),
    gender varchar(20) not null,
    country_of_birth varchar(50) not null,

    constraint person_id_pk primary key (id),
    constraint person_first_name_check check (trim(first_name) <> ''),
    constraint person_last_name_check check (trim(last_name) <> ''),
    constraint person_email_unique unique (email),
    constraint person_fin_code_unique unique (fin_code),
    constraint person_fin_code_check check (fin_code ~  '^[A-Z0-9]{7}$'),
    constraint person_date_of_birth_check check (date_of_birth >= '1940-01-01' and date_of_birth <= current_date),
    constraint person_gender_check check (gender in ('Male', 'Female', 'Agender', 'Polygender', 'Bigender', 'Genderfluid', 'Non-binary', 'Genderqueer'))
);

create table car (
    id bigint generated always as identity,
    make varchar(50) not null,
    model varchar(30) not null,
    price numeric(10, 2) not null,
    vin varchar(17) not null,
    owner_id bigint,
    production_year int not null,
    purchased_at date,

    constraint car_id_pk primary key (id),
    constraint car_price_check check (price > 0),
    constraint car_vin_unique unique (vin),
    constraint car_vin_check check (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),
    -- Kişi silinince araba sistemde kalır, sadece sahipsiz olur.
    -- Not: car_owner_purchase_check ile çakışır (bkz. stage-6, görev 6.4).
    constraint car_owner_id_fk foreign key (owner_id) references person (id) on delete set null,

    constraint car_production_year_check check (production_year >= 1886 and production_year <= extract (year from current_date) + 1),

    -- Sahibi olan arabanın satın alma tarihi olmalı, sahipsiz arabanın olmamalı.
    constraint car_owner_purchase_check check (
        (owner_id is null and purchased_at is null)
        or
        (owner_id is not null and purchased_at is not null)
    ),

    -- Tarih varsa: bugünden sonra olamaz, üretim yılından önce olamaz.
    -- purchased_at NULL ise ifade NULL olur ve CHECK geçer.
    constraint car_purchased_at_check check (
        (purchased_at <= current_date) and (extract (year from purchased_at) >= production_year)
    )
);

-- FK, child sütununa otomatik index eklemez.
create index car_owner_id_idx on car (owner_id);
