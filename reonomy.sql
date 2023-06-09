/*
Write SQL query to find the average yearly wage for H-1B visa applicants working in the San Francisco and Manhattan.

For this question I assumed:
	1. 1 case can be for 1 or more applicants
	2. Every applicant is paid the prevailing_wage vs. a value in range of wage_rate_of_pay_from/to
	3. Every applicant is already working when they applied
*/

  select datepart(year, case_submitted) as year
       , worksite_city as city
       , sum(
          case
            when pw_unit_of_pay = 'Year' then prevailing_wage*total_workers
            when pw_unit_of_pay = 'Hour' then prevailing_wage*40*52*total_workers
            when pw_unit_of_pay = 'Month' then prevailing_wage*12*total_workers
            when pw_unit_of_pay = 'Bi-Weekly' then prevailing_wage*26*total_workers
          end
         )/sum(total_workers) as avg_salary
    from cases
   where worksite_city in ('Manhattan', 'San Francisco')
     and worksite_state in ('NY', 'CA')
     and visa_class = 'H-1B'
group by datepart(year, case_submitted), worksite_city;

/*
Write a SQL query using the data visualizations, show why the average wage is higher in one city, San Francisco and Manhattan.

For this question I only used 2016 and 2017 data.

  select datepart(year, case_submitted) as year
       , worksite_city as city
	     , agent_representing_employer
       , sum(
          case
            when pw_unit_of_pay = 'Year' then prevailing_wage*total_workers
            when pw_unit_of_pay = 'Hour' then prevailing_wage*40*52*total_workers
            when pw_unit_of_pay = 'Month' then prevailing_wage*12*total_workers
            when pw_unit_of_pay = 'Bi-Weekly' then prevailing_wage*26*total_workers
          end
         )/sum(total_workers) as avg_salary
    from cases
   where worksite_city in ('Manhattan', 'San Francisco')
     and worksite_state in ('NY', 'CA')
     and visa_class = 'H-1B'
	   and datepart(year, case_submitted) in ('2016','2017')
	   and agent_representing_employer is not null
group by datepart(year, case_submitted), worksite_city, agent_representing_employer

I used the above query to compare wages of workers with and without representation then did select * from the view created below for the visualization.
*/

create view city_aggregation as (
select distinct 'SF' as city
     , agent_representing_employer as is_represented
     , sum(total_workers) over (partition by agent_representing_employer) as total
     , sum(total_workers) over () as grand_total
  from cases
 where worksite_city = 'San Francisco'
   and worksite_state = 'CA'
   and visa_class = 'H-1b'
   and datepart(year, case_submitted) in ('2016','2017')
   and agent_representing_employer is not null

union all

select distinct 'NY' as city
     , agent_representing_employer as is_represented
     , sum(total_workers) over (partition by agent_representing_employer) as total
     , sum(total_workers) over () as grand_total
  from cases
 where worksite_city = 'Manhattan'
   and worksite_state = 'NY'
   and visa_class = 'H-1b'
   and agent_representing_employer is not null
)

/*
Write a SQL query to show top 3 cities per state. Result of the Query should return top 3 city names per State, Avg Wage and Rank.
Clarification: Rank 1 is assigned to Highest AVG Wage.

For this question:
	1. I limited to H1-B applicants
	3. I used 2015 applications because in other years there looked to be some applications that contained errors i.e. an hourly wage of over $50,000
*/

with avg_salary_calculations as (
  select datepart(year, case_submitted) as year
	     , worksite_state
	     , worksite_city
	     , sum(
		       case
			        when pw_unit_of_pay = 'Year' then prevailing_wage*total_workers
			        when pw_unit_of_pay = 'Hour' then prevailing_wage*40*52*total_workers
			        when pw_unit_of_pay = 'Month' then prevailing_wage*12*total_workers
			        when pw_unit_of_pay = 'Bi-Weekly' then prevailing_wage*26*total_workers
		       end
	       )/sum(total_workers) as avg_salary
    from cases
   where visa_class = 'H-1B'
     and datepart(year, case_submitted) = 2015
group by datepart(year, case_submitted), worksite_state, worksite_city
),

avg_salary_rankings as (
  select worksite_state
  	   , worksite_city
  	   , avg_salary, rank() over (partition by worksite_state order by avg_salary desc) as rank
    from avg_salary_calculations
   where worksite_state is not null
 )

  select *
    from avg_salary_rankings
   where rank <= 3
order by worksite_state;

/*
How would you optimize the SQL query in part 3? Explain
*/

One approach would be to have a table with the year, state, city, avg_salary and ranking already calculated so you could perform a select * from table where rank <= X
