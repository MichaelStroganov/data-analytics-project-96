-- Скрипт для определения кол-ва органических визитов
select
	visit_date::date,
	count(visitor_id)
from
	sessions s
where
	source = 'organic'
group by
	visit_date::date;

-- Скрипт для создания сводной таблицы
with visitors_with_leads as (
select
	s.visitor_id,
	s.visit_date,
	l.lead_id,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	lower(s.source) as utm_source,
	row_number() over (
            partition by s.visitor_id
order by
	s.visit_date desc
        ) as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
	and s.visit_date <= l.created_at
where
	s.medium != 'organic'
),
aggregated_data as (
select
	utm_source,
	utm_medium,
	utm_campaign,
	date(visit_date) as visit_date,
	count(visitor_id) as visitors_count,
	count(
            case
                when created_at is not null then visitor_id
            end
        ) as leads_count,
	count(case when status_id = 142 then visitor_id end) as purchases_count,
	sum(case when status_id = 142 then amount end) as revenue
from
	visitors_with_leads
where
	rn = 1
group by
	1,
	2,
	3,
	4
),
marketing_data as (
select
	date(campaign_date) as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as total_cost
from
	ya_ads
group by
	1,
	2,
	3,
	4
union all
select
	date(campaign_date) as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as total_cost
from
	vk_ads
group by
	1,
	2,
	3,
	4
)
select
	a.visit_date,
	a.visitors_count,
	a.utm_source,
	a.utm_medium,
	a.utm_campaign,
	m.total_cost,
	a.leads_count,
	a.purchases_count,
	a.revenue
from
	aggregated_data as a
left join marketing_data as m
    on
	a.visit_date = m.visit_date
	and a.utm_source = m.utm_source
	and a.utm_medium = m.utm_medium
	and a.utm_campaign = m.utm_campaign
order by
	9 desc nulls last,
	1,
	2 desc,
	3,
	4;

-- Скрипт для поиска органических лидов 
with visitors_with_leads as (
select
	s.visitor_id,
	s.visit_date,
	l.lead_id,
	l.created_at,
	l.amount,
	l.closing_reason,
	l.status_id,
	s.medium as utm_medium,
	s.campaign as utm_campaign,
	s.source as utm_source,
	row_number() over (
            partition by s.visitor_id
order by
	s.visit_date desc
        ) as rn
from
	sessions as s
left join leads as l
        on
	s.visitor_id = l.visitor_id
	and s.visit_date <= l.created_at
where
	s.source = 'organic'
)
select
	visit_date::date,
	count(lead_id)
from
	visitors_with_leads
where
	rn = 1
group by
	visit_date::date;

-- Скрипт для поиска затрат по каналам
select
	date(campaign_date) as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as total_cost
from
	ya_ads
group by
	1,
	2,
	3,
	4
union all
    select
	date(campaign_date) as visit_date,
	utm_source,
	utm_medium,
	utm_campaign,
	sum(daily_spent) as total_cost
from
	vk_ads
group by
	1,
	2,
	3,
	4;
