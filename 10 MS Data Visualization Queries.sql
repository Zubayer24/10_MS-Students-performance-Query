-- Actual mark calculation

SELECT  
es.user_id, 
e.exam_name, 
es.session_id, 
(es.total_correct_answers * e.each_ques_mark)  - (es.total_false_answers * e.per_ques_negative_marking) AS actual_mark 
FROM  
10_ms.exam_sessions AS es 
JOIN  
10_ms.exams AS e 
ON  
es.exam_id = e.exam_id;


-- Pass/Fail Classification

SELECT   
es.user_id AS auth_user_id,   
e.exam_name,   
(es.total_correct_answers * e.each_ques_mark)   - (es.total_false_answers * e.per_ques_negative_marking) AS actual_mark,   
e.pass_mark,   
IF(   
(es.total_correct_answers * e.each_ques_mark)   - (es.total_false_answers * e.per_ques_negative_marking) >= e.pass_mark,   
'Pass',   
'Fail'   
) AS result_status   
FROM   
10_ms.exam_sessions AS es   
INNER JOIN   
10_ms.exams AS e   
ON   
es.exam_id = e.exam_id;


-- Top Performers- Finding the top 5 students in each exam based on their actual mark.		
WITH marks_calculated AS (
    SELECT 
        es.user_id AS auth_user_id,
        e.exam_name,
        (es.total_correct_answers * e.each_ques_mark) 
        - (es.total_false_answers * e.per_ques_negative_marking) AS actual_mark
    FROM 10_ms.exam_sessions AS es
    JOIN 10_ms.exams AS e
        ON es.exam_id = e.exam_id
),
ranked_students AS (
    SELECT
        exam_name,
        auth_user_id,
        actual_mark,
        RANK() OVER (PARTITION BY exam_name ORDER BY actual_mark DESC) AS `rank`
    FROM marks_calculated
)
SELECT 
    exam_name,
    auth_user_id,
    actual_mark,
    `rank`
FROM ranked_students
WHERE `rank` <= 5
ORDER BY exam_name, `rank`;

--  Performance Trend per Student Across Exams for each student, determining how their actual mark changed from their previous exam.	

select 
auth_user_id, exam_name, user_exam_starts_at, actual_mark, 
previous_actual_mark, 
IF( 
previous_actual_mark is null, null, 
if(previous_actual_mark < actual_mark, 'improved', 
if(previous_actual_mark > actual_mark, 'declained','Same') 
) 
) as performance_trend 
FROM ( 
SELECT es.user_id AS auth_user_id, 
e.exam_name, es.user_exam_starts_at, 
(es.total_correct_answers * e.each_ques_mark) - (es.total_false_answers * 
e.per_ques_negative_marking) AS actual_mark, 
LAG( 
(es.total_correct_answers * e.each_ques_mark) - (es.total_false_answers * 
e.per_ques_negative_marking) 
) 
OVER( 
PARTITION BY es.user_id 
ORDER BY user_exam_starts_at 
) AS previous_actual_mark 
FROM 10_MS.exam_sessions es 
INNER JOIN 10_MS.exams e 
ON es.exam_id=e.exam_id 
) AS performance;	