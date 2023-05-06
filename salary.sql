
use employees;

-- SALARY REPORT PART 1
-- version 1
SELECT
    e.gender
,   AVG(s.salary) as avg_salary
,   COUNT(1) as amount
FROM
        salaries as s
    INNER JOIN
        employees e on e.emp_no = s.emp_no
WHERE NOW() BETWEEN s.from_date AND s.to_date
GROUP BY e.gender
ORDER By 2 DESC;

-- version 2
SELECT
    e.gender
,   AVG(s.salary) as avg_salary
,   COUNT(1) as amount
FROM
        salaries as s
    INNER JOIN
        employees e using(emp_no)
WHERE NOW() BETWEEN s.from_date AND s.to_date

GROUP BY e.gender
ORDER By 2 DESC;


-- SALARY REPORT PART 2
-- version 1
SELECT
    e.gender
,   d.dept_name
,   avg(s.salary) as avg_salary
,   count(1) as amount
FROM
        salaries as s
    INNER JOIN
        employees e on e.emp_no = s.emp_no
    INNER JOIN
        dept_emp as de on
            de.emp_no = e.emp_no
            AND NOW() BETWEEN de.from_date and de.to_date

    INNER JOIN
        departments as d on d.dept_no = de.dept_no
WHERE NOW() BETWEEN s.from_date AND s.to_date
GROUP BY e.gender, d.dept_name WITH ROLLUP
ORDER By 2, 1 DESC;

-- version 2
SELECT
    e.gender
,   d.dept_name
,   avg(s.salary) as avg_salary
,   count(1) as amount
FROM
        salaries as s
    INNER JOIN
        employees e using(emp_no)
    INNER JOIN
        dept_emp as de on
            de.emp_no = e.emp_no
            AND NOW() BETWEEN de.from_date and de.to_date

    INNER JOIN
        departments as d USING (dept_no)
WHERE NOW() BETWEEN s.from_date AND s.to_date
GROUP BY e.gender, d.dept_name WITH ROLLUP
ORDER By 2, 1 DESC;


    -- SALARY REPORT PART 3
-- version 1
WITH cte as (
    SELECT
        e.gender
    ,   d.dept_name
    ,   avg(s.salary) as avg_salary
    ,   count(1) as amount
    FROM salaries as s
             INNER JOIN
         employees e on e.emp_no = s.emp_no
             INNER JOIN
         dept_emp as de on de.emp_no = e.emp_no
                 AND NOW() BETWEEN de.from_date and de.to_date
             INNER JOIN
         departments as d on d.dept_no = de.dept_no
    WHERE NOW() BETWEEN s.from_date AND s.to_date
    GROUP BY e.gender, d.dept_name
    WITH ROLLUP
    ORDER By 2, 1 DESC
)
SELECT
    *
    , LEAD(avg_salary, 1) OVER (PARTITION BY dept_name ORDER BY gender) / avg_salary as diff
FROM cte
WHERE True
    AND gender IS NOT NULL
    AND dept_name IS NOT NULL;

-- version 2
WITH cte as (
    SELECT
        e.gender
    ,   d.dept_name
    ,   avg(s.salary) as avg_salary
    ,   count(1) as amount
    FROM salaries as s
             INNER JOIN
         employees e using (emp_no)
             INNER JOIN
         dept_emp as de on
                 de.emp_no = e.emp_no
                 AND NOW() BETWEEN de.from_date and de.to_date
             INNER JOIN
         departments as d USING (dept_no)
    WHERE NOW() BETWEEN s.from_date AND s.to_date
    GROUP BY e.gender, d.dept_name
    WITH ROLLUP
    ORDER By 2, 1 DESC
)
SELECT
    *
    , LEAD(avg_salary, 1) OVER (PARTITION BY dept_name ORDER BY gender) / avg_salary as diff
FROM cte
WHERE True
    AND gender IS NOT NULL
    AND dept_name IS NOT NULL;


-- SALARY REPORT PART 4

DELIMITER $$

CREATE PROCEDURE employees.generate_payment_report(p_date DATE)
BEGIN

    SET p_date = LAST_DAY(p_date);

    DROP TABLE IF EXISTS tmp_report;
    CREATE TEMPORARY  TABLE tmp_report AS
    WITH cte as (
        SELECT e.gender,
               d.dept_name,
               avg(s.salary) as avg_salary,
               count(1)      as amount
        FROM salaries as s
                 INNER JOIN
             employees e on e.emp_no = s.emp_no
                 INNER JOIN
             dept_emp as de on de.emp_no = e.emp_no AND p_date BETWEEN de.from_date and de.to_date
                 INNER JOIN
             departments as d on d.dept_no = de.dept_no
        WHERE p_date BETWEEN s.from_date AND s.to_date
        GROUP BY e.gender, d.dept_name
        WITH ROLLUP
        ORDER By 2, 1 DESC
    )
    SELECT
        *
        , LEAD(avg_salary, 1) OVER (PARTITION BY dept_name ORDER BY gender) / avg_salary as diff
    FROM cte
    WHERE True
        AND gender IS NOT NULL
        AND dept_name IS NOT NULL;

    DELETE FROM employees.payment_report
    WHERE generation_date = p_date;

    INSERT INTO employees.payment_report
    SELECT
        *,
        p_date,
        now()
    FROM tmp_report;
END;
DELIMITER $$

-- generating a report in the current view (in a sense an exception)
CALL employees.generate_payment_report(NOW());

-- generating a report for '2021-01-31'
CALL employees.generate_payment_report('2021-01-31');

-- the following call should also generate a report for '2021-01-31'
CALL employees.generate_payment_report('2021-01-05');