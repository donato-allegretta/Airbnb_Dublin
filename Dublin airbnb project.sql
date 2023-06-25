-- data from Inside Airbnb
-- data exploration

--How many listings are there in Dublin currently?
select count(distinct id) from PortfolioProject..listings;
--7,836 unique listings

-- How many Airbnb hosts are there in Dublin currently?
select count(distinct host_id) from PortfolioProject..listings;
-- 5538 unique hosts

-- Hosts with multiple listings?
select no_listings_per_host, 
	count(host_id) as host_count,
	cast(count(host_id) as decimal)/sum(count(host_id)) over () as percentage
from (
	select host_id, count(distinct id) as no_listings_per_host
	from PortfolioProject..listings
	group by host_id
) as a
group by no_listings_per_host
order by no_listings_per_host;
-- 4600 (83%) hosts have only one listing, other hosts could have multiple listings (up to as many as 72)

-- Clean price variable
select *, price, cast(replace(replace(price, '$', ''), ',', '') as decimal(10,0)) as price_clean
from PortfolioProject..listings;
--alter table PortfolioProject..listings
--add price_clean decimal(10, 0);
--update PortfolioProject..listings
--set price_clean = cast(replace(replace(price, '$', ''), ',', '') as decimal(10, 0));
select * from PortfolioProject..listings
where price_clean is null;

-- Number of listings and average price by neighbourhood
select neighbourhood_cleansed, count(id) as no_listings, avg(price_clean) as avg_price
from PortfolioProject..listings
group by neighbourhood_cleansed
order by avg_price desc;
-- Properties in Dublin City costs significantly more than any other neighbourhood

-- Number of listings and average price by Room Type
select room_type, count(id) as no_listings, avg(price_clean) as avg_price
from PortfolioProject..listings
group by room_type
order by avg_price desc;
-- What about number of beds?

-- Average price per bed by neighbourhood
select neighbourhood_cleansed, sum(price_clean)/sum(beds) as price_per_bed
from PortfolioProject..listings
group by neighbourhood_cleansed
order by price_per_bed desc


-- Revenue Potential
-- What are the most profitable properties?
select *
from (
    select id, name, price_clean, 30-availability_30 as booked_out30, 365-availability_365 as booked_out365,
	cast(price_clean*(30-availability_30) as decimal(10,0)) as proj_rev30
    from PortfolioProject..listings
) as a
where booked_out365 < 365
order by proj_rev30 desc;

-- What about potential by neighbourhood and room type?
select
  neighbourhood_cleansed,
  sum(price_clean * (30 - availability_30)) as proj_rev30,
  sum(case when room_type = 'Entire home/apt' then price_clean * (30 - availability_30) end) as potential_entire_home,
  sum(case when room_type = 'Private room' then price_clean * (30 - availability_30) end) as potential_private_room,
  sum(case when room_type = 'Share room' then price_clean * (30 - availability_30) end) as potential_shared_room,
  sum(case when room_type = 'Hotel room' then price_clean * (30 - availability_30) end) as potential_hotel_room
from PortfolioProject..listings
where last_review >= '2022-01-01'
group by neighbourhood_cleansed
order by proj_rev30 desc
-- Entire homes in Dublin City as a room type is the most in demand. No shared room and very few hotel room regardless of the location.




-- Next let's analyse the reviews and ratings
-- Use number_of_reviews as a metric for popularity

select neighbourhood_cleansed, count(reviews.comments)/sum(listings.id) as num_reviews_per_listings from PortfolioProject..reviews
inner join PortfolioProject..listings on PortfolioProject..reviews.listing_id = PortfolioProject..listings.id
group by neighbourhood_cleansed order by num_reviews_per_listings desc;
-- Dan Laoghaire-Rathdown is slightly more popular than the other locations

-- What are the hosts with the most negative comments about dirty properties
select host_id, host_name, count(*) as num_dirty_reviews from PortfolioProject..reviews
inner join PortfolioProject..listings on PortfolioProject..reviews.listing_id = PortfolioProject..listings.id
where comments like '%dirty%'
group by host_id, host_name order by num_dirty_reviews desc;


-- Number of superhosts/non-superhosts in Dublin
select 
  count(case when host_is_superhost = 't' then id end) as Superhost,
  count(case when host_is_superhost = 'f' then id end) as Regular
from PortfolioProject..listings;
-- 1168 superhosts and 6709 regular hosts;

-- Looking into relationship between superhost status and price
select
  avg(case when host_is_superhost = 't' then price_clean end) as superhost_avg_price,
  avg(case when host_is_superhost = 'f' then price_clean end) as regular_avg_price
from PortfolioProject..listings
where last_review >= '2022-01-01';
-- regular hosts charge more (282 vs 192)

-- Pulling the same query, but price per bed this time
select
  avg(case when host_is_superhost = 't' then price_clean/beds end) as superhost_avg_price_per_bed,
  avg(case when host_is_superhost = 'f' then price_clean/beds end) as regular_avg_price_per_bed
from PortfolioProject..listings
where last_review >= '2022-01-01';
-- Still, regular hosts charge more

-- Next, let's look at ratings for superhosts vs regular hosts
select 
  host_is_superhost,
  avg(review_scores_rating) as avg_rating,
  avg(review_scores_accuracy) as avg_rating_accuracy,
  avg(review_scores_cleanliness) as avg_rating_cleanliness,
  avg(review_scores_checkin) as avg_rating_checkin,
  avg(review_scores_communication) as avg_rating_comm,
  avg(review_scores_location) as avg_rating_location
from PortfolioProject..listings
where last_review >= '2022-01-01'
group by host_is_superhost;
-- Superhosts have better ratings

select
  host_is_superhost,
  avg(price_clean * (30 - availability_30)) as avg_proj_rev30
from PortfolioProject..listings
where last_review >= '2022-01-01'
group by host_is_superhost;
-- So how come regular hosts charge more and have better revenues? Being a superhost doesn't seem to pay off
-- Missing opportuinity for Airbnb


-- Relationship between instant book and revenue potential

select
  avg(case when instant_bookable = 't' then price_clean * (30 - availability_30) end) as instantbook_potential,
  avg(case when instant_bookable = 'f' then price_clean * (30 - availability_30) end) as regular_potential
from PortfolioProject..listings
where last_review >= '2022-01-01';
-- Regular bookings obtain better revenues than instantbooking
-- This does not match Airbnb's claim that enabling instant book increases a host's earnings

-- Let's look at price and availability_30 separately
select
  avg(case when instant_bookable = 't' then price_clean end) as instantbook_avg_price,
  avg(case when instant_bookable = 'f' then price_clean end) as regular_avg_price
from PortfolioProject..listings
where last_review >= '2022-01-01'; 
  
-- Average price is even higher without instant book, according to Airbnb hosts get double the reservations because of the convenience factor
-- Is it true that with instant book enabled, hosts get more reservations?
-- Use the availibility for the next 30 days to measure it

select
  avg(case when instant_bookable = 't' then availability_30 end) as instantbook_avail,
  avg(case when instant_bookable = 'f' then availability_30 end) as regular_avail
from PortfolioProject..listings
where last_review >= '2022-10-01';

-- Hosts with instant book seems to be more available, which means they get less reservations.
-- Again a the missing opportunity - hosts are not charging premium for the convenience that comes with instant book
-- Airbnb should work on making their hosts better informed in terms of pricing, also incentivise hosts by optimizing search results etc
